/*
16 registers x 16 bits wide
One combinational read port
Three sequential write ports
Two 4 register sets - each reserved for first two write ports
One register for config mem - reserved for last write port
*/

module regfile #(
    parameter width = 16, 
    parameter num_regs = 16, 
    parameter num_inputs = 4,
    parameter total_inputs = num_inputs + num_inputs)(
    
    input wire clk,
    input wire reset,
    
    // Read port - Vector FU
    input wire ren,
    output reg [width-1:0] r_data [total_inputs:0],
    output reg r_data_vld,
    
    // Write port 1 - CGRA network neighbor 1 (Writes to first set of regs)
    input wire wen1,
    input wire [width-1:0] w_data1 [num_inputs-1:0],
    output reg wr_ack1,

    // Write port 2 - CGRA network neighbor 2 (Writes to second set of regs)
    input wire wen2,
    input wire [width-1:0] w_data2 [num_inputs-1:0],
    output reg wr_ack2,

    // Write port 3 - CGRA network config data
    input wire wen3,
    input wire [width-1:0] w_data3,
    output reg wr_ack3
);

    // Register file
    reg [width-1:0] registers [0:num_regs-1];

    // Read operation (combinational) always reads entire regfile
    always @(*) begin
        // Vector FU is reading input vector and config data
        if (ren) begin
            for (int i = 0; i <= total_inputs; i += 1 ) begin
                r_data[i] = registers[i]; // Input vector elements ...
            end
            r_data_vld = 1'b1;
        // Zero-out outputs on reset
        end else begin
            for (int i = 0; i <= total_inputs; i += 1) begin
                r_data[i] = {width{1'b0}}; // Input vector elements ...
            end
            r_data_vld = 1'b0;
        end
    end

    // Write operation (sequential)
    always @(posedge clk) begin
        wr_ack1 <= 1'b0;
        wr_ack2 <= 1'b0;
        wr_ack3 <= 1'b0;

        if (reset) begin
            // Reset all registers to 0
            for (int i = 0; i < num_regs; i = i + 1) begin
                registers[i] <= {width{1'b0}};
            end

        end else if (!ren) begin
            // Write port 1
            if (wen1) begin
                for (int i = 0; i < num_inputs; i += 1) begin
                    registers[i] <= w_data1[i]; 
                end
                wr_ack1 <= 1'b1;
            end
            // Write port 2
            if (wen2) begin
                for (int i = 0; i < num_inputs; i += 1) begin
                    registers[i + num_inputs] <= w_data2[i]; 
                end
                wr_ack2 <= 1'b1;
            end
            if (wen3) begin
                registers[total_inputs] <= w_data3;
                wr_ack3 <= 1'b1;
            end
        end
    end

endmodule