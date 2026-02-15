// =============================================================================
// Combinational Logic with always: Full Adder
// =============================================================================
// KEY NOTES:
// - Uses the same {cout, sum} = a + b + cin concatenation trick.
// - a + b + cin produces a 2-bit result: MSB = carry, LSB = sum.
// - All three inputs (a, b, cin) must appear in the sensitivity list.
// - Synthesises to the same gate-level circuit as the assign version.
// =============================================================================

module fa (
    input      a, b, cin,
    output reg sum, cout
);

    always @(a or b or cin) begin
        // 2-bit addition: carry is the overflow bit
        {cout, sum} = a + b + cin;
    end

endmodule
