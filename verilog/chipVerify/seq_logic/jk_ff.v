/*
*/
module jk_ff (
    input    j,     // Input J
    input    k,     // Input K
    input    rstn,   // Active-low async reset
    input    clk,    // Input clk
    output reg q
);  // Output Q

  always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
      q <= 0;
    end else begin
      q <= (j & ~q) | (~k & q);
    end
  end
endmodule
