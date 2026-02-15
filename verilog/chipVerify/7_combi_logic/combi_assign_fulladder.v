// =============================================================================
// Combinational Logic with assign: Full Adder
// =============================================================================
// KEY NOTES:
// - A full adder extends the half adder by accepting a carry-in (cin).
// - sum  = a XOR b XOR cin
// - cout = (a AND b) OR ((a XOR b) AND cin)
//   i.e. carry is generated if at least two of the three inputs are 1.
// - Can also be built by cascading two half adders + an OR gate.
//
//  a | b | cin || sum | cout
// ---|---|-----||-----|------
//  0 | 0 |  0  ||  0  |  0
//  0 | 0 |  1  ||  1  |  0
//  0 | 1 |  0  ||  1  |  0
//  0 | 1 |  1  ||  0  |  1
//  1 | 0 |  0  ||  1  |  0
//  1 | 0 |  1  ||  0  |  1
//  1 | 1 |  0  ||  0  |  1
//  1 | 1 |  1  ||  1  |  1
//
// can also use assign like assign {c_out, sum} = a + b + c_in;
// =============================================================================

module fa (
    input  a,
    b,
    cin,
    output sum,
    cout
);

  //sum = a ⊕ b ⊕ cin (XOR of all three)
  assign sum  = (a ^ b) ^ cin;

  // cout = (a & b) | (a & cin) | (b & cin) (carry when 2+ inputs are 1)
  // Carry-out: generated (a&b) OR propagated ((a^b) & cin)
  assign cout = (a & b) | ((a ^ b) & cin);

endmodule
