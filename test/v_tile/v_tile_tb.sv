`timescale 1ns/1ps

module v_tile_tb;

  // Parameters
  localparam width = 16;
  localparam num_inputs = 4;
  localparam num_regs = 16;
  localparam total_inputs = num_inputs * 2;

  // Signals
  reg clk;
  reg reset;
  reg on_off;
  reg write_en1, write_en2, write_en3;
  reg [width-1:0] w_data_in1 [num_inputs-1:0];
  reg [width-1:0] w_data_in2 [num_inputs-1:0];
  reg [width-1:0] w_data_in3;

  wire write_rdy1, write_rdy2, write_rdy3, write_ack1, write_ack2, write_ack3;
  wire [width-1:0] adder_outputs [num_inputs-1:0];
  wire [3:0] dest_info;
  wire adder_ack;

  // Instantiate v_tile module
  v_tile #(
    .width(width),
    .num_inputs(num_inputs),
    .num_regs(num_regs),
    .total_inputs(total_inputs)
  ) v_tile_inst (
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
    .adder_outputs(adder_outputs),
    .dest_info(dest_info),
    .adder_ack(adder_ack)
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
    write_en1 = 0;
    write_en2 = 0;
    write_en3 = 0;

    // Initialize write data
    for (int i = 0; i < num_inputs; i = i + 1) begin
      w_data_in1[i] = i + 1;
      w_data_in2[i] = i + 10;
    end
    w_data_in3 = 100;

    #10;
    reset = 0;
    #10;

    // Write data from neighbor 1
    write_en1 = 1;
    #10;
    write_en1 = 0;
    #10;

    // Write data from neighbor 2
    write_en2 = 1;
    #10;
    write_en2 = 0;
    #10;

    // Write config data
    write_en3 = 1;
    #10;
    write_en3 = 0;
    #10;

    // Trigger adder_fu (4x16b)
    on_off = 1;
    #20;
    on_off = 0;
    $display("4x16b Adder Outputs:");
    $display("adder_outputs[0] = %0d, adder_outputs[1] = %0d, adder_outputs[2] = %0d, adder_outputs[3] = %0d", adder_outputs[0], adder_outputs[1], adder_outputs[2], adder_outputs[3]);
    $display("dest_info = %0d, adder_ack = %0b", dest_info, adder_ack);
    #10;

        // Trigger adder_fu (2x32b)
    w_data_in3 = 1;
    write_en3 = 1;
    #10;
    write_en3 = 0;
    #10;
    on_off = 1;
    #30;
    on_off = 0;
    $display("2x32b Adder Outputs:");
    $display("adder_outputs[0] = %0d, adder_outputs[1] = %0d, adder_outputs[2] = %0d, adder_outputs[3] = %0d", adder_outputs[0], adder_outputs[1], adder_outputs[2], adder_outputs[3]);
    $display("dest_info = %0d, adder_ack = %0b", dest_info, adder_ack);
    #10;

        // Trigger adder_fu (1x64b)
    w_data_in3 = 3;
    write_en3 = 1;
    #10;
    write_en3 = 0;
    #10;
    on_off = 1;
    #40;
    on_off = 0;
    $display("1x64b Adder Outputs:");
    $display("adder_outputs[0] = %0d, adder_outputs[1] = %0d, adder_outputs[2] = %0d, adder_outputs[3] = %0d", adder_outputs[0], adder_outputs[1], adder_outputs[2], adder_outputs[3]);
    $display("dest_info = %0d, adder_ack = %0b", dest_info, adder_ack);
    #10;

    $finish;
  end

endmodule