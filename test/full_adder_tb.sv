`timescale 1ns/1ps

module full_adder_tb;

    parameter width = 8; // Adjust width as needed

    reg  [width-1:0] a_tb;
    reg  [width-1:0] b_tb;
    wire [width-1:0] c_tb;
    reg  [0:0] carry_in_tb;
    wire [0:0] carry_out_tb;
    reg  [0:0] carry_listen_tb;
    reg  [0:0] on_off_tb;

    full_adder #( .width(width) ) uut (
        .a(a_tb),
        .b(b_tb),
        .c(c_tb),
        .carry_in(carry_in_tb),
        .carry_out(carry_out_tb),
        .carry_listen(carry_listen_tb),
        .on_off(on_off_tb)
    );

    initial begin
        // Initialize inputs
        a_tb = 8'd5;
        b_tb = 8'd10;
        carry_in_tb = 1'b0;
        carry_listen_tb = 1'b1;
        on_off_tb = 1'b1;

        // Apply test vectors
        #10;
        $display("a=%d, b=%d, carry_in=%b, carry_listen=%b, on_off=%b, sum=%d, carry_out=%b",
                 a_tb, b_tb, carry_in_tb, carry_listen_tb, on_off_tb, c_tb, carry_out_tb);

        a_tb = 8'd150;
        b_tb = 8'd10;
        carry_in_tb = 1'b1;
        carry_listen_tb = 1'b0;
        on_off_tb = 1'b1;

        #10;
        $display("a=%d, b=%d, carry_in=%b, carry_listen=%b, on_off=%b, sum=%d, carry_out=%b",
                 a_tb, b_tb, carry_in_tb, carry_listen_tb, on_off_tb, c_tb, carry_out_tb);

        on_off_tb = 1'b0;
        #10;
        $display("a=%d, b=%d, carry_in=%b, carry_listen=%b, on_off=%b, sum=%d, carry_out=%b",
                 a_tb, b_tb, carry_in_tb, carry_listen_tb, on_off_tb, c_tb, carry_out_tb);

        $finish;
    end

endmodule