$root = Split-Path -Parent $PSScriptRoot
$src = Join-Path $root 'fpga\riscv_cpu_fpga_37_byte_bram_hybrid_predictor_sync_reset_test.v'
$tb = Join-Path $root 'tests\trace\tb_trace_v1_7_byte_bram.v'
$outDir = Join-Path $root 'sim_artifacts\build_outputs'
$traceDir = Join-Path $root 'results\traces\v1_7\37_instr'
$hex = 'tests\37_instr\rv32i_37.hex'
$commitCount = 75

if (!(Test-Path -LiteralPath $outDir)) {
    New-Item -ItemType Directory -Path $outDir | Out-Null
}

if (!(Test-Path -LiteralPath $traceDir)) {
    New-Item -ItemType Directory -Path $traceDir | Out-Null
}

Push-Location $root

$outFile = Join-Path $outDir 'v17_hybrid_trace_37_instr.vvp'
$traceFile = Join-Path $traceDir 'hybrid_37_instr.trace'

& iverilog -g2012 -DSIMULATION -Wall -s tb_trace_v1_7_byte_bram `
    -o $outFile $src $tb
if ($LASTEXITCODE -ne 0) {
    Pop-Location
    exit 1
}

$runOutput = & vvp $outFile `
    "+HEX=$hex" `
    "+NAME=rv32i_37_hybrid" `
    "+END=98" `
    "+STOP_AFTER=$commitCount" `
    "+TRACE=$traceFile" `
    "+MAX_CYCLES=2000"

$runOutput | Select-String -Pattern 'PASS|FAIL|Load hex|TRACE' |
    ForEach-Object { Write-Output $_ }

if ($runOutput | Select-String -Pattern 'FAIL' -Quiet) {
    Pop-Location
    exit 1
}

$diffOutput = & python scripts\trace_diff.py `
    --hex $hex `
    --trace $traceFile `
    --steps $commitCount
$diffOutput | ForEach-Object { Write-Output $_ }

Pop-Location

if ($diffOutput | Select-String -Pattern '^FAIL:' -Quiet) {
    exit 1
}

Write-Output 'V1.7 HYBRID RV32I_37 TRACE DIFF PASS'
exit 0


