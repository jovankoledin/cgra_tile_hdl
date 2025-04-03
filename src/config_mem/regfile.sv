module regfile #(
    parameter width = 16, 
    parameter num_regs = 16, 
    parameter num_inputs = 8)(
     
    input wire clk,
    input wire reset,
    
    // Read port - Vector FU
    input wire ren,
    output reg [width-1:0] r_data [num_inputs:0],
    
    // Write port - CGRA Network
    input wire wen,
    input wire [width-1:0] w_data [num_inputs:0],
    output reg wr_ack
);

    // Register file
    reg [width-1:0] registers [0:num_regs-1];

    // Read operation (combinational)
    always @(*) begin
        // Vector FU is reading input vector and config data
        if (ren) begin
            for ( int i = 0; i < num_inputs; i += 1 ) begin
                r_data[i] = registers[i]; // Input vector elements ...
            end
            r_data[num_inputs] = registers[num_inputs]; // Configuration data

        // Zero-out outputs
        end else begin
            for (int i = 0; i < num_inputs; i += 1) begin
                r_data[i] = {width{1'b0}}; // Input vector elements ...
            end
            r_data[num_inputs] = {width{1'b0}}; // Configuration data
        end
    end

    // Write operation (sequential)
    always @(posedge clk) begin
        if (reset) begin
            // Reset all registers to 0
            for (int i = 0; i < num_regs; i = i + 1) begin
                registers[i] <= {width{1'b0}};
            end
            wr_ack <= 1'b0;

        end else begin
            // Writing data from CGRA network
            if (wen && !ren) begin
                for (int i = 0; i < num_inputs; i += 1) begin
                    registers[i] <= w_data[i]; // Input vector elements ...
                end
                registers[num_inputs] <= w_data[num_inputs]; // Configuration data
                wr_ack <= 1'b1;
            end else begin
                wr_ack <= 1'b0;
            end
        end
    end

endmodule