// =============================================================================
// Combinational Logic with assign: Full Adder
// =============================================================================
// KEY NOTES:
// - A full adder extends the half adder by accepting a carry-in (cin).
// - sum  = a XOR b XOR cin
// - cout = (a AND b) OR ((a XOR b) AND cin)
//   i.e. carry is generated if at least two of the three inputs are 1.
// - Can also be built by cascading two half adders + an OR gate.
// =============================================================================

module fa (
    input  a, b, cin,
    output sum, cout
);

    // Three-input XOR for the sum bit
    assign sum  = (a ^ b) ^ cin;

    // Carry-out: generated (a&b) OR propagated ((a^b) & cin)
    assign cout = (a & b) | ((a ^ b) & cin);

endmodule
