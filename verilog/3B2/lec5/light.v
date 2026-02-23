// light.v — TLC LED driver
//   LED[5]   : WAIT indicator (request pending)
//   LED[4:0] : traffic light pattern per state
//              G  (00) → 10001  R=off  Y=off  G=on  | ped-R=off  ped-G=on
//              Y  (01) → 10010
//              R  (10) → 01100
//              G1 (11) → 10001  (same as G)
module light (
    input  wire       status,
    input  wire [1:0] state,
    output wire [5:0] LED
);

  assign LED[5] = status;
  assign LED[4:0] = (state == 2'b00) ? 5'b10001 :  // G
      (state == 2'b01) ? 5'b10010 :  // Y
      (state == 2'b10) ? 5'b01100 :  // R
      5'b10001;  // G1

endmodule
