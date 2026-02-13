# Chip Verify Verilog Chapter 6: Assignments

**Assignments** place values onto nets and variables. Verilog has three basic forms of assignments, each with distinct behaviors and use cases.

## Assignment Types Overview

| Type | Operator | Target | Location | Synthesizable | Execution |
|------|----------|--------|----------|---------------|-----------|
| **Procedural** | `=` or `<=` | Variables (reg) | initial/always/task/function | Depends on context | Sequential |
| **Continuous** | `assign` | Nets (wire) | Outside procedural blocks | ✓ Yes | Concurrent |


## Legal LHS Values

What can appear on the left-hand side varies by assignment type:

| Assignment Type | Allowed LHS |
|----------------|-------------|
| **Procedural** | reg variables (scalar/vector), bit/part-select of reg, memory word, concatenation **(no nets)** |
| **Continuous** | wire nets (scalar/vector), bit/part-select of wire, concatenation of nets **(no variables)** |

**Golden Rule:** RHS can be any expression, but LHS restrictions depend on assignment type.

```verilog
module assignments_demo;
    reg [7:0] a, b;
    wire [7:0] x, y;
    
    // LEGAL
    always @(*) a = b + 1;           // Procedural: reg on LHS
    assign x = y & 8'hFF;            // Continuous: wire on LHS
    
    // ILLEGAL
    // assign a = b + 1;             // ERROR: Can't assign to reg
    // always @(*) x = y & 8'hFF;    // ERROR: Can't procedurally assign to wire
endmodule
```

---

## 1. Continuous Assignment (`assign`)

Continuous assignments drive **wire** nets and update whenever RHS changes. Used for **combinational logic** modeling.

### Syntax

```verilog
assign [#delay] <net> = <expression>;
```

### Basic Continuous Assignment

```verilog
wire a, b, c;
assign c = a & b;  // c updated whenever a or b changes
```

Whenever `a` or `b` changes, the expression is re-evaluated and `c` updates immediately (or after optional delay).

### Net Declaration Assignment (Implicit)

Combine declaration and assignment in one statement:

```verilog
// Explicit
wire [1:0] a;
assign a = x & y;

// Implicit (equivalent)
wire [1:0] a = x & y;
```

**Warning:** Only **one** declaration assignment per net (can't redeclare).

### Continuous Assignment Rules

**Always active** - continuously driven  
**Synthesizable** - maps to combinational logic  
**Only for nets** - cannot assign to `reg` variables  
**RHS changes trigger update** - no sensitivity list needed

```verilog
module combo_logic (
    input  a, b, c, d,
    output wire o
);
    // Combinational logic using assign
    assign o = ~((a & b) | (c ^ d));
endmodule
```

### Concatenation with Assign

```verilog
wire [3:0] x;
wire y;
wire [4:0] z;

assign z = {x, y};         // Concatenate x (4-bit) and y (1-bit)
assign z[3:1] = {x, y};    // Partial assignment (z[0] and z[4] undriven = Z)
assign z = {3{y}};         // Replication: {y, y, y}

wire [1:0] a;
wire b;
assign {a, b} = {x, y};    // LHS can be concatenation too
```

**Key Point:** Undriven bits result in high-impedance (Z).

---

## 2. Procedural Assignments

Occur within **procedural blocks** (initial, always, task, function). Assign to **variables** (reg, integer, real).

### Variable Declaration Assignment

Initialize at declaration:

```verilog
reg [31:0] data = 32'hdead_cafe;  // Initial value

// Equivalent to:
reg [31:0] data;
initial data = 32'hdead_cafe;
```

**Warning:** If initialized both at declaration AND in initial block at time 0, evaluation order is undefined.

```verilog
reg [7:0] addr = 8'h05;
initial addr = 8'hee;  // Race condition! Final value = 05 or EE?
```

### Blocking Assignment (`=`)

Executes **sequentially** - each statement completes before the next begins.

```verilog
initial begin
    a = 8'hDA;         // Execute immediately
    b = 8'hF1;         // Execute after a completes
    c = 8'h30;         // Execute after b completes
end
```

**Execution Flow:**
```
Time 0: a = 0xDA  (completes)
Time 0: b = 0xF1  (completes)
Time 0: c = 0x30  (completes)
```

**With Delays:**
```verilog
initial begin
    a = 8'hDA;         // t=0
    #10 b = 8'hF1;     // t=10 (wait 10 units)
    #5  c = 8'h30;     // t=15 (wait 5 more units)
end
```

### Non-Blocking Assignment (`<=`)

Schedules assignments **without blocking** - all RHS evaluated first, then LHS updated at end of time-step.

```verilog
initial begin
    a <= 8'hDA;        // Schedule: evaluate RHS now, assign later
    b <= 8'hF1;        // Schedule: evaluate RHS now, assign later
    c <= 8'h30;        // Schedule: evaluate RHS now, assign later
end
// All assignments happen simultaneously at end of time-step
```

**Execution Flow:**
```
Time 0: Capture RHS values (8'hDA, 8'hF1, 8'h30)
Time 0: Execute all other statements
Time 0 (end): Assign captured values to a, b, c
```

**Critical Difference:**

```verilog
// Example 1: Blocking
initial begin
    a = 8'hDA;
    $display("a=%h", a);  // Prints: a=DA (a already updated)
end

// Example 2: Non-Blocking  
initial begin
    a <= 8'hDA;
    $display("a=%h", a);  // Prints: a=XX (a not yet updated)
end
// After end of time-step, a = DA
```

### Blocking vs Non-Blocking Summary

| Feature | Blocking `=` | Non-Blocking `<=` |
|---------|-------------|-------------------|
| **Execution** | Sequential (one-by-one) | Concurrent (scheduled) |
| **Update Timing** | Immediate | End of time-step |
| **Use Case** | Combinational logic in always | Sequential logic (flip-flops) |
| **Synthesis** | Combo (if `always @(*)`) | Sequential (if `always @(posedge clk)`) |
| **Simulation** | Deterministic within block | Order-independent |


## When to Use Each Type

### Use Continuous Assignment (`assign`) when:
- Modeling **combinational logic**
- Driving **wire** nets
- Outside procedural blocks
- Need concurrent behavior

```verilog
// Good: Combinational logic
assign out = (sel) ? a : b;
assign ready = (count == 10);
```

### Use Blocking (`=`) when:
- **Combinational logic** in always block
- Order matters (sequential evaluation needed)
- Testbench stimulus generation
- Temporary variables in loops

```verilog
// Good: Combinational in always
always @(*) begin
    temp = a + b;      // Blocking: temp used immediately
    out = temp & c;    // Blocking: needs temp value
end
```

### Use Non-Blocking (`<=`) when:
- **Sequential logic** (flip-flops, registers)
- Always blocks with clock edges
- State machines
- Pipeline stages

```verilog
// Good: Sequential logic
always @(posedge clk) begin
    if (rst)
        q <= 0;
    else
        q <= d;  // Non-blocking for flip-flop
end
```

## Quick Reference

| Context | Use | Avoid |
|---------|-----|-------|
| **Combinational outside always** | `assign` | Procedural assignment |
| **Combinational in always** | Blocking `=` with `always @(*)` | Non-blocking `<=` |
| **Sequential (flip-flops)** | Non-blocking `<=` with `always @(posedge clk)` | Blocking `=` |
| **Testbench stimulus** | Blocking `=` or non-blocking `<=` | Either works, be consistent |
| **Variables** | Procedural assignments | `assign` |
| **Nets** | `assign` | Procedural assignments |

1. **Never** use `assign` on `reg` variables
2. **Always** use `<=` for sequential logic (flip-flops)
3. **Always** use `=` for combinational logic in always blocks
4. **Never** mix `=` and `<=` in same always block
5. **Always** provide complete assignments to avoid latches

```verilog
// CONTINUOUS ASSIGNMENT (for wires)
wire [7:0] result;
assign result = a + b;  // Concurrent, always active

// PROCEDURAL BLOCKING (for regs - combinational)
reg [7:0] temp;
always @(*) begin
    temp = a + b;       // Sequential execution
end

// PROCEDURAL NON-BLOCKING (for regs - sequential)
reg [7:0] q;
always @(posedge clk) begin
    q <= d;             // Scheduled assignment
end

// DECLARATION ASSIGNMENTS
wire [3:0] w = 4'b0;    // Implicit continuous
reg  [3:0] r = 4'b0;    // Initial value

// PROCEDURAL CONTINUOUS (testbench only)
initial begin
    assign r = 0;       // Override
    #10 deassign r;     // Release
end
```