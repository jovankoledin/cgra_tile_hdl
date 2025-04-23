/*
Consists of Vector adder Functional unit and local mem register file
Local register file contains adder inputs and configuration info
Can perform 4x16b, 2x32b, or 1x64b add operations on data in register file, config info specifies which of the three add operations 
Ouputs are sent to neighbor specified in config info 
CGRA network writes configuration data and adder inputs into the local mem
*/

`include "../../src/v_tile/mem/mem.sv"
`include "../../src/v_tile/adder_fu/adder_fu.sv"

`timescale 1ns/1ps

module v_tile #(
    parameter width = 16, // Bit width of each register element
    parameter num_inputs = 4, // Num regs for each neighbor input to mem reg file
    parameter num_regs = 16, // Num elements in mem reg file
    parameter total_inputs = num_inputs + num_inputs // Num elements to each adder fu execution 
) (
    input wire clk,
    input wire reset,
    input wire on_off, // Signal for vector fu to tell it to start data reading and op execution (toggled each cycle)

    // CGRA network port from neighbor 1 (input/write)
    input wire write_en1, // Stays high for duration of write, until write_ack is set high
    output wire write_rdy1,
    input wire [width-1:0] w_data_in1 [num_inputs-1:0],
    output wire write_ack1,

    // CGRA network port from neighbor 2 (input/write)
    input wire write_en2, // Stays high for duration of write, until write_ack is set high
    output wire write_rdy2,
    input wire [width-1:0] w_data_in2 [num_inputs-1:0],
    output wire write_ack2,

    // CGRA network port from config mem programmer (input/write)
    input wire write_en3, // Stays high for duration of write, until write_ack is set high
    output wire write_rdy3,
    input wire [width-1:0] w_data_in3,
    output wire write_ack3,

    // Vector fu port (output/read)
    output wire [width-1:0] adder_outputs [num_inputs-1:0],
    output wire [3:0] dest_info,
    output wire adder_ack
);

    // Internal signals
    wire [width-1:0] adder_inputs [total_inputs-1:0];
    wire on_off_vector_fu;
    wire [15:0] config_in;

    // Instantiate mem module
    mem #(
        .width(width),
        .num_regs(num_regs),
        .num_inputs(num_inputs)
    ) mem_inst (
        .clk(clk),
        .reset(reset),
        .on_off(on_off),
        .write_en1(write_en1),
        .write_rdy1(write_rdy1),
        .w_data_in1(w_data_in1),
        .write_ack1(write_ack1),
        .write_en2(write_en2),
        .write_rdy2(write_rdy2),
        .w_data_in2(w_data_in2),
        .write_ack2(write_ack2),
        .write_en3(write_en3),
        .write_rdy3(write_rdy3),
        .w_data_in3(w_data_in3),
        .write_ack3(write_ack3),
        .config_in(config_in),
        .adder_inputs(adder_inputs),
        .on_off_vector_fu(on_off_vector_fu)
    );

    // Instantiate adder_fu module
    adder_fu #(
        .width(width),
        .num_inputs(num_inputs)
    ) adder_fu_inst (
        .clk(clk),
        .reset(reset),
        .inputs(adder_inputs), // Connect mem output to adder input
        .on_off(on_off_vector_fu), // Connect on_off_vector_fu to adder's on_off
        .config_in(config_in),
        .outputs(adder_outputs),
        .dest_info(dest_info),
        .ack(adder_ack)
    );

endmodule