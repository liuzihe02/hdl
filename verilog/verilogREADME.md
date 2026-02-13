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

visit all these pages first, and read them carefully.

High Level Goals:
I want a condensed markdown doc synthesizing the above information for this chapter, containing the core concepts, code, tables and diagrams.
Try to keep the content originally and faithfully as produced (don't do too much summarization), but I do want to condense all the information into a coherent markdown document
Do prioritize concepts core to general HDL/FPGA and discard niche/non-industry-standard concepts

Regarding formatting:
No need to number sections, just use appropriate # headers.
Tables and diagrams are helpful to illustrate/synthesize concepts (but use your judgement and don't overuse everywhere)
Previously, you tend to create a quick reference section at the chapter end. However, sometimes you mix distinct concepts like arrays and params (I understand the chapter actually does cover arrays and params despite being distinct concepts) and include them all in the table. Where possible, try to create tables/concepts that cover a whole concept area rather than mix distinct concepts. Again use your judgement on this though.
```

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