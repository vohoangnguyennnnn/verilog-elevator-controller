`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/16/2026 04:34:38 PM
// Design Name: 
// Module Name: elevator
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


module elevator #(
    parameter integer FLOORS      = 5,
    parameter integer POS_W       = 3,
    parameter integer DOOR_CYCLES = 3
)(
    input  wire                 clk,
    input  wire                 reset,

    input  wire [FLOORS-1:0]    floor_req,   // bitmask requests
    output reg  [POS_W-1:0]     floor_pos,   // current floor index
    output reg                  door_open,   // door open indicator
    output reg                  moving_up,
    output reg                  moving_dn
);

    // State encoding
    localparam [2:0] STATE_IDLE = 3'd0; 
    localparam [2:0] STATE_UP   = 3'd1;
    localparam [2:0] STATE_DN   = 3'd2;
    localparam [2:0] STATE_STOP = 3'd3;
    localparam [2:0] STATE_DOOR = 3'd4;

    reg [2:0] state_q, state_d;

    // pending requests register
    reg [FLOORS-1:0] req_pending_q, req_pending_d;

    // door open timer
    reg [7:0] door_cnt_q, door_cnt_d;

    // direction preference when both above & below exist
    reg dir_up_q, dir_up_d;  // 1=up, 0=down

    // floor position next
    reg [POS_W-1:0] floor_pos_d;

    // scan helpers
    reg req_above, req_below;

    // Combinational scan: find requests above/below
    // (computed from a given pending mask)
    task automatic scan_requests;
        input  [FLOORS-1:0] pending;
        input  [POS_W-1:0]  cur;
        output reg          has_above;
        output reg          has_below;
        integer k;
        begin
            has_above  = 1'b0;
            has_below  = 1'b0;

            // above/below existence
            for (k = 0; k < FLOORS; k = k + 1) begin
                if ((k > cur) && pending[k]) has_above = 1'b1;
                if ((k < cur) && pending[k]) has_below = 1'b1;
            end
        end
    endtask


    // Next-state / next-data logic
    always @(*) begin
        // default keep
        state_d       = state_q;
        floor_pos_d   = floor_pos;
        door_cnt_d    = door_cnt_q;
        dir_up_d      = dir_up_q;

        // accumulate new requests each cycle
        req_pending_d = req_pending_q | floor_req;

        // if we are in DOOR state, we clear current floor request (keeps door stable)
        if (state_q == STATE_DOOR) begin
            req_pending_d[floor_pos] = 1'b0;
        end

        // compute above/below based on req_pending_d (already includes new requests,
        // and already cleared current floor if in DOOR)
        scan_requests(req_pending_d, floor_pos, req_above, req_below);

        case (state_q)
            STATE_IDLE: begin
                door_cnt_d = 8'd0;

                // if request at current floor -> open door
                if (req_pending_d[floor_pos]) begin
                    state_d    = STATE_DOOR;
                    door_cnt_d = 8'd0;
                end
                else if (req_above && !req_below) begin
                    state_d  = STATE_UP;
                    dir_up_d = 1'b1;
                end
                else if (!req_above && req_below) begin
                    state_d  = STATE_DN;
                    dir_up_d = 1'b0;
                end
                else if (req_above && req_below) begin
                    // tie-break by remembered preference
                    state_d = (dir_up_q) ? STATE_UP : STATE_DN;
                end
                else begin
                    state_d = STATE_IDLE;
                end
            end

            STATE_UP: begin
                // move up one floor per cycle
                if (floor_pos < (FLOORS-1)) begin
                    floor_pos_d = floor_pos + 1'b1;

                    // if destination floor has pending request -> open door at arrival
                    if (req_pending_d[floor_pos + 1'b1]) begin
                        state_d    = STATE_STOP;
                        dir_up_d   = 1'b1;
                    end
                end else begin
                    // at top, go idle
                    state_d = STATE_IDLE;
                end
            end

            STATE_DN: begin
                // move down one floor per cycle
                if (floor_pos > 0) begin
                    floor_pos_d = floor_pos - 1'b1;

                    // if destination floor has pending request -> open door at arrival
                    if (req_pending_d[floor_pos - 1'b1]) begin
                        state_d    = STATE_STOP;
                        dir_up_d   = 1'b0;
                    end
                end else begin
                    // at bottom, go idle
                    state_d = STATE_IDLE;
                end
            end
            
            STATE_STOP: begin
                door_cnt_d = 8'd0;
                if (req_pending_d[floor_pos])
                    state_d = STATE_DOOR;
                else
                    state_d = STATE_IDLE;
            end

            STATE_DOOR: begin
                // hold door open for DOOR_CYCLES cycles
                if (door_cnt_q >= (DOOR_CYCLES-1)) begin
                    door_cnt_d = 8'd0;

                    // after door closes, choose next direction based on remaining pending
                    // (req_above/req_below already computed from req_pending_d with current cleared)
                    if (req_above && !req_below) begin
                        state_d  = STATE_UP;
                        dir_up_d = 1'b1;
                    end
                    else if (!req_above && req_below) begin
                        state_d  = STATE_DN;
                        dir_up_d = 1'b0;
                    end
                    else if (req_above && req_below) begin
                        state_d = (dir_up_q) ? STATE_UP : STATE_DN;
                    end
                    else begin
                        state_d = STATE_IDLE;
                    end
                end else begin
                    door_cnt_d = door_cnt_q + 1'b1;
                end
            end

            default: begin
                state_d = STATE_IDLE;
            end
        endcase
    end


    // Sequential registers
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state_q       <= STATE_IDLE;
            floor_pos     <= {POS_W{1'b0}};
            req_pending_q <= {FLOORS{1'b0}};
            door_cnt_q    <= 8'd0;
            dir_up_q      <= 1'b1;
        end else begin
            state_q       <= state_d;
            floor_pos     <= floor_pos_d;
            req_pending_q <= req_pending_d;
            door_cnt_q    <= door_cnt_d;
            dir_up_q      <= dir_up_d;
        end
    end


    // Outputs (Moore-style)
    always @(*) begin
        door_open = (state_q == STATE_DOOR);
        moving_up = (state_q == STATE_UP);
        moving_dn = (state_q == STATE_DN);
    end

endmodule



