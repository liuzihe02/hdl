// =============================================================================
// Combinational Logic with assign: Half Adder
// =============================================================================
// KEY NOTES:
// - A half adder adds two 1-bit inputs; it has NO carry-in.
// - sum  = a XOR b   (difference bit)
// - cout = a AND b   (carry bit)
// - Each assign statement creates an independent, concurrent driver.
// =============================================================================

module ha (
    input  a,
    b,
    output sum,
    cout
);

  // XOR gives 1 when inputs differ -> sum bit
  assign sum  = a ^ b;

  // AND gives 1 only when both inputs are 1 -> carry bit
  assign cout = a & b;

  // instead of doing bitwise logic, we could have done 
  // assign {cout, sum} = a + b;

endmodule
