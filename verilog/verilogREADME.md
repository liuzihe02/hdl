# Verilog

## Resources

- [ChipVerify](https://www.chipverify.com/tutorials/verilog)
  - We'll be following extensively chipverify for core content (Chapter 1-13)
- [hdlbits](https://hdlbits.01xz.net/wiki/Problem_sets#Getting_Started)
  - We'll be using hdlbits for exercises and practice

### Secondary Resources

These are extra resources that weren't used but are here for reference

- [asic-world](https://www.asic-world.com/verilog/veritut.html)
  - very comprehensive tutorial
- [nand-land](https://nandland.com/learn-verilog/)
  - some interesting exercises and tutorials
- UC SD Notes
  - downloaded locally
- UC Davis Notes
  - downloaded locally
- Verilog Quick Reference

## ChipVerify Path

I'll fetch the tutorial site to see the full chapter structure.Based on your course requirements (FPGA experiment, FSM design, sequential/combinational circuits) and 10-15 hour timeframe, here's the breakdown:

### **TIER 1: ABSOLUTELY CORE (6-8 hours)**
*Essential for course and FPGA lab*

**Getting Started (1-2h)**
- Introduction, Hello World, Quick Review

**Basic Syntax & Structure (1h)**
- Verilog Syntax, module, Ports, Module Instantiations

**Data Types & Operators (1h)**
- Data Types, scalar/vector, Net Types, Operators, Concatenation

**Procedural Blocks (1h)**
- initial block, always block, Control Blocks

**Assignments (1h)** ⚠️ **CRITICAL**
- assign statement, **Blocking & Non-Blocking** (most common mistake!)

**Combinational & Sequential Logic (1h)**
- Combinational Logic (assign & always)
- Sequential Logic (always)

**Conditional Statements (0.5h)**
- if-else-if, case statement

**State Machines (1h)** ⚠️ **HIGH PRIORITY**
- Verilog FSM, Sequence Detector

**Testbench & Simulation (1h)**
- Testbench, Simulation, Display Tasks

---

### **TIER 2: HIGHLY RELEVANT (3-4 hours)**
*Important for lab and understanding*

**Flip-Flops & Latches (0.5h)**
- D Latch, D Flip-Flop Async Reset, T/JK Flip-Flops

**Basic Digital Circuits (0.5h)**
- Full Adder, Mux, Priority Encoder

**Counters (0.5h)**
- 4-bit counter, Mod-N counter

**Arrays & Parameters (0.5h)**
- Arrays/Memories, Parameters (for parameterized designs)

**Clock & Timing (0.5h)**
- Clock Generator, Timescale

**Loops & Generate (0.5h)**
- for Loop, generate block

---

### **TIER 3: USEFUL BUT OPTIONAL (1-2 hours)**
*If you have extra time*

- Shift Registers
- Memory Elements
- Gate Level Modeling
- Examples & Practice

---

### **TIER 4: SKIP FOR NOW**
*Too advanced or covered in lectures*

- Timing & Delays (detailed)
- Advanced Testbench Features (VCD, File IO)
- Compiler Directives
- Advanced Topics (UDP, Specify Block, Strength)
- Synthesis (you'll cover this in lectures)
- SDF/Timing Analysis
- Interview Questions

### Code Simple Examples

**Combinational**

- Half adder, full adder, ripple adder → foundation of all arithmetic
- Mux (2:1, 4:1) → LUTs are literally muxes, so this IS the FPGA
- Encoders / Decoders / Priority Encoders — essential combinational logic for address decoding, arbitration.

**Sequential**

- D flip-flop (sync reset, async reset) → the single most important sequential element
- Counters (binary, mod-N) → backbone of timing and control
- Shift register → serial-to-parallel, LFSRs, data movement

**Control**

- FSM (Moore and Mealy) → the glue that ties datapath to control; if you can write an FSM cleanly you can build almost anything

That's roughly 12 circuit types. Everything else in those lists is either a variation (JK/T flip-flops are derived from D), a composition (ALU = adders + mux + logic), or a niche application (FIFO, debounce, edge detector).

### Chip Design Diagrams

We'll be using `yosys` and `netlistsvg` in `wsl` for this