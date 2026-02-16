// ============================================================
// N-BIT BIDIRECTIONAL SHIFT REGISTER
// ============================================================
// A shift register is a chain of flip-flops where each flop's
// output (q) feeds the next flop's data input (d). On every
// clock edge, the entire bit pattern shifts by one position.
//
// Example: 5-bit right shift, input d=0
//   10110 → 01011 → 00101 → 00010 → ...
//   ^^^^^   ^^^^^
//   Each clock cycle, bits move one position to the right.
//   The new bit (d) enters from the left, the rightmost bit
//   falls off.
//
// SHIFT LEFT (dir=0):  {out[MSB-2:0], d}
//   Concatenate: existing bits shifted up by 1, new bit d
//   enters at LSB (bit 0).
//
//   Before:  [ b7 b6 b5 b4 b3 b2 b1 b0 ]
//   After:   [ b6 b5 b4 b3 b2 b1 b0  d  ]
//
// SHIFT RIGHT (dir=1): {d, out[MSB-1:1]}
//   Concatenate: new bit d enters at MSB, existing bits
//   shifted down by 1, LSB falls off.
//
//   Before:  [ b7 b6 b5 b4 b3 b2 b1 b0 ]
//   After:   [  d  b7 b6 b5 b4 b3 b2 b1 ]
//
// COMMON USES:
//   - Serial-to-parallel / parallel-to-serial conversion
//     (e.g. SPI, UART, I2C interfaces)
//   - Pipeline delay chains (shift data through N stages)
//   - Pseudo-random number generators (LFSRs)
//   - Digital filters (tapped delay lines)
// ============================================================

module shift_reg #(
    parameter MSB = 8
) (
    input                d,     // Declare input for data to the first flop in the shift register
    input                clk,   // Declare input for clock to all flops in the shift register
    input                en,    // Declare input for enable to switch the shift register on/off
    input                dir,   // Declare input to shift in either left or right direction
    input                rstn,  // Declare input to reset the register to a default value
    output reg [MSB-1:0] out
);  // Declare output to read out the current value of all flops in this register

  // This always block will "always" be triggered on the rising edge of clock
  // Once it enters the block, it will first check to see if reset is 0 and if yes then reset register
  // If no, then check to see if the shift register is enabled
  // If no => maintain previous output. If yes, then shift based on the requested direction
  always @(posedge clk)
    if (!rstn) out <= 0;
    else begin
      if (en)
        case (dir)
          0: out <= {out[MSB-2:0], d};  // shift left:  MSB falls off, d enters at LSB
          1: out <= {d, out[MSB-1:1]};  // shift right: LSB falls off, d enters at MSB
        endcase
      else out <= out;
    end
endmodule
