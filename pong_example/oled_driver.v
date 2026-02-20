`timescale 1ns / 1ps
module oled_driver(
    input clk,
    output reg [8:0] fb_addr,
    input      [7:0] fb_data,
    output reg frame_done,
    output SDIN, SCLK,
    output reg DC, RES, VBAT, VDD
);

    reg spi_go=0; reg [7:0] spi_byte=0; wire spi_rdy;
    reg dly_go=0; reg [11:0] dly_val=0;  wire dly_rdy;

    SpiCtrl spi(.clk(clk),.send_start(spi_go),.send_data(spi_byte),
                .send_ready(spi_rdy),.CS(),.SDO(SDIN),.SCLK(SCLK));
    delay_ms dly(.clk(clk),.delay_start(dly_go),.delay_time_ms(dly_val),
                 .delay_done(dly_rdy));

    localparam INIT=0, SPI_W=1, DLY_W=2, REF_CMD=3, REF_DATA=4, REF_DATA_W=5, FRAME=6;
    reg [2:0] state=INIT, after=INIT;
    reg [4:0] step=0;
    reg [2:0] rcmd=0;

    always @(posedge clk) begin
        spi_go <= 0; dly_go <= 0; frame_done <= 0;
        case(state)
        INIT: begin
            DC <= 0;
            case(step)
            0:  begin VDD<=0; RES<=1; VBAT<=1; dly_val<=12'd3;   dly_go<=1; after<=INIT; state<=DLY_W; step<=1;  end
            1:  begin spi_byte<=8'hAE; spi_go<=1; after<=INIT; state<=SPI_W; step<=2;  end
            2:  begin RES<=0; dly_val<=12'd3;  dly_go<=1; after<=INIT; state<=DLY_W; step<=3;  end
            3:  begin RES<=1; dly_val<=12'd3;  dly_go<=1; after<=INIT; state<=DLY_W; step<=4;  end
            4:  begin spi_byte<=8'h8D; spi_go<=1; after<=INIT; state<=SPI_W; step<=5;  end
            5:  begin spi_byte<=8'h14; spi_go<=1; after<=INIT; state<=SPI_W; step<=6;  end
            6:  begin spi_byte<=8'hD9; spi_go<=1; after<=INIT; state<=SPI_W; step<=7;  end
            7:  begin spi_byte<=8'hF1; spi_go<=1; after<=INIT; state<=SPI_W; step<=8;  end
            8:  begin VBAT<=0; dly_val<=12'd100; dly_go<=1; after<=INIT; state<=DLY_W; step<=9;  end
            9:  begin spi_byte<=8'h81; spi_go<=1; after<=INIT; state<=SPI_W; step<=10; end
            10: begin spi_byte<=8'h0F; spi_go<=1; after<=INIT; state<=SPI_W; step<=11; end
            11: begin spi_byte<=8'hA0; spi_go<=1; after<=INIT; state<=SPI_W; step<=12; end
            12: begin spi_byte<=8'hC0; spi_go<=1; after<=INIT; state<=SPI_W; step<=13; end
            13: begin spi_byte<=8'hDA; spi_go<=1; after<=INIT; state<=SPI_W; step<=14; end
            14: begin spi_byte<=8'h00; spi_go<=1; after<=INIT; state<=SPI_W; step<=15; end
            15: begin spi_byte<=8'h20; spi_go<=1; after<=INIT; state<=SPI_W; step<=16; end
            16: begin spi_byte<=8'h00; spi_go<=1; after<=INIT; state<=SPI_W; step<=17; end
            17: begin spi_byte<=8'hAF; spi_go<=1; after<=REF_CMD; state<=SPI_W; rcmd<=0; end
            endcase
        end

        SPI_W: if (spi_rdy) state <= after;
        DLY_W: if (dly_rdy) state <= after;

        REF_CMD: begin
            DC <= 0;
            case(rcmd)
            0: spi_byte <= 8'h21; 1: spi_byte <= 8'h00; 2: spi_byte <= 8'h7F;
            3: spi_byte <= 8'h22; 4: spi_byte <= 8'h00; 5: spi_byte <= 8'h03;
            endcase
            spi_go <= 1;
            if (rcmd == 5) begin after <= REF_DATA; fb_addr <= 0; end
            else            begin after <= REF_CMD; end
            rcmd <= rcmd + 1;
            state <= SPI_W;
        end

        REF_DATA: begin
            DC <= 1; spi_byte <= fb_data; spi_go <= 1;
            state <= REF_DATA_W;
        end

        REF_DATA_W: if (spi_rdy) begin
            if (fb_addr == 511) state <= FRAME;
            else begin fb_addr <= fb_addr + 1; state <= REF_DATA; end
        end

        FRAME: begin frame_done <= 1; rcmd <= 0; state <= REF_CMD; end
        endcase
    end
endmodule
