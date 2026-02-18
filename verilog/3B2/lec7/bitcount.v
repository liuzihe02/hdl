module bitcount (
    input wire clock,
    input wire Resetn,
    input wire LA,
    input wire s,
    input wire [7:0] Data,
    output reg [3:0] B,
    output wire Done
);

    // Local parameter definitions for FSM states
    localparam S1 = 2'd0;
    localparam S2 = 2'd1;
    localparam S3 = 2'd2;

    // Internal signal declarations
    reg [1:0] y;
    wire [7:0] A;
    wire z;
    reg EA, LB, EB;
    wire low;
    reg Done_r;

    // --- FSM Transitions ---
    // Controls the state logic based on clock and reset
    always @(negedge Resetn or posedge clock) begin
        if (Resetn == 1'b0) begin
            y <= S1;
        end
        else begin
            case (y)
                S1: begin
                    if (s == 1'b0) y <= S1;
                    else           y <= S2;
                end
                S2: begin
                    if (z == 1'b0) y <= S2;
                    else           y <= S3;
                end
                S3: begin
                    if (s == 1'b1) y <= S3;
                    else           y <= S1;
                end
                default: y <= S1;
            endcase
        end
    end

    // --- FSM Outputs ---
    // Combinational logic to define control signals based on current state
    always @(*) begin
        EA     = 1'b0;
        LB     = 1'b0;
        EB     = 1'b0;
        Done_r = 1'b0;
        case (y)
            S1: begin
                LB = 1'b1;
            end
            S2: begin
                EA = 1'b1;
                if (A[0] == 1'b1) EB = 1'b1;
                else              EB = 1'b0;
            end
            S3: begin
                Done_r = 1'b1;
            end
        endcase
    end

    assign Done = Done_r;

    // --- The Datapath Circuit ---
    // Implements the arithmetic and register logic
    always @(posedge clock or negedge Resetn) begin
        if (!Resetn) begin
            B <= 4'd0;
        end else begin
            if (LB == 1'b1) begin
                B <= 4'd0;
            end else if (EB == 1'b1) begin
                B <= B + 4'd1;
            end
        end
    end

    assign low = 1'b0;

	 // Shifter instantiation (Corrected to match shiftrne_bitcounter ports)
    shiftrne_bitcounter #(.N(8)) shiftA (
        .R		(Data),     // Maps Data to R
        .load	(LA),     	// Maps LA to load
        .enable(EA),   		// Maps EA to enable
        .w		(low),     	// Maps low to w
        .clock	(clock), 	// Maps clock to Clock
        .Q		(A)         // Maps Q to A
    );

    // Zero-detection logic for the shifter output
    assign z = (A == 8'b00000000) ? 1'b1 : 1'b0;
endmodule

module shiftrne_bitcounter #(
	parameter N = 8
) (
	input wire [N-1:0] R,
	input wire load,
	input wire enable,
	input wire w,
	input wire clock,
	output reg [N-1:0] Q
);

integer i;

always @(posedge clock) begin
	
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