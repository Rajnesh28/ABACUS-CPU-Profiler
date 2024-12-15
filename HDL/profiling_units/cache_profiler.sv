module cache_profiler #(
    parameter unsigned CLOCK_FREQ                = 1000000 // 1MHz 
)
(
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

reg [31:0] icache_request_counter_reg = 32'h0;
reg [31:0] dcache_request_counter_reg = 32'h0;

reg [31:0] icache_miss_counter_reg = 32'h0;
reg [31:0] dcache_miss_counter_reg = 32'h0;

reg [31:0] icache_hit_counter_reg = 32'h0;
reg [31:0] dcache_hit_counter_reg = 32'h0;

reg [31:0] icache_line_fill_latency_counter_reg = 32'h0;
reg [31:0] dcache_line_fill_latency_counter_reg = 32'h0;

logic icache_request_prev;
logic dcache_request_prev;
logic icache_miss_prev;
logic dcache_hit_prev;
logic dcache_line_fill_in_progress_prev;

int i;

always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
        icache_request_counter_reg <= 32'h0;
        icache_miss_counter_reg <= 32'h0;
        icache_hit_counter_reg <= 32'h0;
        icache_line_fill_latency_counter_reg <= 32'h0;

        dcache_request_counter_reg <= 32'h0;
        dcache_miss_counter_reg <= 32'h0;
        dcache_hit_counter_reg <= 32'h0;
        dcache_line_fill_latency_counter_reg <= 32'h0;

        icache_request_prev <= 1'b0;
        dcache_request_prev <= 1'b0;
        icache_miss_prev <= 1'b0;
        dcache_hit_prev <= 1'b0;
        dcache_line_fill_in_progress_prev <= 1'b0;

        i <= 0;  // Initialize counter
    end else if (~enable) begin
        icache_request_counter_reg <= 32'h0;
        icache_miss_counter_reg <= 32'h0;
        icache_hit_counter_reg <= 32'h0;
        icache_line_fill_latency_counter_reg <= 32'h0;

        dcache_request_counter_reg <= 32'h0;
        dcache_miss_counter_reg <= 32'h0;
        dcache_hit_counter_reg <= 32'h0;
        dcache_line_fill_latency_counter_reg <= 32'h0;

        i <= 0;  // Reset counter
    end else begin
        if (~icache_request_prev && icache_request) begin
            icache_request_counter_reg <= icache_request_counter_reg + 1;
        end
        icache_request_prev <= icache_request;

        if (~icache_miss_prev & icache_miss) begin
            icache_miss_counter_reg <= icache_miss_counter_reg + 1;
        end
        icache_miss_prev <= icache_miss;

        if (icache_line_fill_in_progress) begin
            icache_line_fill_latency_counter_reg <= icache_line_fill_latency_counter_reg + 1;
        end

        if (~dcache_request_prev & dcache_request) begin
            dcache_request_counter_reg <= dcache_request_counter_reg + 1;
        end
        dcache_request_prev <= dcache_request;

        if (~dcache_hit_prev & dcache_hit) begin
            dcache_hit_counter_reg <= dcache_hit_counter_reg + 1;
        end
        dcache_hit_prev <= dcache_hit;
        
        if (dcache_line_fill_in_progress) begin
            dcache_line_fill_latency_counter_reg <= dcache_line_fill_latency_counter_reg + 1;
        end

        if (~dcache_line_fill_in_progress_prev & dcache_line_fill_in_progress) begin
            dcache_miss_counter_reg <= dcache_miss_counter_reg + 1;
        end
        dcache_line_fill_in_progress_prev <= dcache_line_fill_in_progress;

        icache_hit_counter_reg <= icache_request_counter_reg - icache_miss_counter_reg;

        // Increment counter and update output registers at the specified interval
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

always_comb begin
    icache_request_counter <= icache_request_counter_reg;
    icache_hit_counter <= icache_hit_counter_reg;
    icache_miss_counter <= icache_miss_counter_reg;
    icache_line_fill_latency_counter <= icache_line_fill_latency_counter_reg;

    dcache_request_counter <= dcache_request_counter_reg;
    dcache_hit_counter <= dcache_hit_counter_reg;
    dcache_miss_counter <= dcache_miss_counter_reg;
    dcache_line_fill_latency_counter <= dcache_line_fill_latency_counter_reg;
end

endmodule
