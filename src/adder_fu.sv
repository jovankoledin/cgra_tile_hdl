`timescale 1ns/1ps
`include "../src/full_adder.sv"
`include "../src/half_adder.sv"

module adder_fu #(parameter WIDTH = 16) (
    input wire clk,
    input wire reset,
    input wire [WIDTH-1:0] inputs [7:0],
    input wire on_off,
    input wire [1:0] config_in,
    output reg [WIDTH-1:0] outputs [3:0],
    output reg carry_out_final
);

    wire [WIDTH-1:0] sum1, sum2, sum3, sum4;
    wire carry1, carry2, carry3, carry4;
    wire ack1, ack2, ack3, ack4;
    wire a1_on_off, a2_on_off, a3_on_off, a4_on_off;


    always @(posedge clk) begin
        if (reset) begin
            a1_on_off <= 1'b0;
            a2_on_off <= 1'b0;
            a3_on_off <= 1'b0;
            a4_on_off <= 1'b0;
            carry_out_final <= 1'b0;

        end else begin
            case (config_in)
                2'd0: begin // 4x16b adders
                    a1_on_off <= on_off;
                    a2_on_off <= on_off;
                    a3_on_off <= on_off;
                    a4_on_off <= on_off;
                end
                2'd1: begin // 2x32b adders
                    a1_on_off <= on_off;
                    a2_on_off <= on_off && ack1;
                    a3_on_off <= on_off;
                    a4_on_off <= on_off && ack3;
                end
                2'd3: begin // 1x64b adder
                    a1_on_off <= on_off;
                    a2_on_off <= on_off && ack1;
                    a3_on_off <= on_off && ack2;
                    a4_on_off <= on_off && ack3;
                end
                default: begin
                    a1_on_off <= 1'b0;
                    a2_on_off <= 1'b0;
                    a3_on_off <= 1'b0;
                    a4_on_off <= 1'b0;
                end
            endcase
        end
        carry_out_final <= carry4;
    end

    half_adder #( .width(WIDTH) ) adder1 (
        .reset(reset),
        .a(inputs[0]),
        .b(inputs[1]),
        .c(outputs[0]),
        .carry_out(carry1),
        .ack(ack1),
        .on_off(a1_on_off)
    );

    full_adder #( .width(WIDTH) ) adder2 (
        .reset(reset),
        .a(inputs[2]),
        .b(inputs[3]),
        .c(outputs[1]),
        .carry_in(carry1),
        .carry_out(carry2),
        .carry_listen(config_in[0]),
        .on_off(a2_on_off),
        .ack(ack2)
    );

    full_adder #( .width(WIDTH) ) adder3 (
        .reset(reset),
        .a(inputs[4]),
        .b(inputs[5]),
        .c(outputs[2]),
        .carry_in(carry2),
        .carry_out(carry3),
        .carry_listen(config_in[1]),
        .on_off(a3_on_off),
        .ack(ack3)
    );

    full_adder #( .width(WIDTH) ) adder4 (
        .reset(reset),
        .a(inputs[6]),
        .b(inputs[7]),
        .c(outputs[3]),
        .carry_in(carry3),
        .carry_out(carry4),
        .carry_listen(config_in[0]),
        .on_off(a4_on_off),
        .ack(ack4)
    );

    

endmodule