module bcd7seg (
    input [3:0] bcd,
    output reg [0:6] leds
);
  // Procedural assignment (Behavioral modeling)
  always @(bcd) begin
    case (bcd)
      4'b0000: leds = 7'b0000001;
      4'b0001: leds = 7'b1001111;
      4'b0010: leds = 7'b0010010;
      4'b0011: leds = 7'b0000110;
      4'b0100: leds = 7'b1001100;
      4'b0101: leds = 7'b0100100;
      4'b0110: leds = 7'b0100000;
      4'b0111: leds = 7'b0001111;
      4'b1000: leds = 7'b0000000;
      4'b1001: leds = 7'b0000100;
      default: leds = 7'b1111111;
    endcase
  end
endmodule
