// =============================================================================
// Combinational Logic with always: 4-to-16 Decoder
// =============================================================================
// KEY NOTES:
// - Identical behaviour to the assign version; output is 'reg' [15:0].
// - The left-shift trick (1 << in) creates one-hot encoding:
//   in=0 -> out=0x0001, in=5 -> out=0x0020, in=15 -> out=0x8000.
// - Enable pin: when en=0, all outputs forced to 0.
// - Both 'en' and 'in' must be in the sensitivity list.
// =============================================================================

module dec_4x16 (
    input              en,
    input      [3:0]   in,
    output reg [15:0]  out
);

    always @(en or in) begin
        // One-hot decode with enable gating
        out = en ? (1 << in) : 16'b0;
    end

endmodule
