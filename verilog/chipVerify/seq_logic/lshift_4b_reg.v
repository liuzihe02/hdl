/*
4bit Left Shift Register
Shown below is a 4-bit left shift register that accepts an input d into LSB and all other bits will be shifted left by 1. For example, if d equals zero and the initial value of the register is 0011, it will become 0110 at the next edge of the clock clk.

*/
module lshift_4b_reg (
    input d,
    input clk,
    input rstn,
    output reg [3:0] out
);

  always @(posedge clk) begin
    if (!rstn) begin
      out <= 0;
    end else begin
      out <= {out[2:0], d};
    end
  end
endmodule
