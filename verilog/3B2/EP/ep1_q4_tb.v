module ep1_q4_tb;
  reg [3:0] a;
  wire [6:0] dl, dr;

  ep1_q4 uut (
      .a (a),
      .dl(dl),
      .dr(dr)
  );

  integer i;
  initial begin
    $display("a\t| tens seg\t| units seg");
    $display("------------------------------");
    for (i = 0; i <= 15; i = i + 1) begin
      a = i;
      #10;
      $display("%0d\t| %b\t| %b", i, dl, dr);
    end
    $finish;
  end
endmodule
