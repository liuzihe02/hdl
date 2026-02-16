# Verilog State Machines (FSMs)

A **Finite State Machine (FSM)** is a sequential circuit that transitions between a finite number of states based on inputs and the current state. FSMs are fundamental to digital design — used in protocol controllers, datapath sequencing, pattern detection, and more.

## Types of FSMs

FSMs are classified along two axes: **output generation** and **state encoding**.

**By output generation:**

- **Moore machine** — outputs depend *solely* on the current state. Outputs change only on state transitions (at clock edges), making them inherently glitch-free.
- **Mealy machine** — outputs depend on *both* the current state and current inputs. Outputs can change asynchronously with inputs within a clock cycle, giving faster response but risking glitches.

**By state encoding:**

- **Binary encoding** — states represented as standard binary numbers (e.g., `00`, `01`, `10`, `11`). Uses fewest flip-flops (`⌈log₂(N)⌉` for N states) but more complex next-state logic.
- **One-hot encoding** — each state uses one dedicated bit (e.g., `0001`, `0010`, `0100`, `1000`). Uses N flip-flops for N states but yields simpler, faster combinational logic. Preferred for FPGAs where flip-flops are abundant.

## FSM Structure in Verilog

The recommended approach is the **two-`always`-block** style, which cleanly separates:

1. A **sequential** (clocked) `always` block — updates present state
2. A **combinational** `always` block — computes next state logic

Output logic is handled either inside the combinational block or via separate `assign` statements.

```
                 ┌──────────────────┐
   inputs ──────►│  Combinational   │
                 │  (next state +   ├──────► outputs
        ┌───────►│   output logic)  │
        │        └────────┬─────────┘
        │                 │ next_state
        │        ┌────────▼─────────┐
        │        │   Sequential     │
        └────────┤   (FF register)  │◄────── clk, reset
                 └──────────────────┘
                   cur_state
```

### Sequential Always Block

The state register updates **only at the clock edge**. This block should be minimal — just a reset condition and a state update.

```verilog
// Synthesizable: clocked present-state register
always @(posedge clk) begin
    if (!resetn)
        cur_state <= IDLE;       // Synchronous active-low reset
    else
        cur_state <= next_state; // Transition to computed next state
end
```

> **Rule:** Always use **non-blocking assignments** (`<=`) in sequential `always` blocks. Non-blocking assignments model pipeline register behavior and prevent race conditions in simulation.

### Combinational Always Block

This block computes `next_state` based on `cur_state` and inputs. It re-evaluates whenever any signal in the sensitivity list changes.

```verilog
// Synthesizable: next-state combinational logic
always @(*) begin                    // @(*) auto-includes all read signals
    next_state = IDLE;               // Default assignment prevents latches

    case (cur_state)
        IDLE:    if (input_signal)
                     next_state = STATE_1;

        STATE_1: if (!input_signal)
                     next_state = STATE_2;

        STATE_2: next_state = IDLE;

        default: next_state = IDLE;  // Safe fallback for undefined states
    endcase
end
```

> **Rule:** Always use **blocking assignments** (`=`) in combinational `always` blocks. This ensures signals evaluate in sequential order, correctly modeling combinational logic.

**Key practices for the combinational block:**

- Use `always @(*)` to auto-infer the full sensitivity list and avoid simulation mismatches.
- Provide a **default `next_state` assignment** at the top, before the `case` statement. This prevents unintentional latch inference when not every branch assigns `next_state`.
- Include a `default` case in the `case` statement as a safety net for unreachable/illegal states.

### Output Generation

There are three common approaches for driving FSM outputs:

**Approach 1: Inside the combinational block (most common)**

Place default output values at the top, then override within specific states. This keeps all FSM logic co-located and is clean for Moore-style outputs.

```verilog
always @(*) begin
    // Defaults — prevent latches
    next_state = IDLE;
    output_signal = 0;

    case (cur_state)
        IDLE: begin
            if (go) begin
                next_state = ACTIVE;
                output_signal = 1;
            end
        end
        ACTIVE: begin
            next_state = IDLE;
        end
        // ...
    endcase
end
```

**Approach 2: Separate continuous assignments**

Simple and concise for straightforward Moore outputs, but becomes verbose when many states affect many outputs.

```verilog
assign out = (cur_state == S_DONE) ? 1 : 0;
```

**Approach 3: Registered outputs (third sequential block)**

Outputs are registered through flip-flops using non-blocking assignments in a separate clocked block. This adds one cycle of output latency but eliminates glitches on outputs — useful for clean output timing.

```verilog
// Optional: registered output for glitch-free behavior
always @(posedge clk) begin
    if (!resetn)
        out_reg <= 0;
    else if (next_state == S_DONE)
        out_reg <= 1;
    else
        out_reg <= 0;
end
```

## State Encoding in Practice

States are typically defined with `parameter` for readability:

```verilog
// Binary encoding — compact, uses ⌈log₂(N)⌉ FFs
parameter IDLE = 0, S1 = 1, S2 = 2, S3 = 3;
reg [1:0] cur_state, next_state;

// One-hot encoding — one FF per state, simpler decode logic
parameter IDLE = 4'b0001, S1 = 4'b0010, S2 = 4'b0100, S3 = 4'b1000;
reg [3:0] cur_state, next_state;
```

> **Note:** Most synthesis tools can re-encode states automatically (e.g., via `(* fsm_encoding = "one_hot" *)` attributes), so binary encoding in RTL is common even when one-hot is desired in hardware.

## Example: Sequence Detector (1011)

A classic FSM application: detect the bit pattern `1011` in a serial input stream. The output goes high for one clock cycle when the full pattern is recognized.

**State diagram concept:** each state represents how much of the target pattern has been matched so far. On each clock, the machine either progresses toward a full match or falls back.

```verilog
module det_1011 (
    input  clk,
    input  rstn,
    input  in,
    output out
);

    parameter IDLE = 0,
              S1   = 1,   // Matched "1"
              S10  = 2,   // Matched "10"
              S101 = 3,   // Matched "101"
              S1011 = 4;  // Matched "1011" — full detection

    reg [2:0] cur_state, next_state;

    // Moore output: high only in the detected state
    assign out = (cur_state == S1011) ? 1 : 0;

    // Sequential: state register
    always @(posedge clk) begin
        if (!rstn)
            cur_state <= IDLE;
        else
            cur_state <= next_state;
    end

    // Combinational: next-state logic
    always @(cur_state or in) begin
        case (cur_state)
            IDLE:  next_state = in ? S1   : IDLE;
            S1:    next_state = in ? IDLE : S10;   // got "1", need "0" next
            S10:   next_state = in ? S101 : IDLE;  // got "10", need "1"
            S101:  next_state = in ? S1011: IDLE;  // got "101", need "1"
            S1011: next_state = IDLE;              // detection done, reset
            default: next_state = IDLE;
        endcase
    end
endmodule
```

> **Bug note:** The `S1011` state always transitions to `IDLE` regardless of input. If overlapping detection is desired (e.g., detecting `1011` in `10110...11`), `S1011` should check the input and potentially transition to `S1` (if `in=1`) instead of unconditionally going to `IDLE`.

## Example: Pattern Detector (110101)

A longer pattern detection FSM demonstrating the same two-`always`-block structure scaled to more states. Detects `110101` in a serial bit stream.

```verilog
module det_110101 (
    input  clk,
    input  rstn,
    input  in,
    output out
);

    parameter IDLE    = 0,
              S1      = 1,   // "1"
              S11     = 2,   // "11"
              S110    = 3,   // "110"
              S1101   = 4,   // "1101"
              S11010  = 5,   // "11010"
              S110101 = 6;   // "110101" — detected

    reg [2:0] cur_state, next_state;

    assign out = (cur_state == S110101) ? 1 : 0;

    always @(posedge clk) begin
        if (!rstn)
            cur_state <= IDLE;
        else
            cur_state <= next_state;
    end

    always @(cur_state or in) begin
        case (cur_state)
            IDLE:    next_state = in ? S1     : IDLE;
            S1:      next_state = in ? S11    : IDLE;
            S11:     next_state = in ? S11    : S110;   // Stay in S11 on more 1s
            S110:    next_state = in ? S1101  : IDLE;
            S1101:   next_state = in ? IDLE   : S11010; // Note: 1 here breaks pattern
            S11010:  next_state = in ? S110101: IDLE;
            S110101: next_state = in ? S1     : IDLE;
            default: next_state = IDLE;
        endcase
    end
endmodule
```

**Key observation in `S11`:** when the machine has matched `"11"` and sees another `1`, it stays in `S11` rather than going to `IDLE`. This is because `"111..."` still ends with `"11"`, preserving partial match progress. Getting these fallback transitions right is the core challenge in sequence detector design.

## Overlapping vs. Non-Overlapping Detection

When designing sequence detectors, a critical decision is whether the detector should support **overlapping** matches:

- **Non-overlapping:** after a full match, return to `IDLE` and start fresh. The pattern `1011011` would detect only one `1011`.
- **Overlapping:** after a full match, transition to a state that preserves any partial match with the beginning of the pattern. The pattern `1011011` could detect `1011` twice if the end of one match overlaps with the start of another.

The key implementation difference is in the **detection state's transitions.** Instead of unconditionally going to `IDLE`, check whether the current input begins a new partial match and transition to the appropriate intermediate state.

## FSM Design Guidelines

**Structural rules:**

- Use the **two-`always`-block** style: one clocked (sequential), one combinational. This maps cleanly to the conceptual FSM model and is widely understood.
- **Non-blocking** (`<=`) in sequential blocks, **blocking** (`=`) in combinational blocks. Mixing these up is a classic source of simulation/synthesis mismatches.
- Always provide **default assignments** for `next_state` and all outputs at the top of the combinational block to prevent latch inference.
- Always include a `default` case to handle illegal/unreachable state encodings safely.

**Design considerations:**

- Ensure the state register is **wide enough** to encode all states (`reg [2:0]` supports up to 8 states).
- Use `parameter` (not magic numbers) for state names to improve readability.
- For sequence detectors, carefully work out **fallback transitions** — when a match fails partway, determine if any suffix of the input so far is a prefix of the target pattern.
- Decide **overlapping vs. non-overlapping** detection early, as it affects transitions from the detection state.
- Consider **registered outputs** (third `always` block) when glitch-free outputs are critical for downstream logic.

## Quick Reference

| Aspect | Sequential Block | Combinational Block |
|---|---|---|
| **Sensitivity** | `posedge clk` | `@(*)` (all signals) |
| **Assignment type** | Non-blocking (`<=`) | Blocking (`=`) |
| **Purpose** | Update `cur_state` register | Compute `next_state` + outputs |
| **Reset** | Drives `cur_state` to initial state | Not applicable |
| **Hardware** | Flip-flops | Multiplexers / logic gates |
| **Latch prevention** | N/A (inherently registered) | Default assignments required |