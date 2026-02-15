# Chip Verify Verilog Chapter 3: Data Types and Operators

## Verilog Datatypes

### The 4-Value System

All Verilog data types (except `real` and `event`) hold one of four values:

| Value | Meaning                          |
|-------|----------------------------------|
| `0`   | Logic zero / false               |
| `1`   | Logic one / true                 |
| `x`   | Unknown (could be 0 or 1)       |
| `z`   | High-impedance (unconnected)     |

> **Hardware mapping:** `1` → Vdd (0.8V–3V+), `0` → GND (0V), `z` → floating/unconnected wire.
>
> **Key distinction:** `x` means *unknown*, NOT "don't care" (unlike boolean logic).

---

### Two Main Groups: Nets vs Variables

#### Nets (`wire`)

Nets model **physical connections** (wires between gates). They don't store values — they reflect whatever is driving them.

```verilog
wire        a;          // single-bit wire
wire [3:0]  bus;        // 4-bit vector (bus)

// Driven by continuous assignment
assign bus = a & b | c;
```

- Most common net type: `wire` (other net types like `tri` or `wand` are rarely used)
- **Cannot redeclare** — duplicate net names cause a compile error
- Default value: `z` (high-impedance)

#### Variables (`reg`)

Variables model **storage elements** (flip-flops, latches) — they retain values between assignments.

```verilog
reg         q;          // 1-bit register
reg [3:0]   data;       // 4-bit register
```

- `reg` does NOT always infer a flip-flop — it can represent combinational logic too
- Default value: `x` (unknown)

### Quick Reference: `wire` vs `reg`

| Property            | `wire`                     | `reg`                         |
|---------------------|----------------------------|-------------------------------|
| Represents          | Physical connection         | Storage element (abstract)    |
| Driven by           | `assign` / gate output      | `always` / `initial` blocks   |
| Retains value?      | No (reflects driver)        | Yes (between assignments)     |
| Default value       | `z`                         | `x`                           |
| Synthesizes to      | Wire                        | FF, latch, or combinational   |

---

### Scalars and Vectors

A net or `reg` **without a range** is a 1-bit **scalar**. Adding a range `[msb:lsb]` makes it a multi-bit **vector**.

```verilog
//declaration
wire        o_nor;          // scalar — 1 bit
wire [7:0]  o_flop;         // vector — 8 bits
reg         parity;         // scalar — 1 bit
reg  [31:0] addr;           // vector — 32 bits
```

```
 Scalar (1-bit):    ┌───┐
                    │ 0 │
                    └───┘

 Vector (8-bit):    ┌───┬───┬───┬───┬───┬───┬───┬───┐
          bit index │ 7 │ 6 │ 5 │ 4 │ 3 │ 2 │ 1 │ 0 │
                    └───┴───┴───┴───┴───┴───┴───┴───┘
                    MSB                             LSB
```

**Range rules:**
- `msb` and `lsb` must be **constant expressions** (not variables)
- They can be positive, negative (rare), or zero
- `lsb` can be >, =, or < `msb` (ordering doesnt matter, just use the index range)

```verilog
wire [15:0]      priority;     // OK: msb=15, lsb=0
integer          my_msb;
wire [my_msb:2]  prior;        // ILLEGAL: variable in range
```

#### Bit-Selects

Access a **single bit** of a vector. Out-of-bounds or `x`/`z` index returns `x`.

```verilog
reg [7:0] addr;

addr[0] = 1;       // assign 1 to bit 0
addr[3] = 0;       // assign 0 to bit 3
addr[8] = 1;       // ILLEGAL: bit 8 doesn't exist
```

```
 addr = 8'b1010_0101
        ┌───┬───┬───┬───┬───┬───┬───┬───┐
        │ 1 │ 0 │ 1 │ 0 │ 0 │ 1 │ 0 │ 1 │
        └───┴───┴───┴───┴───┴───┴───┴───┘
 bit:     7   6   5   4   3   2   1   0
                          ▲           ▲
                     addr[3]=0   addr[0]=1
```

#### Part-Selects

Select a **contiguous range** of bits. Two forms:

**1. Constant part-select** — fixed range:

```verilog
reg [31:0] addr;
addr[23:16] = 8'h23;       // replace bits 23 down to 16
```

**2. Indexed part-select** — variable start, fixed width (useful in loops):

```verilog
[<start_bit> +: <width>]   // select <width> bits upward from start_bit
[<start_bit> -: <width>]   // select <width> bits downward from start_bit
```

```
 data = 32'hFACE_CAFE

 Byte layout:
 ┌──────────┬──────────┬──────────┬──────────┐
 │ 31····24 │ 23····16 │ 15·····8 │ 7······0 │
 │   0xFA   │   0xCE   │   0xCA   │   0xFE   │
 └──────────┴──────────┴──────────┴──────────┘
  data[8*3+:8] data[8*2+:8] data[8*1+:8] data[8*0+:8]
```

```verilog
module des;
  reg [31:0] data;
  int        i;

  initial begin
    data = 32'hFACE_CAFE;
    for (i = 0; i < 4; i++) begin
      $display("data[8*%0d +: 8] = 0x%0h", i, data[8*i +: 8]);
    end
  end
endmodule

// Output:
// data[8*0 +: 8] = 0xfe
// data[8*1 +: 8] = 0xca
// data[8*2 +: 8] = 0xce
// data[8*3 +: 8] = 0xfa
```

> **Common error:** Reversed part-select ordering is illegal.
> `data[0:9]` on a `[15:0]` vector → compile error. Must follow the declared `[msb:lsb]` order.

Ordering the range indexes for part select matters: `reg [0:7]` is not the same as `reg [7:0]`

```verilog
reg [7:0] a;    // a[7] is MSB, a[0] is LSB
reg [0:7] b;    // b[0] is MSB, b[7] is LSB

// Both store 8'b1010_0011:
//
// reg [7:0] a:   index:  7  6  5  4  3  2  1  0
//                value:  1  0  1  0  0  0  1  1
//
// reg [0:7] b:   index:  0  1  2  3  4  5  6  7
//                value:  1  0  1  0  0  0  1  1

a[7]   // = 1 (MSB)
b[0]   // = 1 (MSB) — same bit, different index

a[3:0] // = 4'b0011 (lower nibble)
b[0:3] // = 4'b1010 (upper nibble!) — NOT the same slice
```

The key difference: part-selects must follow the **declared order**. So `a[3:0]` is valid but `a[0:3]` is a compile error, and vice versa for `b`.

> In practice, just always use `[N-1:0]` — it's the universal convention and avoids confusion.

### Other Data Types

| Type       | Width     | Signed?  | Use Case                              |
|------------|-----------|----------|---------------------------------------|
| `integer`  | 32-bit    | Signed   | Loop counters, general-purpose math   |
| `time`     | 64-bit    | Unsigned | Store simulation timestamps           |
| `realtime` | 64-bit fp | —        | Simulation time as floating-point     |
| `real`     | 64-bit fp | —        | Floating-point values                 |

```verilog
module testbench;
  integer   int_a;
  real      real_b;
  time      time_c;

  initial begin
    int_a  = 32'hcafe_1234;    // hex literal with underscore separator
    real_b = 0.1234567;

    #20;                        // advance 20 time units
    time_c = $time;             // capture current sim time

    $display("int_a  = 0x%0h", int_a);   // -> 0xcafe1234
    $display("real_b = %0.5f", real_b);   // -> 0.12346
    $display("time_c = %0t", time_c);     // -> 20
  end
endmodule
```

### Verilog Strings

Strings are stored in `reg` variables. Each character = 1 byte (ASCII). Width must be `8 * num_chars`.

```verilog
reg [8*11:1] str1 = "Hello World";   // exact fit  → "Hello World"
reg [8*5:1]  str2 = "Hello World";   // too small  → "World" (left-truncated)
reg [8*20:1] str3 = "Hello World";   // too large  → "         Hello World" (left-padded with 0s)
```

- **Undersized reg** → leftmost characters are truncated
- **Oversized reg** → zero-padded on the left (displays as spaces)

## Verilog Operators

### Arithmetic

```verilog
a + b       // addition
a - b       // subtraction
a * b       // multiplication
a / b       // division      (div by 0 → x)
a % b       // modulus       (div by 0 → x)
a ** b      // exponentiation (a^0 → 1)
+m          // unary plus  (identity, no effect)
-m          // unary minus (two's complement negation)
```

#### Synthesis Mapping

| Op | Hardware Inferred | Notes |
|----|-------------------|-------|
| `+` | Adder (ripple-carry, CLA) | Synthesizable |
| `-` | Subtractor (adder + 2's complement) | Synthesizable |
| `*` | Array / Wallace tree multiplier | Synthesizable, area-expensive |
| `/` | Iterative divider | Synthesizable, very expensive — avoid in datapath |
| `%` | Remainder circuit (alongside divider) | Same cost as `/` |
| `**` | — | **Not synthesizable** (simulation only) |

> If **any bit** of any operand is `x` or `z`, the **entire result** becomes `x`.

#### Signed vs Unsigned

```verilog
reg  [7:0]        u_val;    // unsigned by default
reg  signed [7:0] s_val;    // explicitly signed
integer           i_val;    // always signed

// Assigning negative integer to unsigned reg:
// bit pattern stays the same, interpretation changes
i_val = -1;                  // 32'hFFFF_FFFF (signed)
u_val = i_val;               // u_val = 8'hFF = 255 (unsigned!)

// Use $signed() / $unsigned() to control explicitly:
wire signed [7:0] result = $signed(a) + $signed(b);
```

#### Bit-Width Truncation Trap

Result width = max width of operands. This silently drops carry bits:

```verilog
reg [15:0] a, b, answer;
a = 16'hFFFF;
b = 16'h0001;

answer = (a + b) >> 1;
// a + b = 17'h1_0000, but intermediate is 16-bit → truncated to 0000
// 0000 >> 1 = 0000  ← WRONG

answer = (a + b + 0) >> 1;
// unsized literal 0 (32-bit) widens intermediate to 32 bits
// 32'h0001_0000 >> 1 = 32'h0000_8000 → answer = 16'h8000  ← CORRECT
```

> **Fix:** make the result 1 bit wider, or widen the expression with an unsized constant.


### Relational (result: 1, 0, or x)

```verilog
a <  b      // less than
a >  b      // greater than
a <= b      // less than or equal
a >= b      // greater than or equal
// If either operand contains x/z → result is x
```

### Equality

```verilog
// --- Logical (synthesizable, but x/z operands → result x) ---
a == b      // equal
a != b      // not equal

// --- Case (matches x and z literally, always returns 0 or 1) ---
a === b     // case equal        (testbenches only, not synthesizable)
a !== b     // case not equal    (testbenches only, not synthesizable)
```

```verilog
// Key distinction:
4'b101x == 4'b101x    // → x  (can't resolve x)
4'b101x === 4'b101x   // → 1  (exact match including x bits)
```

### Logical (operate on whole expressions, result: 1, 0, or x)

```verilog
a && b      // logical AND  — true if both non-zero
a || b      // logical OR   — true if either non-zero
!a          // logical NOT  — non-zero→0, zero→1
```

### Bitwise (operate bit-by-bit)

```verilog
a & b       // AND
a | b       // OR
a ^ b       // XOR
a ~^ b      // XNOR  (also ^~)
~a          // NOT (invert all bits)
```

> **`&` vs `&&`:** `&` is bitwise (e.g., `4'b1100 & 4'b1010 = 4'b1000`), while `&&` reduces the whole operand to a boolean (e.g., `4'b1100 && 4'b1010 = 1`).

### Shift

```verilog
//logical or arithmetic shift only affects signed right shift
// Logical  >>  : always fills vacated MSBs with 0
// Arithmetic >>>: fills vacated MSBs with the SIGN BIT (for signed types)
a <<  n     // logical shift left  (fill with 0)
a >>  n     // logical shift right (fill with 0)
a <<< n     // arithmetic shift left  (same as <<)
a >>> n     // arithmetic shift right (fill with sign bit for signed types)
```

```verilog
8'b0000_0001 << 3   // → 8'b0000_1000
8'b1000_0000 >> 3   // → 8'b0001_0000

reg signed [7:0] s = -8;          // 8'b1111_1000
s >>> 2                            // → 8'b1111_1110  (sign-extended)
```

### Operator Precedence (high → low)

```
 Highest    !  ~                          (unary)
            **                            (power)
            *  /  %                       (multiplicative)
            +  -                          (additive)
            << >> <<< >>>                 (shift)
            <  <= >  >=                   (relational)
            == != === !==                 (equality)
            &                             (bitwise AND)
            ^ ~^                          (bitwise XOR/XNOR)
            |                             (bitwise OR)
            &&                            (logical AND)
            ||                            (logical OR)
 Lowest     ?:                            (ternary)
```

## Verilog Concatenation

Use `{ }` to join signals together. Every operand **must have a known size**.

#### Basic Concatenation

```verilog
wire       a, b;
wire [1:0] res;
assign res = {a, b};           // res[1]=a, res[0]=b
```

```
 a=1, b=0:
 ┌───┬───┐
 │ a │ b │  = {a, b} = 2'b10
 └───┴───┘
```

You can mix signals, part-selects, and sized constants:

```verilog
wire [2:0] c;
wire [7:0] res1;
assign res1 = {b, a, c[1:0], 2'b00, c[2]};
//             7  6   5  4    3  2    1  0    ← bit positions
```

#### Replication Operator `{n{expr}}`

Repeat an expression `n` times. `n` must be a **non-negative constant** (not a variable, not `x`/`z`).

```verilog
wire a;
assign res = {7{a}};           // 7 copies of a

// Common use: zero-fill a register
reg [15:0] counter;
initial counter = {16{1'b0}};  // = 16'h0000
```

```
 a = 1:
 {4{a}} = ┌───┬───┬───┬───┐
          │ 1 │ 1 │ 1 │ 1 │ = 4'b1111
          └───┴───┴───┴───┘
```

Replication can nest inside concatenation:

```verilog
reg [1:0] a = 2'b10;
reg [2:0] b = 3'b100;

{a, b, 3'b000, {2{a}}, {3{b}}}
// = 10 | 100 | 000 | 10 10 | 100 100 100
// = 21'b10_100_000_1010_100100100
```

**Illegal:** variable as replication constant → compile error:

```verilog
reg [3:0] n = 3;
{n{a}}              // ERROR: replication constant must be a constant
```

#### Sign Extension (Practical Use of Replication)

Replicate the sign bit to widen a signed value — very common pattern:

```verilog
input  signed [3:0] narrow;    // e.g. 4'b1101 = -3
output signed [7:0] wide;

// Replicate MSB (sign bit) to fill upper bits
assign wide = {{4{narrow[3]}}, narrow};
```

```
 narrow = 4'b1101 (-3):

 {4{narrow[3]}} = {4{1}} = 4'b1111

 wide = ┌───┬───┬───┬───┬───┬───┬───┬───┐
        │ 1 │ 1 │ 1 │ 1 │ 1 │ 1 │ 0 │ 1 │ = 8'b1111_1101 = -3 ✓
        └───┴───┴───┴───┴───┴───┴───┴───┘
         sign-extended      original
```

> **Note:** If both sides are declared `signed`, Verilog will auto sign-extend on assignment. The manual replication trick is for when you need explicit control or are mixing signed/unsigned.