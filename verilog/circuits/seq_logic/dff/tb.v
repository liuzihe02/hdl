module tb;
  reg clk = 0, rstn = 0, d = 0;
  wire q;

  dff uut (
      clk,
      rstn,
      d,
      q
  );  // Instantiate DUT

  always #5 clk = ~clk;
  initial begin
    $dumpfile("dump.vcd");
    $dumpvars;
    #10 rstn = 1;
    #10 d = 1;
    #20 $finish;
  end
endmodule
