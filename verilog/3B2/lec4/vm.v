module vm (
	input wire Clock,
	input wire [1:0] input_coins,
	output reg DEL
);
// Define states using parameters
localparam S0 = 2'b00,
			  S1 = 2'b01,
			  S2 = 2'b10,
			  S4 = 2'b11;

// Register to hold current state
reg [1:0] state, next_state;

// state register
always @(posedge Clock) begin
	state <= next_state;
end

always @(*) begin // next state logic
	case (state)
		S0: begin
			if (input_coins == 2'b01)
				next_state = S2;
			else if (input_coins == 2'b10)
				next_state = S1;
			else
				next_state = S0;	
		end
		
		S1: begin
			if (input_coins == 2'b01)
				next_state = S4;
			else if (input_coins == 2'b10)
				next_state = S2;
			else
				next_state = S1;	
		end
		
		S2: begin
			if (input_coins == 2'b00)
				next_state = S2;
			else
				next_state = S4;	
		end
		
		S4: 	   next_state = S0;
		default: next_state = S0;
	endcase
end

always @(*) begin
	DEL = (state == S4);
end

endmodule