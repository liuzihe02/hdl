// =============================================================================
// Combinational Logic with always: Half Adder
// =============================================================================
// KEY NOTES:
// - Same functionality as the assign version but uses a procedural block.
// - The concatenation {cout, sum} = a + b is a compact idiom:
//   a + b produces a 2-bit result; the MSB is the carry, LSB is the sum.
// - This is equivalent to: sum = a ^ b; cout = a & b;
// - Both 'sum' and 'cout' are declared 'reg' since they are driven
//   inside the always block.
// =============================================================================

module ha (
    input      a, b,
    output reg sum, cout
);

    always @(a or b) begin
        // Addition naturally gives {carry, sum} in a 2-bit result
        {cout, sum} = a + b;
    end

endmodule
