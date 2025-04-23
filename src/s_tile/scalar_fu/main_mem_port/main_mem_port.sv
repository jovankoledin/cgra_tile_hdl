/*
Responsible for moving data between main mem and local tile register file
Config data from local regfile specifies details of data exchange
Can read two 32bit values from main memory simultaneously 
Can simultaneously write two 32 bit values to main memory block

Each R/W address is 16 bits

Regfile is 16 x 16 bits

Local regfile bits config_i will specify: 
 - (3) Read or write?
 - (4:6) addr1&2 location, regfile set (1-6?)
 - (7:11) data destination for reads or data origin for writes, which regfile sets (1-6?)

main mem port:
 - 2 x read from main mem addr ports
 - 2 x write to main mem addr ports

Regfile port:
 - 2 x read from main mem addr ports
 - 2 x write to main mem addr ports

When on_off goes high, read/write is executed on values in local register file 
*/

module main_mem_port #(parameter data_width = 32, parameter addr_size = 16) (
    input clk_i,
    input reset_i,
    input on_off_i,

    input [addr_size-1:0] config_i,
    output logic [addr_size-1:0] addr1_o,
    output logic [addr_size-1:0] addr2_o,

    // Main mem read port 1
    output logic read_en1_o,
    input logic [data_width-1:0] r_data1_i,
    input read_ack1_i,

    // Main mem read port 2
    output logic read_en2_o,
    input logic [data_width-1:0] r_data2_i,
    input read_ack2_i,

    // Main mem write port 1
    output logic write_en1_o, // Stays high for duration of write, until write_ack is set high
    output logic [data_width-1:0] w_data1_o,
    input write_ack1_i,

    // Main mem write port 2
    output logic write_en2_o, // Stays high for duration of write, until write_ack is set high
    output logic [data_width-1:0] w_data2_o,
    input write_ack2_i,

    // Register interface
    // Can request/write two sets of data, each set is 32bits wide
    output logic reg_read_o, 
    output logic reg_write_o, 
    output logic [2:0] reg_set1_o,
    output logic [2:0] reg_set2_o,
    output logic [data_width-1:0] reg_data1_o,
    output logic [data_width-1:0] reg_data2_o,
    input logic [data_width-1:0] reg_data1_i,
    input logic [data_width-1:0] reg_data2_i,
    input reg_ack_i,
);

    // FSM state definition
    typedef enum logic [4:0] { // Increased state bits
        IDLE,               // 0: Waiting for on_off_i
        REQ_ADDR,           // 1: Request addresses from register file (Read/Write op)
        WAIT_ADDR,          // 2: Wait for register file ack for addresses
        REQ_WDATA1,         // 3: Request first word of write data from register file (Write op)
        WAIT_WDATA1,        // 4: Wait for register file ack for first write word
        REQ_WDATA2,         // 5: Request second word of write data from register file (Write op)
        WAIT_WDATA2,        // 6: Wait for register file ack for second write word
        EXEC_WRITE,         // 7: Execute write to main memory (Write op)
        WAIT_WRITE_ACK,     // 8: Wait for main memory write acknowledge
        EXEC_READ,          // 9: Execute read from main memory (Read op)
        WAIT_READ_ACK,      // 10: Wait for main memory read acknowledge
        WRITE_RDATA_P1,     // 11: Write first pair of read data back to regfile (Read op)
        WAIT_WACK_RDATA_P1, // 12: Wait for regfile ack for first pair write
        WRITE_RDATA_P2,     // 13: Write second pair of read data back to regfile (Read op)
        WAIT_WACK_RDATA_P2  // 14: Wait for regfile ack for second pair write
    } state_t;

    // State registers
    state_t current_state, next_state;

    // Internal registers for configuration and intermediate data storage
    logic                   is_read_reg;        // Latched operation type (1=Read, 0=Write)
    logic [reg_idx_width-1:0] addr_reg_idx_base;  // Latched base index for addresses
    logic [reg_idx_width-1:0] data_reg_idx_base;  // Latched base index for data (src for Write, dest for Read)

    logic [addr_size-1:0]   addr1_reg;        // Latched address 1
    logic [addr_size-1:0]   addr2_reg;        // Latched address 2
    logic [data_width-1:0]  w_data1_reg;      // Latched write data 1 (to main mem)
    logic [data_width-1:0]  w_data2_reg;      // Latched write data 2 (to main mem)
    logic [data_width-1:0]  r_data1_reg;      // Latched read data 1 (from main mem)
    logic [data_width-1:0]  r_data2_reg;      // Latched read data 2 (from main mem)

    // Temporary registers for config decoding (combinational)
    logic is_read_comb;
    logic [reg_idx_width-1:0] addr_idx_base_comb;
    logic [reg_idx_width-1:0] data_idx_base_comb;

    // Decode config input combinationally
    // ** IMPORTANT: Verify these bit slices match your design **
    assign is_read_comb = config_i[3];
    assign addr_idx_base_comb = config_i[reg_idx_width+3 : 4]; // Assumes bits [7:4] for 4-bit index
    assign data_idx_base_comb = config_i[reg_idx_width+6 : 7]; // Assumes bits [10:7] for 4-bit index

    // State Register Logic (Sequential)
    always_ff @(posedge clk_i or posedge reset_i) begin
        if (reset_i) begin
            current_state <= IDLE;
            // Reset internal registers
            is_read_reg       <= 1'b0;
            addr_reg_idx_base <= '0;
            data_reg_idx_base <= '0;
            addr1_reg         <= '0;
            addr2_reg         <= '0;
            w_data1_reg       <= '0;
            w_data2_reg       <= '0;
            r_data1_reg       <= '0;
            r_data2_reg       <= '0;
        end else begin
            current_state <= next_state;
            // Latch registers based on FSM state transitions (in combinational block)
            if (next_state == REQ_ADDR) begin // Latch config when starting
                is_read_reg       <= is_read_comb;
                addr_reg_idx_base <= addr_idx_base_comb;
                data_reg_idx_base <= data_idx_base_comb;
            end
            if (current_state == WAIT_ADDR && reg_ack_i) begin
                 // Latch Addr 1&2 from lower 16 bits of regfile read ports
                 addr1_reg <= reg_data1_i[addr_size-1:0];
                 addr2_reg <= reg_data2_i[addr_size-1:0];
            end
            if (current_state == WAIT_WDATA1 && reg_ack_i) begin
                 // Latch w_data1 (combine two 16-bit reads: {Upper, Lower})
                 w_data1_reg <= {reg_data2_i[15:0], reg_data1_i[15:0]};
            end
             if (current_state == WAIT_WDATA2 && reg_ack_i) begin
                 // Latch w_data2 (combine two 16-bit reads: {Upper, Lower})
                 w_data2_reg <= {reg_data2_i[15:0], reg_data1_i[15:0]};
            end
            if (current_state == WAIT_READ_ACK && read_ack1_i && read_ack2_i) begin
                 // Latch data read from main memory
                 r_data1_reg <= r_data1_i;
                 r_data2_reg <= r_data2_i;
            end
            // Reset internal registers if going back to IDLE due to !on_off_i or reset
             if (next_state == IDLE) begin
                 addr1_reg   <= '0;
                 addr2_reg   <= '0;
                 w_data1_reg <= '0;
                 w_data2_reg <= '0;
                 r_data1_reg <= '0;
                 r_data2_reg <= '0;
             end
        end
    end

    // Next State Logic and Output Logic (Combinational)
    always_comb begin
        // Default assignments for outputs
        next_state = current_state;
        addr1_o = addr1_reg; // Output registered values by default
        addr2_o = addr2_reg;
        w_data1_o = w_data1_reg; // Output registered values by default
        w_data2_o = w_data2_reg;
        read_en1_o = 1'b0;
        read_en2_o = 1'b0;
        write_en1_o = 1'b0;
        write_en2_o = 1'b0;
        reg_read_o = 1'b0;  // Default regfile read request to low
        reg_write_o = 1'b0; // Default regfile write request to low
        reg_idx1_o = '0;    // Default regfile indices to 0
        reg_idx2_o = '0;
        reg_data1_o = '0;   // Default regfile write data to 0
        reg_data2_o = '0;

        // FSM Transitions and Output Control
        case (current_state)
            IDLE: begin
                if (on_off_i) begin
                    // Latch configuration in sequential block on next edge
                    next_state = REQ_ADDR;
                end else begin
                    next_state = IDLE;
                end
            end

            REQ_ADDR: begin
                // Request addresses from regfile using latched base index
                reg_read_o = 1'b1; // Assert regfile read request
                reg_idx1_o = addr_reg_idx_base;     // Index for addr1
                reg_idx2_o = addr_reg_idx_base + 1; // Index for addr2
                next_state = WAIT_ADDR;
            end

            WAIT_ADDR: begin
                reg_read_o = 1'b1; // Keep request high until ack
                reg_idx1_o = addr_reg_idx_base;     // Keep indices asserted
                reg_idx2_o = addr_reg_idx_base + 1;
                if (reg_ack_i) begin
                    // Addresses latched in sequential block
                    reg_read_o = 1'b0; // Deassert request
                    if (is_read_reg) begin // Check latched read/write flag
                        next_state = EXEC_READ; // Go to main memory read
                    end else begin
                        next_state = REQ_WDATA1; // Go get data for main memory write
                    end
                end else begin
                    next_state = WAIT_ADDR; // Stay in this state
                end
            end

            // --- States for Main Memory Write Operation ---
            REQ_WDATA1: begin
                reg_read_o = 1'b1; // Request read from regfile
                // Use latched base index for data source
                reg_idx1_o = data_reg_idx_base;      // Index for w_data1 lower 16 bits
                reg_idx2_o = data_reg_idx_base + 1;  // Index for w_data1 upper 16 bits
                next_state = WAIT_WDATA1;
            end

            WAIT_WDATA1: begin
                reg_read_o = 1'b1; // Keep request high
                reg_idx1_o = data_reg_idx_base;
                reg_idx2_o = data_reg_idx_base + 1;
                if (reg_ack_i) begin
                    // w_data1 latched in sequential block
                    reg_read_o = 1'b0; // Deassert request
                    next_state = REQ_WDATA2;
                end else {
                    next_state = WAIT_WDATA1;
                }
            end

            REQ_WDATA2: begin
                reg_read_o = 1'b1; // Request read from regfile
                reg_idx1_o = data_reg_idx_base + 2; // Index for w_data2 lower 16 bits
                reg_idx2_o = data_reg_idx_base + 3; // Index for w_data2 upper 16 bits
                next_state = WAIT_WDATA2;
            end

            WAIT_WDATA2: begin
                reg_read_o = 1'b1; // Keep request high
                reg_idx1_o = data_reg_idx_base + 2;
                reg_idx2_o = data_reg_idx_base + 3;
                if (reg_ack_i) begin
                    // w_data2 latched in sequential block
                    reg_read_o = 1'b0; // Deassert request
                    next_state = EXEC_WRITE; // Proceed to write to main memory
                end else {
                    next_state = WAIT_WDATA2;
                }
            end

            EXEC_WRITE: begin
                // Assert write enables, output latched addresses and data
                write_en1_o = 1'b1;
                write_en2_o = 1'b1;
                addr1_o = addr1_reg;
                addr2_o = addr2_reg;
                w_data1_o = w_data1_reg;
                w_data2_o = w_data2_reg;
                next_state = WAIT_WRITE_ACK;
            end

            WAIT_WRITE_ACK: begin
                write_en1_o = 1'b1; // Keep write enables high
                write_en2_o = 1'b1;
                addr1_o = addr1_reg; // Keep outputs asserted
                addr2_o = addr2_reg;
                w_data1_o = w_data1_reg;
                w_data2_o = w_data2_reg;
                if (write_ack1_i && write_ack2_i) begin
                    write_en1_o = 1'b0; // Deassert on ack
                    write_en2_o = 1'b0;
                    next_state = IDLE; // Operation complete
                end else begin
                    next_state = WAIT_WRITE_ACK; // Stay waiting
                end
            end

            // --- States for Main Memory Read Operation ---
            EXEC_READ: begin
                // Assert read enables, output latched addresses
                read_en1_o = 1'b1;
                read_en2_o = 1'b1;
                addr1_o = addr1_reg;
                addr2_o = addr2_reg;
                next_state = WAIT_READ_ACK;
            end

            WAIT_READ_ACK: begin
                read_en1_o = 1'b1; // Keep read enables high
                read_en2_o = 1'b1;
                addr1_o = addr1_reg; // Keep address outputs asserted
                addr2_o = addr2_reg;
                if (read_ack1_i && read_ack2_i) begin
                    // Read data latched in sequential block
                    read_en1_o = 1'b0; // Deassert on ack
                    read_en2_o = 1'b0;
                    // Proceed to write the fetched data back to the register file
                    next_state = WRITE_RDATA_P1;
                end else begin
                    next_state = WAIT_READ_ACK; // Stay waiting
                end
            end

            // --- States for Writing Read Data back to Register File ---
            WRITE_RDATA_P1: begin
                reg_write_o = 1'b1; // Assert regfile write request
                // Write lower and upper 16 bits of r_data1_reg
                reg_idx1_o = data_reg_idx_base;     // Dest index for r_data1_reg[15:0]
                reg_idx2_o = data_reg_idx_base + 1; // Dest index for r_data1_reg[31:16]
                reg_data1_o = {16'b0, r_data1_reg[15:0]}; // Data for index base
                reg_data2_o = {16'b0, r_data1_reg[31:16]}; // Data for index base+1
                next_state = WAIT_WACK_RDATA_P1;
            end

            WAIT_WACK_RDATA_P1: begin
                reg_write_o = 1'b1; // Keep write request high
                reg_idx1_o = data_reg_idx_base;     // Keep indices asserted
                reg_idx2_o = data_reg_idx_base + 1;
                reg_data1_o = {16'b0, r_data1_reg[15:0]}; // Keep data asserted
                reg_data2_o = {16'b0, r_data1_reg[31:16]};
                if (reg_ack_i) begin
                    reg_write_o = 1'b0; // Deassert write request
                    next_state = WRITE_RDATA_P2; // Proceed to write second pair
                end else begin
                    next_state = WAIT_WACK_RDATA_P1; // Stay waiting
                end
            end

            WRITE_RDATA_P2: begin
                reg_write_o = 1'b1; // Assert regfile write request
                // Write lower and upper 16 bits of r_data2_reg
                reg_idx1_o = data_reg_idx_base + 2; // Dest index for r_data2_reg[15:0]
                reg_idx2_o = data_reg_idx_base + 3; // Dest index for r_data2_reg[31:16]
                reg_data1_o = {16'b0, r_data2_reg[15:0]}; // Data for index base+2
                reg_data2_o = {16'b0, r_data2_reg[31:16]}; // Data for index base+3
                next_state = WAIT_WACK_RDATA_P2;
            end

            WAIT_WACK_RDATA_P2: begin
                reg_write_o = 1'b1; // Keep write request high
                reg_idx1_o = data_reg_idx_base + 2; // Keep indices asserted
                reg_idx2_o = data_reg_idx_base + 3;
                reg_data1_o = {16'b0, r_data2_reg[15:0]}; // Keep data asserted
                reg_data2_o = {16'b0, r_data2_reg[31:16]};
                if (reg_ack_i) begin
                    reg_write_o = 1'b0; // Deassert write request
                    next_state = IDLE; // Read operation fully complete
                end else begin
                    next_state = WAIT_WACK_RDATA_P2; // Stay waiting
                end
            end

            default: begin
                next_state = IDLE;
            end
        endcase

        // Handle on_off override: If disabled mid-operation, abort to IDLE
        // Reset has higher priority (handled in sequential block)
        if (!reset_i && !on_off_i && current_state != IDLE) begin
             next_state = IDLE;
             // Reset outputs immediately
             read_en1_o = 1'b0;
             read_en2_o = 1'b0;
             write_en1_o = 1'b0;
             write_en2_o = 1'b0;
             reg_read_o = 1'b0;
             reg_write_o = 1'b0;
        end
    end

    // Connect internal indices to outputs (if original reg_set names are needed)
    // Use this if the downstream module expects reg_set*_o with fewer bits.
    // Otherwise, consider renaming the outputs to reg_idx*_o directly.
    // output logic [2:0] reg_set1_o, // Original port - Connect if needed
    // output logic [2:0] reg_set2_o, // Original port - Connect if needed
    // assign reg_set1_o = reg_idx1_o[2:0];
    // assign reg_set2_o = reg_idx2_o[2:0];

endmodule