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

### Verilog Code Structure

All code lives between `module` and `endmodule` keywords.

```verilog
module [design_name] ( [port_list] );
    [list_of_input_ports]
    [list_of_output_ports]
    [declaration_of_other_signals]
    [other_module_instantiations_if_required]
    [behavioral_code_for_this_module]
endmodule
```

- Module Definition
  - module name, alphanumeric and can contain `_`
- Input/Output
  - Interface signals
- Signal declaration
  - Internal wires and regs
- Module instantiations

#### Data Types

Mainly `reg` and `wire`.

A reg datatype is used to hold onto values like a variable.

A wire is just analogous to an electrical wire, that has to be driven continuously (updated instantly).

#### Assignments

Verilog has three basic blocks:

| Block | Description |
|-------|-------------|
| `always @(condition)` | always executed when the condition is satisfied |
| `initial` | will be executed only once, when the simulation begins |
| `assign [LHS] = [RHS]` | Value of LHS will be updated *whenever RHS changes* |


* `reg` can be assigned to only in `initial` and `always` blocks
* `wire` can be assigned a value only via `assign` statement
* If there are multiple statements in an **initial/always** block, they should be wrapped in `begin .. end`

```verilog
module testbench;
    
    // Signals d, rst_b, and clk are declared outside initial blog
    // assigned within an initial block, because they are of type `reg`
    reg d;
    reg rst_b;
    reg clk;
    
    wire q;
    
    //Since there are multiple lines for `initial` block, **begin** and **end** are used
    initial begin
        d = 0;
        rst_b = 0;
        clk = 0;
        
        #100 $finish;
    end
    
    always begin
        #10 clk = ~clk;
    end
endmodule
```

* Code inside the initial block will be executed at 0ns i.e. start of simulation
* Since there's no condition for the `always` block, it will run like an infinite loop in C
* **#** is used to represent time delay. `#10` tells the simulator to advance simulation time by 10 units.
* `clk = ~clk;` will toggle the value of clock, and because **#10** is put before the statement, clock will be toggled after every 10 time units.
* `$finish` is the way to end a simulation. In this case, it will run for 100 time units and exit.


#### Quick Reference

| Keyword | Usage |
|---------|-------|
| `module`/`endmodule` | Define a hardware block |
| `input`/`output` | Port directions |
| `reg` | Variable storage (sequential) |
| `wire` | Continuous connection (combinational) |
| `always @()` | Procedural block thats executed based on some condition |
| `initial` | Simulation-only initialization |
| `posedge`/`negedge` | Clock edge triggers |

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

- Testbench has no ports (top-level container)
- Uses `reg` for inputs (driven by TB), `wire` for outputs (driven by DUT)
- `.port_name(signal)` syntax for named port connections
- `initial` block runs once at simulation start
- `1'b0` = 1-bit binary value 0



## Hello World

Minimal runnable Verilog example:

```verilog
// Single line comments use "//"
// top level module with no ports (testbench style)
module tb;
    //execute once at simulation test time 0
    // Initial block is another construct typically used
    // to initialize signal nets and variables for simulation
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

VSCode settings:
```json
  //HDL stuff
  "[verilog]": {
    "editor.defaultFormatter": "mshr-h.VerilogHDL",
    "editor.formatOnSave": true,
  },
  "[systemverilog]": {
    "editor.defaultFormatter": "mshr-h.VerilogHDL",
    "editor.formatOnSave": true,
  },
  // Configure the formatter for hdl, please install verible.
  // I installed the binaries here
  "verilog.formatting.verilogHDL.formatter": "verible-verilog-format",
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