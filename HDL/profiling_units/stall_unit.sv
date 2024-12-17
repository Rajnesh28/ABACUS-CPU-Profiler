module stall_unit # 
    (parameter unsigned CLOCK_FREQ = 1000000) // 1MHz 
(
    input logic clk,
    input logic rst,
    input logic enable,

    input logic branch_misprediction,
    input logic ras_misprediction,
    input logic issue_no_instruction_stat,
    input logic issue_no_id_stat,
    input logic issue_flush_stat,
    input logic issue_unit_busy_stat,
    input logic issue_operands_not_ready_stat,
    input logic issue_hold_stat,
    input logic issue_multi_source_stat,

    output logic [31:0] branch_misprediction_counter,
    output logic [31:0] ras_misprediction_counter,
    output logic [31:0] issue_no_instruction_stat_counter,
    output logic [31:0] issue_no_id_stat_counter,
    output logic [31:0] issue_flush_stat_counter,
    output logic [31:0] issue_unit_busy_stat_counter,
    output logic [31:0] issue_operands_not_ready_stat_counter,
    output logic [31:0] issue_hold_stat_counter,
    output logic [31:0] issue_multi_source_stat_counter
);

reg [31:0] branch_misprediction_counter_reg                     = 32'h0;
reg [31:0] ras_misprediction_counter_reg                        = 32'h0;
reg [31:0] issue_no_instruction_stat_counter_reg                = 32'h0;
reg [31:0] issue_no_id_stat_counter_reg                         = 32'h0;
reg [31:0] issue_flush_stat_counter_reg                         = 32'h0;
reg [31:0] issue_unit_busy_stat_counter_reg                     = 32'h0;
reg [31:0] issue_operands_not_ready_stat_counter_reg            = 32'h0;
reg [31:0] issue_hold_stat_counter_reg                          = 32'h0;
reg [31:0] issue_multi_source_stat_counter_reg                  = 32'h0;

logic branch_misprediction_prev;
logic ras_misprediction_prev;
logic issue_no_instruction_stat_prev;
logic issue_no_id_stat_prev;
logic issue_flush_stat_prev;
logic issue_unit_busy_stat_prev;
logic issue_operands_not_ready_stat_prev;
logic issue_hold_stat_prev;
logic issue_multi_source_stat_prev;

int i;

always_ff @(posedge clk or posedge rst) begin
    if (rst) begin

        branch_misprediction_counter_reg <= 32'h0;
        ras_misprediction_counter_reg <= 32'h0;
        issue_no_instruction_stat_counter_reg <= 32'h0;
        issue_no_id_stat_counter_reg <= 32'h0;
        issue_flush_stat_counter_reg <= 32'h0;
        issue_unit_busy_stat_counter_reg <= 32'h0;
        issue_operands_not_ready_stat_counter_reg <= 32'h0;
        issue_hold_stat_counter_reg <= 32'h0;
        issue_multi_source_stat_counter_reg <= 32'h0;

        branch_misprediction_prev <= 0;
        ras_misprediction_prev <= 0;
        issue_no_instruction_stat_prev <= 0;
        issue_no_id_stat_prev <= 0;
        issue_flush_stat_prev <= 0;
        issue_unit_busy_stat_prev <= 0;
        issue_operands_not_ready_stat_prev <= 0;
        issue_hold_stat_prev <= 0;
        issue_multi_source_stat_prev <= 0;

        i <= 0; //Initialize counter

    end else if (~enable) begin
        branch_misprediction_counter_reg <= 32'h0;
        ras_misprediction_counter_reg <= 32'h0;
        issue_no_instruction_stat_counter_reg <= 32'h0;
        issue_no_id_stat_counter_reg <= 32'h0;
        issue_flush_stat_counter_reg <= 32'h0;
        issue_unit_busy_stat_counter_reg <= 32'h0;
        issue_operands_not_ready_stat_counter_reg <= 32'h0;
        issue_hold_stat_counter_reg <= 32'h0;
        issue_multi_source_stat_counter_reg <= 32'h0;

        branch_misprediction_prev <= 0;
        ras_misprediction_prev <= 0;
        issue_no_instruction_stat_prev <= 0;
        issue_no_id_stat_prev <= 0;
        issue_flush_stat_prev <= 0;
        issue_unit_busy_stat_prev <= 0;
        issue_operands_not_ready_stat_prev <= 0;
        issue_hold_stat_prev <= 0;
        issue_multi_source_stat_prev <= 0;

        i <= 0; //Initialize counter
        
    end else begin
        if (~branch_misprediction_prev && branch_misprediction) begin 
            branch_misprediction_counter_reg <= branch_misprediction_counter_reg + 1;
        end
        branch_misprediction_prev <= branch_misprediction;

        if (~ras_misprediction_prev && ras_misprediction) begin 
            ras_misprediction_counter_reg <= ras_misprediction_counter_reg + 1;
        end
        ras_misprediction_prev <= ras_misprediction;

        if (~issue_no_instruction_stat_prev && issue_no_instruction_stat) begin 
            issue_no_instruction_stat_counter_reg <= issue_no_instruction_stat_counter_reg + 1;
        end
        issue_no_instruction_stat_prev <= issue_no_instruction_stat;

        if (~issue_no_id_stat_prev && issue_no_id_stat) begin 
            issue_no_id_stat_counter_reg <= issue_no_id_stat_counter_reg + 1;
        end
        issue_no_id_stat_prev <= issue_no_id_stat;

        if (~issue_flush_stat_prev && issue_flush_stat) begin 
            issue_flush_stat_counter_reg <= issue_flush_stat_counter_reg + 1;
        end
        issue_flush_stat_prev <= issue_flush_stat;

        if (~issue_unit_busy_stat_prev && issue_unit_busy_stat) begin 
            issue_unit_busy_stat_counter_reg <= issue_unit_busy_stat_counter_reg + 1;
        end
        issue_unit_busy_stat_prev <= issue_unit_busy_stat;

        if (~issue_operands_not_ready_stat_prev && issue_operands_not_ready_stat) begin 
            issue_operands_not_ready_stat_counter_reg <= issue_operands_not_ready_stat_counter_reg + 1;
        end
        issue_operands_not_ready_stat_prev <= issue_operands_not_ready_stat;

        if (~issue_hold_stat_prev && issue_hold_stat) begin 
            issue_hold_stat_counter_reg <= issue_hold_stat_counter_reg + 1;
        end
        issue_hold_stat_prev <= issue_hold_stat;

        if (~issue_multi_source_stat_prev && issue_multi_source_stat) begin 
            issue_multi_source_stat_counter_reg <= issue_multi_source_stat_counter_reg + 1;
        end
        issue_multi_source_stat_prev <= issue_multi_source_stat;

        // Increment counter and update output registers at the specified interval
        if (i == CLOCK_FREQ*2) begin  // Update all registers at twice the clock frequency.
            branch_misprediction_counter <= branch_misprediction_counter_reg;
            ras_misprediction_counter <= ras_misprediction_counter_reg;
            issue_no_instruction_stat_counter <= issue_no_instruction_stat_counter_reg;
            issue_no_id_stat_counter <= issue_no_id_stat_counter_reg;
            issue_flush_stat_counter <= issue_flush_stat_counter_reg;
            issue_unit_busy_stat_counter <= issue_unit_busy_stat_counter_reg;
            issue_operands_not_ready_stat_counter <= issue_operands_not_ready_stat_counter_reg;
            issue_hold_stat_counter <= issue_hold_stat_counter_reg;
            issue_multi_source_stat_counter <= issue_multi_source_stat_counter_reg;
            i <= 0;
        end else begin
            i <= i + 1;
        end
    end
end

endmodule
