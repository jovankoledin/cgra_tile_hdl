/*
Consists of Vector adder Functional unit and local register file
Can perform 4x16b, 2x32b, or 1x64b add operations on data in register file, config mem specifies add operation 
Ouputs are sent to location specified by data in config mem 
*/

`timescale 1ns/1ps
`include "../../src/config_mem/regfile.sv"

module config_mem #(
    parameter width = 16, 
    num_regs = 16, 
    num_inputs = 8) (

    input wire clk,
    input wire reset,
    input wire on_off, // Signal for vector fu to tell it to start data reading and op execution (toggled each cycle)

    // CGRA network port (write)
    input wire write_en, //Stays high for duration of wrtie, until write_ack is set high
    output reg write_rdy,
    input wire [width-1:0] w_data_in [num_inputs:0],
    output reg write_ack,

    // Vector fu port (read)
    output wire [width-1:0] r_data_out [num_inputs:0],
    output wire on_off_vector_fu // Goes to vector fu to activate its execution
);

module adder_fu #(parameter WIDTH = 16) (
    input wire clk,
    input wire reset,
    input wire [WIDTH-1:0] inputs [7:0],
    input wire on_off,
    input wire [1:0] config_in,
    output reg [WIDTH-1:0] outputs [3:0],
    output reg ack
);
