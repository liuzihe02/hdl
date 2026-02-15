# Chip Verify Verilog Chapter 2: Basic Syntax and Structure

## Verilog Syntax

Basic syntax (comments, whitespaces, operators, strings) are for the most part the same as C. However differences are:

- **Number literals** are totally different — Verilog uses `<size>'<base><value>` format like `8'hFF` or `4'b1010`. Nothing like this in C.
- **No `int main()`** — the top-level construct is `module ... endmodule`, not functions
- **`begin`/`end`** instead of `{ }` for procedural blocks (inside `always`, `initial`, etc.). Though `module`/`endmodule` uses keyword delimiters too.
- **Two assignment types** — `=` (blocking) and `<=` (non-blocking) have very different semantics related to simulation scheduling
- **`wire` vs `reg`** data types instead of just declaring variables
- **Concurrency is the default** — statements in a module execute in parallel, not sequentially. This is the biggest mental shift from C

### Number Format

#### Sized

*size* is written only in decimal to specify the number of bits required

```
[size]'[base_format][number]
```

* *base_format* can be either decimal ('d or 'D), hexadecimal ('h or 'H) and octal ('o or 'O) and specifies what base the *number* part represents.
* *number* is specified as consecutive digits from 0, 1, 2 ... 9 for decimal base format and 0, 1, 2 .. 9, A, B, C, D, E, F for hexadecimal.

```verilog
3'b010;     // size is 3, base format is binary ('b), and the number is 010 (indicates value 2 in binary)
3'd2;       // size is 3, base format is decimal ('d) and the number is 2 (specified in decimals)
8'h70;      // size is 8, base format is hexadecimal ('h) and the number is 0x70 (in hex) to represent decimal 112
9'h1FA;     // size is 9, base format is hexadecimal ('h) and the number is 0x1FA (in hex) to represent decimal 506

4'hA = 4'd10 = 4'b1010 = 4'o12	// Decimal 10 can be represented in any of the four formats
8'd234 = 8'D234                 // Legal to use either lower case or upper case for base format
32'hFACE_47B2;                  // Underscore (_) can be used to separate 16 bit numbers for readability
```

Uppercase letters are legal for number specification when the base format is hexadecimal.

```verilog
16'hcafe;         // lowercase letters Valid
16'hCAFE;         // uppercase letters Valid
32'h1D40_CAFE;    // underscore can be used as separator between 4 letters Valid
```

#### Unsized

Numbers without a *base_format* specification are decimal numbers by **default**. Numbers without a *size* specification have a default number of bits depending on the type of simulator and machine.

```verilog
integer a = 5423;       // base format is not specified, a gets a decimal value of 5423
integer a = 'h1AD7;     // size is not specified, because a is int (32 bits) value stored in a = 32'h0000_1AD7
```

#### Negative

Negative numbers are specified by placing a minus `-` sign before the size of a number. It is illegal to have a minus sign between *base_format* and *number*.

```verilog
-6'd3;            // 8-bit negative number stored as two's complement of 3
-6'sd9;           // For signed maths
8'd-4;            // Illegal
```

## Verilog Modules

A **module** is a block of Verilog code that implements a specific functionality. Modules are the fundamental building blocks in Verilog - they can be embedded within other modules, and higher-level modules communicate with lower-level modules using input/output ports.

### Syntax
```verilog
module <name> ([port_list]);
    // Contents of the module
endmodule

// Module can have empty portlist
module name;
    // Contents
endmodule
```

- Must be enclosed within `module` and `endmodule` keywords
- Ports declared in port list cannot be redeclared in module body
- All declarations, dataflow statements, functions, tasks, and sub-module instances must be inside module/endmodule

### Example: D Flip-Flop

**Module Diagram:**
```
        ┌─────────┐
    d ──┤         │
        │   dff   │── q
   clk ─┤         │
        │         │
  rstn ─┤         │
        └─────────┘
```

**Verilog Code:**
```verilog
// D flip-flop with 3 inputs and 1 output
module dff (
    input       d,
    input       clk,
    input       rstn,
    output reg  q
);
    
    always @(posedge clk) begin
        if (!rstn)
            q <= 0;
        else 
            q <= d;
    end
    
endmodule
```

### Module Reuse: Shift Register

Modules can be instantiated multiple times to build more complex designs.

```verilog
module shift_reg (
    input   d,
    input   clk,
    input   rstn,
    output  q
);
    
    wire [2:0] q_net;
    
    // Instantiate 4 D flip-flops
    // name function arguments and inputs, basically saying funcation_arg=actual_value
    // .function_arg(actual_value)
    dff u0 (.d(d),         .clk(clk), .rstn(rstn), .q(q_net[0]));
    dff u1 (.d(q_net[0]),  .clk(clk), .rstn(rstn), .q(q_net[1]));
    dff u2 (.d(q_net[1]),  .clk(clk), .rstn(rstn), .q(q_net[2]));
    dff u3 (.d(q_net[2]),  .clk(clk), .rstn(rstn), .q(q));
    
endmodule
```

**Shift Register Schematic:**
```
d ──┤DFF├──┤DFF├──┤DFF├──┤DFF├── q
    └───┘  └───┘  └───┘  └───┘
     clk     clk     clk     clk
```


### Top-Level Modules

A **top-level module** contains all other modules and is not instantiated anywhere, usually using the `design` keyword
```verilog
// Sub-modules
module mod3 ([port_list]);
    // Design code
endmodule

module mod1 ([port_list]);
    wire y;
    mod3 mod_inst1 (...);  // Instance of mod3
    mod3 mod_inst2 (...);  // Another instance
endmodule

module mod2 ([port_list]);
    // Design code
endmodule

// Top-level design module (contains all sub-modules)
module design ([port_list]);
    wire _net;
    mod1 mod_inst1 (...);
    mod2 mod_inst2 (...);
endmodule
```

**Testbench Example:**
```verilog
// Testbench is the top-level module for simulation
module testbench;
    // Instantiate design under test
    design d0 ([port_connections]);
    
    // Stimulus generation and verification code
endmodule
```

### Hierarchical Names

> Hierarchical access stuff are not *synthesizable*, and is only used in testing or verification to debug stuff etc

Signals can be accessed using dot notation through the module hierarchy:

```verilog
design.mod_inst1              // Access module instance
design.mod_inst1.y            // Access signal "y" in mod_inst1
design.mod_inst2.mod_inst2.a  // Access nested signal

testbench.d0._net             // Access design signal from testbench
```

**Hierarchy Structure:**
```
testbench (root)
    └── design
        ├── mod_inst1
        │   ├── mod_inst1 (mod3)
        │   └── mod_inst2 (mod3)
        └── mod_inst2
            ├── mod_inst1 (mod4)
            └── mod_inst2 (mod4)
```

## Verilog Ports

Ports are the interface signals for a module. They act as the "pins" of a hardware module - the only way to send and receive data. Module as a physical chip on a PCB - ports are the chip's pins.


### Port Types

| Type | Direction | Description | Default Type | Can Override to `reg` |
|------|-----------|-------------|--------------|----------------------|
| `input` | IN | Module receives values from outside | `wire` | No (always wire) |
| `output` | OUT | Module sends values to outside | `wire` | Yes |
| `inout` | BIDIRECTIONAL | Module can both send and receive | `wire` | No (must be wire) |

**Default:** Ports are considered `wire` type by default - no `reg`!

### Syntax

```verilog
input  [net_type] [range] list_of_names;    // Input port
output [net_type] [range] list_of_names;    // Output port (wire)
output [var_type] [range] list_of_names;    // Output port (variable)
inout  [net_type] [range] list_of_names;    // Bidirectional port
```

### Example

```verilog
module my_design (
    input wire        clk,      // Clock input
    input             en,       // Enable (implicitly wire)
    input             rw,       // Read/Write
    inout [15:0]      data,     // Bidirectional data bus
    output            int       // Interrupt output
);
    
    // Design behavior
    
endmodule
```

- Port names must be unique within a module
- Cannot declare the same port name multiple times

### Signed Ports

The `signed` attribute can be applied to ports for signed arithmetic operations.

```verilog
module design1 (
    input      a, b,    // Unsigned by default
    output     c
);
    // a, b, c are unsigned
endmodule

module design2 (
    input signed  a, b,    // Explicitly signed
    output        c
);
    wire a, b;            // a, b inherit signed attribute from port
    reg signed c;         // c is signed from reg declaration
endmodule
```

**Rule:** If either the port or net/reg declaration is signed, both are considered signed.

### Port Declaration Styles

Port directions declared inline (recommended):

```verilog
module test (
    input  [7:0] a,
    input  [7:0] b,        // b is also 8-bit input
    output [7:0] c
);
    // Design content
endmodule

module test2 (
    input wire  [7:0] a,   // Explicit wire type
    input wire  [7:0] b,
    output reg  [7:0] c    // Explicit reg type
);
    // Design content
endmodule
```

### Port Declaration Rules (Verilog-2001)

**Complete Declaration:**
If port includes net/variable type, it's completely declared - cannot redeclare.

```verilog
module test (
    input      [7:0] a,       // Implicitly wire (incomplete)
    output reg [7:0] e        // Explicitly reg (complete)
);
    
    wire signed [7:0] a;      // ILLEGAL - simulator dependent, some simulators allow some don't
    wire        [7:0] e;      // ILLEGAL - e already complete
    
endmodule
```

**Incomplete Declaration:**
If port doesn't include net/variable type, it can be declared later.

```verilog
module test (
    input  [7:0] a,           // Incomplete (no wire/reg specified)
    output [7:0] e            // Incomplete
);
    
    reg [7:0] e;              // LEGAL - e was not fully declared
    
endmodule
```

## Verilog Module Instantiations

When instantiating a module, its ports must be connected to signals in the parent module. This can be done in two ways: **by ordered list** or **by name**.

### Method 1: Ordered List (Positional)

Ports are connected based on their position in the port list.

```verilog
// Design module
module mydesign (
    input  x, y, z,    // Position 1, 2, 3
    output o           // Position 4
);
    // Module contents
endmodule

// Parent module - ordered connection
module tb_top;
    wire [1:0] a;
    wire       b, c;
    
    // Connections by position
    mydesign d0 (a[0], b, a[1], c);
    //           pos1  pos2 pos3  pos4
    //            ↓     ↓    ↓    ↓
    //            x     y    z    o
endmodule
```

**Drawbacks:**
- Must know exact port order
- Error-prone if port order changes
- Difficult to debug with many ports

### Method 2: Named Connection (Recommended)

Explicitly connect ports using their names with dot notation.

```verilog
module design_top;
    wire [1:0] a;
    wire       b, c;
    
    // Named connections (order irrelevant)
    mydesign d0 (
        .x (a[0]),    // Design port .x connects to signal a[0]
        .y (b),       // Design port .y connects to signal b
        .z (a[1]),    // Design port .z connects to signal a[1]
        .o (c)        // Design port .o connects to signal c
    );
endmodule
```

**Syntax:** `.port_name (signal_name)`
- `.port_name` = port in the instantiated module
- `signal_name` = signal in parent module

**Advantages:**
- Order-independent
- Self-documenting
- Easy to debug (one port per line)
- Safe when ports are added/removed

**Rules:**
- Each port can only be connected once
- Connection order doesn't matter


### Unconnected/Floating Ports

Ports can be left unconnected - they will have high-impedance (Z) value.

```verilog
module design_top;
    wire [1:0] a;
    wire       c;
    
    mydesign d0 (
        // .x not connected → x will be Z
        .y (a[1]),
        .z (a[1]),
        .o ()          // o left floating → not connected to c
    );
endmodule
```

### Port Type Rules

```verilog
// VALID: inputs are implicitly wire
module des0 (input wire clk);    // Explicit wire (redundant)
module des0 (input clk);         // Implicit wire (preferred)

// INVALID: inputs cannot be reg
module des1 (input reg clk);     // ERROR: inputs cannot be reg

// VALID: outputs that store values must be reg
module des2 (output reg [3:0] data);

// Port width mismatch
module des2 (output [3:0] data);  // 4-bit output
module des3 (input  [7:0] data);  // 8-bit input

module top;
    wire [7:0] net;
    des2 u0 (.data(net));         // Upper 4 bits of net are undriven
    des3 u1 (.data(net));         // Works, but u0 only drives [3:0]
endmodule
```

### Key Port Rules Summary

| Port Type | Can be `wire`? | Can be `reg`? | Usage |
|-----------|---------------|---------------|-------|
| `input` | Yes (default) | **NO** | Must be driven externally |
| `output` | Yes | Yes (if storing) | Can drive external signals |
| `inout` | Yes | **NO** | Bidirectional, must be driven |

**Important:**
- `input` and `inout` cannot be `reg` (continuously driven from outside)
- `output` can be `reg` when used in procedural blocks (`always`, `initial`)
- Port width mismatches: smaller width prevails, extra bits ignored

### Best Practices

1. **Always use named connections** for clarity and maintainability
2. **One port per line** for easy debugging
3. **Declare output as `reg`** when storing values in procedural blocks
4. **Be careful with width mismatches** - can cause subtle bugs
5. **Leave ports unconnected explicitly** with `()` to show intent