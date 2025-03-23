`timescale 1ns/1ps

module full_adder_tb;

  parameter WIDTH = 16;

  reg reset;
  reg [WIDTH-1:0] a;
  reg [WIDTH-1:0] b;
  wire [WIDTH-1:0] c;
  reg [0:0] carry_in;
  wire carry_out;
  wire ack;
  reg [0:0] carry_listen;
  reg [0:0] on_off;

  full_adder #( .width(WIDTH) ) dut (
    .reset(reset),
    .a(a),
    .b(b),
    .c(c),
    .carry_in(carry_in),
    .carry_out(carry_out),
    .ack(ack),
    .carry_listen(carry_listen),
    .on_off(on_off)
  );

  initial begin
    // Initialize inputs
    reset = 1'b1;
    a = 0;
    b = 0;
    carry_in = 1'b0;
    carry_listen = 1'b0;
    on_off = 1'b0;

    // Apply reset
    #10;
    reset = 1'b0;

    // Test case 1: on_off = 0 (disabled)
    #10;
    on_off = 1'b0;
    a = 16'h1234;
    b = 16'h5678;
    carry_in = 1'b1;
    carry_listen = 1'b1;
    #10;
    if (c !== 16'h0 || carry_out !== 1'b0 || ack !==1'b0) $error("Test case 1 failed"); else $display("Test case 1 passed");

    // Test case 2: on_off = 1, carry_listen = 0 (no carry_in)
    #10;
    on_off = 1'b1;
    carry_listen = 1'b0;
    a = 16'h1234;
    b = 16'h5678;
    carry_in = 1'b1; // carry_in should be ignored
    #10;
    if ({carry_out, c} !== 17'h068AC) $error("Test case 2 failed"); else $display("Test case 2 passed");

    // Test case 3: on_off = 1, carry_listen = 1, carry_in = 0
    #10;
    carry_listen = 1'b1;
    carry_in = 1'b0;
    a = 16'h1234;
    b = 16'h5678;
    #10;
    if ({carry_out, c} !== 17'h068AC || ack !== 1'b1) $error("Test case 3 failed"); else $display("Test case 3 passed");

    // Test case 4: on_off = 1, carry_listen = 1, carry_in = 1
    #10;
    carry_in = 1'b1;
    a = 16'h1234;
    b = 16'h5678;
    #10;
    if ({carry_out, c} !== 17'h068AD) $error("Test case 4 failed"); else $display("Test case 4 passed");

    // Test case 5: Max Value test
    #10;
    a = 16'hFFFF;
    b = 16'h0001;
    carry_in = 1'b0;
    #10;
    if ({carry_out, c} !== 17'h10000) $error("Test case 5 failed"); else $display("Test case 5 passed");

    // Test case 6: Max Value test with Carry in
    #10;
    carry_in = 1'b1;
    #10;
    if ({carry_out, c} !== 17'h10001) $error("Test case 6 failed"); else $display("Test case 6 passed");

    // Test case 7: Zero Values test
    #10;
    a = 16'h0000;
    b = 16'h0000;
    carry_in = 1'b0;
    #10;
    if ({carry_out, c} !== 17'h00000) $error("Test case 7 failed"); else $display("Test case 7 passed");

    // Test case 8: Zero Values test with carry in.
    #10;
    carry_in = 1'b1;
    #10;
    if ({carry_out, c} !== 17'h00001) $error("Test case 8 failed"); else $display("Test case 8 passed");

    #10;
    $finish;
  end

endmodule