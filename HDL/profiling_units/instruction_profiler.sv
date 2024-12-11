module sim_instruction_profiler(
    input logic clk,
    input logic rst,
    input logic enable,

    input logic [31:0] instruction, // NOTE: TAKE EXECUTED INSTRUCTIONS
    input logic instruction_issued,

    output logic [31:0] load_word,
    output logic [31:0] store_word,
    output logic [31:0] add_counter,
    output logic [31:0] bitwise_counter,
    output logic [31:0] shift_rotate_counter,
    output logic [31:0] comparison_counter,
    output logic [31:0] branch_counter,
    output logic [31:0] control_transfer_counter,
    output logic [31:0] system_privilege_counter,
    output logic [31:0] atomic_counter
);

// Counters for different instruction types, initialized to zero.
reg [31:0] load_word_counter_reg        = 32'h0;
reg [31:0] store_word_counter_reg       = 32'h0;
reg [31:0] add_counter_reg              = 32'h0;
reg [31:0] bitwise_counter_reg          = 32'h0;
reg [31:0] shift_rotate_counter_reg     = 32'h0;
reg [31:0] comparison_counter_reg       = 32'h0;
reg [31:0] branch_counter_reg           = 32'h0;
reg [31:0] control_transfer_counter_reg = 32'h0;
reg [31:0] system_privilege_counter_reg = 32'h0;
reg [31:0] atomic_counter_reg           = 32'h0;

// Procedure to increment counters
always_ff @(posedge clk) begin
    if (rst | ~enable) begin
        // Reset all counters
        load_word_counter_reg        <= 32'b0;
        store_word_counter_reg       <= 32'b0;
        add_counter_reg              <= 32'b0;
        bitwise_counter_reg          <= 32'b0;
        shift_rotate_counter_reg     <= 32'b0;
        comparison_counter_reg       <= 32'b0;
        branch_counter_reg           <= 32'b0;
        control_transfer_counter_reg <= 32'b0;
        system_privilege_counter_reg <= 32'b0;
        atomic_counter_reg           <= 32'b0;
    end
    else if (instruction_issued) begin
        // Extract opcode from issued instruction (RISC-V, 7-bit opcode [6:0])
        case (instruction[6:0])
            7'b0000011: load_word_counter_reg <= load_word_counter_reg + 1;  // Load instruction
            7'b0100011: store_word_counter_reg <= store_word_counter_reg + 1; // Store instruction
            7'b1100011: branch_counter_reg <= branch_counter_reg + 1; // Branch instructions
            7'b1101111: control_transfer_counter_reg <= control_transfer_counter_reg + 1; // Jump (JAL)
            7'b1110011: system_privilege_counter_reg <= system_privilege_counter_reg + 1; // System (ECALL)
            7'b0101111: atomic_counter_reg <= atomic_counter_reg + 1; // Atomic (AMO)

            7'b0110011: begin
                // R-type arithmetic (add.)
                case (instruction[31:25]) // Check funct7
                    7'b0000000: add_counter_reg <= add_counter_reg + 1;    // ADD
                endcase
            end

            7'b0010011: begin
                // Immediate arithmetic (bitwise, shift, etc.)
                case (instruction[14:12]) // Check funct3
                    3'b000: add_counter_reg <= add_counter_reg + 1; // ADDI
                    3'b100: bitwise_counter_reg <= bitwise_counter_reg + 1; // XORI (bitwise)
                    3'b001: shift_rotate_counter_reg <= shift_rotate_counter_reg + 1; // SLLI (shift)
                endcase
            end
        endcase
    end
end


always_comb begin
    load_word                <= load_word_counter_reg;
    store_word               <= store_word_counter_reg;
    add_counter              <= add_counter_reg;
    bitwise_counter          <= bitwise_counter_reg;
    shift_rotate_counter     <= shift_rotate_counter_reg;
    comparison_counter       <= comparison_counter_reg;
    branch_counter           <= branch_counter_reg;
    control_transfer_counter <= control_transfer_counter_reg;
    system_privilege_counter <= system_privilege_counter_reg;
    atomic_counter           <= atomic_counter_reg;
end
endmodule
