`timescale 1ns / 1ps
module pong_top(
    input        clk,
    input        btnl,
    input        btnr,
    output [7:0] LED,
    output       oled_sdin,
    output       oled_sclk,
    output       oled_dc,
    output       oled_res,
    output       oled_vbat,
    output       oled_vdd
);

    // Button debounce (output stable level, not edge)
    wire bl, br;
    btn_debounce dbl(.clk(clk), .btn(btnl), .stable(bl));
    btn_debounce dbr(.clk(clk), .btn(btnr), .stable(br));

    // Game tick ~30 Hz
    reg [21:0] tick_cnt = 0;
    reg game_tick = 0;
    always @(posedge clk) begin
        game_tick <= 0;
        if (tick_cnt == 22'd3_333_333) begin
            tick_cnt <= 0;
            game_tick <= 1;
        end else
            tick_cnt <= tick_cnt + 1;
    end

    // OLED driver <-> Game
    wire [8:0] fb_addr;
    wire [7:0] fb_data;
    wire frame_done;

    oled_driver oled(
        .clk(clk), .fb_addr(fb_addr), .fb_data(fb_data),
        .frame_done(frame_done),
        .SDIN(oled_sdin), .SCLK(oled_sclk),
        .DC(oled_dc), .RES(oled_res), .VBAT(oled_vbat), .VDD(oled_vdd)
    );

    pong_game game(
        .clk(clk), .game_tick(game_tick),
        .btn_l(bl), .btn_r(br),
        .fb_addr(fb_addr), .fb_data(fb_data),
        .led_score(LED)
    );

endmodule

// Simple debounce: outputs stable level (not edge)
module btn_debounce(
    input  clk,
    input  btn,
    output reg stable
);
    reg [19:0] cnt = 0;
    reg sync0=0, sync1=0;
    always @(posedge clk) begin
        sync0 <= btn; sync1 <= sync0;
        if (sync1 != stable) begin
            cnt <= cnt + 1;
            if (cnt[19]) begin stable <= sync1; cnt <= 0; end
        end else cnt <= 0;
    end
endmodule
