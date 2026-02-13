# Chip Verify Verilog Chapter 6: Assignments

**Assignments** place values onto nets and variables. Verilog has various assignment types (continuous, procedural blocking and procedural non-blocking)

> Note there's also procedural continuous assignment, but we don't discuss this as its rarely used and not synthesizable

## The Big Picture

But first we review some concepts.

### Two Kinds of Hardware Logic

- **Combinational logic** = output depends ONLY on current inputs (no memory). Examples: gates, muxes, ALUs. These respond **asynchronously** — the output changes immediately whenever an input changes. No clock involved.

- **Sequential logic** = output depends on current inputs AND past state (has memory). Examples: flip-flops, registers, state machines. These operate **synchronously** — the output only changes on a clock edge.

> **Combinational = Asynchronous** and **Sequential = Synchronous** are the same distinction, just described from different angles. "Combinational/sequential" emphasizes *what* the logic does (memory or not). "Async/sync" emphasizes *when* the output changes (immediately vs. on clock edge).

### Two Verilog Data Types

- **Nets (`wire`)** — model physical connections/wires. Must be continuously driven (like a real wire connected to a battery). Cannot store values.
- **Variables (`reg`)** — model storage in simulation. Hold their value until reassigned. 

> Despite the name, `reg` does NOT necessarily synthesize to a register — it can model combinational OR sequential logic depending on how you use it.

### Two Syntax Locations

- **Continuous assignment (`assign`)** — written outside procedural blocks. Drives `wire` types. Always models combinational logic.
- **Procedural assignment (`=` or `<=`)** — written inside procedural blocks (`always`, `initial`, `task`, `function`). Drives `reg` types. Can model EITHER combinational or sequential logic, depending on which operator you use.

### Two Procedural Operators

These are only used within procedural blocks.

- **Blocking (`=`)** — executes sequentially: each statement completes before the next begins. Used for **combinational** logic.
- **Non-blocking (`<=`)** — schedules all assignments simultaneously: all RHS values captured first, all LHS updated at end of time-step. Used for **sequential** logic (flip-flops).

> "Blocking" and "non-blocking" describe **simulation execution order**, not hardware logic. Confusingly, the mapping is **opposite** to what the names suggest:
> - **Blocking** `=` (sequential *simulation* execution) → models **combinational/async** hardware
> - **Non-blocking** `<=` (concurrent *simulation* execution) → models **sequential/sync** hardware
>
> Why? Because flip-flops all capture their inputs and update *simultaneously* at the clock edge — that's exactly what `<=` does in simulation.

```verilog
// ASYNCHRONOUS Logic (no clock) - uses BLOCKING =
always @(*) begin              // Triggers on ANY input change
    sum = a + b;               // Changes IMMEDIATELY when a or b changes
    product = sum * c;         // No clock involved!
end
// This is COMBINATIONAL (asynchronous gates)

// SYNCHRONOUS Logic (clocked) - uses NON-BLOCKING <=
always @(posedge clk) begin    // Triggers ONLY on clock edge
    q <= d;                    // Changes ONLY at clock rising edge
end
// This is SEQUENTIAL (synchronous flip-flops)
```

### 3 Assignment Patterns

Everything collapses into just three synthesizable patterns:

```
PATTERN 1: Combinational logic with assign (wire)
─────────────────────────────────────────────────
    wire [7:0] result;
    assign result = a + b;        // Updates immediately whenever a or b changes

PATTERN 2: Combinational logic with always (reg)
─────────────────────────────────────────────────
    reg [7:0] temp;
    always @(*) begin             // Trigger on ANY input change (async)
        temp = a + b;             // Blocking = sequential execution in sim
    end                           //   → synthesizes to combinational gates

PATTERN 3: Sequential logic with always (reg)
─────────────────────────────────────────────────
    reg [7:0] q;
    always @(posedge clk) begin   // Trigger ONLY on clock edge (sync)
        q <= d;                   // Non-blocking = simultaneous update in sim
    end                           //   → synthesizes to flip-flop
```

|Assignment Type | Hardware Behaviour | Data Type | Syntax | Operator | Sensitivity |
|---|---|---|---|---|---|
|**Continuous**| Combinational (async) | Nets - `wire` | `assign` | (implicit) | Auto (any RHS change) |
|**Procedural (Blocking)**| Combinational (async) | Variables - `reg` | `always` block | `=` (blocking) | `always @(*)` |
|**Procedural (Non-blocking)**| Sequential (sync) | Variables - `reg` | `always` block | `<=` (non-blocking) | `always @(posedge clk)` |

## Legal LHS Values

| Assignment Type | Allowed LHS |
|---|---|
| **Continuous** (`assign`) | wire nets (scalar/vector), bit/part-select of wire, concatenation of nets. **No variables.** |
| **Procedural** (`=` / `<=`) | reg variables (scalar/vector), bit/part-select of reg, memory word, concatenation of regs. **No nets.** |

**Golden Rule:** RHS can be any expression. LHS is restricted by assignment type.

```verilog
module assignments_demo;
    reg [7:0] a, b;
    wire [7:0] x, y;

    // LEGAL
    always @(*) a = b + 1;           // Procedural: reg on LHS ✓
    assign x = y & 8'hFF;            // Continuous: wire on LHS ✓

    // ILLEGAL
    // assign a = b + 1;             // ERROR: Can't continuously assign to reg
    // always @(*) x = y & 8'hFF;    // ERROR: Can't procedurally assign to wire
endmodule
```

---

## 1. Continuous Assignment (`assign`)

- Drives **wire** nets continuously - updates whenever RHS changes  
- Hardware Behaviour: Combinational logic ONLY (gates, muxes, etc.)  
- Syntax/Location: Outside procedural blocks

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

## 2. Procedural Assignments

- Drives **Variables** (reg, integer, real)
- Hardware Behaviour: Can model **EITHER** combinational OR sequential logic depending on operator used
- Location/Syntax: Occur within **procedural blocks** (initial, always, task, function)  

### Variable Declaration Assignment

```verilog
reg [31:0] data = 32'hdead_cafe;  // Initial value at declaration

// Equivalent to:
reg [31:0] data;
initial data = 32'hdead_cafe;
```

**Warning:** If initialized both at declaration AND in `initial` block at time 0, order is undefined (race condition):

```verilog
reg [7:0] addr = 8'h05;
initial addr = 8'hee;  // Final value = 05 or EE? Undefined!
```

### 2a. Blocking Assignment (`=`) — For Combinational Logic

Each statement **completes before** the next begins. Values are immediately visible to subsequent statements.

```verilog
// All at time 0, but executed in order
initial begin
    a = 8'hDA;                     // a updates first
    $display("a=%h", a);           // Prints: a=DA (a already has new value)
    b = 8'hF1;                     // b updates after a updates
    c = 8'h30;                     // c updates after b updates
end
```

With delays:
```verilog
initial begin
    a = 8'hDA;         // t=0
    #10 b = 8'hF1;     // t=10 (wait 10, then assign)
    #5  c = 8'h30;     // t=15 (wait 5 more, then assign)
end
```

**Why this models combinational logic:** In `always @(*)`, blocking `=` means each intermediate result is immediately available to the next line. Any code afterwards must use the updated values

```verilog
always @(*) begin
    a = 1;         // Completes immediately
    b = a;         // Uses NEW a (=1)
    c = b;         // Uses NEW b (=1)
end
// Result: a=1, b=1, c=1 — like a chain of wires, no pipeline
```

### 2b. Non-Blocking Assignment (`<=`) — For Sequential Logic

All RHS values **captured first**, then all LHS **updated simultaneously** at end of time-step. No statement blocks the next.

```verilog
initial begin
    a <= 8'hDA;                    // Schedule: capture RHS, don't assign yet
    $display("a=%h", a);           // Prints: a=XX (a NOT yet updated!)
    b <= 8'hF1;                    // Schedule: capture RHS
    c <= 8'h30;                    // Schedule: capture RHS
end
// End of time-step: a=DA, b=F1, c=30 all update at once
```

**Why this models sequential logic (flip-flops):** Real flip-flops all sample their D-input at the clock edge and update Q simultaneously. `<=` replicates this — all RHS values are read (sampled) using the OLD state, then all LHS values update at once.

```verilog
always @(posedge clk) begin
    a <= 1;        // Captures RHS (=1), doesn't update a yet
    b <= a;        // Uses OLD a (not 1!), doesn't update b yet
    c <= b;        // Uses OLD b, doesn't update c yet
end
// End of time-step: all update simultaneously
// Result: shift register! a→b→c pipeline, each value shifts one stage per clock
```

### Blocking vs Non-Blocking Summary

| | Blocking `=` | Non-Blocking `<=` |
|---|---|---|
| **Simulation execution** | Sequential (one-by-one) | Concurrent (all at end of time-step) |
| **Value visibility** | Immediate — next line sees new value | Deferred — next line sees OLD value |
| **Models what hardware** | Combinational (in `always @(*)`) | Sequential flip-flops (in `always @(posedge clk)`) |
| **Why it works** | Gate outputs propagate immediately | Flip-flops sample and update simultaneously |

## Tips

1. **Never** use `assign` on `reg` variables
2. **Always** use `<=` for sequential logic (flip-flops) in `always @(posedge clk)`
3. **Always** use `=` for combinational logic in `always @(*)`
4. **Never** mix `=` and `<=` in the same `always` block
5. **Always** assign all outputs in combinational blocks to avoid inferring latches