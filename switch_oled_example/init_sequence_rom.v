`timescale 1ns / 1ps
module init_sequence_rom (
    input         clka,
    input  [3:0]  addra,
    output reg [15:0] douta
);
    always @(posedge clka)
        case (addra)
            4'd0:  douta <= 16'h1901;
            4'd1:  douta <= 16'h51AE;
            4'd2:  douta <= 16'h2101;
            4'd3:  douta <= 16'h3101;
            4'd4:  douta <= 16'h518D;
            4'd5:  douta <= 16'h5114;
            4'd6:  douta <= 16'h51D9;
            4'd7:  douta <= 16'h51F1;
            4'd8:  douta <= 16'h1264;
            4'd9:  douta <= 16'h5081;
            4'd10: douta <= 16'h500F;
            4'd11: douta <= 16'h50A0;
            4'd12: douta <= 16'h50C0;
            4'd13: douta <= 16'h50DA;
            4'd14: douta <= 16'h5000;
            4'd15: douta <= 16'h50AF;
        endcase
endmodule
