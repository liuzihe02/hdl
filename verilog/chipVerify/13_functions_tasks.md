# Chip Verify Verilog Functions & Tasks

Functions and tasks allow repetitive code to be encapsulated into reusable blocks, similar to functions/procedures in software languages. Both are declared inside modules (or globally for tasks), but they differ fundamentally in what they can do.

## Module vs Function vs Task

These three constructs serve different levels of abstraction in Verilog:

| Aspect | `module` | `function` | `task` |
|---|---|---|---|
| **What it represents** | A physical hardware block with I/O ports | A combinational computation helper | A procedural subroutine |
| **Usage** | *Instantiated* — each instance is distinct hardware | *Called* — inlined at the call site | *Called* — inlined or executed procedurally |
| **Lifetime** | Exists for the entire design lifetime | Executes in zero simulation time | May consume simulation time |
| **State / hierarchy** | Creates hierarchy; can contain `always`, `assign`, instances, functions, tasks | No hierarchy — flattened away during synthesis | No hierarchy — flattened away during synthesis |
| **Ports / arguments** | `input`, `output`, `inout` ports (physical wires) | At least one `input`; single return value | Zero or more `input`, `output`, `inout` arguments |
| **Can contain** | Everything (other modules, always blocks, functions, tasks) | Combinational statements only | Any procedural statements including time control |
| **Software analogy** | Class (instantiated, has state, has interfaces) | Pure inline function | Method (can have side effects, take time) |

## Functions

A function is meant to **compute and return a single value** for use in an expression. It executes in **zero simulation time** — meaning no time-control statements are allowed inside it.

### Syntax

```verilog
function [automatic] [return_type] name ([port_list]);
    [statements]
endfunction
```

The `automatic` keyword makes the function **reentrant** — local variables are dynamically allocated per invocation rather than shared (important for recursion and concurrent calls).

### Declaration Styles

```verilog
// style: ANSI-style port list (preferred)
function [7:0] sum (input [7:0] a, b);
    begin
        sum = a + b;
    end
endfunction
```

### Returning a Value

A function implicitly creates an internal variable with the **same name as the function**. Assigning to this variable sets the return value. It is therefore illegal to declare another variable of the same name inside the function.

### Calling a Function

A function call is an **operand within an expression**:

```verilog
reg [7:0] result, a, b;

initial begin          // ⚠️ initial is simulation-only
    a = 4;
    b = 5;
    #10 result = sum(a, b);  // function call as RHS of assignment
end
```

### Function Rules

Functions have strict restrictions because they must execute in zero simulation time:

- **No time-control statements**: `#`, `@`, `wait`, `posedge`, `negedge` are all forbidden
- **Cannot call tasks** (tasks may consume simulation time)
- **Must have at least one input** argument
- **Cannot have `output` or `inout`** arguments
- **Cannot contain non-blocking assignments** (`<=`), `force-release`, or `assign-deassign`
- **Cannot have event triggers**
- **Returns exactly one value** via the implicit return variable

> **Synthesis note:** Pure combinational functions (no time-control, no `initial`/`fork`) are synthesizable and map to combinational logic. The synthesis tool inlines the function body at each call site.

### Recursive Functions

Recursive functions **must** be declared `automatic`, otherwise all invocations share the same local variables and the recursion breaks.

```verilog
module tb;                              // ⚠️ Testbench — simulation only
    initial begin
        integer result = factorial(4);
        $display("factorial(4) = %0d", result);
    end

    function automatic integer factorial(integer i);
        integer result = i;
        if (i)
            result = i * factorial(i - 1);  // recursive call
        else
            result = 1;
        return result;
    endfunction
endmodule
```

```
// Output:
// factorial(4) = 24
```

---

## Tasks

A task is a more general-purpose subroutine. Unlike functions, tasks **can consume simulation time** and can return **multiple values** through `output` and `inout` arguments.

### Syntax

```verilog
// Style 1: ANSI-style (preferred)
task [automatic] name (input [port_list], inout [port_list], output [port_list]);
    begin
        [statements]
    end
endtask

// Style 2: Old-style
task [automatic] name;
    input  [port_list];
    inout  [port_list];
    output [port_list];
    begin
        [statements]
    end
endtask

// Empty port list (valid — tasks don't require arguments)
task name ();
    begin
        [statements]
    end
endtask
```

### Static vs Automatic Tasks

By default, tasks are **static** — all local variables are shared across concurrent invocations. The `automatic` keyword allocates local variables independently per invocation.

**Static task** — shared variable across concurrent calls:

```verilog
module tb;                              // ⚠️ Simulation only
    initial display();
    initial display();
    initial display();
    initial display();

    task display();
        integer i = 0;
        i = i + 1;
        $display("i=%0d", i);           // prints 1, 2, 3, 4
    endtask
endmodule
```

Each `initial` block calls `display()` concurrently at time 0, but because `i` is shared (static), it increments across all invocations.

**Automatic task** — independent variable per call:

```verilog
module tb;                              // ⚠️ Simulation only
    initial display();
    initial display();
    initial display();
    initial display();

    task automatic display();
        integer i = 0;
        i = i + 1;
        $display("i=%0d", i);           // prints 1, 1, 1, 1
    endtask
endmodule
```

Each invocation gets its own copy of `i`, so every call independently starts at 0 and prints 1.

### Task Invocation & Argument Passing

Task arguments are passed **positionally** — the caller's arguments map in order to the task's declared ports:

```verilog
task sum (input [7:0] a, b, output [7:0] c);
    begin
        c = a + b;
    end
endtask

initial begin                           // ⚠️ Simulation only
    reg [7:0] x, y, z;
    sum(x, y, z);   // x→a, y→b, c→z (output written back)
end
```

### Global Tasks

Tasks declared **outside all modules** have global scope and can be called from any module:

```verilog
// Global task — declared outside modules
task display();
    $display("Hello World !");
endtask

module des;
    initial begin
        display();                      // accessible directly
    end
endmodule
```

Tasks declared **inside** a module are local to that module. Other modules can call them only via hierarchical references:

```verilog
module tb;
    des u0();
    initial begin
        u0.display();   // hierarchical reference to task in 'des'
    end
endmodule

module des;
    task display();
        $display("Hello World");
    endtask

    initial begin
        display();       // local call within the module
    end
endmodule
```

### Disabling Tasks

Tasks can be prematurely terminated using the `disable` keyword on a **named block** within the task:

```verilog
module tb;                              // ⚠️ Simulation only
    initial display();

    initial begin
        #50 disable display.T_DISPLAY;  // kill T_DISPLAY at t=50
    end

    task display();
        begin : T_DISPLAY               // named block
            $display("[%0t] T_Task started", $time);
            #100;
            $display("[%0t] T_Task ended", $time);   // never reached
        end

        begin : S_DISPLAY               // starts after T_DISPLAY completes/disabled
            #10;
            $display("[%0t] S_Task started", $time);
            #20;
            $display("[%0t] S_Task ended", $time);
        end
    endtask
endmodule
```

```
// Output:
// [0] T_Task started
// [60] S_Task started        ← starts at 50 + 10
// [80] S_Task ended          ← finishes at 60 + 20
```

When `T_DISPLAY` is disabled at t=50, execution skips to the next sequential block `S_DISPLAY` immediately.

---

## Function vs Task Comparison

| Aspect | `function` | `task` |
|---|---|---|
| **Time control** (`#`, `@`, `wait`) | ❌ Not allowed | ✅ Allowed |
| **Can call** | Other functions only | Both tasks and functions |
| **Arguments** | At least one `input` required; no `output`/`inout` | Zero or more of any direction (`input`, `output`, `inout`) |
| **Return value** | Exactly one (via implicit variable) | None directly; uses `output` arguments instead |
| **Simulation time** | Executes in zero time | May consume simulation time |
| **Synthesizability** | ✅ Synthesizable (pure combinational) | ⚠️ Only if no time-control statements |
| **Typical use** | Combinational computations, conversions, bit manipulation | Bus protocols, stimulus generation, multi-output operations |

---

## Quick Reference

### `automatic` Keyword

| Context | Effect |
|---|---|
| `function automatic ...` | Each call gets its own local variables; **required** for recursive functions |
| `task automatic ...` | Each concurrent invocation gets its own local variables |
| Default (no keyword) | Static — all invocations share local variables |

> **Note:** Items inside `automatic` tasks/functions cannot be accessed via hierarchical references.

### Synthesizable vs Simulation-Only Usage

| Construct | Synthesizable? | Notes |
|---|---|---|
| `function` (pure combinational) | ✅ | Inlined as combinational logic by synthesis tools |
| `task` (no time control) | ✅ | Inlined similarly to functions |
| `task` with `#`, `@`, `wait` | ❌ | Simulation/testbench only |
| `initial` blocks | ❌ | Simulation only — used in testbenches |
| `fork`/`join` with concurrent tasks | ❌ | Simulation only |
| `disable` on task blocks | ❌ | Simulation only |
