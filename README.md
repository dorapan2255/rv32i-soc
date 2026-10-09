# Lightweight RV32I SoC in SystemVerilog

A compact educational SoC built around a single-cycle RV32I processor. The repository covers RTL, self-checking simulation, bare-metal RISC-V software, synthesis, static timing analysis, and a basic OpenROAD physical-design flow.

[中文说明](README.zh-CN.md)

The system-level C demonstration performs this sequence:

```text
Calculate 1 + 2 + ... + 10 = 55
          ↓
Write to and read back data memory
          ↓
Read the memory-mapped timer
          ↓
Transmit the sum and timer snapshot through UART
```

![RV32I SoC architecture](docs/images/rv32i_soc_architecture.svg)

## Architecture

The Harvard-style CPU completes fetch, decode, register read, execute, memory access, and writeback selection in one cycle. Its datapath contains a program counter, decoder and control unit, 31 physically stored general-purpose registers with a constant-zero `x0`, immediate generator, ALU, branch/jump logic, and writeback multiplexer.

Supported instructions (21):

```text
ADD  SUB  AND  OR   XOR  SLT  SLL  SRL  SRA
ADDI ANDI ORI  XORI
LW   SW
BEQ  BNE
JAL  JALR LUI  AUIPC
```

The implementation supports aligned 32-bit `LW` and `SW`. It does not implement the M extension, CSR instructions, exceptions, interrupts, caches, AXI, floating point, or pipelining.

## SoC

`rv32i_soc` connects the CPU to separate 1 KiB instruction and data memories, a memory-mapped UART transmitter, and a 32-bit timer.

| Address | Device | Access |
|---|---|---|
| `0x0000_0000–0x0000_03ff` | Data memory | 1 KiB RAM; initial stack pointer is `0x400` |
| `0x1000_0000` | UART TXDATA | Write the low byte to transmit an 8N1 frame |
| `0x1000_0004` | UART STATUS | Bit 0 reports ready |
| `0x1000_0010` | Timer count | Read or write the 32-bit counter |
| `0x1000_0014` | Timer control | Bit 0 enables counting |

Instruction memory also starts at address zero, but occupies a separate Harvard memory space.
The timer increments once per cycle while enabled. Software polls UART STATUS before writing
TXDATA; both peripherals use ordinary `LW` and `SW` instructions.

## Verification

Self-checking testbenches cover the ALU, register file, immediate generator, decoder, control unit, PC and branch logic, both memories, MMIO interconnect, UART, and timer. Program-level tests build real RV32I ELF files, reject instructions outside the implemented subset, and exercise arithmetic, branches, jumps, memory, `.data`/`.bss`, stack use, function return through `JALR`, and MMIO. The assembly integration test also confirms that an unsupported instruction produces no architectural side effects.

The system demonstration calculates `1 + ... + 10 = 55`, writes and reads RAM, samples the timer, and sends an 11-byte result frame through the UART pin. The testbench decodes the 8N1 waveform and cross-checks it against RAM.

| Check | Result |
|---|---:|
| Four software ELF instruction allowlists | PASS |
| All module and SoC simulations | PASS |
| System program | `sum=55, timer=58` |
| Generic and Nangate45 netlist reload | 0 problems |
| Pre-layout STA | WNS `+4.208 ns`, TNS `0 ns` |
| Detailed-route DRC | 0 violations |
| Post-route STA | setup `+5.03 ns`, hold `+0.06 ns` |

## Implementation results

The synthesis, STA, and P&R figures below apply to **`rv32i_core` only**. Instruction/data memories, UART, timer, I/O pads, and a power-delivery network are excluded.

| Metric | Result |
|---|---:|
| Target clock | 100 MHz |
| Nangate45 standard cells | 6186 |
| DFFs | 1024 |
| Mapped cell area | 11254.46 µm² |
| Pre-layout setup slack / TNS | +4.208 ns / 0 ns |
| Die / core size | 199.32 × 199.32 / 179.17 × 177.80 µm |
| Final design area / utilization | 13624 µm² / 43% |
| CTS sinks / inserted buffers | 1024 / 137 |
| Routed wire length / vias | 126387 µm / 53999 |
| Detailed-route violations | 0 |
| Post-route setup / hold slack | +5.03 ns / +0.06 ns |

Compact source reports are retained in [`reports/`](reports/). These are educational typical-corner results, not multi-PVT signoff or a tapeout-ready full-SoC implementation.
The flow is described in the Chinese [standard-cell mapping and STA](docs/13_standard_cell_mapping_sta.md)
and [OpenROAD P&R](docs/14_openroad_basic_pnr.md) documents.

![OpenROAD basic P&R of rv32i_core](docs/images/rv32i_core_final_layout.png)

## Requirements and usage

Required for functional simulation and software builds:

- GNU Make and Python 3
- Icarus Verilog (`iverilog`, `vvp`)
- an RV32I-capable GNU bare-metal toolchain

Required for `make lint`:

- Verilator

Required for the back-end implementation flow:

- Yosys
- OpenSTA (`sta`)
- OpenROAD

All tools must be available through `PATH`. The software build defaults to the `riscv64-unknown-elf-` prefix; override it explicitly when needed:

```bash
make RISCV_PREFIX=/opt/riscv/bin/riscv64-unknown-elf- regression
```

Common commands:

```bash
make lint                 # Verilator checks for CPU and SoC tops
make regression           # build software and run all self-checking tests
make synth-core           # generic Yosys synthesis and netlist checks
make timing               # Nangate45 mapping and pre-layout STA
make pnr-core             # core-only floorplan, CTS, routing, and post-route STA
bash scripts/view_layout.sh
make clean
```

`make clean` removes generated software images, build directories, waveforms, detailed
reports, netlists, and physical databases. It preserves the three compact summary reports
under `reports/`.

## Repository layout

```text
rtl/          CPU, memory, interconnect, UART, timer, and SoC RTL
tb/           self-checking SystemVerilog testbenches
software/     startup code, linker script, assembly/C tests, image tools
docs/         Chinese module and flow documentation
constraints/  STA and physical-design constraints
scripts/      Yosys, OpenSTA, and OpenROAD flows
platforms/    Nangate45 library files used by the open-source flow
reports/      compact synthesis, timing, and P&R summaries
```

## License

Original source code, scripts, and documentation in this repository are released under the
[MIT License](LICENSE). Files under `platforms/nangate45/` retain their third-party license
terms described in [`platforms/nangate45/LICENSE`](platforms/nangate45/LICENSE).

## Known Limitations

- The CPU implements the 21 instructions listed above, rather than the complete RV32I base ISA.
- Data memory supports aligned 32-bit `LW` and `SW` only; byte, halfword, and unaligned accesses are unsupported.
- The design has no pipeline, M extension, CSR subsystem, exceptions, interrupts, caches, AXI, debug interface, or floating-point unit.
- Synthesis, STA, and OpenROAD P&R cover `rv32i_core` only. The memories, MMIO interconnect, UART, and timer are verified at RTL but are not included in the reported physical implementation.
- The physical flow excludes SRAM macros, I/O pads, a power-delivery network, antenna analysis, LVS, and multi-corner/multi-mode analysis.
- Reported area and timing use the Nangate45 typical library and a single educational constraint set. They are reproducible flow results, not signoff or tapeout claims.

## Engineering notes

Two failures shaped the final RTL and verification flow:

- **Undriven `registers[0]` after netlist reload.** A 32-entry register array allowed synthesis to preserve 32 undriven bits for RISC-V `x0`. The final register file physically stores only `x1–x31`, supplies zero at both read ports by default, and the synthesis scripts reload every generated netlist and run `check -assert`.
- **Icarus stalled near 55 ns while using CPU continuously.** Two combinational blocks formed an event-queue feedback path when `ram_read` briefly changed `0→1`. The MMIO decoder now derives read data directly from the address and request, and RAM read enable no longer feeds back into the same combinational decision chain.
