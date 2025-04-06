`timescale 1ns/1ps

module mem_tb;

    localparam width = 16;
    localparam num_inputs = 4;
    localparam num_regs = 16;
    localparam total_inputs = num_inputs * 2;

    logic clk;
    logic reset;
    logic on_off;

    logic write_en1, write_en2, write_en3;
    logic write_rdy1, write_rdy2, write_rdy3;
    logic [width-1:0] w_data_in1 [num_inputs-1:0];
    logic [width-1:0] w_data_in2 [num_inputs-1:0];
    logic [width-1:0] w_data_in3;
    logic write_ack1, write_ack2, write_ack3;
    logic [width-1:0] vec1 [num_inputs-1:0];
    logic [width-1:0] vec2 [num_inputs-1:0];
    logic [width-1:0] config_value;

    logic [width-1:0] config_in;
    wire [width-1:0] adder_inputs [total_inputs-1:0];
    logic on_off_vector_fu, r_data_vld;

    // Instantiate DUT
    mem #(
        .width(width),
        .num_regs(num_regs),
        .num_inputs(num_inputs)
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
        .config_in(config_in),
        .adder_inputs(adder_inputs),
        .r_data_vld(r_data_vld),
        .on_off_vector_fu(on_off_vector_fu)
    );

    // Clock generation
    always #5 clk = ~clk;

    initial begin
        clk = 0;
        reset = 1;
        on_off = 0;

        write_en1 = 0;
        write_en2 = 0;
        write_en3 = 0;

        #20 reset = 0;


        config_value = 16'h1;

        // Load test data
        for (int i = 0; i < num_inputs; i++) begin
            w_data_in1[i] = i + 1;
            w_data_in2[i] = (i + 1) * 10;
        end

        // === CONFIG WRITE ===
        fork
            begin
                wait(write_rdy3);
                w_data_in3 = config_value;
                write_en3 = 1;
                wait(write_ack3);
                write_en3 = 0;
                $display("Wrote config: %h", config_value);
            end
        join

        // === PARALLEL VECTOR WRITES ===
        fork
            begin
                wait(write_rdy1);
                write_en1 = 1;
                wait(write_ack1);
                write_en1 = 0;
                $display("Wrote vec1");
            end
            begin
                wait(write_rdy2);
                write_en2 = 1;
                wait(write_ack2);
                write_en2 = 0;
                $display("Wrote vec2");
            end
        join

        // === TRIGGER READ ===
        #10 on_off = 1;
        wait(r_data_vld);
        #10
        $display("on_off_vector_fu=%0b", on_off_vector_fu);


        // === CHECK OUTPUTS ===
        for (int i = 0; i < num_inputs; i++) begin
            if (adder_inputs[i] !== w_data_in1[i])
                $display("FAIL: adder_inputs[%0d] = %h != %h", i, adder_inputs[i], w_data_in1[i]);
            else
                $display("PASS: adder_inputs[%0d] = %h", i, adder_inputs[i]);

            if (adder_inputs[i + num_inputs] !== w_data_in2[i])
                $display("FAIL: adder_inputs[%0d] = %h != %h", i + num_inputs, adder_inputs[i + num_inputs], w_data_in2[i]);
            else
                $display("PASS: adder_inputs[%0d] = %h", i + num_inputs, adder_inputs[i + num_inputs]);
        end

        if (config_in !== config_value)
            $display("FAIL: config_in = %h != %h", config_in, config_value);
        else
            $display("PASS: config_in = %h", config_in);

        on_off = 0;
        $finish;
    end

endmodule
