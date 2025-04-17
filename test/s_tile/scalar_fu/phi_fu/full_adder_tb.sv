`timescale 1ns / 1ps

module full_adder_tb;

  // Parameters
  parameter WIDTH = 16;

  // Inputs
  reg clk;
  reg reset;
  reg [WIDTH-1:0] a;
  reg [WIDTH-1:0] b;
  reg carry_in;
  reg carry_listen;
  reg on_off;

  // Outputs
  wire [WIDTH-1:0] c;
  wire carry_out;
  wire ack;

  // Instantiate the module
  full_adder #(
    .width(WIDTH)
  ) dut (
    .clk(clk),
    .reset(reset),
    .a(a),
    .b(b),
    .carry_in(carry_in),
    .c(c),
    .carry_out(carry_out),
    .ack(ack),
    .carry_listen(carry_listen),
    .on_off(on_off)
  );

  // Clock generation
  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  // Test sequence
  initial begin
    // Reset sequence
    reset = 1;
    on_off = 1;
    #10;
    reset = 0;
    #10;

    // Test case 1: Basic addition without carry_in and carry_listen
    a = 16'h000A;
    b = 16'h0005;
    carry_in = 1'b0;
    carry_listen = 1'b0;
    #10;
    $display("Test Case 1: a=%h, b=%h, carry_in=%b, carry_listen=%b, c=%h, carry_out=%b, ack=%b", a, b, carry_in, carry_listen, c, carry_out, ack);
    assert (c == 16'h000F) else $error("Test Case 1 failed: c mismatch");
    assert (carry_out == 1'b0) else $error("Test Case 1 failed: carry_out mismatch");
    assert (ack == 1'b1) else $error("Test Case 1 failed: ack mismatch");

    // Test case 2: Addition with carry_in and carry_listen
    a = 16'h000A;
    b = 16'h0005;
    carry_in = 1'b1;
    carry_listen = 1'b0;
    #10;
    $display("Test Case 2: a=%h, b=%h, carry_in=%b, carry_listen=%b, c=%h, carry_out=%b, ack=%b", a, b, carry_in, carry_listen, c, carry_out, ack);
    assert (c == 16'h000F) else $error("Test Case 2 failed: c mismatch");
    assert (carry_out == 1'b0) else $error("Test Case 2 failed: carry_out mismatch");
    assert (ack == 1'b1) else $error("Test Case 2 failed: ack mismatch");

    // Test case 3: Addition with carry_out
    a = 16'hFFFF;
    b = 16'h0001;
    carry_in = 1'b0;
    carry_listen = 1'b0;
    #10;
    $display("Test Case 3: a=%h, b=%h, carry_in=%b, carry_listen=%b, c=%h, carry_out=%b, ack=%b", a, b, carry_in, carry_listen, c, carry_out, ack);
    assert (c == 16'h0000) else $error("Test Case 3 failed: c mismatch");
    assert (carry_out == 1'b1) else $error("Test Case 3 failed: carry_out mismatch");
    assert (ack == 1'b1) else $error("Test Case 3 failed: ack mismatch");

    // Test case 4: Addition with carry_in and carry_out
    a = 16'hFFFF;
    b = 16'h0000;
    carry_in = 1'b1;
    carry_listen = 1'b1;
    #10;
    $display("Test Case 4: a=%h, b=%h, carry_in=%b, carry_listen=%b, c=%h, carry_out=%b, ack=%b", a, b, carry_in, carry_listen, c, carry_out, ack);
    assert (c == 16'h0000) else $error("Test Case 4 failed: c mismatch");
    assert (carry_out == 1'b1) else $error("Test Case 4 failed: carry_out mismatch");
    assert (ack == 1'b1) else $error("Test Case 4 failed: ack mismatch");

    // Test case 5: on_off = 0
    a = 16'h000A;
    b = 16'h0005;
    carry_in = 1'b1;
    carry_listen = 1'b1;
    on_off = 0;
    #10;
    $display("Test Case 5: on_off=%b, c=%h, carry_out=%b, ack=%b", on_off, c, carry_out, ack);
    assert (c == 16'h0000) else $error("Test Case 5 failed: c mismatch");
    assert (carry_out == 1'b0) else $error("Test Case 5 failed: carry_out mismatch");
    assert (ack == 1'b0) else $error("Test Case 5 failed: ack mismatch");

    // Test case 6: on_off back to 1.
    on_off = 1;
    #10;
    $display("Test Case 6: on_off=%b, c=%h, carry_out=%b, ack=%b", on_off, c, carry_out, ack);
    assert (c == 16'h0010) else $error("Test Case 6 failed: c mismatch");
    assert (carry_out == 1'b0) else $error("Test Case 6 failed: carry_out mismatch");
    assert (ack == 1'b1) else $error("Test Case 6 failed: ack mismatch");

    $finish;
  end

endmodule