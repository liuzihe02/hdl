`timescale 1ns / 1ps

module ep1_q6_tb;
  // Inputs
  reg clk;
  reg rst_n;

  // Outputs
  wire [2:0] count;

  // Expected Gray code sequence
  reg [2:0] expected_sequence[0:7];
  integer i;
  integer pass_count, fail_count;

  // Instantiate the design under test
  ep1_q6 dut (
      .clk  (clk),
      .rst_n(rst_n),
      .count(count)
  );

  // Clock generation: 10ns period (100MHz)
  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  // Test stimulus
  initial begin
    $dumpfile("ep1_q6.vcd");
    $dumpvars(0, ep1_q6_tb);

    // Initialize expected sequence
    expected_sequence[0] = 3'b000;  // State 1
    expected_sequence[1] = 3'b001;  // State 2
    expected_sequence[2] = 3'b011;  // State 3
    expected_sequence[3] = 3'b010;  // State 4
    expected_sequence[4] = 3'b110;  // State 5
    expected_sequence[5] = 3'b111;  // State 6
    expected_sequence[6] = 3'b101;  // State 7
    expected_sequence[7] = 3'b100;  // State 8

    pass_count = 0;
    fail_count = 0;

    // Apply reset - release BETWEEN clock edges
    rst_n = 0;
    #12;  // Release at time 12 (between clock edges at 5 and 15)
    rst_n = 1;
    #6;  // Wait until time 18 (after clock edge at 15)

    $display("\nGray Code Counter Test");
    $display("Time\t State | Count | Expected | Status");
    $display("------------------------------------------------");

    // Test 16 states (2 complete cycles)
    for (i = 0; i < 16; i = i + 1) begin
      #1;  // Small delay for output to stabilize

      if (count === expected_sequence[i%8]) begin
        $display("%0t\t %0d     | %b   | %b        | PASS", $time, (i % 8) + 1, count,
                 expected_sequence[i%8]);
        pass_count = pass_count + 1;
      end else begin
        $display("%0t\t %0d     | %b   | %b        | FAIL", $time, (i % 8) + 1, count,
                 expected_sequence[i%8]);
        fail_count = fail_count + 1;
      end

      @(posedge clk);  // Wait for next clock edge
    end

    // Summary
    $display("\n========================================");
    $display("Test Summary:");
    $display("  PASSED: %0d/16", pass_count);
    $display("  FAILED: %0d/16", fail_count);
    $display("========================================");

    if (fail_count == 0) $display("✓ ALL TESTS PASSED!");
    else $display("✗ SOME TESTS FAILED!");

    #20;
    $finish;
  end

endmodule
