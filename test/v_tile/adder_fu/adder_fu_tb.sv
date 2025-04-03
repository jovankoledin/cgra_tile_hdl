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
        config_tb = 2'd0;

        inputs[0] = 16'd1;
        inputs[1] = 16'd2;
        inputs[2] = 16'd3;
        inputs[3] = 16'd4;
        inputs[4] = 16'd5;
        inputs[5] = 16'd6;
        inputs[6] = 16'd7;
        inputs[7] = 16'd8;

        on_off = 1;


        #10;
        reset = 0;
        #20;
        // Test 4x16b adders (config_tb = 2'd0)
        $display("Config: 2'd0, Inputs:");
        for (int i = 0; i < 8; i++) begin
            $display("inputs[%0d] = %h", i, inputs[i]);
        end
        $display("Outputs:");
        for (int i = 0; i < 4; i++) begin
            $display("outputs[%0d] = %h", i, outputs[i]);
        end
        $display("Carry: %b", carry_out_final);

        config_tb = 2'd1; // Test 2x32b adders
        inputs[0] = 16'hFFFF;
        inputs[1] = 16'h0001;
        inputs[2] = 16'd30;
        inputs[3] = 16'd40;
        inputs[4] = 16'd50;
        inputs[5] = 16'd60;
        inputs[6] = 16'd70;
        inputs[7] = 16'd80;
        #20;
        $display("Config: 2'd1, Inputs:");
        for (int i = 0; i < 8; i++) begin
            $display("inputs[%0d] = %h", i, inputs[i]);
        end
        $display("Outputs:");
        for (int i = 0; i < 4; i++) begin
            $display("outputs[%0d] = %h", i, outputs[i]);
        end
        $display("Carry: %b", carry_out_final);

        config_tb = 2'd3; // Test 1x64b adder
        inputs[0] = 16'hFFFF;
        inputs[1] = 16'hFFFF;
        inputs[2] = 16'hFFFF;
        inputs[3] = 16'hFFFF;
        inputs[4] = 16'hFFFF;
        inputs[5] = 16'hFFFF;
        inputs[6] = 16'h0F00;
        inputs[7] = 16'h0F00;
        #20;
        $display("Config: 2'd3, Inputs:");
        for (int i = 0; i < 8; i++) begin
            $display("inputs[%0d] = %h", i, inputs[i]);
        end
        $display("Outputs:");
        for (int i = 0; i < 4; i++) begin
            $display("outputs[%0d] = %h", i, outputs[i]);
        end
        $display("Carry: %b", carry_out_final);

        on_off = 0; // Test off mode
        #25;
        $display("Config: %d, off mode, Outputs:", config_tb);
        for (int i = 0; i < 4; i++) begin
            $display("outputs[%0d] = %h", i, outputs[i]);
        end
        $display("Carry: %b", carry_out_final);

        $finish;
    end

    always #5 clk = ~clk; // Generate clock

endmodule