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

> Hierarchical access is not *synthesizable*, and is only used in testing or verification to debug stuff etc

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