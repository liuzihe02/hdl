// =============================================================================
// Combinational Logic with assign: 4-to-16 Decoder
// =============================================================================
// KEY NOTES:
// - A decoder activates exactly one of 2^N output lines based on an N-bit input.
// - Here: 4-bit input 'in' -> 16-bit one-hot output 'out'.
// - 'en' (enable): when low, all outputs are 0 (decoder disabled).
// - The left-shift trick (1 << in) produces a one-hot encoding directly.
// - The ternary handles the enable: en ? active : all-zero.
// =============================================================================

module dec_4x16 (
    input              en,
    input      [3:0]   in,
    output     [15:0]  out
);

    // Shift a 1 into the position indicated by 'in'; zero everything if !en
    assign out = en ? (1 << in) : 16'b0;

endmodule
