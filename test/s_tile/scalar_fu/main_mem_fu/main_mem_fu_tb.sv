// Testbench for main_mem_fu
`timescale 1ns / 1ps

// Define parameters for the testbench
`define DATA_WIDTH 32
`define ADDR_SIZE 16
`define NUM_REG_SETS 6
`define REG_SET_IDX_WIDTH 3
`define CONFIG_OFFSET 3

// Define memory and register file sizes for the models
`define MAIN_MEM_SIZE 2**`ADDR_SIZE // 65536 locations
`define REG_FILE_SIZE 16 // 16 entries per set (assuming 16x16 bits, but DUT uses 32-bit words)
`define REG_FILE_SETS `NUM_REG_SETS // Number of register sets

// Define configuration bit masks (based on DUT decoding)
// config_i:
// - (3) Read or write? (1=Read, 0=Write)
// - (4:6) addr1&2 location, regfile set
// - (7:11) data destination for reads or data origin for writes, which regfile sets (1-6?)
// Assuming reg_set_idx_width = 3, the indices are 3 bits wide.
// config_i[3]: is_read (1 bit)
// config_i[6:4]: addr_idx (3 bits)
// config_i[9:7]: data_idx1 (3 bits)
// config_i[12:10]: data_idx2 (3 bits) 
`define CONFIG_IS_READ_MASK 1 << `CONFIG_OFFSET
`define CONFIG_ADDR_IDX_MASK ((1 << `REG_SET_IDX_WIDTH) - 1) << (`CONFIG_OFFSET + 1)
`define CONFIG_DATA_IDX1_MASK ((1 << `REG_SET_IDX_WIDTH) - 1) << (`CONFIG_OFFSET + 1 + `REG_SET_IDX_WIDTH)
`define CONFIG_DATA_IDX2_MASK ((1 << `REG_SET_IDX_WIDTH) - 1) << (`CONFIG_OFFSET + 1 + `REG_SET_IDX_WIDTH * 2)


module tb_main_mem_fu;

    // Clock and Reset signals
    logic clk;
    logic reset;
    logic on_off;

    // DUT interface signals
    logic [`ADDR_SIZE-1:0] config;
    logic [`ADDR_SIZE-1:0] addr1;
    logic [`ADDR_SIZE-1:0] addr2;

    logic read_en1;
    logic [`DATA_WIDTH-1:0] r_data1;
    logic read_ack1;

    logic read_en2;
    logic [`DATA_WIDTH-1:0] r_data2;
    logic read_ack2;

    logic write_en1;
    logic [`DATA_WIDTH-1:0] w_data1;
    logic write_ack1;

    logic write_en2;
    logic [`DATA_WIDTH-1:0] w_data2;
    logic write_ack2;

    logic reg_read1;
    logic reg_read2;
    logic reg_write1;
    logic reg_write2;
    logic [`REG_SET_IDX_WIDTH-1:0] reg_set1_idx;
    logic [`REG_SET_IDX_WIDTH-1:0] reg_set2_idx;
    logic [`DATA_WIDTH-1:0] reg_data1_out; // Data from regfile to DUT (for write to mem)
    logic [`DATA_WIDTH-1:0] reg_data2_out; // Data from regfile to DUT (for write to mem)
    logic [`DATA_WIDTH-1:0] reg_data1_in; // Data from DUT to regfile (for read from mem)
    logic [`DATA_WIDTH-1:0] reg_data2_in; // Data from DUT to regfile (for read from mem)
    logic reg_ack1;
    logic reg_ack2;

    // Internal signals for models
    logic [`DATA_WIDTH-1:0] main_memory [`MAIN_MEM_SIZE-1];
    // Register file model: reg_file[set][index]
    // Assuming each regfile entry is 16 bits, but DUT reads/writes 32-bit words.
    // The DUT requests addr1/addr2 from one regfile entry (32 bits total).
    // The DUT requests/writes w_data1/w_data2 from/to two separate regfile entries (32 bits each).
    // Let's model the regfile as 32-bit entries to match the DUT's data ports.
    logic [`DATA_WIDTH-1:0] register_file [`REG_FILE_SETS-1][`REG_FILE_SIZE-1];

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 10ns period, 100MHz
    end

    // DUT Instantiation
    main_mem_fu #(
        .data_width(`DATA_WIDTH),
        .addr_size(`ADDR_SIZE),
        .num_reg_sets(`NUM_REG_SETS),
        .reg_set_idx_width(`REG_SET_IDX_WIDTH)
    ) dut (
        .clk_i(clk),
        .reset_i(reset),
        .on_off_i(on_off),
        .config_i(config),
        .addr1_o(addr1),
        .addr2_o(addr2),
        .read_en1_o(read_en1),
        .r_data1_i(r_data1),
        .read_ack1_i(read_ack1),
        .read_en2_o(read_en2),
        .r_data2_i(r_data2),
        .read_ack2_i(read_ack2),
        .write_en1_o(write_en1),
        .w_data1_o(w_data1),
        .write_ack1_i(write_ack1),
        .write_en2_o(write_en2),
        .w_data2_o(w_data2),
        .write_ack2_i(write_ack2),
        .reg_read1_o(reg_read1),
        .reg_read2_o(reg_read2),
        .reg_write1_o(reg_write1),
        .reg_write2_o(reg_write2),
        .reg_set1_idx_o(reg_set1_idx),
        .reg_set2_idx_o(reg_set2_idx),
        .reg_data1_o(reg_data1_in), // DUT outputs data to regfile
        .reg_data2_o(reg_data2_in), // DUT outputs data to regfile
        .reg_data1_i(reg_data1_out), // Regfile outputs data to DUT
        .reg_data2_i(reg_data2_out), // Regfile outputs data to DUT
        .reg_ack1_i(reg_ack1),
        .reg_ack2_i(reg_ack2)
    );

    // Main Memory Model
    // This model provides a simple delay for read/write operations.
    // It responds to read_en/write_en and addr by providing/consuming data
    // and asserting ack signals after a delay.
    parameter MEM_ACCESS_DELAY = 10; // Simulate memory access time

    always_comb begin
        // Default acks low
        read_ack1 = 1'b0;
        read_ack2 = 1'b0;
        write_ack1 = 1'b0;
        write_ack2 = 1'b0;
        // Default read data to 0
        r_data1 = {`DATA_WIDTH{1'b0}};
        r_data2 = {`DATA_WIDTH{1'b0}};
    end

    // Main Memory Read Logic
    always_ff @(posedge clk) begin
        if (read_en1) begin
            // Simulate read access delay
            #MEM_ACCESS_DELAY;
            if (addr1 < `MAIN_MEM_SIZE) begin
                r_data1 <= main_memory[addr1];
            end else begin
                $display("Main Memory Read Error: Address 0x%h out of bounds at time %0t", addr1, $time);
                r_data1 <= {`DATA_WIDTH{1'bX}}; // Indicate invalid data
            end
            read_ack1 <= 1'b1; // Assert ack
        end else begin
            read_ack1 <= 1'b0; // Deassert ack
        end

        if (read_en2) begin
             // Simulate read access delay
            #MEM_ACCESS_DELAY;
            if (addr2 < `MAIN_MEM_SIZE) begin
                r_data2 <= main_memory[addr2];
            end else begin
                $display("Main Memory Read Error: Address 0x%h out of bounds at time %0t", addr2, $time);
                r_data2 <= {`DATA_WIDTH{1'bX}}; // Indicate invalid data
            end
            read_ack2 <= 1'b1; // Assert ack
        end else begin
            read_ack2 <= 1'b0; // Deassert ack
        end
    end

    // Main Memory Write Logic
    always_ff @(posedge clk) begin
        if (write_en1) begin
            // Simulate write access delay
            #MEM_ACCESS_DELAY;
            if (addr1 < `MAIN_MEM_SIZE) begin
                main_memory[addr1] <= w_data1;
                $display("Main Memory Write: Addr 0x%h <= Data 0x%h at time %0t", addr1, w_data1, $time);
            end else begin
                 $display("Main Memory Write Error: Address 0x%h out of bounds at time %0t", addr1, $time);
            end
             write_ack1 <= 1'b1; // Assert ack
        end else begin
            write_ack1 <= 1'b0; // Deassert ack
        end

         if (write_en2) begin
            // Simulate write access delay
            #MEM_ACCESS_DELAY;
            if (addr2 < `MAIN_MEM_SIZE) begin
                main_memory[addr2] <= w_data2;
                $display("Main Memory Write: Addr 0x%h <= Data 0x%h at time %0t", addr2, w_data2, $time);
            end else begin
                 $display("Main Memory Write Error: Address 0x%h out of bounds at time %0t", addr2, $time);
            end
             write_ack2 <= 1'b1; // Assert ack
        end else begin
            write_ack2 <= 1'b0; // Deassert ack
        end
    end


    // Local Register File Model
    // This model provides a simple delay for read/write operations.
    // It responds to reg_read/reg_write and reg_set_idx by providing/consuming data
    // and asserting ack signals after a delay.
    parameter REG_ACCESS_DELAY = 5; // Simulate register file access time

    always_comb begin
        // Default acks low
        reg_ack1 = 1'b0;
        reg_ack2 = 1'b0;
        // Default read data to 0
        reg_data1_out = {`DATA_WIDTH{1'b0}};
        reg_data2_out = {`DATA_WIDTH{1'b0}};
    end

    // Register File Read Logic
    // Handles requests for addresses and write data
    always_ff @(posedge clk) begin
        if (reg_read1) begin
            #REG_ACCESS_DELAY;
            if (reg_set1_idx < `REG_FILE_SETS && 0 < `REG_FILE_SIZE) begin // Assuming index 0 for addresses
                // DUT expects 32 bits for addresses, packed as {addr2, addr1}
                reg_data1_out <= register_file[reg_set1_idx][0]; // Assuming index 0 holds the packed addresses
                $display("RegFile Read 1: Set %0d, Index 0 -> Data 0x%h at time %0t", reg_set1_idx, register_file[reg_set1_idx][0], $time);
            end else begin
                 $display("RegFile Read 1 Error: Set %0d or Index 0 out of bounds at time %0t", reg_set1_idx, $time);
                 reg_data1_out <= {`DATA_WIDTH{1'bX}};
            end
            reg_ack1 <= 1'b1;
        end else begin
            reg_ack1 <= 1'b0;
        end

         if (reg_read2) begin
            #REG_ACCESS_DELAY;
            if (reg_set2_idx < `REG_FILE_SETS && 0 < `REG_FILE_SIZE) begin // Assuming index 0 for data
                // DUT expects 32 bits for data2
                reg_data2_out <= register_file[reg_set2_idx][0]; // Assuming index 0 holds data
                 $display("RegFile Read 2: Set %0d, Index 0 -> Data 0x%h at time %0t", reg_set2_idx, register_file[reg_set2_idx][0], $time);
            end else begin
                 $display("RegFile Read 2 Error: Set %0d or Index 0 out of bounds at time %0t", reg_set2_idx, $time);
                 reg_data2_out <= {`DATA_WIDTH{1'bX}};
            end
            reg_ack2 <= 1'b1;
        end else begin
            reg_ack2 <= 1'b0;
        end
    end

    // Register File Write Logic
    // Handles writes of read data back from main memory
    always_ff @(posedge clk) begin
        if (reg_write1) begin
            #REG_ACCESS_DELAY;
             if (reg_set1_idx < `REG_FILE_SETS && 0 < `REG_FILE_SIZE) begin // Assuming index 0 for data
                register_file[reg_set1_idx][0] <= reg_data1_in;
                $display("RegFile Write 1: Set %0d, Index 0 <= Data 0x%h at time %0t", reg_set1_idx, reg_data1_in, $time);
            end else begin
                $display("RegFile Write 1 Error: Set %0d or Index 0 out of bounds at time %0t", reg_set1_idx, $time);
            end
            reg_ack1 <= 1'b1;
        end else begin
            reg_ack1 <= 1'b0;
        end

         if (reg_write2) begin
            #REG_ACCESS_DELAY;
             if (reg_set2_idx < `REG_FILE_SETS && 0 < `REG_FILE_SIZE) begin // Assuming index 0 for data
                register_file[reg_set2_idx][0] <= reg_data2_in;
                $display("RegFile Write 2: Set %0d, Index 0 <= Data 0x%h at time %0t", reg_set2_idx, reg_data2_in, $time);
            end else begin
                $display("RegFile Write 2 Error: Set %0d or Index 0 out of bounds at time %0t", reg_set2_idx, $time);
            end
            reg_ack2 <= 1'b1;
        end else begin
            reg_ack2 <= 1'b0;
        end
    end


    // Stimulus Generation
    initial begin
        // Initialize signals
        reset = 1;
        on_off = 0;
        config = {`ADDR_SIZE{1'b0}};

        // Initialize memory and register file
        for (int i = 0; i < `MAIN_MEM_SIZE; i++) begin
            main_memory[i] = i; // Initialize with some pattern
        end
        for (int i = 0; i < `REG_FILE_SETS; i++) begin
            for (int j = 0; j < `REG_FILE_SIZE; j++) begin
                register_file[i][j] = {`DATA_WIDTH{1'b0}};
            end
        end

        // Apply reset
        #20;
        reset = 0;
        #10;
        $display("Reset released at time %0t", $time);

        // --- Test Case 1: Write Operation ---
        $display("\n--- Starting Write Test Case ---");
        // Configure for write: is_read=0, addr_idx=1, data_idx1=2, data_idx2=3
        // Addresses will be read from regfile set 1, index 0
        // Write data will be read from regfile set 2, index 0 (data1) and set 3, index 0 (data2)
        config = (0 << `CONFIG_OFFSET) | // is_read = 0 (Write)
                 (1 << (`CONFIG_OFFSET + 1)) | // addr_idx = 1
                 (2 << (`CONFIG_OFFSET + 1 + `REG_SET_IDX_WIDTH)) | // data_idx1 = 2
                 (3 << (`CONFIG_OFFSET + 1 + `REG_SET_IDX_WIDTH*2)); // data_idx2 = 3

        // Set addresses in regfile set 1, index 0
        // addr1 = 0x1000, addr2 = 0x1004
        register_file[1][0] = {16'h1004, 16'h1000};
        $display("Set RegFile[1][0] to 0x%h (Addresses 0x1000, 0x1004) at time %0t", register_file[1][0], $time);

        // Set write data in regfile set 2, index 0 and set 3, index 0
        // w_data1 = 0xAABBCCDD, w_data2 = 0xEEFF1122
        register_file[2][0] = 32'hAABBCCDD;
        register_file[3][0] = 32'hEEFF1122;
        $display("Set RegFile[2][0] to 0x%h (w_data1) at time %0t", register_file[2][0], $time);
        $display("Set RegFile[3][0] to 0x%h (w_data2) at time %0t", register_file[3][0], $time);

        // Start the operation
        on_off = 1;
        #10; // Wait for DUT to react to on_off
        on_off = 0; // Deassert on_off after one cycle

        // Wait for the write operation to complete (DUT goes back to IDLE)
        wait (dut.current_state == dut.IDLE);
        $display("Write operation completed at time %0t", $time);

        // Check if data was written correctly to main memory
        #10; // Wait a bit for memory model to finish
        if (main_memory[16'h1000] == 32'hAABBCCDD && main_memory[16'h1004] == 32'hEEFF1122) begin
            $display("Write Test Case Passed: Main Memory Addr 0x1000 is 0x%h, Addr 0x1004 is 0x%h", main_memory[16'h1000], main_memory[16'h1004]);
        end else begin
            $display("Write Test Case Failed: Main Memory Addr 0x1000 is 0x%h (Expected 0xAABBCCDD), Addr 0x1004 is 0x%h (Expected 0xEEFF1122)", main_memory[16'h1000], main_memory[16'h1004]);
        end


        // --- Test Case 2: Read Operation ---
        $display("\n--- Starting Read Test Case ---");
        // Initialize main memory locations to be read
        main_memory[16'h2000] = 32'h11223344;
        main_memory[16'h2008] = 32'h55667788;
        $display("Initialized Main Memory Addr 0x2000 to 0x%h and Addr 0x2008 to 0x%h for read test", main_memory[16'h2000], main_memory[16'h2008]);

        // Configure for read: is_read=1, addr_idx=4, data_idx1=5, data_idx2=6
        // Addresses will be read from regfile set 4, index 0
        // Read data will be written to regfile set 5, index 0 (data1) and set 6, index 0 (data2)
         config = (1 << `CONFIG_OFFSET) | // is_read = 1 (Read)
                 (4 << (`CONFIG_OFFSET + 1)) | // addr_idx = 4
                 (5 << (`CONFIG_OFFSET + 1 + `REG_SET_IDX_WIDTH)) | // data_idx1 = 5
                 (6 << (`CONFIG_OFFSET + 1 + `REG_SET_IDX_WIDTH*2)); // data_idx2 = 6

        // Set addresses in regfile set 4, index 0
        // addr1 = 0x2000, addr2 = 0x2008
        register_file[4][0] = {16'h2008, 16'h2000};
         $display("Set RegFile[4][0] to 0x%h (Addresses 0x2000, 0x2008) at time %0t", register_file[4][0], $time);

        // Clear destination regfile locations
        register_file[5][0] = {`DATA_WIDTH{1'b0}};
        register_file[6][0] = {`DATA_WIDTH{1'b0}};
        $display("Cleared RegFile[5][0] and RegFile[6][0] for read destination");

        // Start the operation
        on_off = 1;
        #10; // Wait for DUT to react to on_off
        on_off = 0; // Deassert on_off after one cycle

        // Wait for the read operation to complete (DUT goes back to IDLE)
        wait (dut.current_state == dut.IDLE);
        $display("Read operation completed at time %0t", $time);

        // Check if data was read correctly into the register file
        #10; // Wait a bit for regfile model to finish
        if (register_file[5][0] == 32'h11223344 && register_file[6][0] == 32'h55667788) begin
             $display("Read Test Case Passed: RegFile[5][0] is 0x%h, RegFile[6][0] is 0x%h", register_file[5][0], register_file[6][0]);
        end else begin
             $display("Read Test Case Failed: RegFile[5][0] is 0x%h (Expected 0x11223344), RegFile[6][0] is 0x%h (Expected 0x55667788)", register_file[5][0], register_file[6][0]);
        end


        // --- End of Simulation ---
        #100;
        $finish;
    end

    // Optional: Monitor signals
    // initial begin
    //     $monitor("Time=%0t State=%s on_off=%b config=0x%h | MM: r_en1=%b r_en2=%b w_en1=%b w_en2=%b addr1=0x%h addr2=0x%h r_data1=0x%h r_data2=0x%h w_data1=0x%h w_data2=0x%h | RF: r_en1=%b r_en2=%b w_en1=%b w_en2=%b set1=%0d set2=%0d data1_out=0x%h data2_out=0x%h data1_in=0x%h data2_in=0x%h",
    //              $time, dut.current_state.name(), on_off, config,
    //              read_en1, read_en2, write_en1, write_en2, addr1, addr2, r_data1, r_data2, w_data1, w_data2,
    //              reg_read1, reg_read2, reg_write1, reg_write2, reg_set1_idx, reg_set2_idx, reg_data1_out, reg_data2_out, reg_data1_in, reg_data2_in);
    // end

endmodule