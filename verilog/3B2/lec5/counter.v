// counter.v — parameterized countdown counter
//   n: bit width
//   k: wrap-around value (counts k-1 down to 0, then reloads k-1)
module counter #(
    parameter integer n = 4,
    parameter integer k = 15
) (
    input  wire         clock,
    reset,
    enable,
    load,
    input  wire [n-1:0] start_time,
    output reg  [n-1:0] count,
    output wire         rollover
);

  assign rollover = (count == 0);

  always @(posedge clock or negedge reset) begin
    if (!reset) begin
      count <= start_time;
    end else if (load) begin
      count <= start_time;
    end else if (enable) begin
      if (count != 0) count <= count - 1'b1;
      else count <= k - 1;
    end
  end

endmodule
