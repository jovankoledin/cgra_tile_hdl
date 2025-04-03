`timescale 1ns/1ps

module config_mem_tb;

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

  // Clock generation
  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  // Test sequence
  initial begin
    // Initialize inputs
    reset = 1;
    on_off = 0;
    write_en = 0;

    // Apply reset
    #10;
    reset = 0;

    // Write data to registers
    #10;
    write_en = 1;
    for (int i = 0; i <= num_inputs; i = i + 1) begin
      w_data_in[i] = i * 10; // Example data
    end
    #10;
    while (!write_ack) #10; // Wait for write acknowledge
    write_en = 0;

    // Read data from registers
    #10;
    on_off = 1;
    #10;
    $display("Read Data:");
    for (int i = 0; i <= num_inputs; i = i + 1) begin
      $display("r_data_out[%0d] = %0d", i, r_data_out[i]);
      if (r_data_out[i] != i * 10) $error("Data mismatch at reg %0d",i);
    end
    on_off = 0;

    // Test write_rdy
    #10;
    if (write_rdy != 1) $error("write_rdy not high when idle");

    write_en = 1;
    #10;
    if (write_rdy != 0) $error("write_rdy not low during write");

    write_en = 0;
    while(!write_ack) #10;

    // Test on_off_vector_fu
    #10;
    if (on_off_vector_fu != 0) $error("on_off_vector_fu not low when off");
    on_off = 1;
    #10;
    if (on_off_vector_fu != 1) $error("on_off_vector_fu not high when on");
    on_off = 0;
    #10;
    if (on_off_vector_fu != 0) $error("on_off_vector_fu not low after off");

    // Additional write and read tests can be added here
    #10;
    $finish;
  end

endmodule