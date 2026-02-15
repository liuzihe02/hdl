/*
for priority encoder, take the MSB of the input, so it is like a select variable
we have some kind of hardcoded encoding (up to us to decide is arbitrary) the select will choose which encoding to return
*/
module priority_encoder_case (
    input [3:0] request,
    output reg [1:0] encode
);
  always @(*) begin
    //casez will treat z and ? as dont care states
    casez (request)
      4'b1zzz: encode = 2'b11;  // req[3] has highest priority
      4'b01zz: encode = 2'b10;  // req[2]
      4'b001z: encode = 2'b01;  // req[1]
      default: encode = 2'b00;  // req[0] or none active
    endcase
  end
endmodule
