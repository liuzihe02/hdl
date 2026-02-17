module shiftrne #(
	parameter N = 4
) (
	input wire [N-1:0] R,
	input wire			 load,
	input wire			 enable, 
	input wire		    w, 
	input wire		    Clock,
	output reg [N-1:0] Q
);

integer i;

always @(posedge Clock) begin
	
	if (load) begin
		Q <= R;
	end
	else if (enable) begin
		for (i = 0; i < N-1; i = i + 1) begin
			Q[i] <= Q[i+1];
		end	
		Q[N-1] <= w;
	end
end

endmodule
	