/*
Coordinates reads and writes to the vector tile register file.
Requests for register file data will come from local vector functional unit 
cgra network will write data to the regfile.
*/

`timescale 1ns/1ps
`include "../../src/mem/regfile.sv"

module mem #(
    parameter width = 16, 
    num_regs = 16, 
    num_inputs = 8) (

    input wire clk,
    input wire reset,
    input wire on_off, // Signal for vector fu to tell it to start data reading and op execution (toggled each cycle)

    // CGRA network port (write)
    input wire write_en, //Stays high for duration of write, until write_ack is set high
    output reg write_rdy,
    input wire [width-1:0] w_data_in [num_inputs:0],
    output reg write_ack,

    // Vector fu port (read)
    output wire [width-1:0] r_data_out [num_inputs:0],
    output wire on_off_vector_fu // Goes to vector fu to activate its execution
);

    reg write_reg_en;
    wire read_reg_en;
    reg write_ack_reg;
    wire write_ack_wire;

    always @(posedge clk) begin
        if (reset) begin
            write_reg_en <= 0;
            write_rdy <= 0;

        end else begin
            if (!write_en && !on_off) begin
                write_rdy <= 1'b1;
            end else begin
                write_rdy <= 1'b0;
            end
            
            if (write_en && !on_off && !write_ack) begin
                write_reg_en <= 1;
            end else begin
                write_reg_en <= 1'b0;
            end
        end

    end

    assign write_ack = write_ack_wire;
    assign on_off_vector_fu = on_off && !write_en;
    assign read_reg_en = on_off_vector_fu;

    regfile #( .width(width) ) regfile1 (
        .clk(clk),
        .reset(reset),
        .ren(read_reg_en),
        .r_data(r_data_out),
        .wen(write_reg_en),
        .w_data(w_data_in),
        .wr_ack(write_ack_wire)
    );

endmodule