// stat_counter.v — simple N-bit up-counter
module stat_counter #(
    parameter integer N = 8
) (
    input  wire       clock,
    input  wire       reset,
    input  wire       inc,
    output reg  [N-1:0] count
);

  always @(posedge clock or negedge reset) begin
    if (!reset) count <= 0;
    else if (inc) count <= count + 1'b1;
  end

endmodule
