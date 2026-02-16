// =============================================================================
// Single-Port Synchronous RAM
//
// WHAT: A single-port RAM has one data port shared for reads and writes.
//   Read and write cannot occur simultaneously at different addresses.
//   Each location stores DATA_WIDTH bits; DEPTH total locations.
//
// SIGNALS:
//   clk  — synchronous clock (all operations on posedge)
//   addr — selects which memory location to access (ADDR_WIDTH bits)
//   data — bidirectional (inout) data bus carrying read/write data
//   cs   — chip select: RAM is active only when cs=1
//   we   — write enable: 1=write, 0=read (when cs=1)
//   oe   — output enable: drives data bus during reads (active high)
//
// BEHAVIOUR:
//   Write: cs=1, we=1        → data bus value stored into mem[addr]
//   Read:  cs=1, we=0, oe=1  → mem[addr] driven onto data bus
//   Idle:  cs=0              → data bus is high-impedance
//
// NOTE: The bidirectional inout data bus uses tri-state logic.
//   The RAM drives the bus only during reads (oe=1, we=0).
//   The external driver (testbench/master) drives during writes (oe=0).
//   Both sides must never drive simultaneously — one must be hi-Z.
// =============================================================================

module single_port_sync_ram #(
    parameter ADDR_WIDTH = 4,
    parameter DATA_WIDTH = 32,
    parameter DEPTH      = 16
) (
    input                  clk,
    input [ADDR_WIDTH-1:0] addr,
    inout [DATA_WIDTH-1:0] data,  // Bidirectional: driven by RAM or external
    input                  cs,    // Chip select
    input                  we,    // Write enable
    input                  oe     // Output enable (active high, for reads)
);

  reg [DATA_WIDTH-1:0] tmp_data;  // Registered read data (1-cycle latency)
  reg [DATA_WIDTH-1:0] mem[0:DEPTH-1];  // Memory array: DEPTH entries of DATA_WIDTH bits

  // --- Synchronous write ---
  // When chip is selected and write enabled, store data on clock edge
  always @(posedge clk) begin
    if (cs & we) mem[addr] <= data;
  end

  // --- Synchronous read ---
  // When chip is selected and NOT writing, latch mem contents into tmp_data
  // Read data appears one cycle after address is presented
  always @(posedge clk) begin
    if (cs & !we) tmp_data <= mem[addr];
  end

  // --- Tri-state output driver ---
  // Drive data bus only when: chip selected, output enabled, NOT writing
  // Otherwise high-impedance so external driver can use the bus
  assign data = (cs & oe & !we) ? tmp_data : {DATA_WIDTH{1'bz}};

endmodule
