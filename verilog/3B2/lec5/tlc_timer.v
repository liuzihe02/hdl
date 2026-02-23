`include "counter.v"
`include "bcd7seg.v"
`include "light.v"

// --- top-level module ---
module tlc_timer (
    input  wire       CLOCK_50,
    input  wire [1:0] KEY,
    output wire [5:0] LEDS,
    output wire [6:0] HEX0,
    output wire [6:0] HEX1
);

  wire    one_second;
  wire    state_event;
  wire    req_status;
  wire [1:0]  state;
  wire [7:0]  state_time;
  wire [3:0] BCD1, BCD0;
  wire [1:0] roll;

  // State machine
  FSM states (
      .clock      (CLOCK_50),
      .reset      (KEY[0]),
      .request    (KEY[1]),
      .tick       (one_second),
      .timer1     (BCD1),
      .timer0     (BCD0),
      .req_status (req_status),
      .state_event(state_event),
      .state_time (state_time),
      .state      (state)
  );

  // 1-second generator
  counter #(
      .n(26),
      .k(50000000)
  ) slow_clock (
      .clock   (CLOCK_50),
      .reset   (KEY[0]),
      .enable  (1'b1),
      .load   (1'b0),
      .start_time (26'd0),
      .count   (),
      .rollover  (one_second)
  );

  // Ones digit counter
  counter #(
      .n(4),
      .k(10)
  ) ones (
      .clock   (CLOCK_50),
      .reset   (KEY[0]),
      .enable  (one_second),
      .load   (state_event),
      .start_time (state_time[3:0]),
      .count   (BCD0),
      .rollover  ()
  );

  // Tens digit counter
  counter #(
      .n(4),
      .k(10)
  ) tens (
      .clock   (CLOCK_50),
      .reset   (KEY[0]),
      .enable  (one_second & (BCD0 == 4'd0)),
      .load   (state_event),
      .start_time (state_time[7:4]),
      .count   (BCD1),
      .rollover  ()
  );

  // Convert BCD to seven segment
  bcd7seg digit0 (
      .BCD  (BCD0),
      .state(state),
      .HEX  (HEX0)
  );

  bcd7seg digit1 (
      .BCD  (BCD1),
      .state(state),
      .HEX  (HEX1)
  );

  // Drive the LEDs
  light lights (
      .status(req_status),
      .state(state),
      .LED(LEDS)
  );

endmodule

// --- FSM module ---
module FSM (
    input  wire       clock,
    reset,
    request,
    input  wire       tick,
    input  wire [3:0] timer1,
    timer0,  // 4 bit per digit
    output wire       state_event,
    output wire       req_status,
    output wire [1:0] state,
    output wire [7:0] state_time    // combined digits
);

  // encode states G-"00", Y-"01", R-"10", G1-"11"
  reg       st_event;  // initialize to '0'
  reg       status;  // all SIGNALS to be used inside the PROCESS statement
  reg [1:0] state_s;  // starts G
  reg [7:0] st_time;

  reg       second_req;  // "remembered" when in G1: '0' - no memory

  always @(posedge clock or negedge reset) begin
    if (!reset) begin
      state_s    <= 2'b00;  // reset machine to initial values
      second_req <= 1'b0;
      status     <= 1'b0;
      st_event   <= 1'b1;
      st_time    <= 8'b00000000;
    end else begin
      st_event <= 1'b0;
      case (state_s)
        2'b00: begin  // G
          if (request == 1'b0 || second_req) begin
            state_s    <= 2'b01;  // Y
            st_time    <= 8'b00000101;  // 
            st_event   <= 1'b1;
            second_req <= 1'b0;
            status     <= 1'b1;  // WAIT indicator
          end
        end
        2'b01: begin  // Y
          if ({timer1, timer0} == 8'b00000000 && tick == 1'b1) begin  // i.e. (99) when end_time
            state_s  <= 2'b10;  // R
            st_time  <= 8'b00010000;  // (11)
            st_event <= 1'b1;
            status   <= 1'b0;
          end
        end
        2'b10: begin  // R
          if ({timer1, timer0} == 8'b00000000 && tick == 1'b1) begin
            state_s  <= 2'b11;  // G1
            st_time  <= 8'b00010000;  // (11)
            st_event <= 1'b1;
          end
        end
        2'b11: begin  // G1
          if ({timer1, timer0} == 8'b00000000 && tick == 1'b1) begin
            state_s  <= 2'b00;  // G
            st_event <= 1'b1;
          end else if (request == 1'b0) begin  // prioritize conditions
            second_req <= 1'b1;  // set flag here (requires a bistable)
            status     <= 1'b1;
          end
        end
      endcase
    end
  end

  assign state       = state_s;  // update outputs after process
  assign state_time  = st_time;
  assign state_event = st_event;
  assign req_status  = status;

endmodule


