# Chip Verify Chapter 12 Verilog Loops & Generate

## `for` Loop

A `for` loop iterates a set of statements as long as a given condition is true. In Verilog, it is primarily used to **replicate hardware logic** — it does not describe sequential execution at runtime the way software loops do. The synthesis tool **unrolls** the loop into **parallel hardware.**

```verilog
for (<initial_condition>; <condition>; <step_assignment>) begin
    // Statements
end
```

The three parts are: initial condition, loop-continuation check, and step (update of the control variable). Unlike a `while` loop (which is more general-purpose), a `for` loop has a definite beginning and end controlled by the step variable.

> **Note:** Verilog does **not** have the `++` or `--` operators. Use `i = i + 1` instead.

### Basic Usage (Simulation Only)

```verilog
module my_design;
    integer i;

    // initial block: simulation-only, not synthesizable
    initial begin
        for (i = 0; i < 10; i = i + 1) begin
            $display("Current loop#%0d", i);
        end
    end
endmodule
```

### Synthesizable Example — Shift Register

Without a `for` loop, an 8-bit left circular shift register requires manually writing every bit assignment:

```verilog
// Tedious, non-scalable approach
op[0] <= op[7];
op[1] <= op[0];
op[2] <= op[1];
// ... etc for all 8 bits
```

Using a `for` loop makes this **concise and scalable** — if the register width is parameterized, the same code works for any width:

```verilog
module lshift_reg (
    input             clk,
    input             rstn,       // Active-low reset
    input  [7:0]      load_val,
    input             load_en,
    output reg [7:0]  op
);
    integer i;

    // Synthesizable: for loop inside always @(posedge clk)
    always @(posedge clk) begin
        if (!rstn) begin
            op <= 0;
        end else if (load_en) begin
            op <= load_val;
        end else begin
            for (i = 0; i < 8; i = i + 1) begin
                op[i+1] <= op[i];  // Shift left
            end
            op[0] <= op[7];        // Circular wrap
        end
    end
endmodule
```

The synthesis tool unrolls this into 8 parallel non-blocking assignments — the resulting hardware is identical to the manual version.

## `generate` Blocks

A `generate` block allows you to **replicate module instances** or **conditionally instantiate** modules/logic based on parameters. Everything inside `generate`...`endgenerate` is evaluated at **elaboration time** (before simulation), not at runtime.

Generated instantiations can contain: modules, continuous assignments (`assign`), `always` or `initial` blocks, and user-defined primitives.

> **Restriction:** A `generate` block **cannot** contain port declarations, parameter declarations, `specparam` declarations, or `specify` blocks.

There are three generate construct types:

| Construct | Purpose | Key Mechanism |
|---|---|---|
| `generate for` | Replicate instances N times | Loop with `genvar` iterator |
| `generate if` | Conditionally instantiate one of two designs | `if`/`else` on a parameter |
| `generate case` | Select one of many designs | `case` on a parameter |

### `generate for` — Replicating Instances

Use `generate for` when the same module or logic needs to be instantiated multiple times. The loop variable **must** be declared with `genvar` — this is a special elaboration-time variable that does not exist during simulation.

```verilog
// Half adder to be replicated
module ha (
    input  a, b,
    output sum, cout
);
    assign sum  = a ^ b;
    assign cout = a & b;
endmodule

// Top-level: instantiate N half adders
module my_design #(parameter N = 4) (
    input  [N-1:0] a, b,
    output [N-1:0] sum, cout
);
    genvar i;  // Elaboration-time variable, not available in simulation

    generate
        for (i = 0; i < N; i = i + 1) begin
            ha u0 (a[i], b[i], sum[i], cout[i]);
        end
    endgenerate
endmodule
```

Each iteration creates an independent half adder instance: `a[0]`/`b[0]` → `sum[0]`/`cout[0]`, `a[1]`/`b[1]` → `sum[1]`/`cout[1]`, etc.

### `generate if` — Conditional Instantiation

Use `generate if` to select between different design implementations based on a parameter value. This is resolved at elaboration time — only one branch is instantiated.

```verilog
// Option A: mux using assign
module mux_assign (input a, b, sel, output out);
    assign out = sel ? a : b;
endmodule

// Option B: mux using case
module mux_case (input a, b, sel, output reg out);
    always @(a or b or sel) begin
        case (sel)
            0 : out = a;
            1 : out = b;
        endcase
    end
endmodule

// Top-level: parameter selects which implementation
module my_design (input a, b, sel, output out);
    parameter USE_CASE = 0;

    generate
        if (USE_CASE)
            mux_case  mc (.a(a), .b(b), .sel(sel), .out(out));
        else
            mux_assign ma (.a(a), .b(b), .sel(sel), .out(out));
    endgenerate
endmodule
```

### `generate case` — Multi-Way Selection

Use `generate case` when there are more than two design alternatives to choose from.

```verilog
module ha (input a, b, output reg sum, cout);
    always @(a or b)
        {cout, sum} = a + b;
endmodule

module fa (input a, b, cin, output reg sum, cout);
    always @(a or b or cin)
        {cout, sum} = a + b + cin;
endmodule

module my_adder (input a, b, cin, output sum, cout);
    parameter ADDER_TYPE = 1;

    generate
        case (ADDER_TYPE)
            0 : ha u0 (.a(a), .b(b), .sum(sum), .cout(cout));
            1 : fa u1 (.a(a), .b(b), .cin(cin), .sum(sum), .cout(cout));
        endcase
    endgenerate
endmodule
```

When `ADDER_TYPE=0`, only the half adder is instantiated — `cin` has no effect on outputs.

---

## `for` Loop vs `generate for` — Key Distinction

| Aspect | `for` loop (inside `always`/`initial`) | `generate for` |
|---|---|---|
| **When evaluated** | Simulation time (or unrolled at synthesis) | Elaboration time (before simulation) |
| **Iterator type** | `integer` | `genvar` |
| **Can instantiate modules?** | No | Yes |
| **Can contain `assign`, `always`?** | No (already inside a procedural block) | Yes |
| **Primary use** | Replicate assignments within a procedural block | Replicate module instances or structural code |
| **Synthesizable?** | Yes, if bounds are compile-time constants | Yes, always |

---

## Quick Reference

### `for` Loop Syntax

```verilog
integer i;
always @(posedge clk) begin
    for (i = 0; i < N; i = i + 1) begin
        // Replicated assignments (unrolled into parallel hardware)
    end
end
```

### `generate` Block Syntax

```verilog
genvar i;
generate
    // generate for
    for (i = 0; i < N; i = i + 1) begin
        // Module instantiations, assign, always blocks
    end

    // generate if
    if (PARAM)
        mod_a u0 (...);
    else
        mod_b u0 (...);

    // generate case
    case (PARAM)
        0 : mod_a u0 (...);
        1 : mod_b u1 (...);
    endcase
endgenerate
```

### Common Pitfalls

- **No `++`/`--` operators** in Verilog. Always write `i = i + 1`.
- **`genvar` vs `integer`:** Use `genvar` only inside `generate for`. Use `integer` for `for` loops inside procedural blocks.
- **`genvar` scope:** The `genvar` variable does not exist during simulation — it is only used during elaboration.
- **Loop bounds must be compile-time constants** for synthesis. A `for` loop with runtime-variable bounds will not synthesize.
- **`generate` cannot contain ports or parameters** — only module items like instances, `assign`, `always`, `initial`.