// =============================================================================
// Combinational Logic with always: 2x1 Multiplexer
// =============================================================================
// KEY NOTES:
// - The ternary operator works identically inside an always block.
// - Alternatively, you could use an if-else or case statement here;
//   all synthesise to the same MUX hardware.
// - Output 'c' must be 'reg' since it is procedurally assigned.
// - Sensitivity list includes all inputs: a, b, sel.
// =============================================================================

module mux_2x1 (
    input      a, b, sel,
    output reg c
);

    always @(a or b or sel) begin
        // sel=1 -> c=a, sel=0 -> c=b
        c = sel ? a : b;
    end

endmodule
