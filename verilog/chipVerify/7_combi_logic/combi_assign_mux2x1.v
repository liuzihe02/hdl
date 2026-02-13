// =============================================================================
// Combinational Logic with assign: 2x1 Multiplexer
// =============================================================================
// KEY NOTES:
// - A mux selects one of N inputs and routes it to a single output.
// - The ternary operator (sel ? a : b) maps directly to a MUX primitive
//   in synthesis: if sel=1 -> output=a, if sel=0 -> output=b.
// - For wider muxes, use nested ternaries or case statements (always block).
// =============================================================================

module mux_2x1 (
    input  a, b, sel,
    output c
);

    // Ternary: sel high selects 'a', sel low selects 'b'
    assign c = sel ? a : b;

endmodule
