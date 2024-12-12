module abacus_top
#(
    parameter [31:0] ABACUS_BASE_ADDR = 32'hf0030000,
    parameter logic INCLUDE_INSTRUCTION_PROFILER = 1'b1,
    parameter logic INCLUDE_CACHE_PROFILER = 1'b1
)
(
    input logic clk,
    input logic rst,

    //Nets from the core
    input [31:0] abacus_instruction,
    input abacus_instruction_issued,
    input logic abacus_icache_request,
    input logic abacus_dcache_request,
    input logic abacus_icache_miss,
    input logic abacus_dcache_hit,

    // Wishbone signals
    input logic wb_cyc,
    input logic wb_stb,
    input logic wb_we,
    input logic [31:0] wb_adr,
    input logic [31:0] wb_dat_i,
    output logic [31:0] wb_dat_o,
    output logic wb_ack
);

// All addresses must be 4-byte (dword) aligned

localparam logic [31:0] INSTRUCTION_PROFILE_UNIT_ENABLE_ADDR  = ABACUS_BASE_ADDR + 16'h0004;
localparam logic [31:0] CACHE_PROFILE_UNIT_ENABLE_ADDR       = ABACUS_BASE_ADDR + 16'h0008;

localparam logic [31:0] INSTRUCTION_PROFILE_UNIT_BASE_ADDR   = ABACUS_BASE_ADDR + 16'h0100;

// Read-only counter base addresses
localparam logic [31:0] LOAD_WORD_COUNTER_ADDR               = INSTRUCTION_PROFILE_UNIT_BASE_ADDR + 16'h0000;
localparam logic [31:0] STORE_WORD_COUNTER_ADDR              = INSTRUCTION_PROFILE_UNIT_BASE_ADDR + 16'h0004;
localparam logic [31:0] ADDITION_COUNTER_ADDR                = INSTRUCTION_PROFILE_UNIT_BASE_ADDR + 16'h0008;
localparam logic [31:0] SUBTRACTION_COUNTER_ADDR             = INSTRUCTION_PROFILE_UNIT_BASE_ADDR + 16'h000C;
localparam logic [31:0] LOGICAL_BITWISE_COUNTER_ADDR         = INSTRUCTION_PROFILE_UNIT_BASE_ADDR + 16'h0010;
localparam logic [31:0] SHIFT_BITWISE_COUNTER_ADDR           = INSTRUCTION_PROFILE_UNIT_BASE_ADDR + 16'h0014;
localparam logic [31:0] COMPARISON_COUNTER_ADDR              = INSTRUCTION_PROFILE_UNIT_BASE_ADDR + 16'h0018;
localparam logic [31:0] BRANCH_COUNTER_ADDR                  = INSTRUCTION_PROFILE_UNIT_BASE_ADDR + 16'h001C;
localparam logic [31:0] JUMP_COUNTER_ADDR                    = INSTRUCTION_PROFILE_UNIT_BASE_ADDR + 16'h0020;
localparam logic [31:0] SYSTEM_PRIVILEGE_COUNTER_ADDR        = INSTRUCTION_PROFILE_UNIT_BASE_ADDR + 16'h0024;
localparam logic [31:0] ATOMIC_COUNTER_ADDR                  = INSTRUCTION_PROFILE_UNIT_BASE_ADDR + 16'h0028;

reg [31:0] instruction_profile_unit_enable_reg;
reg [31:0] load_word_counter_reg;
reg [31:0] store_word_counter_reg;
reg [31:0] addition_counter_reg;
reg [31:0] subtraction_counter_reg;
reg [31:0] logical_bitwise_counter_reg;
reg [31:0] shift_bitwise_counter_reg;
reg [31:0] comparison_counter_reg;
reg [31:0] branch_counter_reg;
reg [31:0] jump_counter_reg;
reg [31:0] system_privilege_counter_reg;
reg [31:0] atomic_counter_reg;

localparam logic [31:0] CACHE_PROFILE_UNIT_BASE_ADDR = ABACUS_BASE_ADDR + 16'h0200;

localparam logic [31:0] ICACHE_REQUEST_COUNTER_ADDR          = CACHE_PROFILE_UNIT_BASE_ADDR + 16'h0000;
localparam logic [31:0] ICACHE_HIT_COUNTER_ADDR              = CACHE_PROFILE_UNIT_BASE_ADDR + 16'h0004;
localparam logic [31:0] ICACHE_MISS_COUNTER_ADDR             = CACHE_PROFILE_UNIT_BASE_ADDR + 16'h0008;

localparam logic [31:0] DCACHE_REQUEST_COUNTER_ADDR          = CACHE_PROFILE_UNIT_BASE_ADDR + 16'h0010;
localparam logic [31:0] DCACHE_HIT_COUNTER_ADDR              = CACHE_PROFILE_UNIT_BASE_ADDR + 16'h0014;
localparam logic [31:0] DCACHE_MISS_COUNTER_ADDR             = CACHE_PROFILE_UNIT_BASE_ADDR + 16'h0018;

reg [31:0] cache_profile_unit_enable_reg;
reg [31:0] icache_request_counter_reg;
reg [31:0] icache_hit_counter_reg;
reg [31:0] icache_miss_counter_reg;
reg [31:0] dcache_request_counter_reg;
reg [31:0] dcache_hit_counter_reg;
reg [31:0] dcache_miss_counter_reg;

// Wishbone implementation derived from
// https://zipcpu.com/zipcpu/2017/05/29/simple-wishbone.html

// Wishbone Acknowledgement and Data Handling
always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
        wb_ack <= 1'b0;  // Clear acknowledge on reset

        instruction_profile_unit_enable_reg <= 32'h0;
        cache_profile_unit_enable_reg <= 32'h0;

        load_word_counter_reg <= 32'h0;
        store_word_counter_reg <= 32'h0;
        addition_counter_reg <= 32'h0;
        subtraction_counter_reg <= 32'h0;
        logical_bitwise_counter_reg <= 32'h0;
        shift_bitwise_counter_reg <= 32'h0;
        comparison_counter_reg <= 32'h0;
        branch_counter_reg <= 32'h0;
        jump_counter_reg <= 32'h0;
        system_privilege_counter_reg <= 32'h0;
        atomic_counter_reg <= 32'h0;

        icache_request_counter_reg <= 32'h0;
        icache_hit_counter_reg <= 32'h0;
        icache_miss_counter_reg <= 32'h0;
        dcache_request_counter_reg <= 32'h0;
        dcache_hit_counter_reg <= 32'h0;
        dcache_miss_counter_reg <= 32'h0;

    end else begin
        // When a valid transaction is ongoing and acknowledged
        wb_ack <= wb_cyc & wb_stb & ~wb_ack;  // One-cycle acknowledge

        if (wb_cyc & wb_stb & wb_we) begin
            // Write operation
            case (wb_adr[31:0])
                INSTRUCTION_PROFILE_UNIT_ENABLE_ADDR: instruction_profile_unit_enable_reg <= wb_dat_i;
                CACHE_PROFILE_UNIT_ENABLE_ADDR: cache_profile_unit_enable_reg <= wb_dat_i;
            endcase
        end
    end
end

// Handle Read Data
always_comb begin
    wb_dat_o = 32'h0;  // Default value for the output

    if (wb_cyc & wb_stb & ~wb_we) begin
        // Read operation
        case (wb_adr[31:0])
            INSTRUCTION_PROFILE_UNIT_ENABLE_ADDR: wb_dat_o <= instruction_profile_unit_enable_reg;
            CACHE_PROFILE_UNIT_ENABLE_ADDR: wb_dat_o <= cache_profile_unit_enable_reg;
            LOAD_WORD_COUNTER_ADDR: wb_dat_o <= load_word_counter_reg;
            STORE_WORD_COUNTER_ADDR: wb_dat_o <= store_word_counter_reg;
            ADDITION_COUNTER_ADDR: wb_dat_o <= addition_counter_reg;
            SUBTRACTION_COUNTER_ADDR: wb_dat_o <= subtraction_counter_reg;
            LOGICAL_BITWISE_COUNTER_ADDR: wb_dat_o <= logical_bitwise_counter_reg;
            SHIFT_BITWISE_COUNTER_ADDR: wb_dat_o <= shift_bitwise_counter_reg;
            COMPARISON_COUNTER_ADDR: wb_dat_o <= comparison_counter_reg;
            BRANCH_COUNTER_ADDR: wb_dat_o <= branch_counter_reg;
            JUMP_COUNTER_ADDR: wb_dat_o <= jump_counter_reg;
            SYSTEM_PRIVILEGE_COUNTER_ADDR: wb_dat_o <= system_privilege_counter_reg;
            ATOMIC_COUNTER_ADDR: wb_dat_o <= atomic_counter_reg;
            ICACHE_REQUEST_COUNTER_ADDR: wb_dat_o <= icache_request_counter_reg;
            ICACHE_HIT_COUNTER_ADDR: wb_dat_o <= icache_hit_counter_reg;
            ICACHE_MISS_COUNTER_ADDR: wb_dat_o <= icache_miss_counter_reg;
            DCACHE_REQUEST_COUNTER_ADDR: wb_dat_o <= dcache_request_counter_reg;
            DCACHE_HIT_COUNTER_ADDR: wb_dat_o <= dcache_hit_counter_reg;
            DCACHE_MISS_COUNTER_ADDR: wb_dat_o <= dcache_miss_counter_reg;
            default: wb_dat_o = 32'h0;   // Invalid address, return zero
        endcase
    end
end

// Profiling Units

// Instruction Profiler
generate if (INCLUDE_INSTRUCTION_PROFILER) begin : gen_instruction_profiler_if
    sim_instruction_profiler # ()
    instruction_profiler_block (
        .clk(clk),
        .rst(rst),
        .enable(instruction_profile_unit_enable_reg[0]),
        .instruction_issued(abacus_instruction_issued),
        .instruction(abacus_instruction),
        .load_word_counter(load_word_counter_reg),
        .store_word_counter(store_word_counter_reg),
        .addition_counter(addition_counter_reg),
        .subtraction_counter(subtraction_counter_reg),
        .logical_bitwise_counter(logical_bitwise_counter_reg),
        .shift_bitwise_counter(shift_bitwise_counter_reg),
        .comparison_counter(comparison_counter_reg),
        .branch_counter(branch_counter_reg),
        .jump_counter(jump_counter_reg),
        .system_privilege_counter(system_privilege_counter_reg),
        .atomic_counter(atomic_counter_reg)
    );
end endgenerate

// Cache Profiler
generate if (INCLUDE_CACHE_PROFILER) begin : gen_cache_profiler_if
    sim_cache_profiler # ()
    cache_profiler_block (
        .clk(clk),
        .rst(rst),
        .enable(cache_profile_unit_enable_reg[0]),
        .icache_request(abacus_icache_request),
        .dcache_request(abacus_dcache_request),
        .icache_miss(abacus_icache_miss),
        .dcache_hit(abacus_dcache_hit),
        .icache_request_counter(icache_request_counter_reg),
        .icache_hit_counter(icache_hit_counter_reg),
        .icache_miss_counter(icache_miss_counter_reg),
        .dcache_request_counter(dcache_request_counter_reg),
        .dcache_hit_counter(dcache_hit_counter_reg),
        .dcache_miss_counter(dcache_miss_counter_reg)
    );
end endgenerate

endmodule