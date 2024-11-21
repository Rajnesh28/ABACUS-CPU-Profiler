module abacus_top
    #( 
        parameter logic [31:0] ABACUS_BASE           = 32'hf0003000,
        parameter logic INCLUDE_INSTRUCTION_PROFILER = 1'b1,
        parameter logic INCLUDE_CACHE_PROFILER       = 1'b1,
        parameter logic AXI                          = 1'b1 //Else wishbone
    )   
    (
        input logic clk,
        input logic rst,

        // Wishbone signals
        input logic wb_cyc,
        input logic wb_stb,
        input logic wb_we,
        input logic [31:0] wb_adr,
        input logic [31:0] wb_dat_i,
        output logic [31:0] wb_dat_o,
        output logic wb_ack,

        // AXI Lite signals (excluding optional signals)
        input logic axi_awvalid,
        input logic [31:0] axi_awaddr,
        output logic axi_awready,
        input logic axi_wvalid,
        input logic [31:0] axi_wdata,
        output logic axi_wready,
        output logic axi_bvalid,
        input logic axi_bready,
        input logic axi_arvalid,
        input logic [31:0] axi_araddr,
        output logic axi_arready,
        output logic axi_rvalid, 
        output logic [31:0] axi_rdata,
        input logic axi_rready,

        //CPU nets
        // Instruction Profiling Unit
        input logic instruction_issued,
        input logic [31:0] issued_instruction,
        
        // Cache Profiling Unit
        input logic icache_hit,
        input logic dcache_hit,
        input logic icache_request,
        input logic dcache_request
    );

    // All addresses must be 4-byte (dword) aligned
    localparam logic [31:0] INSTRUCTION_PROFILE_UNIT_ENABLE_ADDR  = ABACUS_BASE + 16'h0004; // Look-up table of executed instructions
    localparam logic [31:0] CACHE_PROFILE_UNIT_ENABLE_ADDR        = ABACUS_BASE + 16'h0008; // Contains cache hits/misses/requests histogram plus latency count                         
                                                                                            // TODO: Consider having something for the branch predictor.
    
    // RW ABACUS Control Registers
    reg [31:0] abacus_base_reg                       = 32'h0; // Reserved
    reg [31:0] instruction_profile_unit_enable_reg   = 32'h0;
    reg [31:0] cache_profile_unit_enable_reg         = 32'h0;

    localparam logic [31:0] INSTRUCTION_PROFILE_UNIT_BASE = ABACUS_BASE + 16'h0100;
    localparam logic [31:0] CACHE_PROFILE_UNIT_BASE       = ABACUS_BASE + 16'h0200;

    // Read-only counter base addresses
    localparam logic [31:0] LOAD_WORD_COUNTER_ADDR        = INSTRUCTION_PROFILE_UNIT_BASE + 16'h0000;
    localparam logic [31:0] STORE_WORD_COUNTER_ADDR       = INSTRUCTION_PROFILE_UNIT_BASE + 16'h0004;
    localparam logic [31:0] ADD_COUNTER_ADDR              = INSTRUCTION_PROFILE_UNIT_BASE + 16'h0008;
    localparam logic [31:0] MUL_COUNTER_ADDR              = INSTRUCTION_PROFILE_UNIT_BASE + 16'h000C;
    localparam logic [31:0] DIV_COUNTER_ADDR              = INSTRUCTION_PROFILE_UNIT_BASE + 16'h0010;
    localparam logic [31:0] BITWISE_COUNTER_ADDR          = INSTRUCTION_PROFILE_UNIT_BASE + 16'h0014;
    localparam logic [31:0] SHIFT_ROTATE_COUNTER_ADDR     = INSTRUCTION_PROFILE_UNIT_BASE + 16'h0018;
    localparam logic [31:0] COMPARISON_COUNTER_ADDR       = INSTRUCTION_PROFILE_UNIT_BASE + 16'h001C;
    localparam logic [31:0] BRANCH_COUNTER_ADDR           = INSTRUCTION_PROFILE_UNIT_BASE + 16'h0020;
    localparam logic [31:0] CONTROL_TRANSFER_COUNTER_ADDR = INSTRUCTION_PROFILE_UNIT_BASE + 16'h0024;
    localparam logic [31:0] SYSTEM_PRIVILEGE_COUNTER_ADDR = INSTRUCTION_PROFILE_UNIT_BASE + 16'h0028;
    localparam logic [31:0] ATOMIC_COUNTER_ADDR           = INSTRUCTION_PROFILE_UNIT_BASE + 16'h002C;
    localparam logic [31:0] FLOATING_POINT_COUNTER_ADDR   = INSTRUCTION_PROFILE_UNIT_BASE + 16'h0030;

    //Read-only Instruction Mix Counters 
    reg [31:0] load_word_reg                 = 32'h0;
    reg [31:0] store_word_reg                = 32'h0;
    reg [31:0] add_counter_reg               = 32'h0;
    reg [31:0] mul_counter_reg               = 32'h0;
    reg [31:0] div_counter_reg               = 32'h0;
    reg [31:0] bitwise_counter_reg           = 32'h0;
    reg [31:0] shift_rotate_counter_reg      = 32'h0;
    reg [31:0] comparison_counter_reg        = 32'h0;
    reg [31:0] branch_counter_reg            = 32'h0;
    reg [31:0] control_transfer_counter_reg  = 32'h0;
    reg [31:0] system_privilege_counter_reg  = 32'h0;
    reg [31:0] atomic_counter_reg            = 32'h0;
    reg [31:0] floating_point_counter_reg    = 32'h0;

    localparam logic [31:0] ICACHE_HIT_COUNTER_ADDR     = CACHE_PROFILE_UNIT_BASE + 32'h0000;
    localparam logic [31:0] ICACHE_MISS_COUNTER_ADDR    = CACHE_PROFILE_UNIT_BASE + 32'h0004;
    localparam logic [31:0] ICACHE_REQUEST_COUNTER_ADDR = CACHE_PROFILE_UNIT_BASE + 32'h0008; 
    localparam logic [31:0] DCACHE_HIT_COUNTER_ADDR     = CACHE_PROFILE_UNIT_BASE + 32'h0010;
    localparam logic [31:0] DCACHE_MISS_COUNTER_ADDR    = CACHE_PROFILE_UNIT_BASE + 32'h0014;
    localparam logic [31:0] DCACHE_REQUEST_COUNTER_ADDR = CACHE_PROFILE_UNIT_BASE + 32'h0018;

    reg [31:0] icache_hit_counter_reg     = 32'h0;
    reg [31:0] icache_miss_counter_reg    = 32'h0;
    reg [31:0] icache_request_counter_reg = 32'h0;
    reg [31:0] dcache_hit_counter_reg     = 32'h0;
    reg [31:0] dcache_miss_counter_reg    = 32'h0;
    reg [31:0] dcache_request_counter_reg = 32'h0;

    // Flag to indicate write operation
    logic write_test;

    // Combinational logic for AXI or Wishbone interface
    generate if (AXI) begin : gen_axi_if
        // Simple single-cycle read/write AXI implementation
        logic doing_write;
        assign doing_write = axi_awvalid & axi_awready & axi_wvalid & axi_wready;

        // Outputs for AXI interface
        assign axi_arready = ~axi_rvalid;
        assign axi_awready = ~axi_bvalid & ~axi_arvalid & axi_awvalid & axi_wvalid;
        assign axi_wready = axi_awready;

        always_ff @(posedge clk) begin
            if (rst) begin
                axi_rvalid <= 0;
                axi_bvalid <= 0;
            end else begin
                axi_rvalid <= axi_rvalid ? ~axi_rready : axi_arvalid;
                axi_bvalid <= axi_bvalid ? ~axi_bready : doing_write;
            end
        end

        always_ff @(posedge clk) begin
            if (~axi_rvalid) begin
                case({axi_araddr[31:0]})
                    INSTRUCTION_PROFILE_UNIT_ENABLE_ADDR: axi_rdata <= instruction_profile_unit_enable_reg;
                    CACHE_PROFILE_UNIT_ENABLE_ADDR: axi_rdata <= cache_profile_unit_enable_reg;

                    // Read-only counters

                    LOAD_WORD_COUNTER_ADDR: axi_rdata <= load_word_reg;
                    STORE_WORD_COUNTER_ADDR: axi_rdata <= store_word_reg;
                    ADD_COUNTER_ADDR: axi_rdata <= add_counter_reg;
                    MUL_COUNTER_ADDR: axi_rdata <= mul_counter_reg;
                    DIV_COUNTER_ADDR: axi_rdata <= div_counter_reg;
                    BITWISE_COUNTER_ADDR: axi_rdata <= bitwise_counter_reg;
                    SHIFT_ROTATE_COUNTER_ADDR: axi_rdata <= shift_rotate_counter_reg;
                    COMPARISON_COUNTER_ADDR: axi_rdata <= comparison_counter_reg;
                    BRANCH_COUNTER_ADDR: axi_rdata <= branch_counter_reg;
                    CONTROL_TRANSFER_COUNTER_ADDR: axi_rdata <= control_transfer_counter_reg;
                    SYSTEM_PRIVILEGE_COUNTER_ADDR: axi_rdata <= system_privilege_counter_reg;
                    ATOMIC_COUNTER_ADDR: axi_rdata <= atomic_counter_reg;
                    FLOATING_POINT_COUNTER_ADDR: axi_rdata <= floating_point_counter_reg;

                    ICACHE_HIT_COUNTER_ADDR: axi_rdata <= icache_hit_counter_reg;
                    ICACHE_MISS_COUNTER_ADDR: axi_rdata <= icache_miss_counter_reg;
                    ICACHE_REQUEST_COUNTER_ADDR: axi_rdata <= icache_request_counter_reg;

                    DCACHE_HIT_COUNTER_ADDR: axi_rdata <= dcache_hit_counter_reg;
                    DCACHE_MISS_COUNTER_ADDR: axi_rdata <= dcache_miss_counter_reg;
                    DCACHE_REQUEST_COUNTER_ADDR: axi_rdata <= dcache_request_counter_reg;

                    default: axi_rdata <= 32'h0; // Invalid address
                endcase
            end
        end

        always_ff @(posedge clk) begin
            if (doing_write) begin
                case ({axi_awaddr[31:0]})
                    INSTRUCTION_PROFILE_UNIT_ENABLE_ADDR: instruction_profile_unit_enable_reg <= axi_wdata;
                    CACHE_PROFILE_UNIT_ENABLE_ADDR: cache_profile_unit_enable_reg <= axi_wdata;
                    default: ; // Read-only counters, do nothing
                endcase
            end
        end

        // Not in use for Wishbone
        assign wb_ack = 0;

    end else begin : gen_wishbone_if
        // Wishbone combinational response
        assign wb_ack = wb_cyc & wb_stb;

    always_comb begin
        wb_dat_o = '0;  // Default output value
        write_test = 0;

        case ({wb_adr[31:0]})
            INSTRUCTION_PROFILE_UNIT_ENABLE_ADDR: begin
                if (wb_we) write_test = wb_cyc & wb_stb & wb_we;
                else wb_dat_o <= instruction_profile_unit_enable_reg;
            end
            CACHE_PROFILE_UNIT_ENABLE_ADDR: begin
                if (wb_we) write_test = wb_cyc & wb_stb & wb_we;
                else wb_dat_o <= cache_profile_unit_enable_reg;
            end

            // Read-only counters
            LOAD_WORD_COUNTER_ADDR: wb_dat_o <= load_word_reg;
            STORE_WORD_COUNTER_ADDR: wb_dat_o <= store_word_reg;
            ADD_COUNTER_ADDR: wb_dat_o <= add_counter_reg;
            MUL_COUNTER_ADDR: wb_dat_o <= mul_counter_reg;
            DIV_COUNTER_ADDR: wb_dat_o <= div_counter_reg;
            BITWISE_COUNTER_ADDR: wb_dat_o <= bitwise_counter_reg;
            SHIFT_ROTATE_COUNTER_ADDR: wb_dat_o <= shift_rotate_counter_reg;
            COMPARISON_COUNTER_ADDR: wb_dat_o <= comparison_counter_reg;
            BRANCH_COUNTER_ADDR: wb_dat_o <= branch_counter_reg;
            CONTROL_TRANSFER_COUNTER_ADDR: wb_dat_o <= control_transfer_counter_reg;
            SYSTEM_PRIVILEGE_COUNTER_ADDR: wb_dat_o <= system_privilege_counter_reg;
            ATOMIC_COUNTER_ADDR: wb_dat_o <= atomic_counter_reg;
            FLOATING_POINT_COUNTER_ADDR: wb_dat_o <= floating_point_counter_reg;

            ICACHE_HIT_COUNTER_ADDR: wb_dat_o <= icache_hit_counter_reg;
            ICACHE_MISS_COUNTER_ADDR: wb_dat_o <= icache_miss_counter_reg;
            ICACHE_REQUEST_COUNTER_ADDR: wb_dat_o <= icache_request_counter_reg;

            DCACHE_HIT_COUNTER_ADDR: wb_dat_o <= dcache_hit_counter_reg;
            DCACHE_MISS_COUNTER_ADDR: wb_dat_o <= dcache_miss_counter_reg;
            DCACHE_REQUEST_COUNTER_ADDR: wb_dat_o <= dcache_request_counter_reg;


            default: wb_dat_o = '0; // Invalid address
        endcase
    end

    // Write logic for Wishbone
    always_ff @(posedge clk) begin
        if (write_test) begin
            case ({wb_adr[31:0]})
                INSTRUCTION_PROFILE_UNIT_ENABLE_ADDR: instruction_profile_unit_enable_reg <= wb_dat_i;
                CACHE_PROFILE_UNIT_ENABLE_ADDR: cache_profile_unit_enable_reg <= wb_dat_i;
                default: ; 
            endcase
        end
    end

    // Not in use for AXI
    assign axi_awready = 0;
    assign axi_wready = 0;
    assign axi_bvalid = 0;
    assign axi_arready = 0;
    assign axi_rvalid = 0;

    end
    endgenerate

    // Profiling Units
    
    // Instruction Mix
    generate if (INCLUDE_INSTRUCTION_PROFILER) begin : gen_instruction_profiler_if
        instruction_profiler # ()
        instruction_profiler_block (
            .clk(clk),
            .rst(rst),
            .enable(instruction_profile_unit_enable_reg),

            .instruction_issued(instruction_issued),
            .issued_instruction(issued_instruction),
            .load_word(load_word_reg),
            .store_word(store_word_reg),
            .add_counter(add_counter_reg),
            .mul_counter(mul_counter_reg),
            .div_counter(div_counter_reg),
            .bitwise_counter(bitwise_counter_reg),
            .shift_rotate_counter(shift_rotate_counter_reg),
            .comparison_counter(comparison_counter_reg),
            .branch_counter(branch_counter_reg),
            .control_transfer_counter(control_transfer_counter_reg),
            .system_privilege_counter(system_privilege_counter_reg),
            .atomic_counter(atomic_counter_reg),
            .floating_point_counter(floating_point_counter_reg)
        );
    end endgenerate
    

    generate if (INCLUDE_CACHE_PROFILER) begin : gen_cache_profiler_if
        cache_profiler # ()
        cache_profiler_block (
            .clk(clk),
            .rst(rst),
            .enable(cache_profile_unit_enable_reg),

            .icache_hits(icache_tag_hit),
            .icache_requests(icache_request_in_progress),
            .dcache_hits(dcache_tag_hit),
            .dcache_requests(dcache_request_in_progress),

            .icache_hit_counter(icache_hit_counter),
            .icache_miss_counter(icache_miss_counter),
            .icache_request_counter(icache_request_counter),

            .dcache_hit_counter(dcache_hit_counter),
            .dcache_miss_counter(dcache_miss_counter),
            .dcache_request_counter(dcache_request_counter)
        );
    end endgenerate

endmodule
