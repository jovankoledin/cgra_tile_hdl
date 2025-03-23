`timescale 1ns/1ps

module adder_fu_tb;

    parameter WIDTH = 16;

    reg clk;
    reg reset;
    reg [WIDTH-1:0] inputs [7:0];
    reg on_off;
    reg [1:0] config_tb;
    wire [WIDTH-1:0] outputs [3:0];
    wire carry_out_final;

    adder_fu #( .WIDTH(WIDTH) ) uut (
        .clk(clk),
        .reset(reset),
        .inputs(inputs),
        .on_off(on_off),
        .config_in(config_tb),
        .outputs(outputs),
        .carry_out_final(carry_out_final)
    );

    initial begin
        clk = 0;
        reset = 1;
        on_off = 1;
        config_tb = 2'd0;

        inputs[0] = 16'd1;
        inputs[1] = 16'd2;
        inputs[2] = 16'd3;
        inputs[3] = 16'd4;
        inputs[4] = 16'd5;
        inputs[5] = 16'd6;
        inputs[6] = 16'd7;
        inputs[7] = 16'd8;

        #10;
        reset = 0;
        #10;
        // Test 4x16b adders (config_tb = 2'd0)
        $display("Config: 2'd0, Inputs: %p, Outputs: %p, Carry: %b", inputs, outputs, carry_out_final);

        config_tb = 2'd1; // Test 2x32b adders
        inputs[0] = 16'd10;
        inputs[1] = 16'd20;
        inputs[2] = 16'd30;
        inputs[3] = 16'd40;
        inputs[4] = 16'd50;
        inputs[5] = 16'd60;
        inputs[6] = 16'd70;
        inputs[7] = 16'd80;
        #20;
        $display("Config: 2'd1, Inputs: %p, Outputs: %p, Carry: %b", inputs, outputs, carry_out_final);

        config_tb = 2'd3; // Test 1x64b adder
        inputs[0] = 16'd100;
        inputs[1] = 16'd200;
        inputs[2] = 16'd300;
        inputs[3] = 16'd400;
        inputs[4] = 16'd500;
        inputs[5] = 16'd600;
        inputs[6] = 16'd700;
        inputs[7] = 16'd800;
        #20;
        $display("Config: 2'd3, Inputs: %p, Outputs: %p, Carry: %b", inputs, outputs, carry_out_final);

        on_off = 0; // Test off mode
        #10;
        $display("Config: %d, off mode, Outputs: %p, Carry: %b", config_tb, outputs, carry_out_final);

        $finish;
    end

    always #5 clk = ~clk; // Generate clock

endmodule