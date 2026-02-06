module ep1_q6 (
    input wire clk,
    input wire rst_n,
    output reg [2:0] count  // D1, D2, D3
);
  // D flip-flop implementation using sequential always block
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      // Reset to state 1 (000)
      count <= 3'b000;
    end else begin
      // Compute next state using if-then sequential logic
      case (count)
        3'b000:  count <= 3'b001;  // State 1 → State 2
        3'b001:  count <= 3'b011;  // State 2 → State 3
        3'b011:  count <= 3'b010;  // State 3 → State 4
        3'b010:  count <= 3'b110;  // State 4 → State 5
        3'b110:  count <= 3'b111;  // State 5 → State 6
        3'b111:  count <= 3'b101;  // State 6 → State 7
        3'b101:  count <= 3'b100;  // State 7 → State 8
        3'b100:  count <= 3'b000;  // State 8 → State 1
        default: count <= 3'b000;  // Safety: reset to state 1
      endcase
    end
  end

endmodule
