`timescale 1ns / 1ps
module switch_oled_top(
    input         clk,
    input  [7:0]  SW,
    output [7:0]  LED,
    output        oled_sdin,
    output        oled_sclk,
    output        oled_dc,
    output        oled_res,
    output        oled_vbat,
    output        oled_vdd
);

    // LEDs follow switches
    assign LED = SW;

    // State machine
    localparam S_INIT       = 0,
               S_INIT_WAIT  = 1,
               S_WRITE      = 2,
               S_WRITE_WAIT = 3,
               S_UPDATE     = 4,
               S_UPD_WAIT   = 5,
               S_IDLE       = 6;

    reg [2:0] state = S_INIT;
    reg [5:0] char_idx = 0;
    reg [7:0] sw_latched = 0;

    // OLED control signals
    reg        disp_on_start = 0;
    reg        write_start = 0;
    reg [7:0]  write_ascii_data = 0;
    reg [8:0]  write_base_addr = 0;
    reg        update_start = 0;
    reg        update_clear = 0;

    wire       disp_on_ready, write_ready, update_ready;
    wire       disp_off_ready, toggle_disp_ready;

    OLEDCtrl oled_ctrl (
        .clk(clk),
        .write_start(write_start),
        .write_ascii_data(write_ascii_data),
        .write_base_addr(write_base_addr),
        .write_ready(write_ready),
        .update_start(update_start),
        .update_clear(update_clear),
        .update_ready(update_ready),
        .disp_on_start(disp_on_start),
        .disp_on_ready(disp_on_ready),
        .disp_off_start(1'b0),
        .disp_off_ready(disp_off_ready),
        .toggle_disp_start(1'b0),
        .toggle_disp_ready(toggle_disp_ready),
        .SDIN(oled_sdin), .SCLK(oled_sclk),
        .DC(oled_dc), .RES(oled_res),
        .VBAT(oled_vbat), .VDD(oled_vdd)
    );

    // Binary to BCD (0-255 -> 3 decimal digits)
    reg [3:0] d_hundreds, d_tens, d_ones;
    integer k;
    reg [19:0] bcd_shift;
    always @(*) begin
        bcd_shift = 20'd0;
        bcd_shift[7:0] = sw_latched;
        for (k = 0; k < 8; k = k + 1) begin
            if (bcd_shift[11:8]  >= 5) bcd_shift[11:8]  = bcd_shift[11:8]  + 3;
            if (bcd_shift[15:12] >= 5) bcd_shift[15:12] = bcd_shift[15:12] + 3;
            if (bcd_shift[19:16] >= 5) bcd_shift[19:16] = bcd_shift[19:16] + 3;
            bcd_shift = bcd_shift << 1;
        end
        d_ones     = bcd_shift[11:8];
        d_tens     = bcd_shift[15:12];
        d_hundreds = bcd_shift[19:16];
    end

    // Display string: line0 = "SW: XXX         " (16 chars), lines 1-3 = spaces
    // Total 64 characters (4 lines x 16 chars)
    reg [7:0] display_char;
    always @(*) begin
        case (char_idx)
            // Line 0: "SW: XXX         "
            6'd0:  display_char = 8'h53; // 'S'
            6'd1:  display_char = 8'h57; // 'W'
            6'd2:  display_char = 8'h3A; // ':'
            6'd3:  display_char = 8'h20; // ' '
            6'd4:  display_char = (d_hundreds != 0) ? (8'h30 + d_hundreds) : 8'h20;
            6'd5:  display_char = (d_hundreds != 0 || d_tens != 0) ? (8'h30 + d_tens) : 8'h20;
            6'd6:  display_char = 8'h30 + d_ones;
            default: display_char = 8'h20; // space
        endcase
    end

    // State machine
    always @(posedge clk) begin
        case (state)
        S_INIT: begin
            disp_on_start <= 1;
            state <= S_INIT_WAIT;
        end
        S_INIT_WAIT: begin
            disp_on_start <= 0;
            if (write_ready) begin
                sw_latched <= SW;
                char_idx <= 0;
                state <= S_WRITE;
            end
        end
        S_WRITE: begin
            write_start <= 1;
            write_ascii_data <= display_char;
            write_base_addr <= {char_idx[5:4], char_idx[3:0], 3'b000};
            state <= S_WRITE_WAIT;
        end
        S_WRITE_WAIT: begin
            write_start <= 0;
            if (write_ready) begin
                if (char_idx == 63) begin
                    state <= S_UPDATE;
                end else begin
                    char_idx <= char_idx + 1;
                    state <= S_WRITE;
                end
            end
        end
        S_UPDATE: begin
            update_start <= 1;
            update_clear <= 0;
            state <= S_UPD_WAIT;
        end
        S_UPD_WAIT: begin
            update_start <= 0;
            if (update_ready)
                state <= S_IDLE;
        end
        S_IDLE: begin
            if (SW != sw_latched) begin
                sw_latched <= SW;
                char_idx <= 0;
                state <= S_WRITE;
            end
        end
        endcase
    end
endmodule
