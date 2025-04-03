`timescale 1ns/1ps

module regfile_tb;

    parameter WIDTH = 16;
    parameter NUM_REGS = 16;
    parameter NUM_INPUTS = 8;

    reg clk;
    reg reset;
    reg rev;
    reg wen;
    reg [WIDTH-1:0] w_data [NUM_INPUTS:0];
    wire [WIDTH-1:0] r_data [NUM_INPUTS:0];
    wire wr_ack;

    regfile #(
        .width(WIDTH),
        .num_regs(NUM_REGS),
        .num_inputs(NUM_INPUTS)
    ) uut (
        .clk(clk),
        .reset(reset),
        .rev(rev),
        .wen(wen),
        .w_data(w_data),
        .r_data(r_data),
        .wr_ack(wr_ack)
    );
    always @(wr_ack) begin
        $display("Write ack just changed, wr_ack=%b", wr_ack);
    end

    initial begin
        clk = 0;
        reset = 1;
        rev = 0;
        wen = 0;

        // Reset the regfile
        #10;
        reset = 0;

        // Write data into registers
        wen = 1;
        w_data[0] = 16'h1111;
        w_data[1] = 16'h2222;
        w_data[2] = 16'h3333;
        w_data[3] = 16'h4444;
        w_data[4] = 16'h5555;
        w_data[5] = 16'h6666;
        w_data[6] = 16'h7777;
        w_data[7] = 16'h8888;
        w_data[8] = 16'h9999;
        $display("Just wrote some vals,wr_ack=%b", wr_ack);


        #10;
        wen = 0;

        // Read data from registers (rev = 1)
        rev = 1;
        #10;
        $display("Read with rev=1: r_data[8]=%h", r_data[8]);

        // Read data from registers (rev = 0)
        rev = 0;
        #10;
        $display("Read with rev=0: r_data[8]=%h", r_data[8]);

        // Write new data to some registers
        wen = 1;
        w_data[0] = 16'hAAAA;
        w_data[3] = 16'hBBBB;
        w_data[8] = 16'hCCCC;

        #10;
        wen = 0;

        // Read data after partial write
        rev = 1;
        #10;
        $display("Read after partial write: r_data[8]=%h", r_data[8]);

        // Test with rev = 1 and wen = 1, should not write.
        wen = 1;
        rev = 1;
        w_data[0] = 16'hDDDD;
        #10;
        rev = 0;
        wen = 0;
        #10;
        rev = 1;
        #10;
        $display("Read after rev==1 and wen==1 write attempt: r_data=%h",r_data[0]);
        $display("wr_ack=%b", wr_ack);

        $finish;
    end

    always #5 clk = ~clk;

endmodule