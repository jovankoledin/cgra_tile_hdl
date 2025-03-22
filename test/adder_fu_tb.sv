`timescale 1ns/1ps

module adder_fu_tb;

    parameter width = 8; // Adjust width as needed

    reg  [width-1:0] a_tb;
    reg  [width-1:0] b_tb;
    wire [width-1:0] c_tb;
    reg  [0:0] carry_in_tb;
    wire [0:0] carry_out_tb;
    reg  [0:0] carry_listen_tb;
    reg  [0:0] on_off_tb;
    
    typedef enum {
        add_16,
        add_32,
        add_64,
    } config;

     ADD_16 = 0;

    input wire [WIDTH-1:0] inputs [7:0],
    input wire on_off,
    input wire [2:0] config,
    output reg [WIDTH-1:0] outputs [3:0],
    output reg car

    adder_fu #( .width(width) ) uut (
        .inputs(inputs_tb),
        .config(),
        .carry_out(carry_out_tb),
        .on_off(on_off_tb)
    );

    initial begin
        // Initialize inputs
        a_tb = 8'd5;
        b_tb = 8'd10;
        on_off_tb = 1'b1;

        // Apply test vectors
        #10;
        $display("a=%d, b=%d, on_off=%b, sum=%d, carry_out=%b",
                 a_tb, b_tb, on_off_tb, c_tb, carry_out_tb);

        a_tb = 8'd250;
        b_tb = 8'd21;
        on_off_tb = 1'b1;

        #10;
        $display("a=%d, b=%d, on_off=%b, sum=%d, carry_out=%b",
                 a_tb, b_tb, on_off_tb, c_tb, carry_out_tb);

        on_off_tb = 1'b0;
        #10;
        $display("a=%d, b=%d, on_off=%b, sum=%d, carry_out=%b",
                 a_tb, b_tb, on_off_tb, c_tb, carry_out_tb);

        $finish;
    end

endmodule