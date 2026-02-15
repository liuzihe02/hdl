/*
A JK flip flop is one of the many types of flops used to store values and has two data inputs j and k along with one for reset rstn and another for clock clk. The truth table for a JK flop is shown below and is typically implemented using NAND gates.

| rstn | j | k | q            | Comments                                                  |
|------|---|---|--------------|-----------------------------------------------------------|
| 0    | 0 | 0 | 0            | When reset is asserted, output is always zero             |
| 1    | 0 | 0 | Hold value   | When both j and k are 0, output remains the same as before|
| 1    | 0 | 1 | 1            | When k=1, output becomes 1                                |
| 1    | 1 | 0 | 0            | When k=0, output becomes 0                                |
| 1    | 1 | 1 | Toggle value | When j=1,k=1 output toggles current value                 |

Hold (J=0, K=0): Maintains current value
Set (J=1, K=0): Output becomes 1
Reset (J=0, K=1): Output becomes 0
Toggle (J=1, K=1): Output flips to opposite value
*/
module jk_ff (
    input    j,     // Input J
    input    k,     // Input K
    input    rstn,   // Active-low async reset
    input    clk,    // Input clk
    output reg q
);  // Output Q

  always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
      q <= 0;
    end else begin
      q <= (j & ~q) | (~k & q);
    end
  end
endmodule
