module myRAM (
    input	wire 			write,
    input 	wire 			clock,
    input 	wire [3:0] 	DataIn,
    input 	wire [4:0] 	Address_STD,
    output 	wire [3:0] 	DataOut
);

    reg	[4:0] Address_reg;
    wire [4:0] Address;
    
    // declare memory array
    reg 	[3:0] memory_array [0:31];
    
    assign Address = Address_STD;
    
    // infer RAM module
    always @(posedge clock) begin
        if (write) begin
            memory_array[Address] <= DataIn;
        end
        Address_reg <= Address;
    end
    
    assign DataOut = memory_array[Address_reg];

endmodule