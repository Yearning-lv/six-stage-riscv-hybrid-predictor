# Six-Stage RV32I Soft Core with Hybrid Branch Prediction

This repository contains the RTL, tests, scripts and result records for an
FPGA-oriented six-stage RV32I soft-core processor.

## Main Design

- Pipeline: `IF / ID / EX / MEM1 / MEM2 / WB`
- ISA coverage: 37 RV32I instructions
- Hazard handling: forwarding, load-use stall and control-hazard flush
- Predictor configurations: No Predictor, BTB, BTB+PHT, BTB+Gshare,
  BTB+Gshare+RAS and Hybrid
- FPGA board: A7-LITE 100T
- FPGA device: XC7A100T-FGG484-2L
- FPGA tool: Vivado 2023.2

## Repository Layout

| Directory | Contents |
|---|---|
| `fpga/` | FPGA-oriented RTL, top-level wrappers, memory image and XDC constraints |
| `tests/` | Instruction, hazard, benchmark, trace and predictor tests |
| `scripts/` | PowerShell regression scripts, trace comparison and Python figure generation |
| `results/` | CSV results and selected commit traces |
| `docs/` | Experiment notes, evidence index and generated figures |

## Reproduction

Run the v1.7 trace differential test from the repository root:

```powershell
.\scripts\run_v1_7_all_37_trace_diff.ps1
```

The script requires Icarus Verilog and Python. It generates temporary simulator
outputs under `sim_artifacts/`, which is intentionally ignored by Git.

The Vivado frequency-sweep script requires a local Vivado installation and
should be called with the local `vivado.bat` path. For example:

```powershell
.\scripts\run_v1_7_hybrid_fmax_sweep.ps1 `
  -VivadoBat 'C:\Xilinx\Vivado\2023.2\bin\vivado.bat'
```

Generated Vivado projects are written under `local-vivado-project/` by default
and are ignored by Git. The original machine-specific project directories are
not part of this repository.

## Scope and Limitations

The performance workloads are custom benchmark programs. The reported power is
a Vivado estimate, and the 50 MHz result is a validated clock constraint rather
than a complete theoretical maximum-frequency scan.

## License and Citation

This code and data package is provided for research reproducibility. Add the
preferred license and citation information before making the repository public.
All RTL, test programs and result records should be reviewed by the author
before publication.


