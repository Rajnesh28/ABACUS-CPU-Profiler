module cache_profiler (
    input logic clk,
    input logic rst,
    input logic enable,

    input logic icache_miss,
    input logic icache_request,

    input logic dcache_hit,
    input logic dcache_request,

    input logic icache_line_fill_in_progress,
    input logic dcache_line_fill_in_progress,

    output logic [31:0] icache_hit_counter,
    output logic [31:0] icache_miss_counter,
    output logic [31:0] icache_request_counter,

    output logic [31:0] dcache_hit_counter,
    output logic [31:0] dcache_miss_counter,
    output logic [31:0] dcache_request_counter,

    output logic [31:0] icache_line_fill_latency_counter,
    output logic [31:0] dcache_line_fill_latency_counter
);

reg[31:0] icache_request_counter_reg = 32'h0;
reg[31:0] dcache_request_counter_reg = 32'h0;

reg[31:0] icache_miss_counter_reg = 32'h0;
reg[31:0] dcache_miss_counter_reg = 32'h0;

reg[31:0] icache_hit_counter_reg = 32'h0;
reg[31:0] dcache_hit_counter_reg = 32'h0;

reg[31:0] icache_line_fill_latency_counter_reg = 32'h0;
reg[31:0] dcache_line_fill_latency_counter_reg = 32'h0;

typedef enum logic [1:0] {
    IDLE = 2'b00,
    WAIT_LOW = 2'b01
} state_t;

state_t icache_miss_state, icache_request_state;
state_t dcache_hit_state, dcache_request_state;


always_ff @(posedge clk) begin
    if (rst) begin
        icache_request_counter_reg <= 32'h0;
        icache_miss_counter_reg <= 32'h0;
        icache_hit_counter_reg <= 32'h0;
        dcache_miss_counter_reg <= 32'h0;
        dcache_hit_counter_reg <= 32'h0;
        dcache_line_fill_latency_counter_reg <= 32'h0;

        icache_request_prev <= 1'b0;
        dcache_request_prev <= 1'b0;
        icache_miss_prev <= 1'b0;
        dcache_hit_prev <= 1'b0;
        dcache_line_fill_in_progress_prev <= 1'b0;

    end else if (~enable) begin
        icache_request_counter_reg <= 32'h0;
        icache_miss_counter_reg <= 32'h0;
        icache_hit_counter_reg <= 32'h0;
        icache_line_fill_latency_counter_reg <= 32'h0;

        dcache_request_counter_reg <= 32'h0;
        dcache_miss_counter_reg <= 32'h0;
        dcache_hit_counter_reg <= 32'h0;
        dcache_line_fill_latency_counter_reg <= 32'h0;

    end else begin
        case (dcache_request_state)
            IDLE: begin
                if (dcache_request) begin
                    dcache_request_counter_reg <= dcache_request_counter_reg + 1;
                    dcache_request_state <= WAIT_LOW;
                end
            end
            WAIT_LOW: begin
                if (!dcache_request) begin
                    dcache_request_state <= IDLE;
                end
            end
        endcase
    end
end

always_ff @(posedge clk) begin
    if (rst | ~enable) begin
        icache_line_fill_latency_counter_reg <= 32'h0;        
    end else begin
        if (icache_line_fill_in_progress) begin
            icache_line_fill_latency_counter_reg <= icache_line_fill_latency_counter_reg + 1;
        end
    end
end

always_ff @(posedge clk) begin
    if (rst | ~enable) begin
        dcache_line_fill_latency_counter_reg <= 32'h0;        
    end else begin
        if (dcache_line_fill_in_progress) begin
            dcache_line_fill_latency_counter_reg <= dcache_line_fill_latency_counter_reg + 1;
        end

        if (~dcache_line_fill_in_progress_prev & dcache_line_fill_in_progress) begin
            dcache_miss_counter_reg <= dcache_miss_counter_reg + 1;
        end
        dcache_line_fill_in_progress_prev <= dcache_line_fill_in_progress;

        icache_hit_counter_reg <= icache_request_counter_reg - icache_miss_counter_reg;

    end
end


always_ff @(posedge clk)  begin
    if (rst) begin
        i <= 0;
    end else begin
        if (~enable) begin
            i <= 0;
        end
        if (i == CLOCK_FREQ*2) begin  // Update all registers every two seconds for data consistency
            icache_request_counter <= icache_request_counter_reg;
            icache_hit_counter <= icache_hit_counter_reg;
            icache_miss_counter <= icache_miss_counter_reg;
            icache_line_fill_latency_counter <= icache_line_fill_latency_counter_reg;

            dcache_request_counter <= dcache_request_counter_reg;
            dcache_hit_counter <= dcache_hit_counter_reg;
            dcache_miss_counter <= dcache_miss_counter_reg;
            dcache_line_fill_latency_counter <= dcache_line_fill_latency_counter_reg;
            i <= 0;
        end else begin
            i <= i + 1;
        end
    end
end

endmodule
