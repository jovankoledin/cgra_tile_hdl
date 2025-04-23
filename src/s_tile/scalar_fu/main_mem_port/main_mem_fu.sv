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
 - (7:12) data destination for reads or data origin for writes, which regfile sets (1-6?)

main mem port:
 - 2 x read from main mem addr ports
 - 2 x write to main mem addr ports

Regfile port:
 - 2 x read from main mem addr ports
 - 2 x write to main mem addr ports

When on_off goes high, read/write is executed on values in local register file 
*/

`define CONFIG_OFFSET 3

module main_mem_fu #(parameter data_width = 32, parameter addr_size = 16, num_reg_sets = 6, reg_set_idx_width = 3) (
    input clk_i,
    input reset_i,
    input on_off_i,

    input [addr_size-1:0] config_i,
    output logic [addr_size-1:0] addr1_o,
    output logic [addr_size-1:0] addr2_o,

    // Main mem read port 1
    output logic read_en1_o,
    input [data_width-1:0] r_data1_i,
    input read_ack1_i,

    // Main mem read port 2
    output logic read_en2_o,
    input [data_width-1:0] r_data2_i,
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
    output logic reg_read1_o, 
    output logic reg_read2_o, 
    output logic reg_write1_o, 
    output logic reg_write2_o, 
    output logic [reg_set_idx_width-1:0] reg_set1_idx_o,
    output logic [reg_set_idx_width-1:0] reg_set2_idx_o,
    output logic [data_width-1:0] reg_data1_o,
    output logic [data_width-1:0] reg_data2_o,
    input [data_width-1:0] reg_data1_i,
    input [data_width-1:0] reg_data2_i,
    input reg_ack1_i,
    input reg_ack2_i
);

    // FSM state definition
    typedef enum logic [4:0] { // Increased state bits
        IDLE,               // 0: Waiting for on_off_i
        REQ_ADDR,           // 1: Request addresses from register file (Read/Write op)
        WAIT_ADDR,          // 2: Wait for register file ack for addresses
        REQ_WDATA,          // 3: Request both words of write data from register file (Write op)
        WAIT_WDATA,         // 4: Wait for register file ack for write words
        EXEC_WRITE,         // 5: Execute write to main memory (Write op)
        WAIT_WRITE_ACK,     // 6: Wait for main memory write acknowledge
        EXEC_READ,          // 7: Execute read from main memory (Read op)
        WAIT_READ_ACK,      // 8: Wait for main memory read acknowledge
        WRITE_RDATA_P,      // 9: Write first pair of read data back to regfile (Read op)
        WAIT_WACK_RDATA_P   // 10: Wait for regfile ack for write
    } state_t;

    // State registers
    state_t current_state, next_state;

    // Internal registers for configuration and intermediate data storage
    logic                   is_read_reg;          // Latched main mem operation type (1=Read, 0=Write)
    logic [reg_set_idx_width-1:0] addr_reg_set;  // Latched base register set that contains addresses
    logic [reg_set_idx_width-1:0] data_reg_idx1;  // Latched base index for data (data src for Write, data dest for Read)
    logic [reg_set_idx_width-1:0] data_reg_idx2;  // Latched base index for data (data src for Write, data dest for Read)


    logic [addr_size-1:0]   addr1_reg;        // Latched address 1
    logic [addr_size-1:0]   addr2_reg;        // Latched address 2
    logic [data_width-1:0]  w_data1_reg;      // Latched write data 1 (to main mem)
    logic [data_width-1:0]  w_data2_reg;      // Latched write data 2 (to main mem)
    logic [data_width-1:0]  r_data1_reg;      // Latched read data 1 (from main mem)
    logic [data_width-1:0]  r_data2_reg;      // Latched read data 2 (from main mem)

    // Temporary registers for config decoding (combinational)
    logic is_read_comb;
    logic [reg_set_idx_width-1:0] addr_idx_comb;
    logic [reg_set_idx_width-1:0] data_idx1_comb;
    logic [reg_set_idx_width-1:0] data_idx2_comb;

    // Decode config input combinationally
    assign is_read_comb = config_i[CONFIG_OFFSET];
    assign addr_idx_comb = config_i[reg_set_idx_width+CONFIG_OFFSET : 4]; // Assumes bits [6:4] for 3-bit index
    assign data_idx1_comb = config_i[reg_set_idx_width+CONFIG_OFFSET : 7]; // Assumes bits [9:7] for 3-bit index
    assign data_idx2_comb = config_i[reg_set_idx_width+CONFIG_OFFSET+CONFIG_OFFSET : 10]; // Assumes bits [12:10] for 3-bit index

    // State Register Logic (Sequential)
    always_ff @(posedge clk_i) begin
        if (reset_i) begin
            current_state <= IDLE;
            // Reset internal registers
            is_read_reg       <= 1'b0;
            addr_reg_set <= {reg_set_idx_width{1'b0}};
            data_reg_idx1 <= {reg_set_idx_width{1'b0}};
            data_reg_idx2 <= {reg_set_idx_width{1'b0}};
            addr1_reg         <= {addr_size{1'b0}};
            addr2_reg         <= {addr_size{1'b0}};
            w_data1_reg       <= {data_width{1'b0}};
            w_data2_reg       <= {data_width{1'b0}};
            r_data1_reg       <= {data_width{1'b0}};
            r_data2_reg       <= {data_width{1'b0}};
        end else begin
            current_state <= next_state;
            // Latch registers based on FSM state transitions (in combinational block)
            if (next_state == REQ_ADDR) begin // Latch config when starting
                is_read_reg       <= is_read_comb;
                addr_reg_idx <= addr_idx_comb;
                data_reg_idx1 <= data_idx1_comb;
                data_reg_idx2 <= data_idx2_comb;
            end
            if (current_state == WAIT_ADDR && reg_ack1_i) begin
                 // Latch Addr 1&2 
                addr1_reg <= reg_data1_i[addr_size-1:0];
                addr2_reg <= reg_data1_i[addr_size+addr_size-1:addr_size];
            end
            if (current_state == WAIT_WDATA && reg_ack1_i && reg_ack2_i) begin
                 // Latch w_data from register going to main mem
                 w_data1_reg <= reg_data1_i;
                 w_data2_reg <= reg_data2_i;
            end
            if (current_state == WAIT_READ_ACK && read_ack1_i && read_ack2_i) begin
                 // Latch data read from main memory
                 r_data1_reg <= r_data1_i;
                 r_data2_reg <= r_data2_i;
            end
            // Reset internal registers if going back to IDLE due to !on_off_i or reset
             if (next_state == IDLE) begin
                addr1_reg         <= {addr_size{1'b0}};
                addr2_reg         <= {addr_size{1'b0}};
                w_data1_reg       <= {data_width{1'b0}};
                w_data2_reg       <= {data_width{1'b0}};
                r_data1_reg       <= {data_width{1'b0}};
                r_data2_reg       <= {data_width{1'b0}};
             end
        end
    end

    // Next State Logic and Output Logic (Combinational)
    always_comb begin
        // FSM Transitions and Output Control
        case (current_state)
            IDLE: begin
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
                reg_read1_o = 1'b0;  // Default regfile read request to low
                reg_read2_o = 1'b0;  // Default regfile read request to low
                reg_write1_o = 1'b0; // Default regfile write request to low
                reg_write2_o = 1'b0; // Default regfile write request to low
                reg_set1_idx_o = {reg_set_idx_width{1'b0}};    // Default regfile indices to 0
                reg_set2_idx_o = {reg_set_idx_width{1'b0}};
                reg_data1_o = {data_width{1'b0}};   // Default regfile write data to 0
                reg_data2_o = {data_width{1'b0}};

                if (on_off_i) begin
                    // Latch configuration in sequential block on next edge
                    next_state = REQ_ADDR;
                end else begin
                    next_state = IDLE;
                end
            end

            REQ_ADDR: begin
                // Request addresses from regfile using latched base index
                reg_read1_o = 1'b1; // Assert regfile read request
                reg_set1_idx_o = addr_reg_idx;     // Index for addr1
                next_state = WAIT_ADDR;
            end

            WAIT_ADDR: begin
                reg_read_o = 1'b1; // Keep request high until ack
                reg_set1_idx_o = addr_reg_idx;     // Keep asserted
                if (reg_ack1_i) begin
                    // Addresses latched in sequential block
                    reg_read_o = 1'b0; // Deassert request
                    if (is_read_reg) begin // Check latched read/write flag
                        next_state = EXEC_READ; // Go to main memory read
                    end else begin
                        next_state = REQ_WDATA; // Go get data for main memory write
                    end
                end else begin
                    next_state = WAIT_ADDR; // Stay in this state
                end
            end

            // --- States for Main Memory Write Operation ---
            REQ_WDATA: begin
                reg_read_o = 1'b1; // Request read from regfile
                // Use latched base index for data source
                reg_set1_idx_o = data_reg_idx1;      // Index for w_data1
                reg_set2_idx_o = data_reg_idx2;  // Index for w_data2
                next_state = WAIT_WDATA;
            end

            WAIT_WDATA: begin
                reg_read1_o = 1'b1; // Keep request high
                reg_set1_idx_o = data_reg_idx1;      // Index for w_data1 
                reg_read2_o = 1'b1; // Keep request high
                reg_set2_idx_o = data_reg_idx2;  // Index for w_data2
                if (reg_ack1_i && reg_ack2_i) begin
                    // w_data1 latched in sequential block
                    reg_read1_o = 1'b0; // Deassert request
                    reg_read2_o = 1'b0; // Deassert request
                    next_state = EXEC_WRITE;
                end else {
                    next_state = WAIT_WDATA;
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
                    next_state = WRITE_RDATA;
                end else begin
                    next_state = WAIT_READ_ACK; // Stay waiting
                end
            end

            // --- States for Writing Read Data back to Register File ---
            WRITE_RDATA: begin
                reg_write1_o = 1'b1; // Assert regfile write request
                reg_write2_o = 1'b1; // Assert regfile write request
                // Write lower and upper 16 bits of r_data1_reg
                reg_set1_idx_o = data_reg_idx1;    
                reg_set2_idx_o = data_reg_idx2 
                reg_data1_o = r_data1_reg
                reg_data2_o = r_data2_reg
                next_state = WAIT_WACK_RDATA;
            end

            WAIT_WACK_RDATA: begin
                reg_write1_o = 1'b1; // Keep write request high
                reg_write2_o = 1'b1; // Keep write request high
                reg_set1_idx_o = data_reg_idx1;     // Keep indices asserted
                reg_set2_idx_o = data_reg_idx2;
                reg_data1_o = r_data1_reg
                reg_data2_o = r_data2_reg
                if (reg_ack_i) begin
                    reg_write1_o = 1'b0; // Deassert write request
                    reg_write2_o = 1'b0; // Deassert write request
                    next_state = IDLE; // Proceed to write second pair
                end else begin
                    next_state = WAIT_WACK_RDATA; // Stay waiting
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
             reg_read1_o = 1'b0;
             reg_write1_o = 1'b0;
             reg_read2_o = 1'b0;
             reg_write2_o = 1'b0;
        end
    end

endmodule