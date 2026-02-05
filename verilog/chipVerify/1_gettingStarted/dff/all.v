// all.v - design + testbench together
module dff (input clk, rstn, d, output reg q);
    always @(posedge clk) q <= !rstn ? 0 : d;
endmodule

module tb;
    reg clk=0, rstn=0, d=0;
    wire q;
    dff uut (clk, rstn, d, q);
    always #5 clk = ~clk;
    initial begin
        #10 rstn=1; #10 d=1; #20 $finish;
    end
endmodule