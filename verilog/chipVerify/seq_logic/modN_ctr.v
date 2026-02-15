/*
 * Modulo-N Counter with Synchronous Active-Low Reset
 * 
 * Functionality:
 * - Counts from 0 to N-1, then wraps back to 0
 * - Increments by 1 on each rising clock edge
 * - Synchronous active-low reset clears counter to 0
 * 
 * Parameters:
 * - N     : Modulus (counter counts 0 to N-1)
 * - WIDTH : Bit width of counter output (must be >= log2(N))
 * 
 * Operation: On each posedge clk:
 *   if (!rstn)           → out = 0       (reset)
 *   else if (out == N-1) → out = 0       (wrap around)
 *   else                 → out = out + 1 (increment)
 * 
 * Example (N=10, WIDTH=4):
 *   Count sequence: 0 → 1 → 2 → ... → 8 → 9 → 0 → 1 → ...
 * 
 * State Diagram:
 *   0 → 1 → 2 → ... → (N-2) → (N-1) → 0 (wraps)
 *   ↑___________________________________|
 * 
 * Truth Table (at posedge clk):
 * +------+-----------+-------------+---------------------------+
 * | rstn | out (cur) | out (next)  | Comments                  |
 * +------+-----------+-------------+---------------------------+
 * |  0   |    X      |      0      | Reset: clear to 0         |
 * |  1   |   0..N-2  |  out + 1    | Increment                 |
 * |  1   |   N-1     |      0      | Wrap around to 0          |
 * +------+-----------+-------------+---------------------------+
 * 
 * Important Notes:
 * 1. WIDTH must be large enough to represent N-1
 *    Required: WIDTH >= ceil(log2(N))
 *    Example: N=10 requires WIDTH >= 4 (since 2^4 = 16 > 10)
 * 
 * 2. If WIDTH is too small, counter will overflow incorrectly
 * 
 * 3. This is a synchronous counter (all bits change on same clock)
 * 
 * 4. For power of 2 counts (N = 2^k), counter naturally wraps
 *    without explicit comparison
 * 
 * Use cases: 
 * - Clock dividers (MOD-N creates clk/N frequency)
 * - State machines with cyclic states
 * - Time slot generators
 * - Frequency counters
 */

module modN_ctr #(
    parameter N = 10,
    parameter WIDTH = 4
) (
    input clk,
    input rstn,
    output reg [WIDTH-1:0] out
);

  always @(posedge clk) begin
    if (!rstn) begin
      out <= 0;
    end else begin
      if (out == N - 1) out <= 0;
      else out <= out + 1;
    end
  end
endmodule
