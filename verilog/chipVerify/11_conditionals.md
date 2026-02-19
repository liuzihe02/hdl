# ChipVerify Chapter 11: Verilog Conditional Statements

Conditional statements control the flow of execution based on conditions. Verilog provides three main mechanisms: the **conditional (ternary) operator**, the **if-else-if** statement, and the **case** statement.

---

## Conditional (Ternary) Operator

```verilog
<variable> = <condition> ? <expression_1> : <expression_2>;
```

If the condition is true, `expression_1` is assigned; otherwise, `expression_2` is assigned. This is usable in both continuous assignments (`assign`) and procedural blocks, and is **synthesizable**.

**Nested conditional operators** are legal but quickly hurt readability:

```verilog
// y when (a < b) AND (x % 2); z when (a < b) AND !(x % 2); 0 otherwise
assign out = (a < b) ? (x % 2) ? y : z : 0;
```

The ternary operator is best suited for **simple, single-line conditional assignments** — think of it as a compact mux. For anything with multiple branches or complex conditions, prefer `if-else` or `case`.

---

## `if-else-if` Statement

This is a **procedural statement** — it can only appear inside `always`, `initial`, `task`, or `function` blocks.

### Syntax

```verilog
// Single statement — no begin/end needed
if (<expression>)
    <statement>;

// Multiple statements — must use begin/end
if (<expression>) begin
    <statements>
end

// if-else
if (<expression>) begin
    <statements>
end else begin
    <statements>
end

// if-else-if chain
if (<expression_1>)
    <statement>;
else if (<expression_2>) begin
    <statements>
end else
    <statement>;
```

Evaluation rules:
- Expression evaluates to **true** (any non-zero value) → execute the `if` block.
- Expression evaluates to **false** (`0`, `x`, or `z`) → skip to `else` / next `else if`.

### Hardware Implementation

The key synthesis implication of `if-else-if` is that it creates **priority logic** — conditions are checked in order, and the first match wins. This maps to a priority encoder / priority mux chain.

#### `if` without `else` (Latch inference)

When an `if` has no `else` and is inside a combinational `always` block, the output must retain its old value when the condition is false. This implies **memory** — the synthesizer infers a **latch**.

> A latch is basically a single (sequential) memory elements such as the `D` latch or the `SR` latch. A flip-flop is built from 2 latches in a master-slave configuration. `gates -> latch -> flip-flop`

```verilog
module des (input en, input d, output reg q);
    // ⚠ COMBINATIONAL always block with incomplete if → latch inferred
    always @(en or d)
        if (en)
            q = d;
            // no else: q retains value when en=0 → LATCH
endmodule
```

> **Synthesis result:** A latch on `q`, enabled by `en`. In most cases flip-flops are preferred over altches due to timing stability!

#### `if-else` (Clean combinational or sequential logic)

```verilog
module dff (input clk, input rstn, input d, output reg q);
    // ✔ SEQUENTIAL always block (posedge clk) — synthesizes to a D flip-flop
    always @(posedge clk) begin
        if (!rstn)
            q <= 0;     // Synchronous reset
        else
            q <= d;
    end
endmodule
```

> **Synthesis result:** D flip-flop with synchronous reset.

#### `if-else-if` chain (counter with mode control)

```verilog
module des (input [1:0] mode, input clk, input rstn,
            output reg [3:0] q);

    always @(posedge clk) begin
        if (!rstn)
            q <= 0;
        else begin
            if (mode == 1)
                q <= q + 1;       // increment
            else if (mode == 2)
                q <= q - 1;       // decrement
            // mode 0 and 3: q retains value (flop holds)
        end
    end
endmodule
```

> **Synthesis result:** 4-bit flop with a clock-enable (CE) pin. CE is active only when `mode == 1` or `mode == 2`. An adder/subtractor feeds back through a mux controlled by `mode`.

When `mode` is reduced to 1-bit (always either increment or decrement), the CE pin is no longer needed — a regular flop with a mux suffices, since all paths are covered.

---

## `case` Statement

The `case` statement evaluates an expression **once** and compares it against a list of alternatives **in order**. It is **procedural** (must be inside `always`, `initial`, etc.) and is **synthesizable**.

### Syntax

```verilog
case (<expression>)
    case_item1 :  <single statement>;
    case_item2,
    case_item3 :  <single statement>;            // multiple items share one action
    case_item4 :  begin
                      <multiple statements>
                  end
    default    :  <statement>;                   // optional, at most one
endcase
```

- If no item matches and no `default` is provided, **nothing executes** (and in combinational blocks, this can infer latches — same issue as `if` without `else`).
- Case statements can be **nested**.
- Multiple case items can share a single action by comma-separating them.
- If you can't implement a function/mapping using simple Boolean gates, then consider using `case`!

### Example: 4-to-1 Multiplexer

```verilog
module my_mux (input      [2:0] a, b, c,
               input      [1:0] sel,
               output reg [2:0] out);

    // ✔ Combinational always — all inputs in sensitivity list
    always @(a, b, c, sel) begin
        case (sel)
            2'b00   : out = a;
            2'b01   : out = b;
            2'b10   : out = c;
            default : out = 0;    // sel=3 → output zero
        endcase
    end
endmodule
```

> **Synthesis result:** A 4-to-1 multiplexer.

### X/Z Matching Behaviour

In a standard `case` statement, comparison succeeds only when **each bit matches exactly**, including `x` and `z` values. This means:

- If `sel` contains any `x` or `z` bits at runtime, it will **not** match `2'b00`, `2'b01`, etc. — only the `default` branch (if present) will execute.
- Conversely, you *can* place `x`/`z` in the case items themselves, and they will match only if the expression has the exact same `x`/`z` pattern.

```verilog
// Case items with x/z — matches only exact x/z patterns
case (sel)
    2'bxz   : out = a;   // matches sel === 2'bxz exactly
    2'bzx   : out = b;
    2'bxx   : out = c;
    default : out = 0;
endcase
```

> This is primarily a **simulation** concern. In synthesis, `x` and `z` have no real hardware meaning — the synthesizer treats `case` as matching only concrete `0`/`1` patterns.

---

## `case` vs `if-else-if`

| Aspect | `if-else-if` | `case` |
|---|---|---|
| **Condition type** | Arbitrary boolean expressions (can compare different variables, use `&&`, `\|\|`, etc.) | Single expression matched against constant items |
| **Synthesis result** | Priority encoder / priority mux (order matters) | Multiplexer (parallel selection, all items checked equally) |
| **X/Z handling** | `x` and `z` evaluate as *false* | `x` and `z` participate in exact 4-value matching |
| **Best for** | Complex, unrelated conditions; prioritized logic | Selecting among values of a single signal; FSMs; decoders |

---

## Pitfalls and Guidelines

**Unintentional latch inference** — The most common synthesis pitfall in this chapter. In a combinational `always` block, every path through `if-else` or `case` must assign **every** output. If any branch omits an assignment (including a missing `else` or missing `default`), the synthesizer infers a latch to hold the previous value. To avoid this:
- Always include an `else` clause in combinational `if` statements.
- Always include a `default` clause in combinational `case` statements.
- Alternatively, assign a default value to outputs at the top of the `always` block, before the `if`/`case`.

**`begin`/`end` scoping** — Without `begin`/`end`, only the *single next statement* belongs to the `if`/`else` branch. This is a frequent source of bugs:

```verilog
if (a == 10)
    $display("a is 10");
    $display("always runs");   // ← NOT inside the if block!
```

**Blocking (`=`) vs non-blocking (`<=`)** — Use `=` (blocking) for combinational `always` blocks and `<=` (non-blocking) for sequential (`posedge`/`negedge`) blocks. Mixing them within the same block causes simulation-synthesis mismatches.

**Nested ternary operators** — Legal but consider replacing deep nesting with `if-else` or `case` for readability and maintainability.

---

## Quick Reference

| Construct | Context | Synthesizable? | Typical Hardware |
|---|---|---|---|
| `? :` (ternary) | `assign` or procedural | Yes | 2-to-1 mux |
| `if-else-if` | Procedural blocks only | Yes | Priority encoder / priority mux chain |
| `case` | Procedural blocks only | Yes | Parallel mux (e.g. 4-to-1) |
| `if` without `else` (combinational) | Procedural | Yes — but infers **latch** | Latch (usually unintended) |
| `case` without `default` (combinational) | Procedural | Yes — but infers **latch** | Latch (usually unintended) |