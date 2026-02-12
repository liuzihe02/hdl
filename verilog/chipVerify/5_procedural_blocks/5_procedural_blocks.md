# Chip Verify Verilog Chapter 5: Procedural Blocks

**Procedural blocks** contain statements that execute sequentially (unlike concurrent module-level statements). Verilog has two main types: `initial` and `always`.

## Initial Block

The `initial` block executes **once** at the start of simulation (time 0) and is **NOT synthesizable**. Used exclusively for testbenches and simulation.

```verilog
initial 
    [single_statement]

initial begin
    [multiple_statements]
end
```

### Timing Behavior

**Start:** Time 0 units  
**End:** When all statements complete  
**Execution:** Once per simulation

```verilog
module example;
    reg [1:0] a, b;
    
    // Executes at time 0, completes at time 10
    initial begin
        a = 2'b10;      // Executes at time 0
        #10 b = 2'b01;  // Executes at time 10
    end
endmodule
```

### Multiple Initial Blocks

- **Unlimited** number of initial blocks allowed per module
- All start at time 0 and execute **in parallel**
- Each runs independently until completion

```verilog
module multi_init;
    initial begin
        #20 $display("Block 1 done");  // Finishes at t=20
    end
    
    initial begin
        #10 $display("Block 2 done");  // Finishes at t=10
        #40 $display("Block 2 really done");  // Finishes at t=50
    end
    
    initial begin
        #60 $finish;  // Ends simulation at t=60, killing all other blocks
    end
endmodule
```

**Important:** If one block calls `$finish`, simulation ends immediately, terminating all active blocks.

### Use Cases

| Use | Example |
|-----|---------|
| Initialize variables | `initial clk = 0;` |
| Generate test stimulus | `initial begin #10 din = 8'hAA; end` |
| Monitor signals | `initial $monitor("time=%0t data=%h", $time, data);` |
| Control simulation | `initial #1000 $finish;` |

**Synthesis:** Initial blocks are **NEVER synthesizable** - ignored by synthesis tools.

## Always Block

The `always` block is a **continuous process** that executes whenever signals in its sensitivity list change. It **IS synthesizable**.

### Syntax

```verilog
always @ (sensitivity_list)
    [statement]

always @ (sensitivity_list) begin
    [multiple_statements]
end
```

### Sensitivity List

The **sensitivity list** defines when the always block triggers. It contains signals whose changes activate the block.

```verilog
// Triggers when a OR b changes
always @ (a or b) begin
    out = a & b;
end

// Triggers on positive edge of clk
always @ (posedge clk) begin
    q <= d;
end

// Triggers on posedge clk OR negedge reset
always @ (posedge clk or negedge rstn) begin
    if (!rstn)
        q <= 0;
    else
        q <= d;
end
```

### Edge Specifiers

| Keyword | Meaning | Usage |
|---------|---------|-------|
| `posedge` | Rising edge (0→1) | Clocks, synchronous logic |
| `negedge` | Falling edge (1→0) | Resets, inverted clocks |

### Empty Sensitivity List

**Dangerous!** Without timing control, creates infinite zero-delay loop:

```verilog
// BAD - simulation hangs!
always 
    clk = ~clk;  // Executes forever at time 0

// GOOD - adds delay (for testbench only, not synthesizable)
always #10 clk = ~clk;  // Toggle every 10 time units
```

**Rule:** Design code must always have a sensitivity list.

### Sequential Logic with Always

Use for flip-flops, registers, and state machines.

```verilog
// D Flip-Flop with async reset
module dff (
    input      clk,
    input      rstn,
    input      d,
    output reg q
);
    // on the rising edge of clock
    always @ (posedge clk or negedge rstn) begin
        if (!rstn)
            q <= 0;          // Async reset
        else
            q <= d;          // Capture data on clock edge
    end
endmodule
```

**Execution Flow (posedge clk):**
1. Check reset condition
2. If reset active → set output to default
3. Else → perform sequential operation

**Execution Flow (negedge rstn):**
1. Reset becomes active (1→0)
2. Output forced to reset value
3. Sequential operation suspended

### Combinational Logic with Always

Use for combo logic (muxes, decoders, ALUs).

```verilog
module combo (
    input  a, b, c, d,
    output reg o
);
    // All inputs in sensitivity list
    always @ (a or b or c or d) begin
        o = ~((a & b) | (c ^ d));
    end
endmodule

// Verilog-2001 shorthand
always @ (*) begin  // Auto-includes all RHS signals
    o = ~((a & b) | (c ^ d));
end
```

**Critical:** For combo logic, **ALL** inputs must be in sensitivity list to avoid synthesis/simulation mismatch.

## Control Flow Statements

### if-else-if

```verilog
// Single if
if (condition)
    statement;

// if-else
if (condition)
    statement1;
else
    statement2;

// if-else-if ladder
if (condition1)
    statement1;
else if (condition2)
    statement2;
else
    statement3;  // default case

// Multiple statements require begin-end
if (condition) begin
    statement1;
    statement2;
end else begin
    statement3;
end
```

**Nested if Rules:**
- `else` pairs with nearest unpaired `if`
- Use `begin-end` to clarify pairing
- Last `else` handles default case

## Loops

### forever Loop

Executes continuously until simulation ends or `$finish` called.

```verilog
initial begin
    forever begin
        #10 clk = ~clk;  // Clock generator
    end
end
```

**Warning:** Without delay, creates infinite loop!

### repeat Loop

Executes fixed number of times.

```verilog
initial begin
    repeat(4) begin
        $display("Iteration");
    end
end
// Prints "Iteration" 4 times
```

**Note:** If count expression is X or Z, treated as 0 (no execution).

### while Loop

Executes while condition is true.

```verilog
integer i = 5;

initial begin
    while (i > 0) begin
        $display("i = %0d", i);
        i = i - 1;
    end
end
// Prints: i=5, i=4, i=3, i=2, i=1
```

### for Loop

Counter-based iteration.

```verilog
integer i;

initial begin
    for (i = 0; i < 5; i = i + 1) begin
        $display("Loop #%0d", i);
    end
end
// Prints: Loop #0, Loop #1, ..., Loop #4
```

**Three-step process:**
1. Initialize counter
2. Check condition
3. Increment counter

## Block Statements

Group multiple statements into a single unit.

### Sequential Block (begin-end)

Statements execute **in order**, one after another. Delays are **cumulative**.

```verilog
initial begin
    #10 data = 8'hFE;   // Execute at t=10
    #20 data = 8'h11;   // Execute at t=30 (10+20)
    #15 data = 8'hAA;   // Execute at t=45 (30+15)
end
```

**Timeline:**
```
t=0   : Block starts
t=10  : data = 0xFE
t=30  : data = 0x11
t=45  : data = 0xAA
```

### Parallel Block (fork-join)

Statements execute **concurrently**. Delays are **relative to block start**.

```verilog
initial begin
    #10 data = 8'hFE;   // Execute at t=10
    fork
        #20 data = 8'h11;   // Execute at t=30 (10+20 from start)
        #10 data = 8'h00;   // Execute at t=20 (10+10 from start)
    join
end
```

**Timeline:**
```
t=0   : initial block starts
t=10  : data = 0xFE, fork block starts
t=20  : data = 0x00 (first fork statement completes)
t=30  : data = 0x11 (second fork statement completes)
```

### Nested Blocks

```verilog
initial begin
    #10 data = 8'hFE;
    fork
        #10 data = 8'h11;        // t=20
        begin                     // Sequential inside parallel
            #20 data = 8'h00;    // t=30
            #30 data = 8'hAA;    // t=60 (30+30)
        end
    join
end
```

### Named Blocks

Blocks can be named for reference (e.g., in `disable` statements).

```verilog
begin : seq_block
    // Statements
end

fork : parallel_block
    // Statements
join
```

## Key Differences Summary

| Feature | `initial` | `always` |
|---------|-----------|----------|
| Execution | Once at t=0 | Continuous (triggered by sensitivity) |
| Synthesizable | ✗ No | ✓ Yes |
| Use Case | Testbench, initialization | Design logic (combo/sequential) |
| Sensitivity List | Not allowed | Required for synthesis |
| Typical Usage | Stimulus, monitoring | Flip-flops, combinational logic |

## Common Pitfalls

```verilog
// Missing signals in sensitivity list
always @ (a) begin
    out = a & b;  // b missing! Simulation/synthesis mismatch
end

// Incomplete if without else (unintended latch)
always @ (*) begin
    if (sel)
        out = a;  // What if sel=0? LATCH!
end

// Using initial for hardware logic
initial q = 1'b0;  // Not synthesizable!
```