`timescale 1ns/1ps

module config_mem_tb;

    parameter WIDTH = 16;
    parameter NUM_REGS = 16;
    parameter NUM_INPUTS = 8;

    reg clk;
    reg reset;
    reg wen;
    wire on_off_vector_fu;
    wire on_off_vec;
    reg [WIDTH-1:0] w_data [NUM_INPUTS:0];
    wire [WIDTH-1:0] r_data [NUM_INPUTS:0];
    wire wr_ack;
    wire w_rdy;
    reg on_off;

    config_mem #(
        .width(WIDTH),
        .num_regs(NUM_REGS),
        .num_inputs(NUM_INPUTS)
    ) uut (
        .clk(clk),
        .reset(reset),
        .on_off(on_off),
        
        .write_en(wen),
        .write_rdy(w_rdy),
        .w_data_in(w_data),
        .write_ack(wr_ack),

        .r_data_out(r_data),
        .on_off_vector_fu(on_off_vec)
    );

    always @(wr_ack) begin
        $display("Write ack: %b", wr_ack);
    end

    initial begin
        clk = 0;
        reset = 1;
        wen = 0;
        on_off = 0;

        // Reset the regfile
        #10;
        reset = 0;
        #10;


        // Write data into registers
        $display("Write rdy signal: %h", w_rdy);
        wen = 1;
        #10
        $display("Write rdy signal: %h", w_rdy);

        w_data[0] = 16'h1111;
        w_data[1] = 16'h2222;
        w_data[2] = 16'h3333;
        w_data[3] = 16'h4444;
        w_data[4] = 16'h5555;
        w_data[5] = 16'h6666;
        w_data[6] = 16'h7777;
        w_data[7] = 16'h8888;
        w_data[8] = 16'h9999;
        #6
        $display("Just wrote some vals,wr_ack=%b", wr_ack);


        #10;
        wen = 0;

        // Read data from registers (rev = 1)
        on_off = 1;
        #10;
        $display("Read with on_off=1: r_data[8]=%h", r_data[8]);
        $display("Output vec_on_off=%h", on_off_vec);

        // Read data from registers (rev = 0)
        on_off = 0;
        #10;
        $display("Read with on_off=0: r_data[8]=%h", r_data[8]);
        $display("Output vec_on_off=%h", on_off_vec);

        // Write new data to some registers
        $display("Write rdy signal: %h", w_rdy);
        wen = 1;
        w_data[0] = 16'hAAAA;
        w_data[3] = 16'hBBBB;
        w_data[8] = 16'hCCCC;

        #20;
        wen = 0;

        // Read data after partial write
        on_off = 1;
        #10;
        $display("Read after partial write: r_data[8]=%h", r_data[8]);

        // Test with rev = 1 and wen = 1, should not write.
        // more test cases tbd....

        $finish;
    end

    always #5 clk = ~clk;

endmodule