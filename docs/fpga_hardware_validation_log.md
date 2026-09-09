# FPGA Hardware Validation Log

## Platform

| Item | Value |
|---|---|
| Board | A7-LITE 100T |
| FPGA device | XC7A100T-FGG484-2L |
| Tool | Vivado 2023.2 |
| Clock constraint | 50 MHz (20 ns) |

## Final Board-Level Smoke Test

| Item | Value |
|---|---|
| Design | Six-stage RV32I CPU with instruction BRAM, byte-lane data BRAM and Hybrid Predictor |
| RTL | `fpga/riscv_cpu_fpga_37_byte_bram_hybrid_predictor_sync_reset_test.v` |
| Top module | `a7lite_riscv_top_hybrid_v1_7` |
| Functional program | 37-instruction RV32I test program |
| Observation | `led0` blinked periodically and `led1` stayed on after configuration |
| Result | PASS |

`led0` is driven by a cycle counter and confirms that the configured logic is
running. `led1` is asserted only when the CPU signature registers satisfy
`x3=9`, `x4=18`, `x5=3` and `x7=0x00000178`.

## Implementation Result

| Metric | Value |
|---|---:|
| LUT | 2331 |
| FF | 3030 |
| Block RAM Tile | 2.5 |
| RAMB18 | 5 |
| DSP | 0 |
| WNS | 0.858 ns |
| WHS | 0.098 ns |
| Estimated on-chip power | 0.125 W |
| Bitstream generation | PASS |

The synchronous-reset version did not report the prior `REQP-1840 RAMB18 async
control check` warning. LED observation is a board-level smoke test; it does
not replace exhaustive application-level validation.
