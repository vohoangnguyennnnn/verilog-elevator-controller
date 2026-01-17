`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/17/2026 06:22:28 PM
// Design Name: 
// Module Name: elevator_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module elevator_tb;

  //====================
  // Parameters
  //====================
  localparam integer FLOORS      = 5;
  localparam integer POS_W       = 3;
  localparam integer DOOR_CYCLES = 3;

  //====================
  // DUT I/O
  //====================
  reg                   clk;
  reg                   reset;
  reg  [FLOORS-1:0]      floor_req;
  wire [POS_W-1:0]       floor_pos;
  wire                  door_open;
  wire                  moving_up;
  wire                  moving_dn;
  wire [POS_W:0] floor_disp; 
  
  assign floor_disp = floor_pos + 1'b1;

  //====================
  // Instantiate DUT
  //====================
  elevator #(
    .FLOORS(FLOORS),
    .POS_W(POS_W),
    .DOOR_CYCLES(DOOR_CYCLES)
  ) dut (
    .clk(clk),
    .reset(reset),
    .floor_req(floor_req),
    .floor_pos(floor_pos),
    .door_open(door_open),
    .moving_up(moving_up),
    .moving_dn(moving_dn)
  );

  //====================
  // Clock gen: 10ns period
  //====================
  initial clk = 1'b0;
  always #5 clk = ~clk;

  //====================
  // Helpers
  //====================
  task press_floor(input integer f);
    begin
      if (f < 0 || f >= FLOORS) begin
        $display("[%0t] ERROR: invalid floor %0d", $time, f);
      end else begin
        // pulse one clock long
        @(negedge clk);
        floor_req = {FLOORS{1'b0}};
        floor_req[f] = 1'b1;
        $display("[%0t] Press floor %0d (mask=%b)", $time, f, floor_req);
        @(negedge clk);
        floor_req = {FLOORS{1'b0}};
      end
    end
  endtask

  task press_mask(input [FLOORS-1:0] mask);
    begin
      @(negedge clk);
      floor_req = mask;
      $display("[%0t] Press mask %b", $time, mask);
      @(negedge clk);
      floor_req = {FLOORS{1'b0}};
    end
  endtask

  task wait_cycles(input integer n);
    integer k;
    begin
      for (k = 0; k < n; k = k + 1) begin
        @(posedge clk);
      end
    end
  endtask

  // nice waveform log every posedge
  always @(posedge clk) begin
    $display("[%0t] Floor %0d door=%b up=%b dn=%b",
         $time, floor_disp, door_open, moving_up, moving_dn);
  end

  //====================
  // Stimulus
  //====================
  initial begin
    // init
    floor_req = {FLOORS{1'b0}};
    reset     = 1'b1;

    // hold reset for a bit
    wait_cycles(3);
    reset = 1'b0;
    $display("=== Release reset ===");

    // ------------------------------------------------------------
    // CASE 1: press a single floor (go up from 0 to 3)
    // ------------------------------------------------------------
    press_floor(3);
    wait_cycles(12);

    // ------------------------------------------------------------
    // CASE 2: press multiple floors at once (1 and 4)
    // ------------------------------------------------------------
    press_mask( (1<<1) | (1<<4) );
    wait_cycles(20);

    // ------------------------------------------------------------
    // CASE 3: press while elevator is moving (dynamic requests)
    // - request 2 first, then while moving, request 0 and 4
    // ------------------------------------------------------------
    press_floor(2);
    wait_cycles(2);
    press_mask( (1<<0) | (1<<4) );
    wait_cycles(25);

    // ------------------------------------------------------------
    // CASE 4: press current floor (should open door immediately when idle/arrive)
    // ------------------------------------------------------------
    wait_cycles(2);
    press_floor(floor_pos);
    wait_cycles(10);

    // ------------------------------------------------------------
    // CASE 5: spam same floor multiple times (should not break)
    // ------------------------------------------------------------
    press_floor(1);
    press_floor(1);
    press_floor(1);
    wait_cycles(20);

    $display("END SIM");
    $finish;
  end

endmodule
