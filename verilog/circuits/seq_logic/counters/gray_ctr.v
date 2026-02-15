// ============================================================
// GRAY COUNTER
// ============================================================
// A gray counter outputs a gray code sequence where only ONE
// bit changes between successive values, unlike binary where
// multiple bits can toggle simultaneously.
//
// Binary: 000 → 001 → 010  (2 bits change: bits[1:0])
// Gray:   000 → 001 → 011  (1 bit changes each step)
//
// WHY IT MATTERS:
// In clock domain crossings (CDC), a multi-bit binary counter
// sampled by a different clock can be read mid-transition,
// producing a completely wrong value. Gray code guarantees
// at most 1 bit is changing, so the worst case is reading
// the old value or the new value — never a glitched third value.
// This is why async FIFO read/write pointers are always gray-coded.
//
// HOW IT WORKS:
// 1. Maintain an internal binary counter q
// 2. Convert q to gray code: gray = q ^ (q >> 1)
//    i.e. each gray bit = XOR of adjacent binary bits
//
//    Binary  q:   1 0 1 1
//    Shifted q>>1: 0 1 0 1
//    XOR (gray):  1 1 1 0
// ============================================================

module gray_ctr #(
    parameter N = 4
) (
    input              clk,
    input              rstn,
    output reg [N-1:0] out
);
  reg [N-1:0] q;  // internal binary counter

  always @(posedge clk) begin
    if (!rstn) begin
      q   <= 0;
      out <= 0;
    end else begin
      q   <= q + 1;
      out <= {q[N-1], q[N-1:1] ^ q[N-2:0]};  // binary-to-gray conversion
    end
  end
endmodule
