`timescale 1ns/1ps

module half_adder_tb;

  parameter WIDTH = 16;

  reg reset;
  reg [WIDTH-1:0] a;
  reg [WIDTH-1:0] b;
  wire [WIDTH-1:0] c;
  wire carry_out;
  wire ack;
  reg [0:0] on_off;

  half_adder #( .width(WIDTH) ) dut (
    .reset(reset),
    .a(a),
    .b(b),
    .c(c),
    .carry_out(carry_out),
    .ack(ack),
    .on_off(on_off)
  );

  initial begin
    // Initialize inputs
    reset = 1'b1;
    a = 0;
    b = 0;
    on_off = 1'b0;

    // Apply reset
    #10;
    reset = 1'b0;

    // Test case 1: on_off = 0 (disabled)
    #10;
    on_off = 1'b0;
    a = 16'h1234;
    b = 16'h5678;
    #10;
    if (c !== 16'h0 || carry_out !== 1'b0 || ack !== 1'b0) $error("Test case 1 failed"); else $display("Test case 1 passed");

    // Test case 2: on_off = 1 (enabled)
    #10;
    on_off = 1'b1;
    a = 16'h1234;
    b = 16'h5678;
    #10;
    if ({carry_out, c} !== 17'h068AC) $error("Test case 2 failed"); else $display("Test case 2 passed");

    // Test case 3: on_off = 1, Max values
    #10;
    a = 16'hFFFF;
    b = 16'h0001;
    #10;
    if ({carry_out, c} !== 17'h10000) $error("Test case 3 failed"); else $display("Test case 3 passed");

    // Test case 4: on_off = 1, zero values
    #10;
    a = 16'h0000;
    b = 16'h0000;
    #10;
    if ({carry_out, c} !== 17'h00000) $error("Test case 4 failed"); else $display("Test case 4 passed");

    // Test case 5: on_off = 1, different values
    #10;
    a = 16'hAAAA;
    b = 16'h5555;
    #10;
    if ({carry_out, c} !== 17'h0FFFF) $error("Test case 5 failed"); else $display("Test case 5 passed");

    // Test case 6: Large values that generate a carry
    #10;
    a = 16'h8000;
    b = 16'h8000;
    #10;
    if ({carry_out, c} !== 17'h10000) $error("Test case 6 failed"); else $display("Test case 6 passed");

    #10;
    $finish;
  end

endmodule