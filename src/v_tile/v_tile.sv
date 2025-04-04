/*
Consists of Vector adder Functional unit and local mem register file
Local register file contains adder inputs and configuration info
Can perform 4x16b, 2x32b, or 1x64b add operations on data in register file, config info specifies which of the three add operations 
Ouputs are sent to neighbor specified in config info 
CGRA network writes configuration data and adder inputs into the local mem
*/

`timescale 1ns/1ps
`include "../../src/config_mem/regfile.sv"
module v_tile #(
    parameter width = 16, 
    num_regs = 16, 
    num_inputs = 8) (

    input wire clk,
    input wire reset,
    input wire on_off, // Signal for vector fu to tell it to start data reading and op execution (toggled each execution cycle)

    // CGRA network port
    // Data is written to config_mem
    input wire write_en, //Stays high for duration of wrtie, until write_ack is set high
    output reg write_rdy,
    input wire [width-1:0] w_data_in [num_inputs:0],
    output reg write_ack,
);

  // Parameters
  parameter width = 16;
  parameter num_regs = 16;
  parameter num_inputs = 8;

  // Inputs
  reg clk;
  reg reset;
  reg on_off;
  reg write_en;
  reg [width-1:0] w_data_in [num_inputs:0];

  // Outputs
  wire write_rdy;
  wire write_ack;
  wire [width-1:0] r_data_out [num_inputs:0];
  wire on_off_vector_fu;

  // Instantiate the module under test
  config_mem #(
    .width(width),
    .num_regs(num_regs),
    .num_inputs(num_inputs)
  ) dut (
    .clk(clk),
    .reset(reset),
    .on_off(on_off),
    .write_en(write_en),
    .write_rdy(write_rdy),
    .w_data_in(w_data_in),
    .write_ack(write_ack),
    .r_data_out(r_data_out),
    .on_off_vector_fu(on_off_vector_fu)
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
