`timescale 1ns/1ps

module regfile_tb;

    parameter WIDTH = 16;
    parameter NUM_REGS = 16;
    parameter NUM_INPUTS = 4;
    parameter TOTAL_INPUTS = NUM_INPUTS + NUM_INPUTS;

    reg clk;
    reg reset;
    reg ren;
    reg wen1;
    reg wen2;
    reg wen3;
    reg [WIDTH-1:0] w_data1 [NUM_INPUTS-1:0];
    reg [WIDTH-1:0] w_data2 [NUM_INPUTS-1:0];
    reg [WIDTH-1:0] w_data3;
    wire [WIDTH-1:0] r_data [TOTAL_INPUTS:0];
    wire r_data_vld;
    wire wr_ack1;
    wire wr_ack2;
    wire wr_ack3;

    regfile #(
        .width(WIDTH),
        .num_regs(NUM_REGS),
        .num_inputs(NUM_INPUTS)
    ) uut (
        .clk(clk),
        .reset(reset),
        .ren(ren),
        .wen1(wen1),
        .wen2(wen2),
        .wen3(wen3),
        .w_data1(w_data1),
        .w_data2(w_data2),
        .w_data3(w_data3),
        .wr_ack1(wr_ack1),
        .wr_ack2(wr_ack2),
        .wr_ack3(wr_ack3),
        .r_data(r_data),
        .r_data_vld(r_data_vld)
    );

    initial begin
        clk = 0;
        reset = 1;
        ren = 0;
        wen1 = 0;
        wen2 = 0;
        wen3 = 0;

        // Reset the regfile
        #10;
        reset = 0;

        // Write data using wen1
        wen1 = 1;
        w_data1[0] = 16'h1111;
        w_data1[1] = 16'h2222;
        w_data1[2] = 16'h3333;
        w_data1[3] = 16'h4444;
        #20


        // Write data using wen2
        wen2 = 1;
        w_data2[0] = 16'h6666;
        w_data2[1] = 16'h7777;
        w_data2[2] = 16'h8888;
        w_data2[3] = 16'h9999;

        // Write data using wen3
        wen3 = 1;
        w_data3 = 16'hBBBB;
        #50;
        $display("wr_ack1=%b", wr_ack1);
        $display("wr_ack2=%b", wr_ack2);
        $display("wr_ack3=%b", wr_ack3);

        wen1 = 0;
        wen2 = 0;
        wen3 = 0;

        // Read data from registers (ren = 1)
        ren = 1;
        #50;
        wait(r_data_vld);
        $display("Read with ren=1: r_data[4]=%h", r_data[4]);
        $display("wr_ack1=%b", wr_ack1);
        $display("wr_ack2=%b", wr_ack2);
        $display("wr_ack3=%b", wr_ack3);

        // Read data from registers (ren = 0)
        ren = 0;
        #10;
        $display("Read with ren=0: r_data[7]=%h", r_data[7]);

        // Test simultaneous writes
        wen1 = 1;
        wen2 = 1;
        wen3 = 1;
        w_data1[0] = 16'hCCCC;
        w_data2[0] = 16'hDDDD;
        w_data3 = 16'hEEEE;

        #10;
        wen1 = 0;
        wen2 = 0;
        wen3 = 0;

        // Read data after simultaneous writes
        ren = 1;
        #10;
        $display("Read after simultaneous writes: r_data[0],[4]=%h, %h", r_data[0], r_data[4]);
        $display("wr_ack1=%b", wr_ack1);
        $display("wr_ack2=%b", wr_ack2);
        $display("wr_ack3=%b", wr_ack3);

        // Test ren = 1 during write attempts.
        wen1 = 1;
        ren = 1;
        w_data1[0] = 16'hFFFF;
        #10;
        wen1 = 0;
        ren = 0;
        #10;
        ren = 1;
        #10;
        $display("Read after ren==1 and wen1==1 write attempt: r_data[0]=%h",r_data[0]);
        $display("wr_ack1=%b", wr_ack1);
        $display("wr_ack2=%b", wr_ack2);
        $display("wr_ack3=%b", wr_ack3);
        
        $finish;
    end

    always #5 clk = ~clk;

endmodule