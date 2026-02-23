// bcd7seg.v — BCD to 7-segment decoder, just for the TLC
//   Displays a dash when state==G (2'b00), otherwise shows the BCD digit.
//   Active-low common-anode encoding.
module bcd7seg (
    input  wire [3:0] BCD,
    input  wire [1:0] state,
    output reg  [6:0] HEX
);

  always @(*) begin
    if (state == 2'b00) begin
      HEX = 7'b0111111;  // stand-by dash when G
    end else begin
      case (BCD)
        4'b0000: HEX = 7'b1000000;  // 0
        4'b0001: HEX = 7'b1111001;  // 1
        4'b0010: HEX = 7'b0100100;  // 2
        4'b0011: HEX = 7'b0110000;  // 3
        4'b0100: HEX = 7'b0011001;  // 4
        4'b0101: HEX = 7'b0010010;  // 5
        4'b0110: HEX = 7'b0000010;  // 6
        4'b0111: HEX = 7'b1111000;  // 7
        4'b1000: HEX = 7'b0000000;  // 8
        4'b1001: HEX = 7'b0010000;  // 9
        default: HEX = 7'b1111111;
      endcase
    end
  end

endmodule
