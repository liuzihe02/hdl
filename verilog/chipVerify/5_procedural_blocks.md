# Procedural Blocks

Verilog statements are executed sequentially inside **procedural blocks**. There are two types: `initial` and `always`. All procedural blocks within a module run **concurrently** with each other from time 0, modelling the parallel nature of hardware.

---

## `initial` Block

An `initial` block executes **once** starting at simulation time 0. It is **not synthesizable** and is used exclusively in testbenches for stimulus generation, variable initialization, and simulation control.

```verilog
initial
    a = 2'b10;           // single statement — no begin/end needed

initial begin
    a = 2'b10;           // executes at t=0
    #10 b = 8'h00;       // executes at t=10
end
```

**Key properties:**

- Executes only once, starting at time 0.
- Multiple `initial` blocks in a module all start at time 0 and run in parallel.
- The simulation ends when all `initial` blocks have completed (or `$finish` is called).
- `$finish` in any block terminates the entire simulation immediately, killing all other active blocks.

```verilog
// Three parallel initial blocks
initial #20  $display("Block 1 done");   // finishes at t=20
initial begin
    #10 $display("Block 2 step 1");      // t=10
    #40 $display("Block 2 step 2");      // t=50
end
initial #60  $finish;                    // simulation ends at t=60
```

---

## `always` Block

An `always` block runs **continuously** throughout simulation, re-triggering whenever its **sensitivity list** event occurs. Unlike `initial`, the `always` block **can be synthesized** into hardware.

```verilog
always @ (event)
    [statement]

always @ (event) begin
    [multiple statements]
end
```

### Sensitivity List

The sensitivity list (after `@`) defines **when** the block executes. It can contain signal names, edge specifiers, or `*` (all inputs).

```verilog
// Trigger on any change of a or b (combinational)
always @ (a or b) begin
    o <= ~((a & b) | (c ^ d));
end

// Trigger on rising edge of clk (sequential)
always @ (posedge clk) begin
    q <= d;
end

// Trigger on rising clk OR falling reset (sequential with async reset)
always @ (posedge clk or negedge rstn) begin
    if (!rstn)
        q <= 0;
    else
        q <= d;
end
```

> **Warning:** An `always` block with **no sensitivity list and no delay** creates a zero-delay infinite loop that hangs the simulation.

```verilog
always clk = ~clk;       // HANGS — no timing control
always #10 clk = ~clk;   // OK — clock toggles every 10 time units (but not synthesizable)
```

### Synthesizable `always` Block Templates

| Template | Sensitivity List | Infers |
|---|---|---|
| Combinational logic | `@ (all_inputs)` or `@ (*)` | Combo gates |
| Latch (usually unintended) | `@ (all_inputs)` with `if` but no `else` | Latch |
| Flip-flop (sync reset) | `@ (posedge clk)` | D flip-flop |
| Flip-flop (async reset) | `@ (posedge clk or negedge rstn)` | D flip-flop with async reset |

> **Important:** All signals assigned inside an `always` block must be declared as `reg`. Explicit `#` delays are not synthesizable — real design code always uses a sensitivity list.

### Combinational Example

```verilog
module combo (input a, b, c, d,
              output reg o);

    always @ (a or b or c or d) begin
        o <= ~((a & b) | (c ^ d));
    end
endmodule
```

### Sequential Example — T Flip-Flop

```verilog
module tff (input       d, clk, rstn,
            output reg  q);

    always @ (posedge clk or negedge rstn) begin
        if (!rstn)
            q <= 0;          // async reset: output cleared
        else if (d)
            q <= ~q;         // toggle on d=1
        else
            q <= q;          // hold
    end
endmodule
```

---

## Control Flow

Hardware behavior requires conditional statements and loops to control logic flow within procedural blocks.

### `if-else-if`

Works like C. The `else` part is optional. Without explicit `begin-end`, a dangling `else` associates with the nearest preceding `if` that lacks one.

```verilog
if (expression)
    [statement]
else if (expression)
    [statement]
else
    [statement]       // default / none-of-the-above

// For multiple statements, use begin-end
if (expression) begin
    [multiple statements]
end else begin
    [multiple statements]
end
```

> **Synthesis note:** An `if` without a corresponding `else` inside a combinational `always` block infers a **latch**, because the previous value must be held.

### Loops

Loops are used inside procedural blocks (`initial` / `always`) for simulation and, in limited cases, for synthesizable logic.

| Loop | Syntax | Behavior |
|---|---|---|
| `forever` | `forever [statement]` | Executes indefinitely. Must include a timing control or `$finish` to avoid hanging. |
| `repeat` | `repeat(N) [statement]` | Executes exactly N times. If N is X or Z, treated as 0. |
| `while` | `while(expr) [statement]` | Executes as long as expression is true. |
| `for` | `for(init; cond; incr) [statement]` | Standard three-part loop (init, condition check, increment). |

```verilog
// forever — commonly used for clock generation in testbenches
initial begin
    clk = 0;
    forever #5 clk = ~clk;  // 10-unit period clock
end

// repeat
initial begin
    repeat(4) begin
        $display("Iteration");
    end
end

// while
integer i = 5;
initial begin
    while (i > 0) begin
        $display("Iteration#%0d", i);
        i = i - 1;
    end
end

// for
initial begin
    for (i = 0; i < 5; i = i + 1) begin
        $display("Loop #%0d", i);
    end
end
```

---

## Block Statements

Block statements group multiple statements into a single syntactic unit. There are two kinds: **sequential** and **parallel**.

### Sequential Blocks (`begin-end`)

Statements execute **one after another**. Delays are **relative** to the previous statement's execution time.

```verilog
initial begin
    #10  data = 8'hfe;    // executes at t=10
    #20  data = 8'h11;    // executes at t=30 (10 + 20)
end
```

### Parallel Blocks (`fork-join`)

Statements launch **concurrently** at the moment the `fork` is entered. Delays are all **relative to the fork entry time**, not to each other. The `join` waits until **all** parallel statements complete.

```verilog
initial begin
    #10 data = 8'hfe;      // t=10
    fork
        #20 data = 8'h11;  // t=30 (10+20)
        #10 data = 8'h00;  // t=20 (10+10) — executes first
    join
end
```

You can **nest** `begin-end` inside `fork-join`. The nested sequential block is launched as one parallel branch:

```verilog
initial begin
    #10 data = 8'hfe;           // t=10
    fork
        #10 data = 8'h11;       // t=20
        begin
            #20 data = 8'h00;   // t=30
            #30 data = 8'haa;   // t=60
        end
    join
end
```

### Naming Blocks

Both block types can be named with `: name` after `begin` or `fork`. Named blocks can be referenced in `disable` statements to exit them early.

```verilog
begin : my_seq_block
    [statements]
end

fork : my_par_block
    [statements]
join
```

---

## Quick Reference: `initial` vs `always`

| Property | `initial` | `always` |
|---|---|---|
| Execution | Once, starting at t=0 | Repeatedly, on each sensitivity event |
| Synthesizable | No | Yes (with proper sensitivity list) |
| Typical use | Testbench stimulus, initialization | RTL design (combinational & sequential logic) |
| Sensitivity list | None | Required for synthesis |
| Multiple per module | Yes, all run in parallel | Yes, all run in parallel |

## Quick Reference: `begin-end` vs `fork-join`

| Property | `begin-end` (Sequential) | `fork-join` (Parallel) |
|---|---|---|
| Execution order | Statements execute in order | Statements launch simultaneously |
| Delay behavior | Relative to previous statement | Relative to fork entry time |
| Completion | After last statement finishes | After **all** branches finish |
| Can be named | Yes (`: name`) | Yes (`: name`) |
| Nesting | Can nest inside `fork-join` | Can nest inside `begin-end` |