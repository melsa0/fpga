`timescale 1ns / 1ps
module charLib (
    input         clka,
    input  [9:0]  addra,
    output reg [7:0] douta
);
    reg [7:0] mem [0:1023];
    integer i;
    initial begin
        for (i = 0; i < 1024; i = i + 1) mem[i] = 8'h00;
        // Space (0x20=32, base=256)
        // '0' (0x30=48, base=384)
        mem[384]=8'h3E; mem[385]=8'h51; mem[386]=8'h49; mem[387]=8'h45; mem[388]=8'h3E;
        // '1' (base=392)
        mem[392]=8'h00; mem[393]=8'h42; mem[394]=8'h7F; mem[395]=8'h40; mem[396]=8'h00;
        // '2' (base=400)
        mem[400]=8'h62; mem[401]=8'h51; mem[402]=8'h49; mem[403]=8'h49; mem[404]=8'h46;
        // '3' (base=408)
        mem[408]=8'h22; mem[409]=8'h41; mem[410]=8'h49; mem[411]=8'h49; mem[412]=8'h36;
        // '4' (base=416)
        mem[416]=8'h18; mem[417]=8'h14; mem[418]=8'h12; mem[419]=8'h7F; mem[420]=8'h10;
        // '5' (base=424)
        mem[424]=8'h27; mem[425]=8'h45; mem[426]=8'h45; mem[427]=8'h45; mem[428]=8'h39;
        // '6' (base=432)
        mem[432]=8'h3C; mem[433]=8'h4A; mem[434]=8'h49; mem[435]=8'h49; mem[436]=8'h31;
        // '7' (base=440)
        mem[440]=8'h41; mem[441]=8'h21; mem[442]=8'h11; mem[443]=8'h09; mem[444]=8'h07;
        // '8' (base=448)
        mem[448]=8'h36; mem[449]=8'h49; mem[450]=8'h49; mem[451]=8'h49; mem[452]=8'h36;
        // '9' (base=456)
        mem[456]=8'h06; mem[457]=8'h49; mem[458]=8'h49; mem[459]=8'h29; mem[460]=8'h1E;
        // ':' (0x3A=58, base=464)
        mem[466]=8'h14;
        // 'S' (0x53=83, base=664)
        mem[664]=8'h26; mem[665]=8'h49; mem[666]=8'h49; mem[667]=8'h49; mem[668]=8'h32;
        // 'W' (0x57=87, base=696)
        mem[696]=8'h3F; mem[697]=8'h40; mem[698]=8'h30; mem[699]=8'h40; mem[700]=8'h3F;
    end

    always @(posedge clka) douta <= mem[addra];
endmodule
