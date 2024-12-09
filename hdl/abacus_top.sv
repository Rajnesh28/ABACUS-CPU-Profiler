module sim_abacus_top 
    #(
        parameter [31:0] ABACUS_BASE_ADDR = 32'hf0030000,
        parameter logic INCLUDE_INSTRUCTION_PROFILER = 1'b1
    )
    (
        input logic clk,
        input logic rst,

        //Nets from the core
        input [31:0] abacus_instruction,
        input abacus_instruction_issued,

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
    localparam logic [31:0] INSTRUCTION_PROFILE_UNIT_ENABLE_ADDR  = ABACUS_BASE_ADDR + 16'h0004; // Look-up table of executed instructions

    localparam logic [31:0] INSTRUCTION_PROFILE_UNIT_BASE_ADDR = ABACUS_BASE_ADDR + 16'h0100;
   
    // Read-only counter base addresses
    localparam logic [31:0] LOAD_WORD_COUNTER_ADDR        = INSTRUCTION_PROFILE_UNIT_BASE_ADDR + 16'h0000;
    localparam logic [31:0] STORE_WORD_COUNTER_ADDR       = INSTRUCTION_PROFILE_UNIT_BASE_ADDR + 16'h0004;
    localparam logic [31:0] ADD_COUNTER_ADDR              = INSTRUCTION_PROFILE_UNIT_BASE_ADDR + 16'h0008;
    localparam logic [31:0] BITWISE_COUNTER_ADDR          = INSTRUCTION_PROFILE_UNIT_BASE_ADDR + 16'h000C;
    localparam logic [31:0] SHIFT_ROTATE_COUNTER_ADDR     = INSTRUCTION_PROFILE_UNIT_BASE_ADDR + 16'h0010;
    localparam logic [31:0] COMPARISON_COUNTER_ADDR       = INSTRUCTION_PROFILE_UNIT_BASE_ADDR + 16'h0014;
    localparam logic [31:0] BRANCH_COUNTER_ADDR           = INSTRUCTION_PROFILE_UNIT_BASE_ADDR + 16'h0018;
    localparam logic [31:0] CONTROL_TRANSFER_COUNTER_ADDR = INSTRUCTION_PROFILE_UNIT_BASE_ADDR + 16'h001C;
    localparam logic [31:0] SYSTEM_PRIVILEGE_COUNTER_ADDR = INSTRUCTION_PROFILE_UNIT_BASE_ADDR + 16'h0020;
    localparam logic [31:0] ATOMIC_COUNTER_ADDR           = INSTRUCTION_PROFILE_UNIT_BASE_ADDR + 16'h0024;

    // Internal register to hold test data
    reg [31:0] instruction_profile_unit_enable_reg;
    reg [31:0] load_word_counter_reg;
    reg [31:0] store_word_counter_reg;
    reg [31:0] add_counter_reg;
    reg [31:0] bitwise_counter_reg;
    reg [31:0] shift_rotate_counter_reg;
    reg [31:0] comparison_counter_reg;
    reg [31:0] branch_counter_reg;
    reg [31:0] control_transfer_counter_reg;
    reg [31:0] system_privilege_counter_reg;
    reg [31:0] atomic_counter_reg;

    // Wishbone implementation derived from
    // https://zipcpu.com/zipcpu/2017/05/29/simple-wishbone.html

    // Wishbone Acknowledgement and Data Handling
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            wb_ack <= 1'b0;  // Clear acknowledge on reset
            instruction_profile_unit_enable_reg <= 32'h0;
            load_word_counter_reg <= 32'h0;
            store_word_counter_reg <= 32'h0;
            add_counter_reg <= 32'h0;
            bitwise_counter_reg <= 32'h0;
            shift_rotate_counter_reg <= 32'h0;
            comparison_counter_reg <= 32'h0;
            branch_counter_reg <= 32'h0;
            control_transfer_counter_reg <= 32'h0;
            system_privilege_counter_reg <= 32'h0;
            atomic_counter_reg <= 32'h0;

        end else begin
            // When a valid transaction is ongoing and acknowledged
            wb_ack <= wb_cyc & wb_stb & ~wb_ack;  // One-cycle acknowledge
            
            if (wb_cyc & wb_stb & wb_we) begin
                // Write operation
                case (wb_adr[31:0])
                    INSTRUCTION_PROFILE_UNIT_ENABLE_ADDR: instruction_profile_unit_enable_reg <= wb_dat_i;
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
            LOAD_WORD_COUNTER_ADDR: wb_dat_o <= load_word_counter_reg;
            STORE_WORD_COUNTER_ADDR: wb_dat_o <= store_word_counter_reg;
            ADD_COUNTER_ADDR: wb_dat_o <= add_counter_reg;
            BITWISE_COUNTER_ADDR: wb_dat_o <= bitwise_counter_reg;
            SHIFT_ROTATE_COUNTER_ADDR: wb_dat_o <= shift_rotate_counter_reg;
            COMPARISON_COUNTER_ADDR: wb_dat_o <= comparison_counter_reg;
            BRANCH_COUNTER_ADDR: wb_dat_o <= branch_counter_reg;
            CONTROL_TRANSFER_COUNTER_ADDR: wb_dat_o <= control_transfer_counter_reg;
            SYSTEM_PRIVILEGE_COUNTER_ADDR: wb_dat_o <= system_privilege_counter_reg;
            ATOMIC_COUNTER_ADDR: wb_dat_o <= atomic_counter_reg;
            default: wb_dat_o = 32'h0;   // Invalid address, return zero
            endcase
        end
    end

    // Profiling Units
    // Instruction Mix
    generate if (INCLUDE_INSTRUCTION_PROFILER) begin : gen_instruction_profiler_if
        sim_instruction_profiler # ()
        instruction_profiler_block (
            .clk(clk),
            .rst(rst),
            .enable(instruction_profile_unit_enable_reg),
            .instruction_issued(abacus_instruction_issued),
            .instruction(abacus_instruction),
            .load_word(load_word_counter_reg),
            .store_word(store_word_counter_reg),
            .add_counter(add_counter_reg),
            .bitwise_counter(bitwise_counter_reg),
            .shift_rotate_counter(shift_rotate_counter_reg),
            .comparison_counter(comparison_counter_reg),
            .branch_counter(branch_counter_reg),
            .control_transfer_counter(control_transfer_counter_reg),
            .system_privilege_counter(system_privilege_counter_reg),
            .atomic_counter(atomic_counter_reg)
        );
    end endgenerate


endmodule