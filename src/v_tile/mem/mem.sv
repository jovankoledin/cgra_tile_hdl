`timescale 1ns/1ps
`include "../../../src/v_tile/mem/regfile.sv"

module mem #(
    parameter width = 16,
    parameter num_regs = 16,
    parameter num_inputs = 4,
    parameter total_inputs = num_inputs + num_inputs
) (
    input wire clk,
    input wire reset,
    input wire on_off, // Signal for vector fu to tell it to start data reading and op execution (toggled each cycle)

    // CGRA network port from neighbor 1 (write)
    input wire write_en1, // Stays high for duration of write, until write_ack is set high
    output reg write_rdy1,
    input wire [width-1:0] w_data_in1 [num_inputs-1:0],

    // CGRA network port from neighbor 2 (write)
    input wire write_en2, // Stays high for duration of write, until write_ack is set high
    output reg write_rdy2,
    input wire [width-1:0] w_data_in2 [num_inputs-1:0],

    // CGRA network port from config mem programmer (write)
    input wire write_en3, // Stays high for duration of write, until write_ack is set high
    output reg write_rdy3,
    input wire [width-1:0] w_data_in3,

    output wire write_ack,

    // Vector fu port (read), access all register file data, vector fu inputs and config data
    output wire [width-1:0] r_data_out [total_inputs:0],
    output wire on_off_vector_fu // Goes to vector fu to activate its execution
);

    reg write_reg_en1, write_reg_en2, write_reg_en3;
    wire read_reg_en;
    wire write_ack_wire;

    always @(posedge clk) begin
        if (reset) begin
            write_reg_en1 <= 0;
            write_reg_en2 <= 0;
            write_reg_en3 <= 0;
            write_rdy1 <= 1'b1;
            write_rdy2 <= 1'b1;
            write_rdy3 <= 1'b1;
        end else begin
            write_reg_en1 <= 0;
            write_reg_en2 <= 0;
            write_reg_en3 <= 0;

            if (!on_off) begin
                write_rdy1 <= (!write_en1) ? 1'b1 : 1'b0;
                write_rdy2 <= (!write_en2) ? 1'b1 : 1'b0;
                write_rdy3 <= (!write_en3) ? 1'b1 : 1'b0;
            end

            if (!on_off && !write_ack) begin
                if (write_en1) write_reg_en1 <= 1;
                if (write_en2) write_reg_en2 <= 1;
                if (write_en3) write_reg_en3 <= 1;
            end
        end
    end

    assign writing = (write_en1 || write_en2 || write_en3);
    assign write_ack = write_ack_wire;
    assign on_off_vector_fu = on_off && !writing;
    assign read_reg_en = on_off_vector_fu;

    regfile #(
        .width(width),
        .num_regs(num_regs),
        .num_inputs(num_inputs)
    ) regfile1 (
        .clk(clk),
        .reset(reset),
        .ren(read_reg_en),
        .r_data(r_data_out),
        .wen1(write_reg_en1),
        .w_data1(w_data_in1),
        .wen2(write_reg_en2),
        .w_data2(w_data_in2),
        .wen3(write_reg_en3),
        .w_data3(w_data_in3),
        .wr_ack(write_ack_wire)
    );

endmodule