`timescale 1ns/1ps

module mem_tb;

  // Parameters
  localparam width = 16;
  localparam num_regs = 16;
  localparam num_inputs = 4;
  localparam total_inputs = num_inputs + num_inputs;

  // Signals
  reg clk;
  reg reset;
  reg on_off;
  reg write_en1, write_en2, write_en3;
  reg [width-1:0] w_data_in1 [num_inputs-1:0];
  reg [width-1:0] w_data_in2 [num_inputs-1:0];
  reg [width-1:0] w_data_in3;
  wire write_ack;
  wire write_rdy1, write_rdy2, write_rdy3;
  wire [width-1:0] r_data_out [total_inputs:0];
  wire on_off_vector_fu;

  // Instantiate the mem module
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
    .write_en2(write_en2),
    .write_rdy2(write_rdy2),
    .w_data_in2(w_data_in2),
    .write_en3(write_en3),
    .write_rdy3(write_rdy3),
    .w_data_in3(w_data_in3),
    .write_ack(write_ack),
    .r_data_out(r_data_out),
    .on_off_vector_fu(on_off_vector_fu)
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

    // Test write from neighbor 1
    write_en1 = 1;
    #20;
    write_en1 = 0;
    #10;

    // Test write from neighbor 2
    write_en2 = 1;
    #20;
    write_en2 = 0;
    #10;

    // Test write from config programmer
    write_en3 = 1;
    #20;
    write_en3 = 0;
    #30;

    // Test read operation
    on_off = 1;
    #10;

    // Verify read data
    $display("Read Data (After Individual Writes):");
    for (int i = 0; i <= total_inputs; i = i + 1) begin
      $display("r_data_out[%0d] = %0d", i, r_data_out[i]);
    end

    on_off = 0;

    for (int i = 0; i < num_inputs; i = i + 1) begin
      w_data_in1[i] = i + 2;
      w_data_in2[i] = i + 20;
    end
    w_data_in3 = 200;

    // Test simultaneous writes
    write_en1 = 1;
    write_en2 = 1;
    write_en3 = 1;
    #10;
    write_en1 = 0;
    write_en2 = 0;
    write_en3 = 0;
    #10;
    
    on_off = 1;
    #10;
    $display("Read Data (After simultaneous writes):");
    for (int i = 0; i <= total_inputs; i = i + 1) begin
      $display("r_data_out[%0d] = %0d", i, r_data_out[i]);
    end

    //Test write ready signals while writing.
    on_off = 0;
    write_en1 = 1;
    #10;
    $display("write_rdy1=%0b, write_rdy2=%0b, write_rdy3=%0b",write_rdy1, write_rdy2, write_rdy3);
    #5;
    write_en1 = 0;
    #10;


    // Test multiple writes back to back.
    on_off = 0;
    write_en1 = 1;
    #5;
    write_en1 = 0;
    write_en2 = 1;
    #5;
    write_en2 = 0;
    write_en3 = 1;
    #5;
    write_en3 = 0;
    #10;

    // Test write ready high when idle.
    $display("write_rdy1=%0b, write_rdy2=%0b, write_rdy3=%0b",write_rdy1, write_rdy2, write_rdy3);

    $finish;
  end

endmodule