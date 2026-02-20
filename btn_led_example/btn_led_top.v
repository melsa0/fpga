`timescale 1ns / 1ps

module btn_led_top(
    input        clk,       // 100 MHz
    input        btnu,      // Mode: Position
    input        btnd,      // Mode: Volume
    input        btnl,      // Left
    input        btnr,      // Right
    input        btnc,      // All LEDs on
    output reg [7:0] LED
);

    // --- Debounced & edge-detected button signals ---
    wire btnu_pulse, btnd_pulse, btnl_pulse, btnr_pulse, btnc_pulse;

    btn_edge U_BTNU (.clk(clk), .btn_in(btnu), .pulse(btnu_pulse));
    btn_edge U_BTND (.clk(clk), .btn_in(btnd), .pulse(btnd_pulse));
    btn_edge U_BTNL (.clk(clk), .btn_in(btnl), .pulse(btnl_pulse));
    btn_edge U_BTNR (.clk(clk), .btn_in(btnr), .pulse(btnr_pulse));
    btn_edge U_BTNC (.clk(clk), .btn_in(btnc), .pulse(btnc_pulse));

    // --- Mode definitions ---
    localparam MODE_POSITION = 2'd0,
               MODE_VOLUME   = 2'd1,
               MODE_ALL      = 2'd2;

    reg [1:0] mode = MODE_POSITION;
    reg [2:0] pos  = 3'd0;   // Position mode: which LED (0-7)
    reg [3:0] vol  = 4'd1;   // Volume mode: how many LEDs (1-8)

    // --- Mode switching & LED control ---
    always @(posedge clk) begin
        // Mode select buttons
        if (btnu_pulse) begin
            mode <= MODE_POSITION;
            pos  <= 3'd0;
        end else if (btnd_pulse) begin
            mode <= MODE_VOLUME;
            vol  <= 4'd1;
        end else if (btnc_pulse) begin
            mode <= MODE_ALL;
        end

        // Direction buttons
        case (mode)
        MODE_POSITION: begin
            if (btnl_pulse && pos < 7)
                pos <= pos + 1;
            else if (btnr_pulse && pos > 0)
                pos <= pos - 1;
        end
        MODE_VOLUME: begin
            if (btnl_pulse && vol < 8)
                vol <= vol + 1;
            else if (btnr_pulse && vol > 1)
                vol <= vol - 1;
        end
        default: ; // MODE_ALL: no L/R action
        endcase
    end

    // --- LED output ---
    always @(*) begin
        case (mode)
        MODE_POSITION: LED = 8'd1 << pos;            // Single LED at pos
        MODE_VOLUME:   LED = (8'hFF >> (8 - vol));    // vol LEDs from right
        MODE_ALL:      LED = 8'hFF;                   // All on
        default:       LED = 8'd0;
        endcase
    end

endmodule


// --- Debouncer + Rising Edge Detector ---
module btn_edge (
    input      clk,
    input      btn_in,
    output reg pulse
);
    // 20-bit counter -> ~10ms debounce at 100MHz
    reg [19:0] cnt = 0;
    reg        btn_stable = 0;
    reg        btn_prev   = 0;
    reg        btn_sync0  = 0, btn_sync1 = 0;

    // Synchronizer
    always @(posedge clk) begin
        btn_sync0 <= btn_in;
        btn_sync1 <= btn_sync0;
    end

    // Debounce
    always @(posedge clk) begin
        if (btn_sync1 != btn_stable) begin
            cnt <= cnt + 1;
            if (cnt == 20'hFFFFF) begin
                btn_stable <= btn_sync1;
                cnt <= 0;
            end
        end else
            cnt <= 0;
    end

    // Edge detect
    always @(posedge clk) begin
        btn_prev <= btn_stable;
        pulse    <= btn_stable & ~btn_prev;  // rising edge
    end

endmodule
