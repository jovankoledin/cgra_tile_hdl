`timescale 1ns/1ps

module adder_fu_tb;

    // Parameters
    parameter WIDTH = 32;

    // Signals
    logic clk;
    logic reset;
    logic [WIDTH-1:0] a;
    logic [WIDTH-1:0] b;
    wire [WIDTH-1:0] c;
    wire ack;
    logic on_off;

    // Instantiate the adder_fu module
    adder_fu #(
        .width(WIDTH)
    ) uut (
        .clk(clk),
        .reset(reset),
        .a(a),
        .b(b),
        .c(c),
        .ack(ack),
        .on_off(on_off)
    );

    // Clock generation
    initial begin
      clk = 0;
      forever #5 clk = ~clk;
    end

    // Testbench
    initial begin
        // Initialize signals
        clk = 0;
        reset = 1;
        on_off = 0;
        a = 0;
        b = 0;

        // Apply reset
        #10;
        reset = 0;

        // Test Case 1: on_off = 0, check reset condition
        #10;
        $display("Test Case 1: on_off = 0");
        on_off = 0;
        a = 32'h1234;
        b = 32'h5678;
        #10;
        $display("  a = %h, b = %h, c = %h, ack = %b", a, b, c, ack);
        if (c == 0 && ack == 0) $display("  PASS");
        else $display("  FAIL");

        // Test Case 2: on_off = 1, simple addition
        #10;
        $display("Test Case 2: on_off = 1, simple addition");
        on_off = 1;
        a = 32'h0001;
        b = 32'h0002;
        #10;
        $display("  a = %h, b = %h, c = %h, ack = %b", a, b, c, ack);
        if (c == 32'h0003 && ack == 1) $display("  PASS");
        else $display("  FAIL");

        // Test Case 3: on_off = 1, larger addition
        #10;
        $display("Test Case 3: on_off = 1, larger addition");
        a = 32'h1234;
        b = 32'h5678;
        #10;
        $display("  a = %h, b = %h, c = %h, ack = %b", a, b, c, ack);
        if (c == 32'h68AC && ack == 1) $display("  PASS");
        else $display("  FAIL");

        // Test Case 4: on_off = 1, addition with carry within width
        #10;
        $display("Test Case 4: on_off = 1, addition with carry within width");
        a = 32'h7FFF;
        b = 32'h0001;
        #10;
        $display("  a = %h, b = %h, c = %h, ack = %b", a, b, c, ack);
        if (c == 32'h8000 && ack == 1) $display("  PASS");
        else $display("  FAIL");

        // Test Case 5: on_off toggles
        #10;
         $display("Test Case 5: on_off toggles");
        a = 32'h0005;
        b = 32'h0007;
        on_off = 1;
        #5;
        on_off = 0;
        #5;
        $display("  a = %h, b = %h, c = %h, ack = %b", a, b, c, ack);
        if(c == 32'h0000 && ack == 0) $display("PASS");
        else $display("FAIL");

        $finish;
    end

endmodule
