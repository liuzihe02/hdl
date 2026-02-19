module counter (
    input  wire       clock,
    input  wire       reset,
    output reg  [2:0] count
);
  // 3 bit to count 8 times
  always @(posedge clock or negedge reset) begin
    if (!reset) begin
      count <= 3'b000;
    end else begin
      if (count == 3'b111) count <= 3'b000;
      else count <= count + 1;
    end
  end

endmodule
