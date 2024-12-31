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

    logic abacus_branch_misprediction;
    logic abacus_ras_misprediction;
    logic abacus_issue_no_instruction_stat;
    logic abacus_issue_no_id_stat;
    logic abacus_issue_flush_stat;
    logic abacus_issue_unit_busy_stat;
    logic abacus_issue_operands_not_ready_stat;
    logic abacus_issue_hold_stat;
    logic abacus_issue_multi_source_stat;
    
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
        .abacus_dcache_line_fill_in_progress(abacus_dcache_line_fill_in_progress),
        .abacus_branch_misprediction(abacus_branch_misprediction),
        .abacus_ras_misprediction(abacus_ras_misprediction),
        .abacus_issue_no_instruction_stat(abacus_issue_no_instruction_stat),
        .abacus_issue_no_id_stat(issuabacus_issue_no_id_state_no_id_stat),
        .abacus_issue_flush_stat(abacus_issue_flush_stat),
        .abacus_issue_unit_busy_stat(abacus_issue_unit_busy_stat),
        .abacus_issue_operands_not_ready_stat(abacus_issue_operands_not_ready_stat),
        .abacus_issue_hold_stat(abacus_issue_hold_stat)
    );

    // Clock generation
    always #5 clk = ~clk;

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
        $display("SUBTRACTION_COUNT: %h", dut.subtraction_counter_reg);
        $display("BRANCH_COUNT: %h", dut.branch_counter_reg);
        $display("JUMP_COUNT: %h", dut.jump_counter_reg);
        $display("SYSTEM_PRIVILEGE_COUNT: %h", dut.system_privilege_counter_reg);
        $display("ATOMIC_COUNT: %h", dut.atomic_counter_reg);
    
        // Assert values of internal registers
        assert(dut.load_word_counter_reg == 32'd7) else $fatal("Assertion failed for LOAD_WORD_COUNT");
        assert(dut.store_word_counter_reg == 32'd3) else $fatal("Assertion failed for STORE_WORD_COUNT");
        assert(dut.addition_counter_reg == 32'd12) else $fatal("Assertion failed for ADD_COUNTER_COUNT");
        assert(dut.subtraction_counter_reg == 32'd2) else $fatal("Assertion failed for SUBTRACTION_COUNTER");
        assert(dut.branch_counter_reg == 32'd6) else $fatal("Assertion failed for BRANCH_COUNT");
        assert(dut.jump_counter_reg == 32'd0) else $fatal("Assertion failed for JUMP_COUNT");
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
        assert(dut.addition_counter_reg == 32'd0) else $fatal("Assertion failed for ADD_COUNTER_COUNT");
        assert(dut.subtraction_counter_reg == 32'd0) else $fatal("Assertion failed for SUBTRACTION_COUNTER");
        assert(dut.branch_counter_reg == 32'd0) else $fatal("Assertion failed for BRANCH_COUNT");
        assert(dut.jump_counter_reg == 32'd0) else $fatal("Assertion failed for JUMP_COUNT");
        assert(dut.system_privilege_counter_reg == 32'd0) else $fatal("Assertion failed for SYSTEM_PRIVILEGE_COUNT");
        assert(dut.atomic_counter_reg == 32'd0) else $fatal("Assertion failed for ATOMIC_COUNT");

    /* Cache Profiler Test */
        #30

        //Enable the profiling unit via Wishbone
        wb_cyc <= 1;
        wb_stb <= 1;
        wb_we <= 1;
        
        wb_adr <= 32'hf0030008;
        wb_dat_i <= 1;
        
        
        // Initialize inputs to zero as rising edge registers an increment to the count registers of these signals     
        abacus_icache_request <= 0;
        abacus_icache_miss <= 0;
        abacus_icache_line_fill_in_progress <= 0;
        
        abacus_dcache_request <= 0;
        abacus_dcache_hit <= 0;
        abacus_dcache_line_fill_in_progress <= 0;
        
        #20 

        wb_cyc <= 0;
        wb_stb <= 0;
        wb_we <= 0;
        
        wb_adr <= 0;
        wb_dat_i <= 0;

        // Test cache requests, hits, misses, and line fill latency
        abacus_icache_request <= 1;
        #50 // Should register as a single icache request count

        abacus_icache_request <= 0;
        abacus_icache_miss <= 1;
        abacus_icache_line_fill_in_progress <= 1;
        #50 // Should register as a single icache miss, and the count for line fill in progress should be 50/10 = 5 clock cycles of latency

        abacus_icache_request <= 0;
        abacus_icache_miss <= 0;
        abacus_icache_line_fill_in_progress <= 0;

        abacus_dcache_request <= 1;
        #30 // Should register
        
        abacus_dcache_request <= 1;
        #30 // Should register as a single dcache request count

        abacus_dcache_request <= 0;
        abacus_dcache_hit <= 1;
        abacus_dcache_line_fill_in_progress <= 1;
        #40 // Should register as a single dcache hit, and the count for line fill in progress should be 40/10 = 4 clock cycles of latency

        abacus_dcache_request <= 0;
        abacus_dcache_hit <= 0;
        abacus_dcache_line_fill_in_progress <= 0;

        #1000 // Wait 100 ns, for data consistency, the internal cache profiler registers drive the 
              // top-level registers after an entire second (p_CLOCK_FREQ set to 100)
              
        // Print the values of the cache profile unit registers
        $display("Cache Profile Unit Registers:");
        $display("ICACHE_REQUEST_COUNTER: %h", dut.icache_request_counter_reg);
        $display("ICACHE_HIT_COUNTER: %h", dut.icache_hit_counter_reg);
        $display("ICACHE_MISS_COUNTER: %h", dut.icache_miss_counter_reg);
        $display("ICACHE_LINE_FILL_LATENCY_COUNTER: %h", dut.icache_line_fill_latency_counter_reg);
        $display("DCACHE_REQUEST_COUNTER: %h", dut.dcache_request_counter_reg);
        $display("DCACHE_HIT_COUNTER: %h", dut.dcache_hit_counter_reg);
        $display("DCACHE_MISS_COUNTER: %h", dut.dcache_miss_counter_reg);
        $display("DCACHE_LINE_FILL_LATENCY_COUNTER: %h", dut.dcache_line_fill_latency_counter_reg);

        // Verify the values with assert statements (replace with expected values)
        assert(dut.icache_request_counter_reg == 32'd1) else $fatal("Assertion failed for ICACHE_REQUEST_COUNTER");
        assert(dut.icache_miss_counter_reg == 32'd1) else $fatal("Assertion failed for ICACHE_MISS_COUNTER");
        assert(dut.icache_line_fill_latency_counter_reg == 32'd5) else $fatal("Assertion failed for ICACHE_LINE_FILL_LATENCY_COUNTER");
        assert(dut.dcache_request_counter_reg == 32'd1) else $fatal("Assertion failed for DCACHE_REQUEST_COUNTER");
        assert(dut.dcache_hit_counter_reg == 32'd1) else $fatal("Assertion failed for DCACHE_HIT_COUNTER");
        assert(dut.dcache_line_fill_latency_counter_reg == 32'd4) else $fatal("Assertion failed for DCACHE_LINE_FILL_LATENCY_COUNTER");

        // Disable the profiling unit
        wb_cyc <= 1;
        wb_stb <= 1;
        wb_we <= 1;
        
        wb_adr <= 32'hf0030008;
        wb_dat_i <= 0;
        
        #20 

        wb_cyc <= 0;
        wb_stb <= 0;
        wb_we <= 0;
        
        wb_adr <= 0;
        wb_dat_i <= 0;

        // Ensure counters are reset
        assert(dut.icache_request_counter_reg == 32'd0) else $fatal("Assertion failed for ICACHE_REQUEST_COUNTER");
        assert(dut.icache_miss_counter_reg == 32'd0) else $fatal("Assertion failed for ICACHE_MISS_COUNTER");
        assert(dut.icache_line_fill_latency_counter_reg == 32'd0) else $fatal("Assertion failed for ICACHE_LINE_FILL_LATENCY_COUNTER");
        assert(dut.dcache_request_counter_reg == 32'd0) else $fatal("Assertion failed for DCACHE_REQUEST_COUNTER");
        assert(dut.dcache_hit_counter_reg == 32'd0) else $fatal("Assertion failed for DCACHE_HIT_COUNTER");
        assert(dut.dcache_line_fill_latency_counter_reg == 32'd0) else $fatal("Assertion failed for DCACHE_LINE_FILL_LATENCY_COUNTER");

        /* Stall Unit Test */
        clk = 0;
        rst = 1;
        #10 rst = 0;

        //Enable the profiling unit via Wishbone
        wb_cyc <= 1;
        wb_stb <= 1;
        wb_we <= 1;
        
        wb_adr <= 32'hf003000C;
        wb_dat_i <= 1;
        
        #20 

        wb_cyc <= 0;
        wb_stb <= 0;
        wb_we <= 0;
        
        wb_adr <= 0;
        wb_dat_i <= 0;

        assert(dut.abacus_branch_misprediction == 32'd0) else $fatal ("Assertion failed for BRANCH MISPREDICTIONS");
        assert(dut.abacus_ras_misprediction == 32'd0) else $fatal ("Assertion failed for RAS MISPREDICTIONS");
        assert(dut.abacus_issue_no_instruction_stat == 32'd0) else $fatal ("Assertion failed for Issue: NO INSTRUCTION ");
        assert(dut.abacus_issue_no_id_stat == 32'd0) else $fatal ("Assertion failed for Issue: NO ID ");
        assert(dut.abacus_issue_flush_stat == 32'd0) else $fatal ("Assertion failed for Issue: Flush ");
        assert(dut.abacus_issue_unit_busy_stat == 32'd0) else $fatal ("Assertion failed for Issue: Unit busy ");
        assert(dut.abacus_issue_operands_not_ready_stat == 32'd0) else $fatal ("Assertion failed for Issue: Operands not ready ");
        assert(dut.abacus_issue_hold_stat == 32'd0) else $fatal ("Assertion failed for Issue: Hold ");

        abacus_branch_misprediction <= 1;
        #10
        abacus_branch_misprediction <= 0;
        
        abacus_ras_misprediction <= 1;
        #30
        abacus_ras_misprediction <= 0;

        abacus_issue_no_id_stat <= 1;
        #45
        abacus_issue_no_id_stat <= 0;

        assert(dut.abacus_branch_misprediction == 32'd1) else $fatal ("Assertion failed for BRANCH MISPREDICTIONS");
        assert(dut.abacus_ras_misprediction == 32'd3) else $fatal ("Assertion failed for RAS MISPREDICTIONS");
        assert(dut.abacus_issue_no_instruction_stat == 32'd0) else $fatal ("Assertion failed for Issue: NO INSTRUCTION ");
        assert(dut.abacus_issue_no_id_stat == 32'd4) else $fatal ("Assertion failed for Issue: NO ID ");
        assert(dut.abacus_issue_flush_stat == 32'd0) else $fatal ("Assertion failed for Issue: Flush ");
        assert(dut.abacus_issue_unit_busy_stat == 32'd0) else $fatal ("Assertion failed for Issue: Unit busy ");
        assert(dut.abacus_issue_operands_not_ready_stat == 32'd0) else $fatal ("Assertion failed for Issue: Operands not ready ");
        assert(dut.abacus_issue_hold_stat == 32'd0) else $fatal ("Assertion failed for Issue: Hold ");

        //Disable the profiling unit via Wishbone
        wb_cyc <= 1;
        wb_stb <= 1;
        wb_we <= 1;
        
        wb_adr <= 32'hf003000C;
        wb_dat_i <= 0;
        
        #10
        
        assert(dut.abacus_branch_misprediction == 32'd0) else $fatal ("Assertion failed for BRANCH MISPREDICTIONS");
        assert(dut.abacus_ras_misprediction == 32'd0) else $fatal ("Assertion failed for RAS MISPREDICTIONS");
        assert(dut.abacus_issue_no_instruction_stat == 32'd0) else $fatal ("Assertion failed for Issue: NO INSTRUCTION ");
        assert(dut.abacus_issue_no_id_stat == 32'd0) else $fatal ("Assertion failed for Issue: NO ID ");
        assert(dut.abacus_issue_flush_stat == 32'd0) else $fatal ("Assertion failed for Issue: Flush ");
        assert(dut.abacus_issue_unit_busy_stat == 32'd0) else $fatal ("Assertion failed for Issue: Unit busy ");
        assert(dut.abacus_issue_operands_not_ready_stat == 32'd0) else $fatal ("Assertion failed for Issue: Operands not ready ");
        assert(dut.abacus_issue_hold_stat == 32'd0) else $fatal ("Assertion failed for Issue: Hold ");
        
        #10 
        # 55

        assert(dut.abacus_branch_misprediction == 32'd1) else $fatal("Assertion failed for BRANCH_MISPREDICTION");
        assert(dut.abacus_ras_misprediction == 32'd3) else $fatal("Assertion failed for RAS_MISPREDICTION");
        assert(dut.abacus_issue_no_id_stat == 32'd4) else $fatal("Assertion failed for ISSUE_NO_ID_STAT");
    

        #10

        //Re-enable the profiling unit via Wishbone
        wb_cyc <= 1;
        wb_stb <= 1;
        wb_we <= 1;
        
        wb_adr <= 32'hf003000C;
        wb_dat_i <= 1;

        #10
        abacus_issue_flush_stat <= 1;
        #10

        
        $finish;
    end

endmodule
