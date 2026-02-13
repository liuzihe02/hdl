// =============================================================================
// Combinational Logic with assign: 1x4 Demultiplexer
// =============================================================================
// KEY NOTES:
// - A demux routes a single input 'f' to one of N outputs based on 'sel'.
// - Each output is driven by its own assign statement.
// - Only one output is active (equals f) at a time; others are 0.
// - IMPORTANT: Do NOT drive the same signal from multiple assign statements;
//   each output here has exactly one driver.
// =============================================================================

module demux_1x4 (
    input             f,
    input      [1:0]  sel,
    output             a, b, c, d
);

    // sel=00 -> a gets f
    assign a = f & ~sel[1] & ~sel[0];

    // sel=10 -> b gets f
    assign b = f &  sel[1] & ~sel[0];

    // sel=01 -> c gets f
    assign c = f & ~sel[1] &  sel[0];

    // sel=11 -> d gets f
    assign d = f &  sel[1] &  sel[0];

endmodule
