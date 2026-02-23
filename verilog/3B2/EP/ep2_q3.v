// ep2_q3.v — TLC timer with request statistics counters
//
// Adds three 8-bit up-counters to tlc_timer (lec5) to distinguish:
//   stat_received — every new button press        (falling edge on KEY[1])
//   stat_executed — presses acted on immediately  (press while in state G)
//   stat_stored   — presses deferred              (press while in state G1,
//                                                  sets second_req flag)
//
// Note: presses during Y or R are received but silently lost.
//   stat_received = stat_executed + stat_stored + lost
//
// Changes from lec5/tlc_timer.v:
//   1. tlc_timer: 3 new output ports + 3 stat_counter instances
//   2. FSM: edge-detect prev_request; 3 new combinational output signals
//   3. stat_counter: new reusable up-counter module

`include "../lec5/counter.v"
`include "../lec5/bcd7seg.v"
`include "../lec5/light.v"
`include "../lec5/stat_counter.v"

// --- top-level module ---
module ep2_q3 (
    input  wire       CLOCK_50,
    input  wire [1:0] KEY,
    output wire [5:0] LEDS,
    output wire [6:0] HEX0,
    output wire [6:0] HEX1,
    output wire [7:0] stat_received,
    output wire [7:0] stat_executed,
    output wire [7:0] stat_stored
);

  wire one_second;
  wire state_event;
  wire req_status;
  wire [1:0] state;
  wire [7:0] state_time;
  wire [3:0] BCD1, BCD0;
  wire       req_received, req_executed, req_stored;

  FSM states (
      .clock        (CLOCK_50),
      .reset        (KEY[0]),
      .request      (KEY[1]),
      .tick         (one_second),
      .timer1       (BCD1),
      .timer0       (BCD0),
      .req_status   (req_status),
      .state_event  (state_event),
      .state_time   (state_time),
      .state        (state),
      .req_received (req_received),
      .req_executed (req_executed),
      .req_stored   (req_stored)
  );

  counter #(.n(26), .k(50000000)) slow_clock (
      .clock(CLOCK_50), .reset(KEY[0]), .enable(1'b1), .load(1'b0),
      .start_time(26'd0), .count(), .rollover(one_second)
  );

  counter #(.n(4), .k(10)) ones (
      .clock(CLOCK_50), .reset(KEY[0]), .enable(one_second),
      .load(state_event), .start_time(state_time[3:0]), .count(BCD0), .rollover()
  );

  counter #(.n(4), .k(10)) tens (
      .clock(CLOCK_50), .reset(KEY[0]), .enable(one_second & (BCD0 == 4'd0)),
      .load(state_event), .start_time(state_time[7:4]), .count(BCD1), .rollover()
  );

  bcd7seg digit0 (.BCD(BCD0), .state(state), .HEX(HEX0));
  bcd7seg digit1 (.BCD(BCD1), .state(state), .HEX(HEX1));
  light   lights (.status(req_status), .state(state), .LED(LEDS));

  stat_counter #(.N(8)) cnt_received (
      .clock(CLOCK_50), .reset(KEY[0]), .inc(req_received), .count(stat_received)
  );
  stat_counter #(.N(8)) cnt_executed (
      .clock(CLOCK_50), .reset(KEY[0]), .inc(req_executed), .count(stat_executed)
  );
  stat_counter #(.N(8)) cnt_stored (
      .clock(CLOCK_50), .reset(KEY[0]), .inc(req_stored),   .count(stat_stored)
  );

endmodule

// --- FSM module (modified: adds req_received, req_executed, req_stored) ---
module FSM (
    input  wire       clock,
    reset,
    request,
    input  wire       tick,
    input  wire [3:0] timer1,
    timer0,
    output wire       state_event,
    output wire       req_status,
    output wire [1:0] state,
    output wire [7:0] state_time,
    output wire       req_received,  // pulse: new button press detected
    output wire       req_executed,  // pulse: press immediately acted on (in G)
    output wire       req_stored     // pulse: press deferred (in G1, !second_req)
);

  reg       st_event;
  reg       status;
  reg [1:0] state_s;
  reg [7:0] st_time;
  reg       second_req;

  // Edge detection: 1-cycle pulse on falling edge of request (KEY active-low)
  reg  prev_request;
  wire req_new = (request == 1'b0) && (prev_request == 1'b1);

  always @(posedge clock or negedge reset) begin
    if (!reset) begin
      state_s      <= 2'b00;
      second_req   <= 1'b0;
      status       <= 1'b0;
      st_event     <= 1'b1;
      st_time      <= 8'b00000000;
      prev_request <= 1'b1;  // released state is high (active-low button)
    end else begin
      prev_request <= request;
      st_event <= 1'b0;
      case (state_s)
        2'b00: begin  // G
          if (request == 1'b0 || second_req) begin
            state_s    <= 2'b01;  // Y
            st_time    <= 8'b00000101;
            st_event   <= 1'b1;
            second_req <= 1'b0;
            status     <= 1'b1;
          end
        end
        2'b01: begin  // Y
          if ({timer1, timer0} == 8'b00000000 && tick == 1'b1) begin
            state_s  <= 2'b10;  // R
            st_time  <= 8'b00010000;
            st_event <= 1'b1;
            status   <= 1'b0;
          end
        end
        2'b10: begin  // R
          if ({timer1, timer0} == 8'b00000000 && tick == 1'b1) begin
            state_s  <= 2'b11;  // G1
            st_time  <= 8'b00010000;
            st_event <= 1'b1;
          end
        end
        2'b11: begin  // G1
          if ({timer1, timer0} == 8'b00000000 && tick == 1'b1) begin
            state_s  <= 2'b00;  // G
            st_event <= 1'b1;
          end else if (request == 1'b0) begin
            second_req <= 1'b1;
            status     <= 1'b1;
          end
        end
        default: ;  // unreachable (state_s is 2-bit, all values covered)
      endcase
    end
  end

  assign state        = state_s;
  assign state_time   = st_time;
  assign state_event  = st_event;
  assign req_status   = status;
  assign req_received = req_new;
  assign req_executed = req_new && (state_s == 2'b00);
  assign req_stored   = req_new && (state_s == 2'b11) && !second_req;

endmodule

