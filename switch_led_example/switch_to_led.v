`timescale 1ns / 1ps

module switch_to_led(
    input  wire [7:0] SW,
    output wire [7:0] LED
);

    assign LED = SW;

endmodule
