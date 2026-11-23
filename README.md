# 32-bit Single-Cycle ARM Processor in SystemVerilog

![SystemVerilog](https://img.shields.io/badge/Language-SystemVerilog-blue.svg)
![Target FPGA](https://img.shields.io/badge/FPGA-Intel%20MAX%2010%20(10M50DAF484C7G)-orange.svg)
![Toolchain](https://img.shields.io/badge/Synthesis-Intel%20Quartus%20Prime-lightgrey.svg)
![Simulation](https://img.shields.io/badge/Simulation-ModelSim--Altera-green.svg)
![Status](https://img.shields.io/badge/Verification-Passed%20(100%25)-brightgreen.svg)

A complete, synthesizable **32-bit Single-Cycle ARM Processor** designed in **SystemVerilog**, featuring an integrated **Barrel Shifter** and full **14-Condition Code Evaluation**. Synthesized targeting the **Intel MAX 10 FPGA (DE10-Lite)** and verified via a self-checking testbench in **ModelSim**.

---

## 🚀 Key Features

- **Architecture:** Single-Cycle Harvard Architecture (Separate Instruction and Data paths).
- **Core Instruction Set (ARMv4 Subset):**
  - **Data Processing:** `ADD`, `SUB`, `AND`, `ORR` (supports register and immediate operands, with optional `S`-bit flag updates).
  - **Memory Operations:** `LDR`, `STR` (positive 12-bit immediate offsets).
  - **Branching:** `B` (relative address calculation $PC + 8 + \text{ExtImm}$).
- **Hardware Enhancements:**
  - **32-bit Barrel Shifter (`shifter.sv`):** Hardware decoding of `Instr[11:5]` supporting all 4 ARM shift operations:
    - `LSL` (Logical Shift Left)
    - `LSR` (Logical Shift Right)
    - `ASR` (Arithmetic Shift Right - sign preserving)
    - `ROR` (Rotate Right)
  - **Comprehensive Condition Evaluator (`condcheck.sv`):** Full hardware evaluation of all 14 ARM condition codes:
    - `EQ`, `NE`, `CS/HS`, `CC/LO`, `MI`, `PL`, `VS`, `VC`, `HI`, `LS`, `GE`, `LT`, `GT`, `LE`, and unconditional `AL`.
- **RTL Quality:** 100% synthesizable SystemVerilog, clean netlist with **0 unintended latches** and **0 compilation errors**.

---

## 📐 Architecture & Block Diagram

```text
       +-------------------------------------------------------------+
       |                        TOP PROCESSOR                        |
       |                                                             |
       |  +--------------------+             +--------------------+  |
       |  | Instruction Memory |             |    Data Memory     |  |
       |  |     (imem.sv)      |             |     (dmem.sv)      |  |
       |  +---------+----------+             +---------+----------+  |
       |            | Instr[31:0]                      ^ Read/Write  |
       |            v                                  | Data        |
       |  +--------------------------------------------+----------+  |
       |  |                    ARM CORE                           |  |
       |  |                                                       |  |
       |  |  +----------------+             +------------------+  |  |
       |  |  |  Control Unit  |---Controls->|     Datapath     |  |  |
       |  |  | (controller.sv)|             |  (datapath.sv)   |  |  |
       |  |  +--------+-------+             +--------+---------+  |  |
       |  |           ^                              |            |  |
       |  |           +---------ALUFlags[3:0]--------+            |  |
       |  |                                                       |  |
       |  |        [Inside Datapath: RegFile -> Barrel Shifter    |  |
       |  |                           -> ALU -> Mem Mux]          |  |
       |  +-------------------------------------------------------+  |
       +-------------------------------------------------------------+
```

---

## 📁 Repository Structure

```text
├── quartus/                     # Intel Quartus Prime project files
│   ├── arm_single_cycle.qpf     # Quartus Project File
│   ├── arm_single_cycle.qsf     # Quartus Settings File (Target: 10M50DAF484C7G)
│   └── memfile.dat              # Machine code for memory preloading
├── sim/                         # ModelSim verification environment
│   ├── testbench.sv             # Self-checking automated testbench
│   ├── run_sim.do               # 1-click ModelSim automated run script
│   ├── memfile.dat              # 21-instruction test program
│   └── generate_memfile.py      # Assembly to machine code translator helper
├── src/                         # Synthesizable SystemVerilog RTL source code
│   ├── top.sv                   # Top-level entity integrating CPU and memories
│   ├── arm.sv                   # Top-level processor module (CU + Datapath)
│   ├── controller.sv            # Top-level Control Unit
│   ├── decode.sv                # Instruction decoder (Main + ALU + PC logic)
│   ├── maindec.sv               # Main decoder (Opcode decoding)
│   ├── aludec.sv                # ALU decoder & S-bit flag write control
│   ├── condlogic.sv             # Conditional logic wrapper with Flag registers
│   ├── condcheck.sv             # 14 ARM condition code checking logic
│   ├── pclogic.sv               # Program counter destination & branch logic
│   ├── datapath.sv              # 32-bit execution datapath
│   ├── regfile.sv               # 16 x 32-bit Register File (R0-R14 + R15 as PC+8)
│   ├── alu.sv                   # 32-bit Arithmetic Logic Unit
│   ├── shifter.sv               # 32-bit Barrel Shifter (LSL, LSR, ASR, ROR)
│   ├── extend.sv                # Immediate value sign/zero extender
│   ├── adder.sv                 # 32-bit parallel adder
│   ├── mux2.sv                  # Parameterized 2-to-1 Multiplexer
│   ├── flopr.sv                 # D Flip-Flop with asynchronous reset
│   ├── flopenr.sv               # D Flip-Flop with enable and asynchronous reset
│   ├── imem.sv                  # 64-word 32-bit Instruction ROM
│   └── dmem.sv                  # 64-word 32-bit Data RAM
├── .gitignore                   # Ignore Quartus/ModelSim temp & binary files
├── REPORT_TEMPLATE.md           # Technical Project Report (Vietnamese)
└── README.md                    # Project documentation
```

---

## 🛠️ Verification & Simulation

The processor is verified against a 21-instruction diagnostic program from *Harris & Harris* (*Digital Design and Computer Architecture: ARM Edition*), which exercises:
1. Data-processing operations with immediate and register operands.
2. Flag updating (`SUBS`) and conditional execution (`BEQ` branch taken, `BNE` skipped).
3. Memory load/store (`LDR` and `STR`).
4. Correct address calculation through the Barrel Shifter and ALU.

### Running with ModelSim:
1. Open ModelSim.
2. Change directory to `sim/`:
   ```tcl
   cd D:/arm_single_cycle/sim
   ```
3. Execute the automated script:
   ```tcl
   do run_sim.do
   ```
4. **Result:** The testbench automatically terminates with:
   ```text
   [Cycle 20] Ghi vao Bo Nho DMEM: Dia chi = 88 (0x58), Du lieu = 7 (0x7)
   ----------------------------------------------------------------
   >>> KET QUA: MO PHONG THANH CONG! (ALL TESTS PASSED!)       <<<
   >>> Chu ky hoan thanh: 20 chu ky.                          <<<
   >>> Gia tri 7 da duoc tinh toan, ghi ra DMEM[84], doc lai   <<<
   >>> qua LDR va ghi tiep ra DMEM[88] hoan toan chinh xac!   <<<
   ----------------------------------------------------------------
   ```

---

## 📊 FPGA Synthesis Results

Compiled with **Intel Quartus Prime 20.1** targeting **Intel MAX 10 FPGA (`10M50DAF484C7G`)**:

| Metric | Result |
| :--- | :--- |
| **Target Device** | Intel MAX 10 - `10M50DAF484C7G` (DE10-Lite) |
| **Logic Elements (LEs)** | **5,395 / 49,760 (11%)** |
| **Dedicated Logic Registers** | **2,561 / 49,760 (5%)** |
| **Total Pins** | **67 / 360 (19%)** |
| **Unintended Latches** | **0 (Clean Netlist)** |
| **Timing / Critical Path** | $T_c \approx 31.8\text{ ns} \implies f_{max} \approx 31.45\text{ MHz}$ |

---

## 👨‍💻 Project Information

- **Student:** Nguyễn Tiến Đạt (Student ID: 24022854)
- **Instructors:** PGS.TS. Phạm Ngọc Quang, KS. Đỗ Đình Minh
- **Course:** Digital Design & Microprocessors (ELT3290)
- **Institution:** VNU University of Engineering and Technology (VNU-UET)
- **GitHub:** [@DkaRobotEngineer](https://github.com/DkaRobotEngineer)
