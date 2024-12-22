module instruction_profiler(
    input logic clk,
    input logic rst,
    input logic enable,

    input logic [31:0] instruction,
    input logic instruction_issued,

    output logic [31:0] load_word_counter,  // LB, LH, LW, LB, LHU, LUI
    output logic [31:0] store_word_counter, // SB, SH, SW
    output logic [31:0] addition_counter,   // ADD, ADDI, AUIPC
    output logic [31:0] subtraction_counter, // SUB
    output logic [31:0] branch_counter,     // BEQ, BNE, BLT, BGE, BLTU, BGEU
    output logic [31:0] jump_counter,       // JAL, JALR
    output logic [31:0] system_privilege_counter, // ECALL, EBREAK
    output logic [31:0] atomic_counter      // LR.W, SC.W, AMOSWAP.W, AMOADD.W, AMOAND.W, AMOOR.W, AMOXOR.W, AMOMAX.W, AMOMIN.W
);

// Source: https://www.cs.sfu.ca/~ashriram/Courses/CS295/assets/notebooks/RISCV/RISCV_CARD.pdf

// Counters for different instruction types, initialized to zero.
reg [31:0] load_word_counter_reg;
reg [31:0] store_word_counter_reg;
reg [31:0] addition_counter_reg;
reg [31:0] subtraction_counter_reg;
reg [31:0] branch_counter_reg;
reg [31:0] jump_counter_reg; 
reg [31:0] system_privilege_counter_reg;
reg [31:0] atomic_counter_reg;

reg [31:0] last_sampled_instruction;

// Procedure to increment counters
always_ff @(posedge clk or posedge rst) begin
    if (rst | ~enable) begin
        // Reset all bit vectors
        load_word_counter_reg        <= 32'b0;
        store_word_counter_reg       <= 32'b0;
        addition_counter_reg         <= 32'b0;
        subtraction_counter_reg      <= 32'b0;
        branch_counter_reg           <= 32'b0;
        jump_counter_reg             <= 32'b0;
        system_privilege_counter_reg <= 32'b0;
        atomic_counter_reg           <= 32'b0;
        last_sampled_instruction     <= 32'b0;
    end else if (instruction_issued & (instruction != last_sampled_instruction)) begin

        // Extract opcode from issued instruction (RISC-V, 7-bit opcode [6:0])
        case (instruction[6:0])
            7'b0000011: load_word_counter_reg <= load_word_counter_reg + 1;
            7'b0100011: store_word_counter_reg <= store_word_counter_reg + 1;
            7'b1100011: branch_counter_reg <= branch_counter_reg + 1;

            7'b1101111: jump_counter_reg <= jump_counter_reg + 1; // JAL
            7'b1100111: jump_counter_reg <= jump_counter_reg + 1;  // JALR

            7'b1110011: system_privilege_counter_reg <= system_privilege_counter_reg + 1;
            7'b0101111: atomic_counter_reg <= atomic_counter_reg + 1;

            // R-type
            7'b0110011: begin
                case (instruction[14:12]) // Check funct3
                    3'b000: begin
                        case (instruction[31:25])
                            7'b0000000: addition_counter_reg <= addition_counter_reg + 1;    // ADD
                            7'b0100000: subtraction_counter_reg <= subtraction_counter_reg + 1; // SUB
                        endcase
                    end
                endcase
            end

            // I-type
            7'b0010011: begin
                case (instruction[14:12]) // Check funct3
                    3'b000: addition_counter_reg <= addition_counter_reg + 1;
                endcase
            end
        endcase
        
        // Update last_sampled_instruction only after counting the instruction
        last_sampled_instruction <= instruction;
    end
end

always_comb begin
    load_word_counter        <= load_word_counter_reg;
    store_word_counter       <= store_word_counter_reg;
    addition_counter         <= addition_counter_reg;
    subtraction_counter      <= subtraction_counter_reg;
    branch_counter           <= branch_counter_reg;
    jump_counter             <= jump_counter_reg;
    system_privilege_counter <= system_privilege_counter_reg;
    atomic_counter           <= atomic_counter_reg;
end

endmodule

