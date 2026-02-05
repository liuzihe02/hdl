# Chip Verify Verilog Chapter 1: Getting Started

## Intro

### Core Structure

#### Hardware Schematic
A diagram showing how combinational gates (NAND, NOR, etc.) connect to achieve specific hardware functionality. Can be abstracted into a black-box with defined inputs/outputs.

#### Hardware Description Language (HDL)
Verilog is an HDL that describes hardware behavior in code. Software tools then convert this behavioral description into actual hardware schematics.

#### Design Functionality
Behavioral requirements that define how hardware should operate. Example for a D flip-flop:
- Clock as input
- Active-low reset: `rstn=0` → reset; `rstn=1` → output `q` follows input `d`
- Output updates only at positive clock edge

#### Verification
Process of checking if Verilog code matches intended behavior. Primary method: **circuit simulation** using EDA (Electronic Design Automation) tools. Design RTL is placed in a **testbench** that provides stimuli and checks outputs.

---

### Verilog Code Structure

All code lives between `module` and `endmodule` keywords.

#### Template
```verilog
module [design_name] ( [port_list] );
    [list_of_input_ports]
    [list_of_output_ports]
    [declaration_of_other_signals]
    [other_module_instantiations_if_required]
    [behavioral_code_for_this_module]
endmodule
```

#### Section Breakdown
| Section | Purpose |
|---------|---------|
| Module definition | Name and port list |
| Input/Output ports | Interface signals |
| Signal declarations | Internal wires/regs |
| Module instantiations | Sub-module instances |
| Behavioral code | Logic description (`always`, `assign`, etc.) |

---

### Example: D Flip-Flop

```verilog
module dff (
    input   d,
            rstn,
            clk,
    output  q
);
    reg q;  // Store output value
    
    always @ (posedge clk) begin
        if (!rstn)
            q <= 0;     // Reset: q = 0
        else
            q <= d;     // Normal: q follows d
    end
endmodule
```

**Key points:**
- `input`/`output` declare port directions
- `reg` stores values across clock cycles
- `always @ (posedge clk)` triggers on rising clock edge
- `<=` is non-blocking assignment (standard for sequential logic)

---

### Testbench Structure

```verilog
module tb;
    // 1. Declare testbench signals
    reg     tb_clk;
    reg     tb_d;
    reg     tb_rstn;
    wire    tb_q;
    
    // 2. Instantiate design under test (DUT)
    dff dff0 (
        .clk    (tb_clk),
        .d      (tb_d),
        .rstn   (tb_rstn),
        .q      (tb_q)
    );
    
    // 3. Apply stimulus
    initial begin
        tb_rstn <= 1'b0;
        tb_clk  <= 1'b0;
        tb_d    <= 1'b0;
    end
endmodule
```

**Key points:**
- Testbench has no ports (top-level container)
- Uses `reg` for inputs (driven by TB), `wire` for outputs (driven by DUT)
- `.port_name(signal)` syntax for named port connections
- `initial` block runs once at simulation start
- `1'b0` = 1-bit binary value 0

### Quick Reference

| Keyword | Usage |
|---------|-------|
| `module`/`endmodule` | Define a hardware block |
| `input`/`output` | Port directions |
| `reg` | Variable storage (sequential) |
| `wire` | Continuous connection (combinational) |
| `always @()` | Procedural block with sensitivity list |
| `initial` | Simulation-only initialization |
| `posedge`/`negedge` | Clock edge triggers |

## Hello World

Minimal runnable Verilog example:

```verilog
// Single line comments use "//"
// top level module with no ports (testbench style)
module tb;
    //execute once at simulation test time 0
    initial
        // system task to print, for simulation or debug only
        $display("Hello World!");
endmodule
```

## Running Locally

We'll be using Icarus Verilog `iverilog` and `gtkwave`
```bash
sudo apt install iverilog gtkwave -y
```

**Option 1: Separate Files**

Our design is stored in [`design.v`](dff/design.v) while the testbench implementation is in [`tb.v`](dff/tb.v)


```bash
iverilog -o sim.vvp design.v tb.v && vvp sim.vvp
```

**Option 2: All-in-One File**

We could also have our design and testbench together in [`all.v`](dff/all.v)

```bash
iverilog -o sim.vvp all.v && vvp sim.vvp
```

### View Waveforms
```bash
gtkwave dump.vcd &
```