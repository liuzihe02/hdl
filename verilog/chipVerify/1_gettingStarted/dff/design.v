module dff (input clk, rstn, d, output reg q);
    always @(posedge clk) q <= !rstn ? 0 : d;
endmodule