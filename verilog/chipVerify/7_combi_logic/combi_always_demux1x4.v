// =============================================================================
// Combinational Logic with always: 1x4 Demultiplexer
// =============================================================================
// KEY NOTES:
// - Same routing logic as the assign version, but all outputs are 'reg'
//   and driven inside a single always block.
// - All outputs are assigned in every execution of the block -> no latches.
//   WARNING: If you forget to assign an output in some branch, synthesis
//   will infer a latch (unwanted sequential element).
// - Sensitivity list: f and sel (both read inside the block).
// =============================================================================

module demux_1x4 (
    input             f,
    input      [1:0]  sel,
    output reg         a, b, c, d
);

    always @(f or sel) begin
        // sel=00 -> a, sel=10 -> b, sel=01 -> c, sel=11 -> d
        a = f & ~sel[1] & ~sel[0];
        b = f &  sel[1] & ~sel[0];
        c = f & ~sel[1] &  sel[0];
        d = f &  sel[1] &  sel[0];
    end

endmodule
