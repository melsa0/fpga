`timescale 1ns / 1ps
module OLEDCtrl (
    input       clk,
    input       write_start,
    input [7:0] write_ascii_data,
    input [8:0] write_base_addr,
    output wire write_ready,
    input       update_start,
    input       update_clear,
    output wire update_ready,
    input       disp_on_start,
    output wire disp_on_ready,
    input       disp_off_start,
    output wire disp_off_ready,
    input       toggle_disp_start,
    output wire toggle_disp_ready,
    output wire SDIN, SCLK, DC, RES, VBAT, VDD
);

localparam Idle=8'h00, Startup=8'h10, StartupFetch=8'h11;
localparam ActiveWait=8'h20, ActiveUpdatePage=8'h21, ActiveUpdateScreen=8'h22;
localparam ActiveSendByte=8'h23, ActiveUpdateWait=8'h24, ActiveToggleDisp=8'h25;
localparam ActiveToggleDispWait=8'h26, ActiveWrite=8'h27, ActiveWriteTran=8'h28, ActiveWriteWait=8'h29;
localparam BringdownDispOff=8'h30, BringdownVbatOff=8'h31, BringdownVddOff=8'h33;
localparam UtilitySpiWait=8'h41, UtilityDelayWait=8'h42;

reg [7:0] state=Idle, after_state=Idle, after_page_state=Idle, after_char_state=Idle, after_update_state=Idle;
reg       disp_is_full=0, clear_screen=0;
reg [2:0] update_page_count=0;
reg [1:0] temp_page=0;
reg [6:0] temp_index=0;
reg       oled_dc=1, oled_res=1, oled_vdd=1, oled_vbat=1;
reg       temp_spi_start=0;
reg [7:0] temp_spi_data=0;
wire      temp_spi_done;
reg       temp_delay_start=0;
reg [11:0] temp_delay_ms=0;
wire      temp_delay_done;
reg [7:0] temp_write_ascii=0;
reg [8:0] temp_write_base_addr=0;
wire [9:0] char_lib_addr;
wire [8:0] pbuf_read_addr;
wire [7:0] pbuf_read_data;
wire       pbuf_write_en;
wire [7:0] pbuf_write_data;
wire [8:0] pbuf_write_addr;
reg [2:0] write_byte_count=0;
wire [15:0] init_operation;
reg [3:0] startup_count=0;
reg       iop_state_select=0, iop_res_set=0, iop_res_val=0;
reg       iop_vbat_set=0, iop_vbat_val=0, iop_vdd_set=0, iop_vdd_val=0;
reg [7:0] iop_data=0;

assign DC=oled_dc; assign RES=oled_res; assign VDD=oled_vdd; assign VBAT=oled_vbat;

SpiCtrl SPI_CTRL(.clk(clk),.send_start(temp_spi_start),.send_data(temp_spi_data),.send_ready(temp_spi_done),.CS(),.SDO(SDIN),.SCLK(SCLK));
delay_ms MS_DELAY(.clk(clk),.delay_start(temp_delay_start),.delay_time_ms(temp_delay_ms),.delay_done(temp_delay_done));

assign pbuf_read_addr = {temp_page, temp_index};
assign char_lib_addr = {temp_write_ascii, write_byte_count};
assign pbuf_write_en = (state == ActiveWrite) ? 1'b1 : 1'b0;
assign pbuf_write_addr = temp_write_base_addr + write_byte_count;

charLib CHAR_LIB(.clka(clk),.addra(char_lib_addr),.douta(pbuf_write_data));
pixel_buffer PIXEL_BUFFER(.clka(clk),.wea(pbuf_write_en),.addra(pbuf_write_addr),.dina(pbuf_write_data),.clkb(clk),.addrb(pbuf_read_addr),.doutb(pbuf_read_data));
init_sequence_rom INIT_SEQ(.clka(clk),.addra(startup_count),.douta(init_operation));

assign disp_on_ready     = (state == Idle       && !disp_on_start)     ? 1'b1 : 1'b0;
assign update_ready      = (state == ActiveWait && !update_start)      ? 1'b1 : 1'b0;
assign write_ready       = (state == ActiveWait && !write_start)       ? 1'b1 : 1'b0;
assign disp_off_ready    = (state == ActiveWait && !disp_off_start)    ? 1'b1 : 1'b0;
assign toggle_disp_ready = (state == ActiveWait && !toggle_disp_start) ? 1'b1 : 1'b0;

always@(posedge clk)
    case (state)
    Idle: begin
        if (disp_on_start) begin startup_count<=0; state<=StartupFetch; end
        disp_is_full <= 0;
    end
    Startup: begin
        oled_dc <= 0;
        oled_vdd  <= iop_vdd_set  ? iop_vdd_val  : oled_vdd;
        oled_res  <= iop_res_set  ? iop_res_val  : oled_res;
        oled_vbat <= iop_vbat_set ? iop_vbat_val : oled_vbat;
        if (!iop_state_select) begin
            temp_delay_start<=1; temp_delay_ms<={4'h0,iop_data}; state<=UtilityDelayWait;
        end else begin
            temp_spi_start<=1; temp_spi_data<=iop_data; state<=UtilitySpiWait;
        end
        if (startup_count==15) begin
            after_state<=ActiveUpdatePage; after_update_state<=ActiveWait;
            after_char_state<=ActiveUpdateScreen; after_page_state<=ActiveUpdateScreen;
            update_page_count<=0; temp_page<=0; temp_index<=0; clear_screen<=1;
        end else begin
            after_state<=StartupFetch; startup_count<=startup_count+1;
        end
    end
    StartupFetch: begin
        state<=Startup;
        iop_state_select<=init_operation[14]; iop_res_set<=init_operation[13]; iop_res_val<=init_operation[12];
        iop_vdd_set<=init_operation[11]; iop_vdd_val<=init_operation[10];
        iop_vbat_set<=init_operation[9]; iop_vbat_val<=init_operation[8]; iop_data<=init_operation[7:0];
    end
    ActiveWait: begin
        if (disp_off_start) state<=BringdownDispOff;
        else if (update_start) begin
            after_update_state<=ActiveUpdateWait; after_char_state<=ActiveUpdateScreen;
            after_page_state<=ActiveUpdateScreen; state<=ActiveUpdatePage;
            update_page_count<=0; temp_page<=0; temp_index<=0; clear_screen<=update_clear;
        end else if (write_start) begin
            state<=ActiveWriteTran; write_byte_count<=0;
            temp_write_ascii<=write_ascii_data; temp_write_base_addr<=write_base_addr;
        end else if (toggle_disp_start) begin
            oled_dc<=0; disp_is_full<=~disp_is_full;
            temp_spi_data<=8'hA4|{7'b0,~disp_is_full}; temp_spi_start<=1;
            after_state<=ActiveToggleDispWait; state<=UtilitySpiWait;
        end
    end
    ActiveWrite: begin
        if (write_byte_count==7) state<=ActiveWriteWait; else state<=ActiveWriteTran;
        write_byte_count <= write_byte_count+1;
    end
    ActiveWriteTran: state <= ActiveWrite;
    ActiveWriteWait: begin
        if (!write_start) state<=ActiveWait;
        write_byte_count <= 0;
    end
    ActiveUpdatePage: begin
        case(update_page_count)
        0: temp_spi_data<=8'h22;
        1: temp_spi_data<={6'b0,temp_page};
        2: temp_spi_data<=8'h00;
        3: temp_spi_data<=8'h10;
        endcase
        if (update_page_count<4) begin
            oled_dc<=0; after_state<=ActiveUpdatePage; temp_spi_start<=1; state<=UtilitySpiWait;
        end else state<=after_page_state;
        update_page_count <= update_page_count+1;
    end
    ActiveSendByte: begin
        oled_dc<=1;
        temp_spi_data <= clear_screen ? 8'b0 : pbuf_read_data;
        after_state<=after_char_state; state<=UtilitySpiWait; temp_spi_start<=1;
    end
    ActiveUpdateScreen: begin
        if (temp_index==127) begin
            temp_index<=0; temp_page<=temp_page+1; update_page_count<=0;
            after_char_state<=ActiveUpdatePage;
            after_page_state <= (temp_page==3) ? after_update_state : ActiveUpdateScreen;
        end else begin
            temp_index<=temp_index+1; after_char_state<=ActiveUpdateScreen;
        end
        state<=ActiveSendByte;
    end
    ActiveUpdateWait: if (!update_start) state<=ActiveWait;
    ActiveToggleDispWait: if (!toggle_disp_start) state<=ActiveWait;
    BringdownDispOff: begin
        oled_dc<=0; temp_spi_start<=1; temp_spi_data<=8'hAE;
        after_state<=BringdownVbatOff; state<=UtilitySpiWait;
    end
    BringdownVbatOff: begin
        oled_vbat<=0; temp_delay_start<=1; temp_delay_ms<=12'd100;
        after_state<=BringdownVddOff; state<=UtilityDelayWait;
    end
    BringdownVddOff: begin oled_vdd<=0; if (!disp_on_start) state<=Idle; end
    UtilitySpiWait: begin temp_spi_start<=0; if (temp_spi_done) state<=after_state; end
    UtilityDelayWait: begin temp_delay_start<=0; if (temp_delay_done) state<=after_state; end
    default: state <= Idle;
    endcase
endmodule
