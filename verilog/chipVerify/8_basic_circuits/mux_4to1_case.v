/*
* MUX basically selects which of the inputs to return
* has a list of inputs and a select variable, which chooses which input to return
*/
module mux_4to1_case (
    input      [3:0] a,    // 4-bit input called a
    input      [3:0] b,    // 4-bit input called b
    input      [3:0] c,    // 4-bit input called c
    input      [3:0] d,    // 4-bit input called d
    input      [1:0] sel,  // input sel used to select between a,b,c,d
    output reg [3:0] out   //reg type, used in procedural block always
);  // 4-bit output based on input sel

  // This always block gets executed whenever a/b/c/d/sel changes value
  // When that happens, based on value in sel, output is assigned to either a/b/c/d
  always @(a or b or c or d or sel) begin
    //case requires exact match
    case (sel)
      2'b00: out = a;
      2'b01: out = b;
      2'b10: out = c;
      2'b11: out = d;
    endcase
  end
endmodule
