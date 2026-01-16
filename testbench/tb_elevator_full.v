`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/16/2026 04:35:10 PM
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

module tb_elevator_full;

  // -----------------------------
  // DUT I/O
  // -----------------------------
  reg         clk;
  reg         reset;
  reg  [4:0]  floor_req;

  wire [2:0]  floor_pos;
  wire        door_open;
  wire        moving_up;
  wire        moving_dn;

  // Instantiate DUT
  elevator #(
    .FLOORS(5),
    .POS_W(3),
    .DOOR_CYCLES(3)
  ) dut (
    .clk(clk),
    .reset(reset),
    .floor_req(floor_req),
    .floor_pos(floor_pos),
    .door_open(door_open),
    .moving_up(moving_up),
    .moving_dn(moving_dn)
  );


  // Clock generation: 10ns period
  initial begin
    clk = 1'b0;
    forever #5 clk = ~clk;
  end

  // Utilities / tasks
  task clear_req;
  begin
    floor_req = 5'b00000;
  end
  endtask

  // Pulse a single floor button for N cycles
  task press_one;
    input integer floor;
    input integer cycles; // number of full clock cycles
    integer c;
  begin
    if (floor < 0 || floor > 4) begin
      $display("[%0t] ERROR: invalid floor %0d", $time, floor);
    end else begin
      $display("[%0t] Press ONE floor=%0d for %0d cycle(s)", $time, floor, cycles);
      floor_req = 5'b00000;
      floor_req[floor] = 1'b1;
      for (c = 0; c < cycles; c = c + 1) begin
        @(posedge clk);
      end
      floor_req = 5'b00000;
    end
  end
  endtask

  // Pulse multiple floors (mask) for N cycles
  task press_multi;
    input [4:0] mask;
    input integer cycles;
    integer c;
  begin
    $display("[%0t] Press MULTI mask=0x%0h (%b) for %0d cycle(s)", $time, mask, mask, cycles);
    floor_req = mask;
    for (c = 0; c < cycles; c = c + 1) begin
      @(posedge clk);
    end
    floor_req = 5'b00000;
  end
  endtask

  // Press one floor then immediately press another (back-to-back)
  task press_back_to_back;
    input integer floor_a;
    input integer floor_b;
  begin
    $display("[%0t] Back-to-back: A=%0d then B=%0d (each 1 cycle)", $time, floor_a, floor_b);
    press_one(floor_a, 1);
    // no extra delay, press next right away
    press_one(floor_b, 1);
  end
  endtask

  // Wait some number of cycles (helper)
  task wait_cycles;
    input integer cycles;
    integer c;
  begin
    for (c = 0; c < cycles; c = c + 1) begin
      @(posedge clk);
    end
  end
  endtask

  // Main stimulus
  initial begin
    // VCD for GTKWave/Vivado
    $dumpfile("tb_elevator_full.vcd");
    $dumpvars(0, tb_elevator_full);

    // Init
    reset     = 1'b1;
    floor_req = 5'b00000;

    // Hold reset 2 cycles
    wait_cycles(2);
    reset = 1'b0;
    $display("[%0t] Release reset", $time);

    // ==========================================
    // CASE 1: Single request 
    // ==========================================
    // From floor 0, request floor 3
    press_one(3, 1);
    // allow system to finish serving (enough time)
    wait_cycles(30);

    // ==========================================
    // CASE 2: Multi-hot simultaneous requests
    // ==========================================
    // Request floors 4 and 1 together: 10010 (0x12)
    // Expect: choose direction based on above/below and serve along the path
    press_multi(5'b10010, 1);
    wait_cycles(40);

    // Another multi-hot: floors 2,3,4 together: 11100 (0x1C)
    press_multi(5'b11100, 1);
    wait_cycles(50);

    // ==========================================
    // CASE 3: Back-to-back requests
    // ==========================================
    // Example: press 2 then 0 in consecutive cycles
    press_back_to_back(2, 0);
    wait_cycles(40);

    // Another back-to-back: press 4 then 1
    press_back_to_back(4, 1);
    wait_cycles(60);

    // ==========================================
    // Extra: mixed stress 
    // ==========================================
    // Press multi, then immediately another multi next cycle
    $display("[%0t] Mixed stress: multi then multi next cycle", $time);
    press_multi(5'b10100, 1); // {4,2}
    press_multi(5'b01010, 1); // {3,1} right after
    wait_cycles(80);

    $display("[%0t] DONE. Finish simulation.", $time);
    #20;
    $finish;
  end

endmodule



