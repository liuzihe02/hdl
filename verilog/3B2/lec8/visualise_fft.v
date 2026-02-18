module visualise_fft (
    // Inputs
    input wire        clk, reset,    
    input wire [3:0]  x0, x1, x2, x3, 

    // LCD Control Signals
    output wire       rs,     // Register Select signal (0=Command, 1=Data)
    output wire       rw,     // Read/Write signal for LCD (0=Write, 1=Read)
    output wire       lcd_on, // Logic signal to turn the LCD ON
    output wire       blon,   // Backlight ON signal
    output wire       e,      // Enable signal for LCD (pulses to send data)
    output wire [7:0] db,     // 8-bit bi-directional data bus connected to LCD

    // 7-Segment Display Outputs 
    // [13:7] = Sign, [6:0] = Magnitude 
    output wire [13:0] disp0, disp1, disp2, disp3
);

    // --- Internal Signals Declaration ---
    wire [5:0] y0r, y1r, y2r, y3r; // Real part results (6-bit signed)
    wire [5:0] y0i, y1i, y2i, y3i; // Imaginary part results (6-bit signed)

    wire [4:0] lcd_read_addr;      // Address wire: LCD Controller -> VRAM (Reading)
    wire [6:0] vram_data_out;      // Data wire: VRAM -> LCD Controller (ASCII Char)

    wire       lcd_enable_tick;    // Slow timing pulse (~500Hz) for the state machine
    wire       lcd_clk_signal;     // Slow clock for driving the LCD ‘e' pin
    
    // --- Writer Logic Signals (Registers) ---
    wire  [4:0] write_addr;         // VRAM address we are writing to
    wire  [6:0] write_data;         // ASCII data we are writing to VRAM
    wire        write_enable;       // write permission to VRAM
 
    // --- Converter Logic Signals ---
    reg  signed [5:0] converter_in; // Input register for the binary-to-ASCII converter
    wire [6:0] c_sign;              // Output wire from converter: ASCII sign
    wire [6:0] c_tens;              // Output wire from converter: ASCII tens digit
    wire [6:0] c_ones;              // Output wire from converter: ASCII ones digit

    // --- Displays ---
    // We manually slice the 14-bit 'disp' bus to feed these inputs.
    signed_hex_driver d0 (
         .val_in(x0), 
         .seg_mag(disp0[6:0]), .seg_sign(disp0[13:7])
    );

    signed_hex_driver d1 (
         .val_in(x1), 
         .seg_mag(disp1[6:0]), .seg_sign(disp1[13:7])
    );

    signed_hex_driver d2 (
         .val_in(x2), 
         .seg_mag(disp2[6:0]), .seg_sign(disp2[13:7])
    );

    signed_hex_driver d3 (
         .val_in(x3), 
         .seg_mag(disp3[6:0]), .seg_sign(disp3[13:7])
    );

    // --- Math Unit Instantiation ---
    fft_4 calc_unit (                   
         .x0(x0),   .x1(x1),   .x2(x2),   .x3(x3), 
         .y0r(y0r), .y1r(y1r), .y2r(y2r), .y3r(y3r), 
         .y0i(y0i), .y1i(y1i), .y2i(y2i), .y3i(y3i) 
    );
    
    // --- ASCII Converter Instantiation ---
    bin6_to_ascii_signed conv_inst (   
         .val_in(converter_in),          // Input comes from our multiplexing logic
         .char_sign(c_sign),             // Output the Sign character
         .char_tens(c_tens),             // Output the Tens digit character
         .char_ones(c_ones)              // Output the Ones digit character
    );

    // --- Memory Instantiation ---
    VRAM_32loc_7bits memory (        
         .clk(clk),                     
         .wr_en(write_enable),           
         .data_in(write_data),           // Connect data input    (from Writer)
         .addr_in_0(write_addr),         // Connect write address (from Writer)
         .addr_in_1(lcd_read_addr),      // Connect read address  (from LCD Controller)
         .data_out(vram_data_out)        // Connect data output   (to LCD Controller)
    );

	 write_to_VRAM writer (
        .clk(clk),
        .reset(reset),
        // FFT Results (inputs to the writer)
        .y0r(y0r), .y1r(y1r), .y2r(y2r), .y3r(y3r),
        .y0i(y0i), .y1i(y1i), .y2i(y2i), .y3i(y3i),
        // Outputs to VRAM
        .write_addr(write_addr),
        .write_data(write_data),
        .write_enable(write_enable)
    );	
	 
    // --- Timing Generator Instantiation ---
    tick_generator clk_div (           
         .clk(clk),                       
         .reset(reset),                   
         .tick(lcd_enable_tick),          // Output the slow update tick
         .slow_clk(lcd_clk_signal)        // Output the physical LCD clock pulse
    );

    // --- LCD Controller Instantiation ---
    lcd_driver lcd_ctrl (   
         .reset(reset),                  
         .clk(clk),                      
         .enable(lcd_enable_tick),       // Update state only on slow ticks
         .data_in(vram_data_out),        // Read character data from VRAM
         .address(lcd_read_addr),        // Output address to VRAM
         .e(),                           // Leave internal e disconnected (we drive it manually)
         .rw(rw), .rs(rs),                 
         .lcd_on(lcd_on), .blon(blon),     
         .db(db)                         
    );
    
    assign e = lcd_clk_signal;            // Manually drive ‘e' pin with our phase-corrected clock
	 
endmodule

module signed_hex_driver (
    input  wire [3:0] val_in,
    output wire [6:0] seg_mag,  
    output wire [6:0] seg_sign 
);

    wire [3:0] magnitude;
    wire       is_negative;

    // Check MSB (Bit 3) for sign
    assign is_negative = val_in[3];

    // If <0, convert 2's complement to mag.
    // If >0, keep as is
    assign magnitude = is_negative ? (~val_in + 1'b1) : val_in;

    // If Negative: Show '-' 
    // If Positive: Show ' ' 
    assign seg_sign = is_negative ? 7'b0111111 : 7'b1111111;

    // Use existing decoder for the number part
    bcd7seg decoder ( 
         .bcd(magnitude), 
         .seg_out(seg_mag) 
    );
endmodule

module bcd7seg (
    input  wire [3:0] bcd,
    output reg  [6:0] seg_out
);
    always @(bcd) begin
        case (bcd)
            4'h0: seg_out = 7'b1000000; 
            4'h1: seg_out = 7'b1111001; 
            4'h2: seg_out = 7'b0100100; 
            4'h3: seg_out = 7'b0110000; 
            4'h4: seg_out = 7'b0011001; 
            4'h5: seg_out = 7'b0010010; 
            4'h6: seg_out = 7'b0000010; 
            4'h7: seg_out = 7'b1111000; 
            4'h8: seg_out = 7'b0000000; 
            default: seg_out = 7'b1111111; 
        endcase
    end
endmodule

module fft_4 (
    // Inputs (4 bits)
    input wire [3:0] x0, x1, x2, x3,
    
    // Outputs (6 bits)
    output wire [5:0] y0r, y1r, y2r, y3r,
    output wire [5:0] y0i, y1i, y2i, y3i
);
    
    wire [4:0] a, b, c, d;

    // Note: {x0[3], x0} performs sign extension (4 bits -> 5 bits)
    assign a = {x0[3], x0} + {x2[3], x2};
    assign b = {x0[3], x0} - {x2[3], x2};    
    assign c = {x1[3], x1} + {x3[3], x3};
    assign d = {x1[3], x1} - {x3[3], x3};
    
    // with twiddle factor equal to 0
    assign y0r =  {a[4], a} + {c[4], c}; 
    assign y0i =  6'b0; 
    assign y2r =  {a[4], a} - {c[4], c};
    assign y2i =  6'b0;
    
    // with twiddle factor equal to '-i'
    assign y1r =  {b[4], b};  
    assign y1i = -{d[4], d}; 
    assign y3r =  {b[4], b};
    assign y3i =  {d[4], d};
endmodule

// Converts a 6-bit signed integer into three ASCII characters
module bin6_to_ascii_signed (
    // Input: 6-bit signed number (Range: -32 to +31)
    input  wire signed [5:0] val_in,
    
    // Outputs: 7-bit registers to hold the ASCII codes for sign, tens, and ones
    output reg [6:0] char_sign,
    output reg [6:0] char_tens,
    output reg [6:0] char_ones
);
    
    // Internal register to store the unsigned magnitude of the input
    reg [5:0] abs_val;

    always @(*) begin
        if (val_in < 0) begin
            char_sign = 7'h2D;   // FIXED: Changed smart quote ’ to standard '
            abs_val   = -val_in; 
        end else begin
            char_sign = 7'h20;   // If positive, set sign character to ASCII Space
            abs_val   = val_in; 
        end
        
        // Add 7'h30 (ASCII '0') to convert the integers into characters
        char_tens = 7'h30 + (abs_val / 10);
        char_ones = 7'h30 + (abs_val % 10);
    end
endmodule

module VRAM_32loc_7bits (
   input  wire  clk,             // clock
   input  wire  wr_en,           // write enable for port 0
   input  wire  [6:0] data_in,   // input data to port 0
   input  wire  [4:0] addr_in_0, // address for port 0
   input  wire  [4:0] addr_in_1, // address for port 1
   output wire  [6:0] data_out   // output data
);

    // Memory Declaration: 32 locations, 7 bits wide
    reg [6:0] ram [0:31]; 

    integer i;

    // Initialisation 
    initial begin
        for (i = 0; i < 32; i = i + 1) begin
            ram[i] = 7'b0100000; 
        end
    end

    // Synchronous Write Process
    always @(posedge clk) begin
        if (wr_en) begin
            // Verilog converts the vector 'addr_in_0' to an integer index
            ram[addr_in_0] <= data_in; 
        end
    end

    // Asynchronous Read Assignment
    assign data_out = ram[addr_in_1];

endmodule

module write_to_VRAM (
    input wire clk, reset,
    input wire [5:0] y0r, y1r, y2r, y3r,
    input wire [5:0] y0i, y1i, y2i, y3i,
    output reg [4:0] write_addr,
    output reg [6:0] write_data,
    output reg       write_enable
);

    reg [5:0] write_counter;
    reg signed [5:0] converter_in;
    wire [6:0] c_sign, c_tens, c_ones;

    // Internal ASCII Converter
    bin6_to_ascii_signed conv_inst (   
         .val_in(converter_in),          
         .char_sign(c_sign),             
         .char_tens(c_tens),             
         .char_ones(c_ones)              
    );

    always @(posedge clk) begin        
        if (reset) begin               
            write_counter <= 0;   
            write_enable  <= 0;  
        end else begin                  
            write_enable <= 1;    
            
            if (write_counter < 63)     
                write_counter <= write_counter + 1; 
            else                        
                write_counter <= 0;    
                
            // Mux Logic
            case (write_counter[5:2]) 
                    0: converter_in <= y0r;
                    1: converter_in <= y1r;
                    2: converter_in <= y2r;
                    3: converter_in <= y3r;
                    4: converter_in <= y0i;
                    5: converter_in <= y1i;
                    6: converter_in <= y2i;
                    7: converter_in <= y3i;
                    default: converter_in <= 0;
             endcase

             // Addressing Logic
             case (write_counter)
                  6'd0:  begin write_addr <= 0; write_data <= 7'h52;  end // 'R'
                  6'd1:  begin write_addr <= 1; write_data <= c_sign; end 
                  6'd2:  begin write_addr <= 2; write_data <= c_tens; end 
                  6'd3:  begin write_addr <= 3; write_data <= c_ones; end 
                  6'd4:  begin write_addr <= 4; write_data <= 7'h20;  end // Space
                  6'd5:  begin write_addr <= 5; write_data <= c_sign; end 
                  6'd6:  begin write_addr <= 6; write_data <= c_tens; end 
                  6'd7:  begin write_addr <= 7; write_data <= c_ones; end 
                  6'd8:  begin write_addr <= 8; write_data <= 7'h20;  end // Space
                  6'd9:  begin write_addr <= 9; write_data <= c_sign; end 
                  6'd10: begin write_addr <= 10; write_data <= c_tens; end 
                  6'd11: begin write_addr <= 11; write_data <= c_ones; end 
                  6'd12: begin write_addr <= 12; write_data <= 7'h20;  end // Space
                  6'd13: begin write_addr <= 13; write_data <= c_sign; end 
                  6'd14: begin write_addr <= 14; write_data <= c_tens; end 
                  6'd15: begin write_addr <= 15; write_data <= c_ones; end 
                  
                  // Line 2
                  6'd16: begin write_addr <= 16; write_data <= 7'h49;  end // 'I'
                  6'd17: begin write_addr <= 17; write_data <= c_sign; end 
                  6'd18: begin write_addr <= 18; write_data <= c_tens; end 
                  6'd19: begin write_addr <= 19; write_data <= c_ones; end 
                  6'd20: begin write_addr <= 20; write_data <= 7'h20;  end // Space 
                  6'd21: begin write_addr <= 21; write_data <= c_sign; end 
                  6'd22: begin write_addr <= 22; write_data <= c_tens; end 
                  6'd23: begin write_addr <= 23; write_data <= c_ones; end 
                  6'd24: begin write_addr <= 24; write_data <= 7'h20;  end // Space
                  6'd25: begin write_addr <= 25; write_data <= c_sign; end 
                  6'd26: begin write_addr <= 26; write_data <= c_tens; end 
                  6'd27: begin write_addr <= 27; write_data <= c_ones; end 
                  6'd28: begin write_addr <= 28; write_data <= 7'h20;  end // Space
                  6'd29: begin write_addr <= 29; write_data <= c_sign; end 
                  6'd30: begin write_addr <= 30; write_data <= c_tens; end 
                  6'd31: begin write_addr <= 31; write_data <= c_ones; end 
                  default: write_enable <= 0; 
            endcase
        end
    end
endmodule

module tick_generator (
    input wire  clk, reset,
    output reg  tick,       // Updates the FSM (Changes Data)
    output reg  slow_clk    // Drives the LCD ‘e' pin
);
    reg [19:0]  count;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            count    <= 0;
            tick     <= 0;
            slow_clk <= 0;
        end else begin
            // Timer: 0 to 100,000 (2ms total period)
            if (count == 100000) begin
                count <= 0;
                tick  <= 1'b1; // FSM updates Data HERE (Start of cycle)
            end else begin
                count <= count + 1;
                tick  <= 1'b0;
            end
            
            // -- LCD Enable Pulse Generation -- 
            // We pulse 'slow_clk' High only in the MIDDLE of the cycle.
            // This ensures Data is stable BEFORE ‘e' rises, and AFTER ‘e' falls.
            // Range: 30,000 to 70,000 (roughly middle 40% of the time)
            if (count > 30000 && count < 70000) 
                slow_clk <= 1'b1;
            else 
                slow_clk <= 1'b0;
        end
    end
endmodule


module lcd_driver (
    input  wire       reset, clk, enable, // 'enable' connects to the 'tick'
    input  wire [6:0] data_in,            // ASCII character read from VRAM
    output wire [4:0] address,            // Address pointer to VRAM
    output reg        e, rw, rs,          // LCD Control lines
    output reg        lcd_on, blon,       // Power controls
    output reg  [7:0] db                  // 8-bit Data bus to LCD
);

    // State Encoding 
    localparam [3:0]
        s_func_set   = 0, // Configure 8-bit mode, 2 lines
        s_disp_on    = 1, // Turn display ON
        s_clear      = 2, // Clear screen command
        s_entry_mode = 3, // Set auto-increment cursor mode
        s_line1_addr = 4, // Set cursor to start of Line 1
        s_write_l1   = 5, // Loop state: Write characters to Line 1
        s_line2_addr = 6, // Set cursor to start of Line 2
        s_write_l2   = 7; // Loop state: Write characters to Line 2

    reg [3:0] state, next_state;
    reg [4:0] addr_cnt;    // Internal counter for VRAM address (0-31)
    reg       inc_address; // Flag to tell the sequential block to increment addr_cnt

    // Map internal counter to output
    assign address = addr_cnt;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state    <= s_func_set;
            addr_cnt <= 5'b0;
        end else if (enable) begin 
            // Only update on the slow 'tick' (every 2ms)
            state <= next_state;
            
            // Increment VRAM address if the Combinational logic requests it
            if (inc_address) 
                addr_cnt <= addr_cnt + 1'b1;

            // --- ADDRESS MANAGEMENT LOGIC ---
            // If we are currently in the state setting up Line 1, 
            // reset the address pointer to 0 so we read from the start of VRAM.
            if (state == s_line1_addr) 
                addr_cnt <= 5'd0; 
            
            // If we are currently in the state setting up Line 2,
            // jump the address pointer to 16 (start of 2nd line in VRAM).
            if (state == s_line2_addr) 
                addr_cnt <= 5'd16; 
            
            // Safety reset during initialization
            if (state == s_func_set)
                addr_cnt <= 5'd0;
        end
    end

    always @(*) begin
        next_state = state; // Default: stay in current state
        inc_address = 0;    // Default: do not increment address

        case (state)
            // --- INITIALIZATION SEQUENCE ---
            // These states simply flow one after another to set up the LCD.
            s_func_set:   next_state = s_disp_on;
            s_disp_on:    next_state = s_clear;
            s_clear:      next_state = s_entry_mode;
            s_entry_mode: next_state = s_line1_addr;
            
            // --- WRITE LOOP ---
            s_line1_addr: next_state = s_write_l1; // Move to writing mode
            
            s_write_l1: begin
                if (addr_cnt == 5'd15) 
                    next_state = s_line2_addr; // Go to set up Line 2
                else begin
                    next_state = s_write_l1;   // Stay here
                    inc_address = 1;           // Increment address pointer for next char
                end
            end

            s_line2_addr: next_state = s_write_l2;

            s_write_l2: begin
                if (addr_cnt == 5'd31) 
                    next_state = s_line1_addr; // Loop back to start of Line 1 (Refresh)
                else begin
                    next_state = s_write_l2;   // Stay here
                    inc_address = 1;           // Increment address pointer
                end
            end
 
            default: next_state = s_func_set;
        endcase
    end

    localparam CMD_FUNC_SET   = 8'h38; // 8-bit bus, 2 display lines, 5x8 font
    localparam CMD_DISP_ON    = 8'h0C; // Display ON, Cursor OFF, Blink OFF
    localparam CMD_CLEAR      = 8'h01; // Clear Display
    localparam CMD_ENTRY_MODE = 8'h06; // Entry Mode: Increment cursor, no shift
    localparam CMD_LINE1      = 8'h80; // RAM Address for Line 1 (0x00)
    localparam CMD_LINE2      = 8'hC0; // RAM Address for Line 2 (0x40)

    always @(*) begin
        e = 1'b1;         // Note: We tie this High here, but in the top module 
                          // it is driven by 'slow_clk'.
        rw = 1'b0;        // 0 = Write Mode (We never read from the LCD)
        rs = 1'b0;        // 0 = Command Mode (Default)
        lcd_on = 1'b1;    // Main Power On
        blon = 1'b1;      // Backlight On
        db = 8'h00;       // Default Bus 0

        case (state)
            s_func_set:   db = CMD_FUNC_SET;
            s_disp_on:    db = CMD_DISP_ON;
            s_clear:      db = CMD_CLEAR;
            s_entry_mode: db = CMD_ENTRY_MODE;
            
            s_line1_addr: db = CMD_LINE1;  // Move cursor command
            s_write_l1: begin
                rs = 1'b1;                 // 1 = Data Mode (Sending ASCII, not commands)
                db = {1'b0, data_in};      // Pad 7-bit ASCII to 8-bit bus
            end
            
            s_line2_addr: db = CMD_LINE2;  // Move cursor command
            s_write_l2: begin
                rs = 1'b1;              // 1 = Data Mode
                db = {1'b0, data_in};   // Pad 7-bit ASCII
            end
        endcase
    end
endmodule


