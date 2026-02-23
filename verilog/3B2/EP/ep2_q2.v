// ep2_q2.v — Successive 0-9 digit display on 7-segment display
//
// Circuit Design:
// ===============
// This module displays digits 0 through 9 on a 7-segment display, cycling
// through each digit approximately once per second using a 50 MHz clock.
//
// Architecture (two-counter approach, as shown in Figure 1):
//
//   50 MHz Clock
//       |
//       v
//   +-----------+
//   | 26-bit    |  (large counter, counts 0 to 49,999,999)
//   | counter   |
//   +-----+-----+
//         |
//         v (rollover produces enable pulse, once per second)
//       +---------+
//   E-->| 4-bit   |
//       | BCD     |  (small counter, counts 0 to 9)
//       | counter |
//       +----+----+
//            |
//            v [3:0] bcd
//       +----------+
//       | bcd7seg  |  (combinational BCD-to-7seg decoder)
//       +----+-----+
//            |
//            v [0:6] leds (active-low 7-segment output)
//
// Large counter (26 bits):
//   - 50 MHz means 50,000,000 clock cycles per second.
//   - The counter counts from 0 to 49,999,999 (needs 26 bits since
//     2^26 = 67,108,864 > 50,000,000).
//   - When the counter reaches 49,999,999, it wraps back to 0 and
//     asserts an enable pulse for exactly one clock cycle.
//
// Small counter (4-bit BCD):
//   - Increments by 1 on each enable pulse (i.e. once per second).
//   - Wraps from 9 back to 0.
//
// bcd7seg decoder:
//   - Combinational logic that maps the 4-bit BCD value to the 7-segment
//     LED pattern (active-low, common-anode display assumed).
//   - Instantiated from lec3/bcd7seg.v.
//
// All flip-flops are clocked directly by the 50 MHz clock (no derived clocks).

module ep2_q2 (
    input CLOCK_50,
    output [0:6] HEX0
);

  // --- Large counter: generates a 1-second enable pulse ---
  // Initial values: on Intel FPGAs, registers power up to 0.
  // The initial blocks also allow correct simulation in Icarus Verilog.
  reg  [25:0] tick_counter = 0;
  wire        tick;

  assign tick = (tick_counter == 26'd49_999_999);

  always @(posedge CLOCK_50) begin
    //reset mini tick counter
    if (tick) tick_counter <= 26'd0;
    //increment1
    else
      tick_counter <= tick_counter + 26'd1;
  end

  // --- Small counter: 4-bit BCD counter (0-9), increments once/sec ---
  reg [3:0] bcd = 0;

  always @(posedge CLOCK_50) begin
    //increment display digit
    if (tick) begin
      if (bcd == 4'd9) bcd <= 4'd0;
      else bcd <= bcd + 4'd1;
    end
  end

  // --- 7-segment decoder from lecture 3, compile together ---
  bcd7seg seg0 (
      .bcd (bcd),
      .leds(HEX0)
  );

endmodule
