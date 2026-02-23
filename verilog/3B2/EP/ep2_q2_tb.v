// ep2_q2_tb.v — Testbench for ep2_q2 (successive 0-9 on 7-segment display)
//
// Strategy:
//   The real design uses a 50,000,000-cycle tick counter, which is far too slow
//   to simulate in full. Instead we override the tick_counter threshold by
//   forcing the counter close to rollover, so each "second" takes only a few
//   clock cycles in simulation. This lets us verify the full 0-9 cycling
//   quickly.

`timescale 1ns / 1ps

module ep2_q2_tb;

    reg         clk;
    wire [0:6]  HEX0;

    // Instantiate DUT
    ep2_q2 dut (
        .CLOCK_50 (clk),
        .HEX0     (HEX0)
    );

    // 50 MHz clock: 20 ns period
    initial clk = 0;
    always #10 clk = ~clk;

    // Expected 7-seg patterns (active-low, [0:6] ordering) from bcd7seg
    reg [0:6] expected [0:9];
    initial begin
        expected[0] = 7'b0000001;
        expected[1] = 7'b1001111;
        expected[2] = 7'b0010010;
        expected[3] = 7'b0000110;
        expected[4] = 7'b1001100;
        expected[5] = 7'b0100100;
        expected[6] = 7'b0100000;
        expected[7] = 7'b0001111;
        expected[8] = 7'b0000000;
        expected[9] = 7'b0000100;
    end

    integer i;
    integer errors;

    initial begin
        errors = 0;

        // Wait a few cycles for initial state to settle
        @(posedge clk);
        @(posedge clk);

        // Verify digit 0 is displayed initially (counters start at 0)
        #1;
        if (HEX0 !== expected[0]) begin
            $display("FAIL: initial display expected %b (digit 0), got %b",
                     expected[0], HEX0);
            errors = errors + 1;
        end else begin
            $display("PASS: digit 0 displayed correctly: %b", HEX0);
        end

        // Fast-forward through each digit 1 through 9, then wrap to 0
        for (i = 1; i <= 10; i = i + 1) begin
            // Force tick_counter to one below rollover, then release before
            // the next posedge so the counter can increment naturally.
            force dut.tick_counter = 26'd49_999_998;
            @(posedge clk);   // tick_counter tries to update but is forced
            release dut.tick_counter;
            // Now tick_counter holds 49,999,998. On next posedge it increments
            // to 49,999,999, making tick = 1 combinationally.
            @(posedge clk);   // tick_counter -> 49,999,999, tick = 1
            @(posedge clk);   // bcd increments (tick was 1), tick_counter -> 0
            #1;
            if (HEX0 !== expected[i % 10]) begin
                $display("FAIL: digit %0d expected %b, got %b",
                         i % 10, expected[i % 10], HEX0);
                errors = errors + 1;
            end else begin
                $display("PASS: digit %0d displayed correctly: %b",
                         i % 10, HEX0);
            end
        end

        // Summary
        if (errors == 0)
            $display("\nAll tests PASSED.");
        else
            $display("\n%0d test(s) FAILED.", errors);

        $finish;
    end

endmodule
