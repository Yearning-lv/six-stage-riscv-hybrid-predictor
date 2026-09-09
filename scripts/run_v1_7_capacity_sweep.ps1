$root = Split-Path -Parent $PSScriptRoot
$srcFile = Join-Path $root 'fpga\riscv_cpu_fpga_37_byte_bram_hybrid_predictor_param_v1_7.v'
$tbFile = Join-Path $root 'tests\benchmarks\tb_benchmark_param_v1_7.v'
$outDir = Join-Path $root 'sim_artifacts\build_outputs'
$resultDir = Join-Path $root 'results'

if (!(Test-Path -Path $outDir)) {
    New-Item -ItemType Directory -Path $outDir | Out-Null
}

if (!(Test-Path -Path $resultDir)) {
    New-Item -ItemType Directory -Path $resultDir | Out-Null
}

$configs = @(
    @{ Id = 'P1'; Entries = 8;  IndexBits = 3; GhrBits = 3; RasDepth = 4 },
    @{ Id = 'P2'; Entries = 16; IndexBits = 4; GhrBits = 4; RasDepth = 4 },
    @{ Id = 'P3'; Entries = 32; IndexBits = 5; GhrBits = 5; RasDepth = 4 },
    @{ Id = 'P4'; Entries = 64; IndexBits = 6; GhrBits = 6; RasDepth = 4 }
)

$benchmarks = @(
    @{
        Name = 'branch_loop'
        Hex = 'tests\benchmarks\branch_loop.hex'
        End = 4
        Args = @('+EXP_X1=20', '+EXP_X2=20')
    },
    @{
        Name = 'call_return'
        Hex = 'tests\benchmarks\call_return.hex'
        End = 8
        Args = @('+EXP_X10=10', '+EXP_X11=10', '+EXP_X12=10')
    },
    @{
        Name = 'memory_loop'
        Hex = 'tests\benchmarks\memory_loop.hex'
        End = 9
        Args = @('+EXP_X1=164', '+EXP_X2=16', '+EXP_X3=16', '+EXP_X5=120')
    },
    @{
        Name = 'mixed_workload'
        Hex = 'tests\benchmarks\mixed_workload.hex'
        End = 14
        Args = @('+EXP_X1=132', '+EXP_X2=8', '+EXP_X3=8', '+EXP_X6=36', '+EXP_X8=44', '+EXP_X9=16')
    },
    @{
        Name = 'correlated_branch'
        Hex = 'tests\benchmarks\correlated_branch.hex'
        End = 8
        Args = @('+EXP_X1=32', '+EXP_X2=32', '+EXP_X4=16')
    },
    @{
        Name = 'branch_dense'
        Hex = 'tests\benchmarks\branch_dense.hex'
        End = 77
        Args = @('+EXP_X1=5', '+EXP_X2=5', '+EXP_X5=0')
    }
)

$rows = @()
$totalFail = 0

Push-Location $root

foreach ($config in $configs) {
    $outFile = Join-Path $outDir ("v17_capacity_" + $config.Id + ".vvp")

    Write-Output ""
    Write-Output "##### $($config.Id): entries=$($config.Entries), ghr=$($config.GhrBits), ras=$($config.RasDepth) #####"

    iverilog -g2012 -Wall `
        -s tb_benchmark_param_v1_7 `
        -P tb_benchmark_param_v1_7.PRED_INDEX_BITS=$($config.IndexBits) `
        -P tb_benchmark_param_v1_7.GHR_BITS=$($config.GhrBits) `
        -P tb_benchmark_param_v1_7.RAS_DEPTH=$($config.RasDepth) `
        -o $outFile $srcFile $tbFile

    if ($LASTEXITCODE -ne 0) {
        Write-Output "COMPILE_FAIL: $($config.Id)"
        $totalFail = $totalFail + 1
        continue
    }

    foreach ($bench in $benchmarks) {
        Write-Output "=== $($config.Id) $($bench.Name) ==="

        $runArgs = @("+HEX=$($bench.Hex)", "+BENCH=$($bench.Name)", "+END=$($bench.End)", '+MAX_CYCLES=3000') + $bench.Args
        $output = vvp $outFile $runArgs
        $output | Select-String -Pattern 'PARAM|PASS|FAIL|BENCH' | ForEach-Object { Write-Output $_ }

        if ($output | Select-String -Pattern 'FAIL' -Quiet) {
            $totalFail = $totalFail + 1
            $rows += [pscustomobject]@{
                experiment_id = $config.Id
                predictor = 'Hybrid'
                entries = $config.Entries
                pred_index_bits = $config.IndexBits
                ghr_bits = $config.GhrBits
                ras_depth = $config.RasDepth
                benchmark = $bench.Name
                cycle = ''
                instret = ''
                cpi = ''
                ipc = ''
                stall = ''
                flush = ''
                control = ''
                predict = ''
                btb_hit = ''
                mispredict = ''
                ras_hit = ''
                prediction_accuracy = ''
                result = 'FAIL'
            }
            continue
        }

        $benchLine = ($output | Select-String -Pattern '^BENCH ' | Select-Object -First 1).Line
        if ($benchLine -match 'name=(\S+) cycle=(\d+) instret=(\d+) stall=(\d+) flush=(\d+) control=(\d+) predict=(\d+) btb_hit=(\d+) mispredict=(\d+) ras_hit=(\d+)') {
            $cycle = [int]$matches[2]
            $instret = [int]$matches[3]
            $control = [int]$matches[6]
            $mispredict = [int]$matches[9]
            $accuracy = if ($control -gt 0) { [math]::Round(1 - ($mispredict / [double]$control), 4) } else { 0 }

            $rows += [pscustomobject]@{
                experiment_id = $config.Id
                predictor = 'Hybrid'
                entries = $config.Entries
                pred_index_bits = $config.IndexBits
                ghr_bits = $config.GhrBits
                ras_depth = $config.RasDepth
                benchmark = $matches[1]
                cycle = $cycle
                instret = $instret
                cpi = [math]::Round($cycle / [double]$instret, 4)
                ipc = [math]::Round($instret / [double]$cycle, 4)
                stall = [int]$matches[4]
                flush = [int]$matches[5]
                control = $control
                predict = [int]$matches[7]
                btb_hit = [int]$matches[8]
                mispredict = $mispredict
                ras_hit = [int]$matches[10]
                prediction_accuracy = $accuracy
                result = 'PASS'
            }
        } else {
            Write-Output "PARSE_FAIL: BENCH line not found"
            $totalFail = $totalFail + 1
        }
    }
}

$csv = Join-Path $resultDir 'v1_7_capacity_sweep_results.csv'
$rows | Export-Csv -Path $csv -NoTypeInformation -Encoding UTF8

Pop-Location

Write-Output ""
Write-Output "Wrote: $csv"

if ($totalFail -eq 0) {
    Write-Output "V1.7 CAPACITY SWEEP PASS"
    exit 0
} else {
    Write-Output "V1.7 CAPACITY SWEEP FAIL: $totalFail failure(s)"
    exit 1
}


