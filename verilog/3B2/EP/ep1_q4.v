// need to use bcd code in verilog/3B2/lec3/bcd7seg.v

/*
we need to go from inputs a to (f7-f4), (f3-f0) which connects to 2 bcd acting as display

## ROM Truth Table

| Decimal | a3 | a2 | a1 | a0 | f7 | f6 | f5 | f4 (tens) | f3 | f2 | f1 | f0 (units) |
|---------|----|----|----|----|----|----|----|-----------|----|----|----|----|
| 0       | 0  | 0  | 0  | 0  | 0  | 0  | 0  | 0         | 0  | 0  | 0  | 0 |
| 1       | 0  | 0  | 0  | 1  | 0  | 0  | 0  | 0         | 0  | 0  | 0  | 1 |
| 2       | 0  | 0  | 1  | 0  | 0  | 0  | 0  | 0         | 0  | 0  | 1  | 0 |
| 3       | 0  | 0  | 1  | 1  | 0  | 0  | 0  | 0         | 0  | 0  | 1  | 1 |
| 4       | 0  | 1  | 0  | 0  | 0  | 0  | 0  | 0         | 0  | 1  | 0  | 0 |
| 5       | 0  | 1  | 0  | 1  | 0  | 0  | 0  | 0         | 0  | 1  | 0  | 1 |
| 6       | 0  | 1  | 1  | 0  | 0  | 0  | 0  | 0         | 0  | 1  | 1  | 0 |
| 7       | 0  | 1  | 1  | 1  | 0  | 0  | 0  | 0         | 0  | 1  | 1  | 1 |
| 8       | 1  | 0  | 0  | 0  | 0  | 0  | 0  | 0         | 1  | 0  | 0  | 0 |
| 9       | 1  | 0  | 0  | 1  | 0  | 0  | 0  | 0         | 1  | 0  | 0  | 1 |
| 10      | 1  | 0  | 1  | 0  | 0  | 0  | 0  | 1         | 0  | 0  | 0  | 0 |
| 11      | 1  | 0  | 1  | 1  | 0  | 0  | 0  | 1         | 0  | 0  | 0  | 1 |
| 12      | 1  | 1  | 0  | 0  | 0  | 0  | 0  | 1         | 0  | 0  | 1  | 0 |
| 13      | 1  | 1  | 0  | 1  | 0  | 0  | 0  | 1         | 0  | 0  | 1  | 1 |
| 14      | 1  | 1  | 1  | 0  | 0  | 0  | 0  | 1         | 0  | 1  | 0  | 0 |
| 15      | 1  | 1  | 1  | 1  | 0  | 0  | 0  | 1         | 0  | 1  | 0  | 1 |

**Key observations:**
- f7-f5 are **always 0** (tens digit never exceeds 1)

- f4 is only 1 for inputs 10–15 (when tens digit = 1)

- f3-f0 cycles 0→9 then 0→5, representing the units digit
- use case statement here as no clean boolean pattern

**alternative code**
assign f[7:4] = (a >= 4'd10) ? 4'd1 : 4'd0;
assign f[3:0] = (a >= 4'd10) ? (a - 4'd10) : a;

Each nibble then feeds into the 7-segment decoder truth table from before.
*/
module ep1_q4 (
    //decimal 0 to 15 in binary
    input  wire [3:0] a,
    //left digit 7 bits
    output wire [6:0] dl,
    //right digit 7 bits
    output wire [6:0] dr
);
  //declare reg to be used inside procedural combi block
  reg [7:0] f;
  always @(*) begin
    begin
      case (a)
        //always@* needs blocking
        4'b0000: f = {4'b0000, 4'b0000};
        4'b0001: f = {4'b0000, 4'b0001};
        4'b0010: f = {4'b0000, 4'b0010};
        4'b0011: f = {4'b0000, 4'b0011};
        4'b0100: f = {4'b0000, 4'b0100};
        4'b0101: f = {4'b0000, 4'b0101};
        4'b0110: f = {4'b0000, 4'b0110};
        4'b0111: f = {4'b0000, 4'b0111};
        4'b1000: f = {4'b0000, 4'b1000};
        4'b1001: f = {4'b0000, 4'b1001};
        4'b1010: f = {4'b0001, 4'b0000};
        4'b1011: f = {4'b0001, 4'b0001};
        4'b1100: f = {4'b0001, 4'b0010};
        4'b1101: f = {4'b0001, 4'b0011};
        4'b1110: f = {4'b0001, 4'b0100};
        4'b1111: f = {4'b0001, 4'b0101};
        default: f = 8'b0;
      endcase
    end
  end

  // Instantiate 7seg decoders (these are modules, not functions!)
  // cannot call them inline
  // will modify dl in place
  // cannot instantiate within procedural blocks
  bcd7seg seg_left (
      .bcd (f[7:4]),
      .leds(dl)
  );
  bcd7seg seg_right (
      .bcd (f[3:0]),
      .leds(dr)
  );

endmodule
