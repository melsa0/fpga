`timescale 1ns / 1ps
module pixel_buffer (
    input         clka,
    input         wea,
    input  [8:0]  addra,
    input  [7:0]  dina,
    input         clkb,
    input  [8:0]  addrb,
    output reg [7:0] doutb
);
    reg [7:0] mem [0:511];
    integer i;
    initial for (i = 0; i < 512; i = i + 1) mem[i] = 8'h00;

    always @(posedge clka)
        if (wea) mem[addra] <= dina;

    always @(posedge clkb)
        doutb <= mem[addrb];
endmodule
