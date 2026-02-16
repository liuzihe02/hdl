// =============================================================================
// Synchronous FIFO (First-In-First-Out)
// Source: ChipVerify - Synchronous FIFO
// =============================================================================
//
// WHAT: A synchronous FIFO buffers data between a writer and reader that
//   share the same clock domain. Data exits in the same order it entered.
//   Used when write rate temporarily exceeds read rate (burst absorption).
//
// DEPTH & WIDTH:
//   - Depth = number of entries the FIFO can hold. Determines buffering
//     capacity. Sizing rule: Depth >= (WriteRate - ReadRate) / ClkFreq
//   - Width (DWIDTH) = bits per entry, i.e. how much data per read/write.
//
// ARCHITECTURE:
//   Internally: a memory array indexed by two pointers.
//   - wptr (write pointer): where the next write goes. Increments on write.
//   - rptr (read pointer):  where the next read comes from. Increments on read.
//   Both pointers wrap around (circular buffer). The difference between
//   wptr and rptr represents the number of queued items.
//
// STATUS FLAGS:
//   - empty: wptr == rptr  → nothing to read
//   - full:  (wptr + 1) == rptr → one slot left would make pointers equal,
//     which is indistinguishable from empty, so we sacrifice one slot.
//     (This means usable depth is DEPTH-1 entries.)
//
// NOTE ON FULL DETECTION:
//   The (wptr+1)==rptr approach wastes one entry. An alternative is to use
//   an extra bit on each pointer to distinguish full vs empty when the
//   lower bits match. This design uses the simpler single-bit-less approach.
//
// SIGNALS:
//   clk   — single clock for both read and write (synchronous)
//   rstn  — active-low synchronous reset
//   wr_en — write enable: writes din into FIFO when high and not full
//   rd_en — read enable: reads next entry to dout when high and not empty
//   din   — data input (DWIDTH bits)
//   dout  — data output (DWIDTH bits, registered: 1-cycle read latency)
//   empty — status flag: FIFO has no data
//   full  — status flag: FIFO cannot accept more data
// =============================================================================

module sync_fifo #(
    parameter DEPTH  = 8,
    parameter DWIDTH = 16
) (
    input                   rstn,
    input                   clk,
    input                   wr_en,
    input                   rd_en,
    input      [DWIDTH-1:0] din,
    output reg [DWIDTH-1:0] dout,
    output                  empty,
    output                  full
);

  // Pointer width: clog2(DEPTH) bits to address DEPTH locations
  // Pointers wrap naturally via unsigned overflow (circular buffer)
  reg [$clog2(DEPTH)-1:0] wptr;
  reg [$clog2(DEPTH)-1:0] rptr;

  // Internal memory array: DEPTH entries of DWIDTH bits each
  reg [DWIDTH-1:0] fifo[0:DEPTH-1];

  // --- Write logic ---
  // On each clock edge: if enabled and not full, store data and advance wptr
  always @(posedge clk) begin
    if (!rstn) begin
      wptr <= 0;
    end else begin
      if (wr_en & !full) begin
        fifo[wptr] <= din;
        wptr       <= wptr + 1;  // Wraps at DEPTH (if DEPTH is power of 2)
      end
    end
  end

  // --- Read logic ---
  // On each clock edge: if enabled and not empty, output data and advance rptr
  // Note: dout is registered → 1-cycle latency from rd_en assertion to valid data
  always @(posedge clk) begin
    if (!rstn) begin
      rptr <= 0;
    end else begin
      if (rd_en & !empty) begin
        dout <= fifo[rptr];
        rptr <= rptr + 1;
      end
    end
  end

  // --- Status flags (combinational) ---
  // full:  next write position would collide with read position
  //        (sacrifices 1 entry to distinguish full from empty)
  // empty: write and read pointers are identical → nothing queued
  assign full  = ((wptr + 1) == rptr);
  assign empty = (wptr == rptr);

endmodule
