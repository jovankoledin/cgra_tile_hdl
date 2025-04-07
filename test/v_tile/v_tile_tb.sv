`timescale 1ns/1ps

module v_tile_tb;

    localparam width = 16;
    localparam num_inputs = 4;
    localparam num_regs = 16;

    logic clk;
    logic reset;
    logic on_off;

    logic write_en1, write_en2, write_en3;
    logic write_rdy1, write_rdy2, write_rdy3;
    logic [width-1:0] w_data_in1 [num_inputs-1:0];
    logic [width-1:0] w_data_in2 [num_inputs-1:0];
    logic [width-1:0] w_data_in3;
    logic write_ack1, write_ack2, write_ack3;

    wire [width-1:0] adder_outputs [num_inputs-1:0];
    logic [3:0] dest_info;
    logic adder_ack;

    // Clock gen
    always #5 clk = ~clk;

    v_tile #(
        .width(width),
        .num_inputs(num_inputs),
        .num_regs(num_regs)
    ) dut (
        .clk(clk),
        .reset(reset),
        .on_off(on_off),
        .write_en1(write_en1),
        .write_rdy1(write_rdy1),
        .w_data_in1(w_data_in1),
        .write_ack1(write_ack1),
        .write_en2(write_en2),
        .write_rdy2(write_rdy2),
        .w_data_in2(w_data_in2),
        .write_ack2(write_ack2),
        .write_en3(write_en3),
        .write_rdy3(write_rdy3),
        .w_data_in3(w_data_in3),
        .write_ack3(write_ack3),
        .adder_outputs(adder_outputs),
        .dest_info(dest_info),
        .adder_ack(adder_ack)
    );

    initial begin
        logic [width-1:0] vec1 [num_inputs-1:0];
        logic [width-1:0] vec2 [num_inputs-1:0];
        logic [width-1:0] expected [num_inputs-1:0];
        int i;

        clk = 0;
        reset = 1;
        on_off = 0;
        write_en1 = 0; write_en2 = 0; write_en3 = 0;

        #20 reset = 0;

        // Assign test vectors
        w_data_in1[0] = 16'hFFFF;
        w_data_in1[1] = 16'hFFFF;
        w_data_in1[2] = 16'hFFFF;
        w_data_in1[3] = 16'h0000;

        w_data_in2[0] = 16'h1;
        w_data_in2[1] = 16'h0000;
        w_data_in2[2] = 16'h0000;
        w_data_in2[3] = 16'h0000;

        // Expected sum
        expected[0] = w_data_in1[0] + w_data_in1[1];
        expected[1] = w_data_in1[2] + w_data_in1[3];
        expected[2] = w_data_in2[0] + w_data_in2[1];
        expected[3] = w_data_in2[2] + w_data_in2[3];


        // Write config (no need for fork here)
        wait (write_rdy3);
        w_data_in3 = 16'b0000000000000001;
        write_en3 = 1;
        wait (write_ack3);
        write_en3 = 0;

        // Write inputs in parallel
        fork
            begin
                wait (write_rdy1);
                write_en1 = 1;
                wait (write_ack1);
                write_en1 = 0;
            end
            begin
                wait (write_rdy2);
                write_en2 = 1;
                wait (write_ack2);
                write_en2 = 0;
            end
        join


        // Fire computation
        #10 on_off = 1;
        wait(adder_ack);
        // Output verification
        for (i = 0; i < num_inputs; i++) begin
            $display("out[%0d] = %h", i, adder_outputs[i]);
            //if (adder_outputs[i] !== expected[i])
            //    $display("FAIL: out[%0d] = %h expected = %h", i, adder_outputs[i], expected[i]);
            //else
            //    $display("PASS: out[%0d] = %h", i, adder_outputs[i]);
        end

        $finish;
    end

endmodule
