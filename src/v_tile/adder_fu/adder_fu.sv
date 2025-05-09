/*
Runs add ops based on config mem
Sends output to neighbor specified by config mem
*/

`timescale 1ns/1ps
`include "../../src/v_tile/adder_fu/full_adder.sv"
`include "../../src/v_tile/adder_fu/half_adder.sv"

module adder_fu #(
    parameter width = 16,
    parameter num_inputs = 4,
    parameter total_inputs = num_inputs + num_inputs
) (
    input wire clk,
    input wire reset,
    input wire [width-1:0] inputs [total_inputs-1:0],
    input wire on_off,
    input wire [15:0] config_in,
    output reg [width-1:0] outputs [num_inputs-1:0],
    output reg [3:0] dest_info,
    output reg ack
);

    wire carry1, carry2, carry3, carry4;
    wire ack1, ack2, ack3, ack4;
    reg a1_on_off, a2_on_off, a3_on_off, a4_on_off;
    wire [1:0] adder_config;

    assign adder_config = config_in[1:0];
    assign dest_info = config_in[5:2];

    always @(posedge clk) begin
        if (reset) begin
            a1_on_off <= 1'b0;
            a2_on_off <= 1'b0;
            a3_on_off <= 1'b0;
            a4_on_off <= 1'b0;

        end else if (on_off) begin
            case (adder_config)
                2'd0: begin // 4x16b adders
                    a1_on_off <= 1'b1;
                    a2_on_off <= 1'b1;
                    a3_on_off <= 1'b1;
                    a4_on_off <= 1'b1;
                end
                2'd1: begin // 2x32b adders
                    a1_on_off <= 1'b1;
                    a2_on_off <= a1_on_off;
                    a3_on_off <= 1'b1;
                    a4_on_off <= a3_on_off;
                end
                2'd3: begin // 1x64b adder
                    a1_on_off <= 1'b1;
                    a2_on_off <= a1_on_off;
                    a3_on_off <= a2_on_off;
                    a4_on_off <= a3_on_off;
                end
                default: begin
                    a1_on_off <= 1'b0;
                    a2_on_off <= 1'b0;
                    a3_on_off <= 1'b0;
                    a4_on_off <= 1'b0;
                end
            endcase
        end else begin
                a1_on_off <= 1'b0;
                a2_on_off <= 1'b0;
                a3_on_off <= 1'b0;
                a4_on_off <= 1'b0;
        end

    end

    assign ack = ack4;

    half_adder #( .width(width) ) adder1 (
        .clk(clk),
        .reset(reset),
        .a(inputs[0]),
        .b(inputs[4]),
        .c(outputs[0]),
        .carry_out(carry1),
        .ack(ack1),
        .on_off(a1_on_off)
    );

    full_adder #( .width(width) ) adder2 (
        .clk(clk),
        .reset(reset),
        .a(inputs[1]),
        .b(inputs[5]),
        .c(outputs[1]),
        .carry_in(carry1),
        .carry_out(carry2),
        .carry_listen(config_in[0]),
        .on_off(a2_on_off),
        .ack(ack2)
    );

    full_adder #( .width(width) ) adder3 (
        .clk(clk),    
        .reset(reset),
        .a(inputs[2]),
        .b(inputs[6]),
        .c(outputs[2]),
        .carry_in(carry2),
        .carry_out(carry3),
        .carry_listen(config_in[1]),
        .on_off(a3_on_off),
        .ack(ack3)
    );

    full_adder #( .width(width) ) adder4 (
        .clk(clk),
        .reset(reset),
        .a(inputs[3]),
        .b(inputs[7]),
        .c(outputs[3]),
        .carry_in(carry3),
        .carry_out(carry4),
        .carry_listen(config_in[0]),
        .on_off(a4_on_off),
        .ack(ack4)
    );
    

endmodule