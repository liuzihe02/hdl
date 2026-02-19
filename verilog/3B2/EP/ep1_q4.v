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
    input wire [3:0] a,
    //left digit 7 bits
    output reg [6:0] dl,
    //right digit 7 bits
    output reg [6:0] dr,
);
reg [7:0] f;
always @(*) begin
    begin
        case (a)
            4'b0000: f <= {4'b0000, 4'b0000}; // 0  → 0, 0
            4'b0001: f <= {4'b0000, 4'b0001}; // 1  → 0, 1
            4'b0010: f <= {4'b0000, 4'b0010}; // 2  → 0, 2
            4'b0011: f <= {4'b0000, 4'b0011}; // 3  → 0, 3
            4'b0100: f <= {4'b0000, 4'b0100}; // 4  → 0, 4
            4'b0101: f <= {4'b0000, 4'b0101}; // 5  → 0, 5
            4'b0110: f <= {4'b0000, 4'b0110}; // 6  → 0, 6
            4'b0111: f <= {4'b0000, 4'b0111}; // 7  → 0, 7
            4'b1000: f <= {4'b0000, 4'b1000}; // 8  → 0, 8
            4'b1001: f <= {4'b0000, 4'b1001}; // 9  → 0, 9
            4'b1010: f <= {4'b0001, 4'b0000}; // 10 → 1, 0
            4'b1011: f <= {4'b0001, 4'b0001}; // 11 → 1, 1
            4'b1100: f <= {4'b0001, 4'b0010}; // 12 → 1, 2
            4'b1101: f <= {4'b0001, 4'b0011}; // 13 → 1, 3
            4'b1110: f <= {4'b0001, 4'b0100}; // 14 → 1, 4
            4'b1111: f <= {4'b0001, 4'b0101}; // 15 → 1, 5
            default: f <= 8'b0;
        endcase
        //input to my bcd 7 seg decoders
        dr<=bcd7seg(f[3:0]);
        dl<=bcd7seg(f[7:4]);
    end
  end

endmodule
