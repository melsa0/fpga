`timescale 1ns / 1ps
module SpiCtrl (
    input        clk,
    input        send_start,
    input  [7:0] send_data,
    output       send_ready,
    output       CS,
    output       SDO,
    output       SCLK
);
    localparam Idle=0, Send=1, HoldCS=2, Hold=3;
    localparam COUNTER_MID=4, COUNTER_MAX=9, SCLK_DUTY=5;
    reg [2:0] state = Idle;
    reg [7:0] shift_register=0;
    reg [3:0] shift_counter=0;
    reg [4:0] counter=0;
    reg       temp_sdo;

    assign SCLK = (counter < SCLK_DUTY) | CS;
    assign SDO = temp_sdo | CS | (state == HoldCS ? 1'b1 : 1'b0);
    assign CS = (state != Send && state != HoldCS) ? 1'b1 : 1'b0;
    assign send_ready = (state == Idle && send_start == 1'b0) ? 1'b1 : 1'b0;

    always@(posedge clk)
        case (state)
        Idle: if (send_start) state <= Send;
        Send: if (shift_counter == 8 && counter == COUNTER_MID) state <= HoldCS;
        HoldCS: if (shift_counter == 4'd3) state <= Hold;
        Hold: if (!send_start) state <= Idle;
        endcase

    always@(posedge clk)
        if (state == Send && ~(counter == COUNTER_MID && shift_counter == 8))
            counter <= (counter == COUNTER_MAX) ? 0 : counter + 1'b1;
        else
            counter <= 0;

    always@(posedge clk)
        if (state == Idle) begin
            shift_counter <= 0;
            shift_register <= send_data;
            temp_sdo <= 1'b1;
        end else if (state == Send) begin
            if (counter == COUNTER_MID) begin
                temp_sdo <= shift_register[7];
                shift_register <= {shift_register[6:0], 1'b0};
                shift_counter <= (shift_counter == 4'b1000) ? 0 : shift_counter + 1'b1;
            end
        end else if (state == HoldCS)
            shift_counter <= shift_counter + 1'b1;
endmodule
