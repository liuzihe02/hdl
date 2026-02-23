// ep2_q3_tb.v — Testbench for ep2_q3 statistics counters
//
// Strategy:
//   The stats logic (req_received/executed/stored) lives entirely in the FSM,
//   so we test it by forcing the FSM's internal state register to put the design
//   in each state of interest (G, G1, Y, R) and pressing the button.
//   This avoids having to run through the full 50 MHz timer countdown.
//
// Test cases:
//   T1: reset      → all stats zero
//   T2: press in G → received=1  executed=1  stored=0   (immediate)
//   T3: press in G1 (fresh) → received=2  executed=1  stored=1  (deferred)
//   T4: press in G1 (second_req already set) → received=3  stored stays 1  (dup ignored)
//   T5: press in Y  → received=4  (lost, neither executed nor stored)
//   T6: press in R  → received=5  (lost)
//   T7: second reset → all stats zero again

`timescale 1ns / 1ps

module ep2_q3_tb;

  reg        clk;
  reg  [1:0] KEY;
  wire [5:0] LEDS;
  wire [6:0] HEX0, HEX1;
  wire [7:0] stat_received, stat_executed, stat_stored;

  integer errors;

  ep2_q3 dut (
      .CLOCK_50     (clk),
      .KEY          (KEY),
      .LEDS         (LEDS),
      .HEX0         (HEX0),
      .HEX1         (HEX1),
      .stat_received(stat_received),
      .stat_executed(stat_executed),
      .stat_stored  (stat_stored)
  );

  // 50 MHz clock (20 ns period)
  initial clk = 0;
  always #10 clk = ~clk;

  // Apply active-low reset for 2 cycles then release.
  task do_reset;
    begin
      KEY    = 2'b11;
      KEY[0] = 0;
      repeat (2) @(posedge clk);
      KEY[0] = 1;
      @(posedge clk);
    end
  endtask

  // Press KEY[1] (active-low) for exactly one clock cycle then release.
  // req_new fires on the posedge while the button is low.
  task press_button;
    begin
      KEY[1] = 0;
      @(posedge clk);  // req_new=1, stat counters increment on this edge
      KEY[1] = 1;
      @(posedge clk);  // prev_request restores to 1, ready for next press
    end
  endtask

  // Check all three stat counters and report pass/fail.
  task check;
    input [7:0]       exp_rcv, exp_exec, exp_stor;
    input [8*20-1:0]  label;
    begin
      #1;  // combinational settle
      if (stat_received !== exp_rcv ||
          stat_executed !== exp_exec ||
          stat_stored   !== exp_stor) begin
        $display("FAIL [%s]: rcv=%0d(exp %0d)  exec=%0d(exp %0d)  stor=%0d(exp %0d)",
                 label,
                 stat_received, exp_rcv,
                 stat_executed, exp_exec,
                 stat_stored,   exp_stor);
        errors = errors + 1;
      end else begin
        $display("PASS [%s]: rcv=%0d  exec=%0d  stor=%0d",
                 label, stat_received, stat_executed, stat_stored);
      end
    end
  endtask

  initial begin
    errors = 0;
    KEY    = 2'b11;

    // T1: reset clears all counters
    do_reset;
    check(0, 0, 0, "T1 reset");

    // T2: press while in G (state=00, after reset) → executed immediately
    press_button;
    check(1, 1, 0, "T2 G press");

    // T3: press while in G1 with second_req clear → stored
    force dut.states.state_s   = 2'b11;
    force dut.states.second_req = 1'b0;
    @(posedge clk);
    press_button;
    release dut.states.state_s;
    release dut.states.second_req;
    check(2, 1, 1, "T3 G1 press");

    // T4: press while in G1 with second_req already set → only received increments
    force dut.states.state_s   = 2'b11;
    force dut.states.second_req = 1'b1;
    @(posedge clk);
    press_button;
    release dut.states.state_s;
    release dut.states.second_req;
    check(3, 1, 1, "T4 G1 dup");

    // T5: press during Y → lost (neither executed nor stored)
    force dut.states.state_s = 2'b01;
    @(posedge clk);
    press_button;
    release dut.states.state_s;
    check(4, 1, 1, "T5 Y lost");

    // T6: press during R → lost
    force dut.states.state_s = 2'b10;
    @(posedge clk);
    press_button;
    release dut.states.state_s;
    check(5, 1, 1, "T6 R lost");

    // T7: second reset clears everything
    do_reset;
    check(0, 0, 0, "T7 re-reset");

    if (errors == 0) $display("\nAll tests PASSED.");
    else             $display("\n%0d test(s) FAILED.", errors);

    $finish;
  end

endmodule
