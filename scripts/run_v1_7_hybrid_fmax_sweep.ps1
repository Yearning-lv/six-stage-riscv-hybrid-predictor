param(
    [Parameter(Mandatory = $true)]
    [string]$VivadoBat,
    [string]$OutputDir,
    [string]$ResultCsv
)

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
$SourceFile = Join-Path $repoRoot 'fpga\riscv_cpu_fpga_37_byte_bram_hybrid_predictor_sync_reset_test.v'
$TopFile = Join-Path $repoRoot 'fpga\a7lite_riscv_top_hybrid_v1_7.v'
$PinXdc = Join-Path $repoRoot 'fpga\A7-LITE_100T.xdc'

if ([string]::IsNullOrWhiteSpace($OutputDir)) {
    $OutputDir = Join-Path $repoRoot 'local-vivado-project\v1_7_fmax_hybrid'
}
if ([string]::IsNullOrWhiteSpace($ResultCsv)) {
    $ResultCsv = Join-Path $repoRoot 'results\v1_7_hybrid_fmax_sweep.csv'
}

if (-not (Test-Path -LiteralPath $VivadoBat)) {
    throw "Vivado executable not found: $VivadoBat"
}
foreach ($path in @($SourceFile, $TopFile, $PinXdc)) {
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Required file not found: $path"
    }
}

$frequencies = @(
    [pscustomobject]@{ MHz = 60; Period = 16.667 },
    [pscustomobject]@{ MHz = 70; Period = 14.286 },
    [pscustomobject]@{ MHz = 80; Period = 12.500 },
    [pscustomobject]@{ MHz = 90; Period = 11.111 },
    [pscustomobject]@{ MHz = 100; Period = 10.000 }
)

New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null
$resultDir = Split-Path -Parent $ResultCsv
New-Item -ItemType Directory -Force -Path $resultDir | Out-Null

function Read-TimingSummary([string]$ReportPath) {
    if (-not (Test-Path -LiteralPath $ReportPath)) { return '' }
    $content = Get-Content -LiteralPath $ReportPath
    $start = ($content | Select-String -Pattern 'Design Timing Summary' | Select-Object -First 1).LineNumber
    if ($null -eq $start) { return '' }

    for ($i = $start; $i -lt $content.Count; $i++) {
        $fields = ($content[$i] -split '\s+') | Where-Object { $_ -ne '' }
        if ($fields.Count -ge 13 -and
            $fields[0] -match '^-?\d+(?:\.\d+)?$' -and
            $fields[1] -match '^-?\d+(?:\.\d+)?$' -and
            $fields[2] -match '^\d+$' -and
            $fields[5] -match '^-?\d+(?:\.\d+)?$') {
            return [pscustomobject]@{
                Wns = $fields[0]
                Tns = $fields[1]
                Whs = $fields[5]
            }
        }
    }
    return ''
}

$records = @()

foreach ($item in $frequencies) {
    $name = "hybrid_$($item.MHz)MHz"
    $projectDir = Join-Path $OutputDir $name
    $projectFile = Join-Path $projectDir "$name.xpr"
    $scriptFile = Join-Path $projectDir "run_$name.tcl"
    $constraintFile = Join-Path $projectDir "$name.xdc"
    $constraintFileName = "$name.xdc"
    $runLog = Join-Path $projectDir "vivado_$name.log"
    $projectDirTcl = $projectDir.Replace('\', '/')
    $sourceFileTcl = $SourceFile.Replace('\', '/')
    $topFileTcl = $TopFile.Replace('\', '/')

    New-Item -ItemType Directory -Force -Path $projectDir | Out-Null

    $constraintText = Get-Content -LiteralPath $PinXdc -Raw
    $clockLine = "create_clock -period $($item.Period.ToString('0.000', [Globalization.CultureInfo]::InvariantCulture)) -name sys_clk [get_ports clk]"
    $constraintText = [regex]::Replace($constraintText, '(?m)^create_clock\s+[^\r\n]+', $clockLine)
    Set-Content -LiteralPath $constraintFile -Value $constraintText -Encoding ASCII

    $tcl = @"
create_project $name {$projectDirTcl} -part xc7a100tlfgg484-2L -force
set_property target_language Verilog [current_project]
add_files -norecurse {$sourceFileTcl}
add_files -norecurse {$topFileTcl}
add_files -fileset constrs_1 -norecurse $constraintFileName
set_property top a7lite_riscv_top_hybrid_v1_7 [current_fileset]
update_compile_order -fileset sources_1
launch_runs synth_1 -jobs 4
wait_on_run synth_1
launch_runs impl_1 -to_step write_bitstream -jobs 4
wait_on_run impl_1
close_project
"@
    Set-Content -LiteralPath $scriptFile -Value $tcl -Encoding ASCII

    $vivadoArgs = "-mode batch -notrace -source `"$scriptFile`""
    $process = Start-Process -FilePath $VivadoBat `
        -ArgumentList $vivadoArgs `
        -WorkingDirectory $projectDir -RedirectStandardOutput $runLog `
        -RedirectStandardError "$runLog.err" -Wait -PassThru

    $implDir = Join-Path $projectDir "$name.runs\impl_1"
    $timingReport = Join-Path $implDir "a7lite_riscv_top_hybrid_v1_7_timing_summary_routed.rpt"
    $bitstream = Join-Path $implDir "a7lite_riscv_top_hybrid_v1_7.bit"
    $timing = Read-TimingSummary $timingReport
    $wns = if ($timing) { $timing.Wns } else { '' }
    $whs = if ($timing) { $timing.Whs } else { '' }
    $tns = if ($timing) { $timing.Tns } else { '' }
    $bitstreamStatus = if (Test-Path -LiteralPath $bitstream) { 'PASS' } else { 'FAIL' }
    $runStatus = if ($process.ExitCode -eq 0 -and $bitstreamStatus -eq 'PASS') { 'PASS' } else { 'FAIL' }

    $records += [pscustomobject]@{
        frequency_mhz = $item.MHz
        period_ns = $item.Period.ToString('0.000', [Globalization.CultureInfo]::InvariantCulture)
        wns_ns = $wns
        whs_ns = $whs
        tns_ns = $tns
        bitstream = $bitstreamStatus
        status = $runStatus
        notes = "project=$projectDir; exit_code=$($process.ExitCode)"
    }
}

$records | Export-Csv -LiteralPath $ResultCsv -NoTypeInformation -Encoding UTF8
Write-Host "Fmax sweep completed. Results: $ResultCsv"


