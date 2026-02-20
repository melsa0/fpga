`timescale 1ns / 1ps
module pong_game(
    input clk,
    input game_tick,
    input btn_l, btn_r,
    input [8:0] fb_addr,
    output [7:0] fb_data,
    output [7:0] led_score
);
    parameter PADDLE_W = 20;

    // Game state
    localparam PLAYING=0, GAMEOVER=1;
    reg gstate = PLAYING;
    reg [7:0] go_timer = 0;

    // Positions
    reg [6:0] ball_x=63, paddle_x=54;
    reg [5:0] ball_y=8;
    reg ball_dx=0, ball_dy=0; // 0=positive, 1=negative
    reg [3:0] sc_tens=0, sc_ones=0;

    assign led_score = sc_tens * 10 + sc_ones;

    // --- Game logic (on tick) ---
    reg [6:0] nx; reg [5:0] ny;

    always @(posedge clk) if (game_tick) begin
        if (gstate == PLAYING) begin
            // Paddle
            if (btn_l && paddle_x > 2)        paddle_x <= paddle_x - 3;
            if (btn_r && paddle_x < 105)       paddle_x <= paddle_x + 3;
            // Ball move
            nx = ball_dx ? ball_x - 1 : ball_x + 1;
            ny = ball_dy ? ball_y - 1 : ball_y + 1;
            // Wall bounce
            if (nx == 0)   ball_dx <= 0;
            if (nx >= 125) ball_dx <= 1;
            if (ny == 0)   ball_dy <= 0;
            // Paddle collision
            if (ny >= 28 && !ball_dy) begin
                if (nx + 2 > paddle_x && nx < paddle_x + PADDLE_W) begin
                    ball_dy <= 1;
                    ny = 28;
                    if (sc_ones == 9) begin sc_ones<=0; if(sc_tens<9) sc_tens<=sc_tens+1; end
                    else sc_ones <= sc_ones+1;
                end
            end
            // Game over
            if (ny >= 31) begin gstate <= GAMEOVER; go_timer <= 0; end
            else begin ball_x <= nx; ball_y <= ny; end
        end else begin
            // Game over timer (~3 sec at 30Hz)
            if (go_timer >= 90) begin
                gstate<=PLAYING; ball_x<=63; ball_y<=8;
                ball_dx<=0; ball_dy<=0; paddle_x<=54;
                sc_tens<=0; sc_ones<=0; go_timer<=0;
            end else go_timer <= go_timer+1;
        end
    end

    // --- Combinational frame buffer ---
    wire [1:0] pg  = fb_addr[8:7];
    wire [6:0] col = fb_addr[6:0];

    // Ball rendering
    wire [2:0] bbit = ball_y[2:0];
    wire [1:0] bpg  = ball_y[4:3];
    wire bcol = (col == ball_x || col == ball_x+1);
    wire [8:0] bmask9 = 9'h03 << bbit;
    wire [7:0] bmask0 = bmask9[7:0];
    wire [7:0] bmask1 = {7'b0, bmask9[8]};

    // Font lookup
    function [7:0] fnt;
        input [3:0] d; input [2:0] c;
        begin fnt=0; case(d)
        0: case(c) 0:fnt=8'h3E;1:fnt=8'h51;2:fnt=8'h49;3:fnt=8'h45;4:fnt=8'h3E; endcase
        1: case(c) 0:fnt=8'h00;1:fnt=8'h42;2:fnt=8'h7F;3:fnt=8'h40;4:fnt=8'h00; endcase
        2: case(c) 0:fnt=8'h62;1:fnt=8'h51;2:fnt=8'h49;3:fnt=8'h49;4:fnt=8'h46; endcase
        3: case(c) 0:fnt=8'h22;1:fnt=8'h41;2:fnt=8'h49;3:fnt=8'h49;4:fnt=8'h36; endcase
        4: case(c) 0:fnt=8'h18;1:fnt=8'h14;2:fnt=8'h12;3:fnt=8'h7F;4:fnt=8'h10; endcase
        5: case(c) 0:fnt=8'h27;1:fnt=8'h45;2:fnt=8'h45;3:fnt=8'h45;4:fnt=8'h39; endcase
        6: case(c) 0:fnt=8'h3C;1:fnt=8'h4A;2:fnt=8'h49;3:fnt=8'h49;4:fnt=8'h31; endcase
        7: case(c) 0:fnt=8'h41;1:fnt=8'h21;2:fnt=8'h11;3:fnt=8'h09;4:fnt=8'h07; endcase
        8: case(c) 0:fnt=8'h36;1:fnt=8'h49;2:fnt=8'h49;3:fnt=8'h49;4:fnt=8'h36; endcase
        9: case(c) 0:fnt=8'h06;1:fnt=8'h49;2:fnt=8'h49;3:fnt=8'h29;4:fnt=8'h1E; endcase
        endcase end
    endfunction

    // Letter font for GAME OVER
    function [7:0] lfnt;
        input [7:0] ch; input [2:0] c;
        begin lfnt=0; case(ch)
        "G": case(c) 0:lfnt=8'h3E;1:lfnt=8'h41;2:lfnt=8'h49;3:lfnt=8'h49;4:lfnt=8'h7A; endcase
        "A": case(c) 0:lfnt=8'h7E;1:lfnt=8'h09;2:lfnt=8'h09;3:lfnt=8'h09;4:lfnt=8'h7E; endcase
        "M": case(c) 0:lfnt=8'h7F;1:lfnt=8'h02;2:lfnt=8'h04;3:lfnt=8'h02;4:lfnt=8'h7F; endcase
        "E": case(c) 0:lfnt=8'h7F;1:lfnt=8'h49;2:lfnt=8'h49;3:lfnt=8'h49;4:lfnt=8'h41; endcase
        "O": case(c) 0:lfnt=8'h3E;1:lfnt=8'h41;2:lfnt=8'h41;3:lfnt=8'h41;4:lfnt=8'h3E; endcase
        "V": case(c) 0:lfnt=8'h1F;1:lfnt=8'h20;2:lfnt=8'h40;3:lfnt=8'h20;4:lfnt=8'h1F; endcase
        "R": case(c) 0:lfnt=8'h7F;1:lfnt=8'h09;2:lfnt=8'h09;3:lfnt=8'h19;4:lfnt=8'h66; endcase
        endcase end
    endfunction

    // "GAME OVER" text positions (page 1, centered)
    // G:37-41 A:43-47 M:49-53 E:55-59  O:67-71 V:73-77 E:79-83 R:85-89
    reg [7:0] go_char; reg [2:0] go_col; reg go_active;
    always @(*) begin
        go_char=0; go_col=0; go_active=0;
        if (col>=37 && col<=41)  begin go_active=1; go_char="G"; go_col=col-37; end
        if (col>=43 && col<=47)  begin go_active=1; go_char="A"; go_col=col-43; end
        if (col>=49 && col<=53)  begin go_active=1; go_char="M"; go_col=col-49; end
        if (col>=55 && col<=59)  begin go_active=1; go_char="E"; go_col=col-55; end
        if (col>=67 && col<=71)  begin go_active=1; go_char="O"; go_col=col-67; end
        if (col>=73 && col<=77)  begin go_active=1; go_char="V"; go_col=col-73; end
        if (col>=79 && col<=83)  begin go_active=1; go_char="E"; go_col=col-79; end
        if (col>=85 && col<=89)  begin go_active=1; go_char="R"; go_col=col-85; end
    end

    // Score position during play: page 0, cols 116-120 (tens), 122-126 (ones)
    wire sc_tens_hit = (col>=116 && col<=120);
    wire sc_ones_hit = (col>=122 && col<=126);
    wire [2:0] sc_col = sc_tens_hit ? col-116 : col-122;
    wire [3:0] sc_dig = sc_tens_hit ? sc_tens : sc_ones;

    // Score under GAME OVER: page 2, cols 55-59 (tens), 61-65 (ones)
    wire go_sc_tens_hit = (col>=55 && col<=59);
    wire go_sc_ones_hit = (col>=61 && col<=65);
    wire [2:0] go_sc_col = go_sc_tens_hit ? col-55 : col-61;
    wire [3:0] go_sc_dig = go_sc_tens_hit ? sc_tens : sc_ones;

    // Compose pixel byte
    reg [7:0] pix;
    always @(*) begin
        pix = 8'h00;
        if (gstate == PLAYING) begin
            // Paddle
            if (pg==3 && col>=paddle_x && col<paddle_x+PADDLE_W)
                pix = pix | 8'hC0;
            // Ball
            if (bcol) begin
                if (pg == bpg)                       pix = pix | bmask0;
                if (pg == bpg+1 && bmask1 != 0)      pix = pix | bmask1;
            end
            // Score
            if (pg==0 && (sc_tens_hit || sc_ones_hit))
                pix = pix | fnt(sc_dig, sc_col);
        end else begin
            // GAME OVER text (page 1)
            if (pg==1 && go_active)
                pix = lfnt(go_char, go_col);
            // Score under text (page 2)
            if (pg==2 && (go_sc_tens_hit || go_sc_ones_hit))
                pix = fnt(go_sc_dig, go_sc_col);
        end
    end

    assign fb_data = pix;
endmodule
