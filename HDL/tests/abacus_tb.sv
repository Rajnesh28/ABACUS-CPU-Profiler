module tb_abacus_top;

    // Parameters
    parameter [31:0] ABACUS_BASE_ADDR = 32'hf0030000;
    parameter logic INCLUDE_INSTRUCTION_PROFILER = 1'b1;
    parameter logic INCLUDE_CACHE_PROFILER = 1'b1;

    // Signals
    logic clk;
    logic rst;

    // Wishbone signals
    logic wb_cyc;
    logic wb_stb;
    logic wb_we;
    logic [31:0] wb_adr;
    logic [31:0] wb_dat_i;
    logic [31:0] wb_dat_o;
    logic wb_ack;

    // Nets from the core
    logic [31:0] abacus_instruction;
    logic abacus_instruction_issued;

    logic abacus_icache_request;
    logic abacus_dcache_request;
    logic abacus_icache_miss;
    logic abacus_dcache_hit;
    logic abacus_icache_line_fill_in_progress;
    logic abacus_dcache_line_fill_in_progress;

    // DUT instance
    abacus_top #(
        .ABACUS_BASE_ADDR(ABACUS_BASE_ADDR),
        .INCLUDE_INSTRUCTION_PROFILER(INCLUDE_INSTRUCTION_PROFILER),
        .INCLUDE_CACHE_PROFILER(INCLUDE_CACHE_PROFILER)
    ) dut (
        .clk(clk),
        .rst(rst),
        .wb_cyc(wb_cyc),
        .wb_stb(wb_stb),
        .wb_we(wb_we),
        .wb_adr(wb_adr),
        .wb_dat_i(wb_dat_i),
        .wb_dat_o(wb_dat_o),
        .wb_ack(wb_ack),
        .abacus_instruction(abacus_instruction),
        .abacus_instruction_issued(abacus_instruction_issued),
        .abacus_icache_request(abacus_icache_request),
        .abacus_dcache_request(abacus_dcache_request),
        .abacus_icache_miss(abacus_icache_miss),
        .abacus_dcache_hit(abacus_dcache_hit),
        .abacus_icache_line_fill_in_progress(abacus_icache_line_fill_in_progress),
        .abacus_dcache_line_fill_in_progress(abacus_dcache_line_fill_in_progress)
    );

    // Clock generation
    always #5 clk = ~clk;

    // Load binary instructions from file or array
    reg [31:0] instruction_memory [0:1023];  // Adjust size as needed
    initial begin
        $readmemh("/localhome/rajneshj/USRA/ABACUS/HDL/tests/instructions.txt", instruction_memory);
    end

    /* Instruction Profiler Test */ 

    initial begin
        clk = 0;
        rst = 1;
        #10 rst = 0;

        //Enable the profiling unit via Wishbone
        wb_cyc <= 1;
        wb_stb <= 1;
        wb_we <= 1;
        
        wb_adr <= 32'hf0030004;
        wb_dat_i <= 1;
        
        #20 

        wb_cyc <= 0;
        wb_stb <= 0;
        wb_we <= 0;
        
        wb_adr <= 0;
        wb_dat_i <= 0;
        
        
        foreach (instruction_memory[i]) begin
            abacus_instruction <= instruction_memory[i];
            abacus_instruction_issued <= 1;
            #10;
            abacus_instruction_issued <= 0;
            #10;
        end

        $display("Instruction Profile Unit Registers:");
        $display("LOAD_WORD_COUNT: %h", dut.load_word_counter_reg);
        $display("STORE_WORD_COUNT: %h", dut.store_word_counter_reg);
        $display("ADDITION_COUNT: %h", dut.addition_counter_reg);
        $display("SUBTRACTION COUNT: %h", dut.subtraction_counter_reg);
        $display("LOGICAL_BITWISE_COUNT: %h", dut.logical_bitwise_counter_reg);
        $display("SHIFT_BITWISE_COUNT: %h", dut.shift_bitwise_counter_reg);
        $display("COMPARISON_COUNT: %h", dut.comparison_counter_reg);
        $display("BRANCH_COUNT: %h", dut.branch_counter_reg);
        $display("JUMP_COUNT: %h", dut.jump_counter_reg);
        $display("SYSTEM_PRIVILEGE_COUNT: %h", dut.system_privilege_counter_reg);
        $display("ATOMIC_COUNT: %h", dut.atomic_counter_reg);
    
        // Assert values of internal registers bypassing having to read them out via bus logic
        assert(dut.load_word_counter_reg == 32'd7) else $fatal("Assertion failed for LOAD_WORD_COUNT");
        assert(dut.store_word_counter_reg == 32'd3) else $fatal("Assertion failed for STORE_WORD_COUNT");
        assert(dut.addition_counter_reg == 32'd12) else $fatal("Assertion failed for ADD_COUNTER_COUNT");
        assert(dut.subtraction_counter_reg == 32'd2) else $fatal("Assertion failed for SUBCTRACTION_COUNTER");
        assert(dut.logical_bitwise_counter_reg == 32'd6) else $fatal("Assertion failed for LOGICAL_BITWISE_COUNT");
        assert(dut.shift_bitwise_counter_reg == 32'd6) else $fatal("Assertion failed for BITWISE_SHIFT_COUNT");
        assert(dut.comparison_counter_reg == 32'd8) else $fatal("Assertion failed for COMPARISON_COUNT");
        assert(dut.branch_counter_reg == 32'd6) else $fatal("Assertion failed for BRANCH_COUNT");
        assert(dut.jump_counter_reg == 32'd0) else $fatal("Assertion failed for CONTROL_TRANSFER_COUNT");
        assert(dut.system_privilege_counter_reg == 32'd5) else $fatal("Assertion failed for SYSTEM_PRIVILEGE_COUNT");
        assert(dut.atomic_counter_reg == 32'd7) else $fatal("Assertion failed for ATOMIC_COUNT");

        //Disable the profiling unit
        wb_cyc <= 1;
        wb_stb <= 1;
        wb_we <= 1;
        
        wb_adr <= 32'hf0030004;
        wb_dat_i <= 0;
        
        #20 

        wb_cyc <= 0;
        wb_stb <= 0;
        wb_we <= 0;
        
        wb_adr <= 0;
        wb_dat_i <= 0;

        assert(dut.load_word_counter_reg == 32'd0) else $fatal("Assertion failed for LOAD_WORD_COUNT");
        assert(dut.store_word_counter_reg == 32'd0) else $fatal("Assertion failed for STORE_WORD_COUNT");
        assert(dut.addition_counter_reg == 32'd0 else $fatal("Assertion failed for ADD_COUNTER_COUNT");
        assert(dut.subtraction_counter_reg == 32'd0) else $fatal("Assertion failed for SUBCTRACTION_COUNTER");
        assert(dut.logical_bitwise_counter_reg == 32'd0) else $fatal("Assertion failed for LOGICAL_BITWISE_COUNT");
        assert(dut.shift_bitwise_counter_reg == 32'd0) else $fatal("Assertion failed for BITWISE_SHIFT_COUNT");
        assert(dut.comparison_counter_reg == 32'd0) else $fatal("Assertion failed for COMPARISON_COUNT");
        assert(dut.branch_counter_reg == 32'd0) else $fatal("Assertion failed for BRANCH_COUNT");
        assert(dut.jump_counter_reg == 32'd0) else $fatal("Assertion failed for CONTROL_TRANSFER_COUNT");
        assert(dut.system_privilege_counter_reg == 32'd0) else $fatal("Assertion failed for SYSTEM_PRIVILEGE_COUNT");
        assert(dut.atomic_counter_reg == 32'd0) else $fatal("Assertion failed for ATOMIC_COUNT");
    end

    /* Cache Profiler Test */
    initial begin
        clk = 0;
        rst = 1;
        #10 rst = 0;

        //Enable the profiling unit via Wishbone
        wb_cyc <= 1;
        wb_stb <= 1;
        wb_we <= 1;
        
        wb_adr <= 32'hf0030008;
        wb_dat_i <= 1;
        
        #20 

        wb_cyc <= 0;
        wb_stb <= 0;
        wb_we <= 0;
        
        wb_adr <= 0;
        wb_dat_i <= 0;

        abacus_icache_request <= 1;
        #50 // Should only register as a single icache request count

        abacus_icache_request <= 0;
        abacus_icache_miss <= 1;
        abacus_icache_line_fill_in_progress <= 1;
        #50 // Should only register as asingle icache miss, and the count for line fill in progress should be 50/10 = 5 clock cycles of latency


        abacus_icache_request <= 0;
        abacus_icache_miss <= 0;
        abacus_icache_line_fill_in_progress <= 0;

        assert(dut.abacus_icache_request == 32'd1) else $fatal("Assertion failed for ICACHE_REQUEST");
        assert(dut.abacus_icache_miss == 32'd1) else $fatal("Assertion failed for ICACHE_MISS");
        $finish    
    end

endmodule
