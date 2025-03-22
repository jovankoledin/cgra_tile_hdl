`timescale 1ns/1ps
module full_adder
    #(parameter width=16) (
    input wire [width-1:0] a
    , input wire [width-1:0] b
    , output reg [width-1:0] c
    , input wire [0:0] carry_in
    , output reg carry_out
    , input wire [0:0] carry_listen
    , input wire [0:0] on_off
    );

    always @* begin
        if (on_off) begin
            if (carry_listen) begin
                {carry_out, c} = a[width-1:0] + b[width-1:0] + carry_in;
            end else begin
                {carry_out, c} = a[width-1:0] + b[width-1:0];
            end
        end else begin
            {carry_out, c} = {1'b0, {width{1'b0}}};         
        end
    end
    
endmodule;