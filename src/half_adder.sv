`timescale 1ns/1ps
module half_adder
    #(parameter width=16) (
    input wire reset
    , input wire [width-1:0] a
    , input wire [width-1:0] b
    , output reg [width-1:0] c
    , output reg carry_out
    , output reg ack
    , input wire [0:0] on_off
    );

    always @* begin
        if (reset) begin
            c <= {width{1'b0}};
            carry_out <= 1'b0;
            ack <= 1'b0;
        end else begin
            if (on_off) begin
            {carry_out, c} = a[width-1:0] + b[width-1:0]; 
                ack = 1'b1;
            end else begin
                {carry_out, c} = {1'b0, {width{1'b0}}};
            end
        end
    end

endmodule;