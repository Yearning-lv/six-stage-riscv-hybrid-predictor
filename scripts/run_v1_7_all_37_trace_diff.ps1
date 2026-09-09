$root = Split-Path -Parent $PSScriptRoot
$tb = Join-Path $root 'tests\trace\tb_trace_v1_7_byte_bram.v'
$outDir = Join-Path $root 'sim_artifacts\build_outputs'
$traceDir = Join-Path $root 'results\traces\v1_7\37_instr'
$resultFile = Join-Path $root 'results\v1_7_trace_diff_summary.csv'
$hex = 'tests\37_instr\rv32i_37.hex'
$commitCount = 75

$versions = [ordered]@{
    'No Predictor' = 'fpga\riscv_cpu_fpga_37_byte_bram_test.v'
    'BTB' = 'fpga\riscv_cpu_fpga_37_byte_bram_btb_test.v'
    'BTB+PHT' = 'fpga\riscv_cpu_fpga_37_byte_bram_btb_pht_test.v'
    'BTB+Gshare' = 'fpga\riscv_cpu_fpga_37_byte_bram_btb_gshare_test.v'
    'BTB+Gshare+RAS' = 'fpga\riscv_cpu_fpga_37_byte_bram_btb_gshare_ras_test.v'
    'Hybrid' = 'fpga\riscv_cpu_fpga_37_byte_bram_hybrid_predictor_sync_reset_test.v'
}

if (!(Test-Path -LiteralPath $outDir)) {
    New-Item -ItemType Directory -Path $outDir | Out-Null
}

if (!(Test-Path -LiteralPath $traceDir)) {
    New-Item -ItemType Directory -Path $traceDir | Out-Null
}

$rows = @()
$totalFail = 0

Push-Location $root

foreach ($version in $versions.Keys) {
    $safeName = $version -replace '[^A-Za-z0-9]+', '_'
    $src = Join-Path $root $versions[$version]
    $outFile = Join-Path $outDir ("v17_trace_37_" + $safeName + ".vvp")
    $traceFile = Join-Path $traceDir ($safeName + '_37_instr.trace')

    Write-Output "=== $version ==="
    & iverilog -g2012 -DSIMULATION -Wall -s tb_trace_v1_7_byte_bram `
        -o $outFile $src $tb
    if ($LASTEXITCODE -ne 0) {
        Write-Output 'COMPILE_FAIL'
        $rows += [pscustomobject]@{
            version = $version
            commits = 0
            status = 'COMPILE_FAIL'
        }
        $totalFail++
        continue
    }

    $runOutput = & vvp $outFile `
        "+HEX=$hex" `
        "+NAME=$safeName" `
        "+END=98" `
        "+STOP_AFTER=$commitCount" `
        "+TRACE=$traceFile" `
        "+MAX_CYCLES=2000"

    $runOutput | Select-String -Pattern 'PASS|FAIL|TRACE' |
        ForEach-Object { Write-Output $_ }

    if ($runOutput | Select-String -Pattern 'FAIL' -Quiet) {
        $rows += [pscustomobject]@{
            version = $version
            commits = 0
            status = 'TRACE_GENERATION_FAIL'
        }
        $totalFail++
        continue
    }

    $diffOutput = & python scripts\trace_diff.py `
        --hex $hex `
        --trace $traceFile `
        --steps $commitCount
    $diffOutput | ForEach-Object { Write-Output $_ }

    $match = $diffOutput | Select-String -Pattern '^PASS: trace matches \((\d+) commits\)$'
    if ($match) {
        $rows += [pscustomobject]@{
            version = $version
            commits = [int]$match.Matches[0].Groups[1].Value
            status = 'PASS'
        }
    } else {
        $rows += [pscustomobject]@{
            version = $version
            commits = 0
            status = 'DIFF_FAIL'
        }
        $totalFail++
    }
}

$rows | Export-Csv -LiteralPath $resultFile -NoTypeInformation -Encoding UTF8

Pop-Location

Write-Output ''
if ($totalFail -eq 0) {
    Write-Output 'V1.7 ALL PREDICTOR RV32I_37 TRACE DIFF PASS'
    exit 0
}

Write-Output "V1.7 ALL PREDICTOR RV32I_37 TRACE DIFF FAIL: $totalFail failure(s)"
exit 1


