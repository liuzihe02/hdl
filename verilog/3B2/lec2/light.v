module light (
	input  wire x1, x2,
	output wire f
);
	wire s1, s2, s3, s4;
	
	NOTg_light c1 (.x(x1), .f(s2));
	NOTg_light c2 (.x(x2), .f(s1));
	
	ANDg_light c3 (.x1(x1), .x2(s1), .f(s3));
	ANDg_light c4 (.x1(s2), .x2(x2), .f(s4));
	
	ORg_light  c5 (.x1(s3), .x2(s4), .f(f)); 
		
endmodule 

module NOTg_light (
	input  wire x,
	output wire f
);
	assign f = ~x; 
	
endmodule	

module ANDg_light (
	input  wire x1, x2,
	output wire f
);
	assign f = x1 & x2;
	
endmodule

module ORg_light (
	input  wire x1, x2,
	output wire f
);
	assign f = x1 | x2;
	
endmodule


