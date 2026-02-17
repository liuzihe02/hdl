module mux4bit (
	input  wire [8:0] sw,
	output wire [4:0] led
);
	wire [3:0] x,y,f; 
	wire       sel;
	
	assign x   = sw[3:0];
	assign y   = sw[7:4];
	assign sel = sw[8];
	
	assign f        = sel ? y : x;
	assign led[4]   = sel;
	assign led[3:0] = f;

endmodule