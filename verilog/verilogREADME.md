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

## ChipVerify Prompt

Here the sample prompt used to condense documents:

```txt
websites:

visit all these pages first, and read them carefully. They should be covering one whole chapter in ChipVerify.

High Level Goals:
I want a condensed markdown doc synthesizing the above information for this chapter, containing the core concepts, code, tables and diagrams.
Try to keep the content originally and faithfully as produced (don't do too much summarization and skimp on explanations/details), but I do want to condense all the core information into a coherent markdown document. You need to use your judgement to balance this.
Do prioritize concepts core to general HDL/FPGA and discard niche/non-industry-standard concepts

Regarding formatting:
No need to number sections, just use appropriate # headers.
Tables/diagrams are helpful to illustrate/synthesize concepts (but use your judgement and don't overuse everywhere)
Previously, you tend to create a quick reference section at the chapter end, this is fine but use them appropriately. However, sometimes you mix distinct concepts like arrays and params (I understand the chapter actually does cover arrays and params despite being distinct concepts) and include them all in the table. Where possible/appropriate, try to create tables/diagrams that cover a whole concept area rather than mix distinct concepts. Again use your judgement on this though.

Regarding technicals:
Where appropriate, do explicitly distinguish between simulation-only constructs (like initial, fork-join, and # delays) and synthesizable hardware constructs (like always @)
Consider using inline or block code comments where it really helps to explain the code.
You can consider having a pitfalls/common mistakes/guidelines/tips section, but use your judgement on whether it really helps with pedagogy when information is too scattered or it serves more to just repeating information
```

### Core Circuits

#### Combinational Logic

- Half adder, full adder, ripple adder → foundation of all arithmetic
- Mux (2:1, 4:1) → LUTs are literally muxes, so this IS the FPGA
- Encoders / Decoders / Priority Encoders — essential combinational logic for address decoding, arbitration.

#### Sequential Logic

- D flip-flop (sync reset, async reset, with gate) → the single most important sequential element
  - MUX and DFF
- Counters (4 bit binary, decade counter mod-N) → backbone of timing and control
- 4bit Shift register → serial-to-parallel, LFSRs, data movement
- Left/Right rotator

#### Finite State Machines

- Serial receiver
- Sequence recognition

#### Others

- Synchronous FIFO
- Single Port RAM
- Debounce Circuit

### Chip Design Diagrams

We'll be using `yosys` and `netlistsvg` in `wsl` for this