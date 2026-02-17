module flipflop (
	input wire D,
	input wire Clk,
	output reg Q
);	

	always @(posedge Clk) begin
		Q <= D;
	end
endmodule

	
