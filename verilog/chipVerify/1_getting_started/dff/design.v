/*
 * D Flip-Flop with Synchronous Active-Low Reset
 * 
 * Functionality:
 * - Captures input 'd' on the rising edge of 'clk'
 * - Synchronous reset: Reset only takes effect at clock edges (not immediately)
 * - Active-low reset: When rstn=0, output is cleared
 * 
 * Operation: On each posedge clk:
 *   if (rstn == 0) → q = 0  (reset)
 *   if (rstn == 1) → q = d  (capture input)
 * 
 * Truth Table (evaluated at rising edge of clk):
 * +------+---+----------+------------------------------------+
 * | rstn | d | q (next) | Comments                           |
 * +------+---+----------+------------------------------------+
 * |  0   | X |    0     | Reset asserted, output cleared     |
 * |  1   | 0 |    0     | Capture d=0                        |
 * |  1   | 1 |    1     | Capture d=1                        |
 * +------+---+----------+------------------------------------+
 * 
 * Important Notes:
 * 1. Synchronous vs Asynchronous Reset:
 *    - This is SYNCHRONOUS (reset checked only at clock edge)
 *    - Asynchronous would be: always @(posedge clk or negedge rstn)
 * 
 * 2. Between clock edges: Output 'q' holds its value regardless of 
 *    changes in 'd' or 'rstn'
 * 
 * 3. Setup/Hold timing: Input 'd' must be stable before/after clock 
 *    edge for reliable capture
 * 
 * Use cases: Registers, pipeline stages, state storage in FSMs
 */

module dff (
    input clk,
    rstn,
    d,
    output reg q
);
  always @(posedge clk) q <= !rstn ? 0 : d;
endmodule
