# Chip Verify Verilog Chapter 4: Arrays, Memories & Parameters

## Verilog Arrays

An **array** is a collection of variables or nets that can be scalar or vector. Arrays allow grouping multiple elements under a single identifier, accessed via indices.

### Array Declaration Syntax

```verilog
<type> [vector_range] <name> [array_dimensions];
```

**Key Points:**
- Arrays can be declared for `reg`, `wire`, `integer`, and `real` types
- Vector range (optional) specifies bit width of each element
- Array dimensions specify depth and structure

### Array Types

```verilog
// 1D Arrays
reg        y1 [11:0];           // Scalar array: 12 elements, each 1-bit wide
wire [7:0] y2 [3:0];            // Vector array: 4 elements, each 8-bit wide
integer    y3 [0:15];           // Integer array: 16 elements

// 2D Arrays  
reg  [7:0] y4 [0:1][0:3];       // 2D array: 2 rows × 4 cols, each 8-bit wide
                                 // Total: 8 elements (2×4)

// Multi-dimensional
reg  [15:0] y5 [0:7][0:3][0:1]; // 3D array: 8×4×2, each 16-bit wide
```

**Important:** An n-element 1-bit array `reg [n-1:0]` is NOT the same as an n-bit vector `reg [n-1:0]`.
- `reg [7:0]` = single 8-bit register
- `reg y [7:0]` = 8 separate 1-bit registers

### Array Assignment Rules

```verilog
reg [7:0] mem [0:3];
reg [7:0] vec;

// LEGAL assignments
mem[0] = 8'hAA;              // Assign to single element
mem[2] = 8'h5C;              // Index-based assignment
mem[1] = vec;                // Assign from variable

// ILLEGAL assignments  
mem = 0;                     // ERROR: Cannot assign entire array at once
mem[0:2] = 24'hAABBCC;       // ERROR: Cannot use range on array
```

**Access Pattern:**
- Specify one index per dimension: `array[i][j][k]`
- Cannot access multiple elements simultaneously
- Must use loops to initialize/copy arrays

### Array Examples

```verilog
module array_demo;
    reg [7:0]  mem1;              // 8-bit vector
    reg [7:0]  mem2 [0:3];        // 4-element array, each 8-bit
    reg [15:0] mem3 [0:3][0:1];   // 2D: 4 rows × 2 cols, each 16-bit
    
    initial begin
        // Vector assignment
        mem1 = 8'hA9;
        $display("mem1 = 0x%0h", mem1);
        
        // 1D array assignment
        mem2[0] = 8'hAA;
        mem2[1] = 8'hBB;
        mem2[2] = 8'hCC;
        mem2[3] = 8'hDD;
        
        // 2D array assignment  
        for (int i = 0; i < 4; i++) begin
            for (int j = 0; j < 2; j++) begin
                mem3[i][j] = i + j;
            end
        end
    end
endmodule
```

## Verilog Memories

**Memories** are digital storage elements (RAM/ROM) modeled using 1D arrays of type `reg`. Each array element represents a memory word.

### Memory Structure

```
Memory Array Visualization:
┌─────────┬────────────┐
│ Address │ Data       │
├─────────┼────────────┤
│  0x0    │ [7:0] data │
│  0x1    │ [7:0] data │
│  0x2    │ [7:0] data │
│  0x3    │ [7:0] data │
└─────────┴────────────┘
```

### Register vs Memory Example

**Single 16-bit Register:**
```verilog
module register_example (
    input              clk,
    input              rstn,
    input              wr,
    input              sel,
    input      [15:0]  wdata,
    output reg [15:0]  rdata
);
    
    reg [15:0] register;  // Single 16-bit storage element
    
    always @(posedge clk) begin
        if (!rstn)
            register <= 0;
        else if (sel & wr)
            register <= wdata;
    end
    
    assign rdata = (sel & ~wr) ? register : 16'h0;
endmodule
```

**Hardware:** One 16-bit flip-flop

**16-bit × 4 Memory:**
```verilog
module memory_example (
    input              clk,
    input              rstn,
    input      [1:0]   addr,     // Address selects 1 of 4 locations
    input              wr,
    input              sel,
    input      [15:0]  wdata,
    output reg [15:0]  rdata
);
    
    reg [15:0] memory [0:3];  // 4 locations × 16-bit each
    integer i;
    
    always @(posedge clk) begin
        if (!rstn) begin
            for (i = 0; i < 4; i = i + 1)
                memory[i] <= 0;
        end else if (sel & wr)
            memory[addr] <= wdata;  // Write to selected address
    end
    
    assign rdata = (sel & ~wr) ? memory[addr] : 16'h0;
endmodule
```

**Hardware:** Four 16-bit flip-flops with address-based multiplexing

### Memory Best Practices

| Feature | Single Register | Memory Array |
|---------|----------------|--------------|
| Declaration | `reg [N-1:0] r` | `reg [N-1:0] mem [0:D-1]` |
| Access | Direct: `r` | Indexed: `mem[addr]` |
| Hardware | N-bit flop | D × N-bit flops + mux |
| Use Case | Single value | Multiple values |

## Verilog Parameters

**Parameters** are compile-time constants that enable module reusability by allowing customization during instantiation. They're like function arguments passed during module instantiation.

### Parameter Declaration

```verilog

// Method 2: ANSI-style (recommended)
module design2 
    #(parameter WIDTH = 8,
      parameter DEPTH = 256)
    (
        input              clk,
        input  [WIDTH-1:0] din,
        output [WIDTH-1:0] dout
    );
    // Module contents
endmodule
```

- Parameters are constants (cannot be modified at runtime)
- Conventionally use UPPERCASE for visibility
- Can specify width: `parameter [7:0] VAL = 8'hFF`
- Multiple parameters in one statement: `parameter A=1, B=2, C=3;`

### Overriding Parameters

**Method 1: Instance Override (Recommended for RTL)**
```verilog
module top;
    wire [15:0] data;
    
    // Override during instantiation using #(...)
    design2 #(
        .WIDTH(16),      // Override WIDTH to 16
        .DEPTH(512)      // Override DEPTH to 512
    ) u0 (
        .clk(clk),
        .din(din),
        .dout(data)
    );
endmodule
```

**Method 2: defparam (Common in Testbenches)**
```verilog
module top;
    design2 u0 (.clk(clk), .din(din), .dout(data));
    
    // Override after instantiation
    defparam u0.WIDTH = 16;
    defparam u0.DEPTH = 512;
endmodule
```

### Parameterized Counter Example

```verilog
module counter 
    #(parameter N = 2,        // Counter width (default: 2-bit)
      parameter DOWN = 0)     // 0=up, 1=down (default: up-counter)
    (
        input                clk,
        input                rstn,
        input                en,
        output reg [N-1:0]   out
    );
    
    always @(posedge clk) begin
        if (!rstn)
            out <= 0;
        else if (en)
            out <= DOWN ? (out - 1) : (out + 1);
    end
endmodule
```

**Usage Examples:**

```verilog
// 2-bit up-counter (uses defaults)
counter u0 (.clk(clk), .rstn(rstn), .en(en), .out(out2));

// 4-bit down-counter (override both parameters)
counter #(.N(4), .DOWN(1)) 
    u1 (.clk(clk), .rstn(rstn), .en(en), .out(out4));

// 8-bit up-counter (override only N)
counter #(.N(8)) 
    u2 (.clk(clk), .rstn(rstn), .en(en), .out(out8));
```

## Local Parameters (`localparam`)

**Local parameters** are constants that CANNOT be overridden from outside the module. Used to protect critical design values.

```verilog
module fifo 
    #(parameter WIDTH = 8)      // Can be overridden
    (
        input [WIDTH-1:0] data_in,
        output [WIDTH-1:0] data_out
    );
    
    localparam DEPTH = 16;      // CANNOT be overridden
    localparam ADDR_WIDTH = 4;  // Derived from DEPTH
    
    reg [WIDTH-1:0] memory [0:DEPTH-1];
    reg [ADDR_WIDTH-1:0] wr_ptr, rd_ptr;
    
    // Design logic...
endmodule
```


**localparam with Parameters:**
```verilog
module design 
    #(parameter PARAM_LENGTH = 4)
    (/* ports */);
    
    // localparam can use parameters in expressions
    localparam LENGTH = 2 + PARAM_LENGTH;        // OK
    localparam HALF = PARAM_LENGTH[2:1];         // Part-select OK
    
    // Changing PARAM_LENGTH affects LENGTH indirectly
endmodule

module top;
    design #(.PARAM_LENGTH(8)) u0 (...);  
    // LENGTH inside u0 becomes 2 + 8 = 10
endmodule
```

## Specify Parameters (`specparam`)

**Specify parameters** are used for timing and delay modeling. Can be declared inside `specify` blocks or module body.

```verilog
module dff (input d, clk, output reg q);
    
    // Timing parameters
    specify
        specparam t_rise = 200;      // Rise time (ps)
        specparam t_fall = 150;      // Fall time (ps)
        specparam clk_to_q = 70;     // Clock-to-Q delay (ps)
    endspecify
    
    // Can also declare in module body
    specparam setup_time = 50;
    
    always @(posedge clk)
        q <= d;
endmodule
```

## Parameter Comparison Table

| Feature | `parameter` | `localparam` | `specparam` |
|---------|-------------|--------------|-------------|
| Keyword | `parameter` | `localparam` | `specparam` |
| Override via instance | ✓ | ✗ | ✗ |
| Override via `defparam` | ✓ | ✗ | ✗ |
| Override via SDF | ✗ | ✗ | ✓ |
| Inside `specify` block | ✗ | ✗ | ✓ |
| Can use specparams | ✗ | ✗ | ✓ |
| Primary Use | Module config | Protected constants | Timing/delays |