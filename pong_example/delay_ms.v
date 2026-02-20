`timescale 1ns / 1ps
module delay_ms (
    input        clk,
    input [11:0] delay_time_ms,
    input        delay_start,
    output       delay_done
);
    localparam Idle=0, Hold=1, Done=2;
    localparam MAX = 17'd99999;
    reg  [1:0]  state = Idle;
    reg  [11:0] stop_time=0, ms_counter=0;
    reg  [16:0] clk_counter=0;

    assign delay_done = (state == Idle && delay_start == 1'b0) ? 1'b1 : 1'b0;

    always@(posedge clk)
        case (state)
        Idle: begin
            stop_time <= delay_time_ms;
            if (delay_start) state <= Hold;
        end
        Hold: if (ms_counter == stop_time && clk_counter == MAX)
                state <= (delay_start) ? Done : Idle;
        Done: if (!delay_start) state <= Idle;
        default: state <= Idle;
        endcase

    always@(posedge clk)
        if (state == Hold)
            if (clk_counter == MAX) begin
                clk_counter <= 0;
                ms_counter <= (ms_counter == stop_time) ? 0 : ms_counter + 1'b1;
            end else
                clk_counter <= clk_counter + 1'b1;
        else begin
            clk_counter <= 0;
            ms_counter <= 0;
        end
endmodule
