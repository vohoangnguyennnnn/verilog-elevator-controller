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

    input  wire [FLOORS-1:0]    floor_req,   // use bitmask of floor requests
    output reg  [POS_W-1:0]     floor_pos,   // current floor index
    output reg                  door_open,   // open door elevator   
    output reg                  moving_up,
    output reg                  moving_dn
);


    // State encoding
    localparam [1:0] STATE_IDLE = 2'd0;
    localparam [1:0] STATE_UP   = 2'd1;
    localparam [1:0] STATE_DN   = 2'd2;
    localparam [1:0] STATE_DOOR = 2'd3;

    reg [1:0] state;

    // pending requests 
    reg [FLOORS-1:0] req_pending;

    // door open timer
    reg [7:0] door_cnt; 

    // when request exist both above and below
    reg dir_up; // 1=prefer up, 0=prefer down

    // Combinational helpers
    reg req_above, req_below;
    reg [POS_W-1:0] next_above, next_below;
    integer i;

    always @(*) begin
        req_above  = 1'b0;
        req_below  = 1'b0;
        
        //default 
        next_above = floor_pos;
        next_below = floor_pos;

        // check request floor above or below
        for (i = 0; i < FLOORS; i = i + 1) begin
            if ((i > floor_pos) && req_pending[i]) begin
                req_above = 1'b1;
            end
            if ((i < floor_pos) && req_pending[i]) begin
                req_below = 1'b1;
            end
        end

        // nearest above
        for (i = 0; i < FLOORS; i = i + 1) begin
            if ((i > floor_pos) && req_pending[i]) begin
                next_above = i[POS_W-1:0];
                disable find_above;
            end
        end
    end

    always @(*) begin : find_above
        next_above = floor_pos;
        for (i = 0; i < FLOORS; i = i + 1) begin
            if ((i > floor_pos) && req_pending[i]) begin
                next_above = i[POS_W-1:0];
                disable find_above;
            end
        end
    end

    always @(*) begin : find_below
        next_below = floor_pos;
        for (i = FLOORS-1; i >= 0; i = i - 1) begin
            if ((i < floor_pos) && req_pending[i]) begin
                next_below = i[POS_W-1:0];
                disable find_below;
            end
        end
    end

    // Sequential FSM
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state       <= STATE_IDLE;
            floor_pos   <= {POS_W{1'b0}};
            req_pending <= {FLOORS{1'b0}};
            door_cnt    <= 8'd0;
            dir_up      <= 1'b1;

            door_open   <= 1'b0;
            moving_up   <= 1'b0;
            moving_dn   <= 1'b0;
        end else begin
            //  requests pending 
            req_pending <= req_pending | floor_req;

            // default outputs
            door_open <= 1'b0;
            moving_up <= 1'b0;
            moving_dn <= 1'b0;

            case (state)
                STATE_IDLE: begin
                    // request in current floor -> open door elevator immediately
                    if (req_pending[floor_pos]) begin
                        state    <= STATE_DOOR;
                        door_cnt <= 8'd0;
                    end else if (req_above && !req_below) begin
                        state  <= STATE_UP;
                        dir_up <= 1'b1;
                    end else if (!req_above && req_below) begin
                        state  <= STATE_DN;
                        dir_up <= 1'b0;
                    end else if (req_above && req_below) begin
                        // tie-break 
                        state  <= (dir_up) ? STATE_UP : STATE_DN;
                    end else begin
                        state <= STATE_IDLE;
                    end
                end

                STATE_UP: begin
                    moving_up <= 1'b1;
                    if (floor_pos < (FLOORS-1)) begin
                        floor_pos <= floor_pos + 1'b1;
                    end else begin
                        state <= STATE_IDLE;
                    end

                    if ((floor_pos < (FLOORS-1)) && req_pending[floor_pos + 1'b1]) begin
                        state    <= STATE_DOOR;
                        door_cnt <= 8'd0;
                        dir_up   <= 1'b1;
                    end
                end

                STATE_DN: begin
                    moving_dn <= 1'b1;

                    if (floor_pos > 0) begin
                        floor_pos <= floor_pos - 1'b1;
                    end else begin
                        state <= STATE_IDLE;
                    end

                    if ((floor_pos > 0) && req_pending[floor_pos - 1'b1]) begin
                        state    <= STATE_DOOR;
                        door_cnt <= 8'd0;
                        dir_up   <= 1'b0;
                    end
                end

                STATE_DOOR: begin
                    door_open <= 1'b1;

                    // clear request pending in current floor
                    req_pending[floor_pos] <= 1'b0;

                    if (door_cnt >= (DOOR_CYCLES-1)) begin
                        door_cnt <= 8'd0;
                        // continue with request pending
                        if (req_above && !req_below) begin
                            state  <= STATE_UP;
                            dir_up <= 1'b1;
                        end else if (!req_above && req_below) begin
                            state  <= STATE_DN;
                            dir_up <= 1'b0;
                        end else if (req_above && req_below) begin
                            state  <= (dir_up) ? STATE_UP : STATE_DN;
                        end else begin
                            state <= STATE_IDLE;
                        end
                    end else begin
                        door_cnt <= door_cnt + 1'b1;
                    end
                end

                default: state <= STATE_IDLE;
            endcase
        end
    end

endmodule


