`timescale 1ns / 1ps

module half_adder_tb;

  // Parameters
  parameter WIDTH = 16;

  // Inputs
  reg clk;
  reg reset;
  reg [WIDTH-1:0] a;
  reg [WIDTH-1:0] b;
  reg on_off;

  // Outputs
  wire [WIDTH-1:0] c;
  wire carry_out;
  wire ack;

  // Instantiate the module
  half_adder #(
    .width(WIDTH)
  ) dut (
    .clk(clk),
    .reset(reset),
    .a(a),
    .b(b),
    .c(c),
    .carry_out(carry_out),
    .ack(ack),
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

    // Test case 1: Basic addition
    a = 16'h000A;
    b = 16'h0005;
    #10;
    $display("Test Case 1: a=%h, b=%h, c=%h, carry_out=%b, ack=%b", a, b, c, carry_out, ack);
    assert (c == 16'h000F) else $error("Test Case 1 failed: c mismatch");
    assert (carry_out == 1'b0) else $error("Test Case 1 failed: carry_out mismatch");
    assert (ack == 1'b1) else $error("Test Case 1 failed: ack mismatch");

    // Test case 2: Addition with carry_out
    a = 16'hFFFF;
    b = 16'h0001;
    #10;
    $display("Test Case 2: a=%h, b=%h, c=%h, carry_out=%b, ack=%b", a, b, c, carry_out, ack);
    assert (c == 16'h0000) else $error("Test Case 2 failed: c mismatch");
    assert (carry_out == 1'b1) else $error("Test Case 2 failed: carry_out mismatch");
    assert (ack == 1'b1) else $error("Test Case 2 failed: ack mismatch");

    // Test case 3: Addition with larger numbers
    a = 16'h8000;
    b = 16'h8000;
    #10;
    $display("Test Case 3: a=%h, b=%h, c=%h, carry_out=%b, ack=%b", a, b, c, carry_out, ack);
    assert (c == 16'h0000) else $error("Test Case 3 failed: c mismatch");
    assert (carry_out == 1'b1) else $error("Test Case 3 failed: carry_out mismatch");
    assert (ack == 1'b1) else $error("Test Case 3 failed: ack mismatch");

    // Test case 4: on_off = 0
    a = 16'h000A;
    b = 16'h0005;
    on_off = 0;
    #10;
    $display("Test Case 4: on_off=%b, c=%h, carry_out=%b, ack=%b", on_off, c, carry_out, ack);
    assert (c == 16'h0000) else $error("Test Case 4 failed: c mismatch");
    assert (carry_out == 1'b0) else $error("Test Case 4 failed: carry_out mismatch");
    assert (ack == 1'b0) else $error("Test Case 4 failed: ack mismatch");

    // Test case 5: on_off back to 1.
    on_off = 1;
    #10;
    $display("Test Case 5: on_off=%b, c=%h, carry_out=%b, ack=%b", on_off, c, carry_out, ack);
    assert (c == 16'h000F) else $error("Test Case 5 failed: c mismatch");
    assert (carry_out == 1'b0) else $error("Test Case 5 failed: carry_out mismatch");
    assert (ack == 1'b1) else $error("Test Case 5 failed: ack mismatch");

    //Test case 6: Zero input
    a = 16'h0000;
    b = 16'h0000;
    #10;
    $display("Test Case 6: a=%h, b=%h, c=%h, carry_out=%b, ack=%b", a, b, c, carry_out, ack);
    assert (c == 16'h0000) else $error("Test Case 6 failed: c mismatch");
    assert (carry_out == 1'b0) else $error("Test Case 6 failed: carry_out mismatch");
    assert (ack == 1'b1) else $error("Test Case 6 failed: ack mismatch");

    $finish;
  end

endmodule