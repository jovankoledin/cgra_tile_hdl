`timescale 1ns/1ps

module multiplier_fu_tb;

// Parameters
parameter WIDTH = 32;
parameter OUT_WIDTH = WIDTH + WIDTH;

// Signals
reg clk;
reg reset;
reg on_off;
reg [WIDTH-1:0] a;
reg [WIDTH-1:0] b;
wire ack;
wire [OUT_WIDTH-1:0] c;

// Instantiate the multiplier_fu module
multiplier_fu #(
    .width(WIDTH),
    .out_width(OUT_WIDTH)
) uut (
    .clk(clk),
    .reset(reset),
    .on_off(on_off),
    .a(a),
    .b(b),
    .ack(ack),
    .c(c)
);

  // Clock generation
  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

// Testbench
initial begin
    // Initialize signals
    reset = 1;
    on_off = 0;
    a = 0;
    b = 0;

    // Apply reset
    #10;
    reset = 0;

    // Test case 1: on_off = 0 (output should be 0, ack = 0)
    #10;
    $display("Test Case 1: on_off = 0");
    on_off = 0;
    a = 32'h12345678;
    b = 32'h9ABCDEF0;
    #10;
    $display("  a = %h, b = %h, c = %h, ack = %b", a, b, c, ack);
    if (c == 64'b0 && ack == 0) $display("  PASS");
    else $display("  FAIL");

    // Test case 2: on_off = 1, simple multiplication
    #10;
    $display("Test Case 2: on_off = 1, simple multiplication");
    on_off = 1;
    a = 32'h00000002;
    b = 32'h00000003;
    #10;
    $display("  a = %h, b = %h, c = %h, ack = %b", a, b, c, ack);
    if (c == 64'd6 && ack == 1) $display("  PASS");
    else $display("  FAIL");

    // Test case 3: on_off = 1, larger multiplication
    #10;
    $display("Test Case 3: on_off = 1, larger multiplication");
    a = 32'h12345678;
    b = 32'h9ABCDEF0;
    #10;
    $display("  a = %h, b = %h, c = %h, ack = %b", a, b, c, ack);
    if (c == (32'h12345678 * 32'h9ABCDEF0) && ack == 1) $display("  PASS");
    else $display("  FAIL");

    // Test case 4: on_off toggles during multiplication
    #10;
    $display("Test Case 4: on_off toggles during multiplication");
    a = 32'h00000005;
    b = 32'h00000007;
    on_off = 1;
    #5;  //on_off is high at posedge clk
    on_off = 0; //on_off goes low before next posedge clk
    #5;
    $display("  a = %h, b = %h, c = %h, ack = %b", a, b, c, ack); // output should be zero
    if (c == 0 && ack == 0) $display("  PASS");
    else $display("  FAIL");

    // Test case 5: Max value test
    #10;
    $display("Test Case 5: Max value test");
    a = 32'hFFFFFFFF;
    b = 32'hFFFFFFFF;
    on_off = 1;
    #10;
    $display("  a = %h, b = %h, c = %h, ack = %b", a, b, c, ack);
    if (c == (64'hFFFFFFFE00000001) && ack == 1) $display("  PASS");
    else $display("  FAIL");

    $finish;
end
endmodule