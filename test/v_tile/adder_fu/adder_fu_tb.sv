`timescale 1ns/1ps

module adder_fu_tb;

  // Parameters
  localparam width = 16;
  localparam num_inputs = 4;
  localparam total_inputs = num_inputs * 2; // Corrected total_inputs

  // Signals
  reg clk;
  reg reset;
  reg on_off;
  reg [width-1:0] inputs [total_inputs-1:0];
  reg [15:0] config_in;
  wire [width-1:0] outputs [num_inputs-1:0];
  wire [3:0] dest_info;
  wire ack;

  // Instantiate the adder_fu module
  adder_fu #(
    .width(width),
    .num_inputs(num_inputs)
  ) adder_fu_inst (
    .clk(clk),
    .reset(reset),
    .inputs(inputs),
    .on_off(on_off),
    .config_in(config_in),
    .outputs(outputs),
    .dest_info(dest_info),
    .ack(ack)
  );

  // Clock generation
  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  // Test sequence
  initial begin
    reset = 1;
    on_off = 0;
    config_in = 0;

    // Initialize inputs
    // 1,2,3,4,5,6,7
    for (int i = 0; i < total_inputs; i = i + 1) begin
      inputs[i] = i * 10000;
    end

    #10;
    reset = 0;
    #10;

    // Test 4x16b adders
    config_in = 16'b0000000000000000; // adder_config = 0, dest_info = 0
    on_off = 1;
    #90;
    $display("4x16b Adders:");
    $display("outputs[0] = %0d, outputs[1] = %0d, outputs[2] = %0d, outputs[3] = %0d", outputs[0], outputs[1], outputs[2], outputs[3]);
    $display("dest_info = %0d, ack = %0b", dest_info, ack);
    #10;

    // Test 2x32b adders
    config_in = 16'b0000000000000001; // adder_config = 1, dest_info = 0
    on_off = 1;
    #90;
    $display("2x32b Adders:");
    $display("outputs[0] = %0d, outputs[1] = %0d, outputs[2] = %0d, outputs[3] = %0d", outputs[0], outputs[1], outputs[2], outputs[3]);
    $display("dest_info = %0d, ack = %0b", dest_info, ack);
    #10;

    // Test 1x64b adder
    config_in = 16'b0000000000000011; // adder_config = 3, dest_info = 0
    on_off = 1;
    #90;
    $display("1x64b Adder:");
    $display("outputs[0] = %0d, outputs[1] = %0d, outputs[2] = %0d, outputs[3] = %0d", outputs[0], outputs[1], outputs[2], outputs[3]);
    $display("dest_info = %0d, ack = %0b", dest_info, ack);
    #10;

    // Test invalid config
    config_in = 16'b0000000000000010; // adder_config = 2, invalid
    on_off = 1;
    #80;
    $display("Invalid Config:");
    $display("outputs[0] = %0d, outputs[1] = %0d, outputs[2] = %0d, outputs[3] = %0d", outputs[0], outputs[1], outputs[2], outputs[3]);
    $display("dest_info = %0d, ack = %0b", dest_info, ack);
    #10;

    //Test different dest_info
    config_in = 16'b0000000000110100; // adder_config = 0, dest_info = 13;
    on_off = 1;
    #80;
    $display("dest_info test:");
    $display("outputs[0] = %0d, outputs[1] = %0d, outputs[2] = %0d, outputs[3] = %0d", outputs[0], outputs[1], outputs[2], outputs[3]);
    $display("dest_info = %0d, ack = %0b", dest_info, ack);
    #10;

    $finish;
  end

endmodule