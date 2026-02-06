module ep1_q3 (
    input  wire a,
    b,
    c,
    d,
    e,
    output wire x,
    y,
    z
);
  // Using explicit operators for clarity
  // use combinational logic - continuous assignment for simple stuff: many "assign" statements
  assign x = (~a & ~b & c & ~d & e) | (~a & ~b & c & d & ~e);
  assign y = (a & b & ~c & ~d & e) | (a & ~b & c & ~d & e);
  assign z = a & ~b;

endmodule
