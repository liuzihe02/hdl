# Chapter 4: Arrays, Memories & Parameters

---

## Verilog Arrays

An **array** declaration of a net or variable can be either scalar or vector. Any number of dimensions can be created by specifying an address range **after** the identifier name. Arrays are allowed for `reg`, `wire`, `integer` and `real` data types.

```verilog
<type> [vector_range] <name> [array_dimensions];
```

```verilog
reg        y1 [11:0];        // scalar reg array of depth=12, each 1-bit wide
wire [0:7] y2 [3:0];         // 8-bit vector net with a depth of 4
reg  [7:0] y3 [0:1][0:3];    // 2D array rows=2, cols=4, each element 8-bit wide
```

An index for every dimension must be specified to access a particular element of an array. The index can be an expression of other variables.

> **Key distinction:** A memory of *n* 1-bit `reg` is **not** the same as an *n*-bit vector `reg`.

### Array Assignment

```verilog
y1 = 0;             // ILLEGAL — cannot assign all elements in a single statement

y2[0] = 8'ha2;      // Assign 0xa2 to index 0
y2[2] = 8'h1c;      // Assign 0x1c to index 2
y3[1][2] = 8'hdd;   // Assign 0xdd to row=1, col=2
y3[0][0] = 8'haa;   // Assign 0xaa to row=0, col=0
```

### Array Example

```verilog
module des ();
  reg [7:0]  mem1;              // reg vector, 8-bit wide
  reg [7:0]  mem2 [0:3];        // 8-bit vector array, depth=4
  reg [15:0] mem3 [0:3][0:1];   // 16-bit vector 2D array, rows=4, cols=2

  initial begin
    int i;

    // --- Simple vector ---
    mem1 = 8'ha9;
    $display("mem1 = 0x%0h", mem1);

    // --- 1D array ---
    mem2[0] = 8'haa;
    mem2[1] = 8'hbb;
    mem2[2] = 8'hcc;
    mem2[3] = 8'hdd;
    for (i = 0; i < 4; i = i + 1)
      $display("mem2[%0d] = 0x%0h", i, mem2[i]);

    // --- 2D array ---
    for (int i = 0; i < 4; i += 1)
      for (int j = 0; j < 2; j += 1) begin
        mem3[i][j] = i + j;
        $display("mem3[%0d][%0d] = 0x%0h", i, j, mem3[i][j]);
      end
  end
endmodule
```

---

## Memories

Memories are digital storage elements (RAMs, ROMs, register files). They are modeled using **one-dimensional arrays of type `reg`** — each element represents a **word**, referenced by a single array index.

```
        ┌─────────────────────┐
  addr ─►  word 0: [N-1 : 0]  │
        │  word 1: [N-1 : 0]  │
        │  ...                 │
        │  word D-1:[N-1 : 0]  │
        └─────────────────────┘
         N bits wide, D words deep
```

### Register Vector (Single Storage Element)

A simple 16-bit register with read/write control:

```verilog
module des (
    input           clk,
    input           rstn,
    input           wr,
    input           sel,
    input  [15:0]   wdata,
    output [15:0]   rdata
);

    reg [15:0] register;

    always @(posedge clk) begin
        if (!rstn)
            register <= 0;
        else if (sel & wr)
            register <= wdata;
        // else: register holds its value
    end

    assign rdata = (sel & ~wr) ? register : 0;
endmodule
```

**Hardware result:** synthesises to a single 16-bit flip-flop with write-enable and read mux.

### Memory (Addressable Array of Registers)

An array with 4 locations × 16 bits, addressed by `addr`:

```verilog
module des (
    input           clk,
    input           rstn,
    input  [1:0]    addr,
    input           wr,
    input           sel,
    input  [15:0]   wdata,
    output [15:0]   rdata
);

    reg [15:0] register [0:3];   // 4-word × 16-bit memory
    integer i;

    always @(posedge clk) begin
        if (!rstn) begin
            for (i = 0; i < 4; i = i + 1)
                register[i] <= 0;
        end else if (sel & wr)
            register[addr] <= wdata;
    end

    assign rdata = (sel & ~wr) ? register[addr] : 0;
endmodule
```

**Hardware result:** each index is a separate 16-bit flip-flop; the input address selects which set of flops to read/write via a mux/demux structure.

---

## Parameters

Parameters allow a module to be **reused with different configurations**. They are compile-time constants — it is illegal to modify them at runtime.

```verilog
parameter MSB = 7;                       // integer constant
parameter REAL = 4.5;                     // real constant
parameter FIFO_DEPTH = 256, MAX_WIDTH = 32;  // multiple declarations
parameter [7:0] f_const = 2'b3;          // 2-bit value widened to 8 bits
```

> **Convention:** Use UPPERCASE names for parameters to distinguish them from signals.

### Module Parameters (ANSI Style — Preferred)

```verilog
module design_ip
    #(parameter BUS_WIDTH  = 32,
      parameter DATA_WIDTH = 64,
      parameter FIFO_DEPTH = 512)
    (
      input  [BUS_WIDTH-1:0]  addr,
      input  [DATA_WIDTH-1:0] wdata,
      input                   write,
      input                   sel,
      output [DATA_WIDTH-1:0] rdata
    );

    reg [7:0] fifo [FIFO_DEPTH];
    // Design code ...
endmodule
```

### Overriding Parameters at Instantiation

The standard (and recommended) way to override parameters is via `#(...)` during instantiation:

```verilog
module tb;
    // Override parameters by name
    design_ip #(.BUS_WIDTH(64), .DATA_WIDTH(128)) d0 ( /* port list */ );
endmodule
```

> **Note:** `defparam` also exists (`defparam d0.FIFO_DEPTH = 128;`) and is sometimes used in testbenches, but it is **not recommended for RTL** and is deprecated in modern practice.

### Parameterised Counter Example

A flexible N-bit counter that can count up or down:

```verilog
module counter
    #(parameter N    = 2,    // bit-width (default: 2-bit)
      parameter DOWN = 0)    // 0 = up-counter, 1 = down-counter
    (
      input               clk,
      input               rstn,
      input               en,
      output reg [N-1:0]  out
    );

    always @(posedge clk) begin
        if (!rstn)
            out <= 0;
        else if (en)
            out <= DOWN ? (out - 1) : (out + 1);
    end
endmodule
```

**Instantiation — 2-bit up-counter (defaults):**

```verilog
counter #(.N(2)) u0 (
    .clk(clk), .rstn(rstn), .en(en), .out(out)
);
```

**Instantiation — 4-bit down-counter:**

```verilog
counter #(.N(4), .DOWN(1)) u1 (
    .clk(clk), .rstn(rstn), .en(en), .out(out)
);
```

---

## Local Parameters (`localparam`)

`localparam` defines constants within a module that **cannot be overridden** from outside (unlike `parameter`). Use these to protect internal design constants from accidental modification during instantiation.

```verilog
module adder
    #(parameter WIDTH = 8)
    (
      input  wire [WIDTH-1:0] a,
      input  wire [WIDTH-1:0] b,
      output wire [WIDTH-1:0] sum
    );

    localparam LENGTH = 4;   // Internal constant — cannot be overridden

    assign sum = a + b;
endmodule
```

Attempting to override a `localparam` at instantiation causes an **elaboration error**:

```
// ILLEGAL — will fail:
adder #(.WIDTH(16), .LENGTH(5)) add_instance2 ( ... );
```

However, `localparam` **can** depend on overridable `parameter` values — the dependency is resolved at elaboration:

```verilog
module adder
    #(parameter WIDTH = 8,
      parameter PARAM_LENGTH = 4)
    ( /* ports */ );

    localparam LENGTH = 2 + PARAM_LENGTH;  // Derived from parameter — OK
    // ...
endmodule
```

When `PARAM_LENGTH` is overridden at instantiation, `LENGTH` recalculates accordingly.