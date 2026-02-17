`timescale 1ns / 1ps

module ep1_q3_tb;
  // Inputs
  reg a, b, c, d, e;

  // Outputs
  wire x, y, z;

  // Instantiate the design under test
  ep1_q3 dut (
      .a(a),
      .b(b),
      .c(c),
      .d(d),
      .e(e),
      .x(x),
      .y(y),
      .z(z)
  );

  // Test stimulus
  initial begin
    $dumpfile("ep1_q3.vcd");
    $dumpvars(0, ep1_q3_tb);

    // Header
    $display("Time\t a b c d e | x y z");
    $display("-----------------------------");

    // Test all 32 combinations (2^5)
    {a, b, c, d, e} = 5'b00000;
    repeat (32) begin
      #10;
      $display("%0t\t %b %b %b %b %b | %b %b %b", $time, a, b, c, d, e, x, y, z);
      {a, b, c, d, e} = {a, b, c, d, e} + 1;
    end

    $display("\nSimulation complete!");
    $finish;
  end

endmodule
