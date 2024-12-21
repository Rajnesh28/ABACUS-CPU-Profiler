module abacus_top
#(
    parameter integer C_S_AXI_DATA_WIDTH	     = 32,
    parameter integer C_S_AXI_ADDR_WIDTH	     = 8,
    parameter logic WITH_AXI                     = 1'b0,
    parameter [31:0] ABACUS_BASE_ADDR            = 32'hf0030000,
    parameter logic INCLUDE_INSTRUCTION_PROFILER = 1'b1,
    parameter logic INCLUDE_CACHE_PROFILER       = 1'b1,
	parameter logic INCLUDE_STALL_UNIT			 = 1'b1,
    parameter unsigned CLOCK_FREQ                = 1000000 // 1MHz
)
(
    input logic clk,
    input logic rst,

    input [31:0] abacus_instruction,
    input abacus_instruction_issued,
	
    input logic abacus_icache_request,
    input logic abacus_dcache_request,
    input logic abacus_icache_miss,
    input logic abacus_dcache_hit,
    input logic abacus_icache_line_fill_in_progress,
    input logic abacus_dcache_line_fill_in_progress,

	input logic abacus_branch_misprediction,
	input logic abacus_ras_misprediction,
	input logic abacus_issue_no_instruction_stat,
	input logic abacus_issue_no_id_stat,
	input logic abacus_issue_flush_stat,
	input logic abacus_issue_unit_busy_stat,
	input logic abacus_issue_operands_not_ready_stat,
	input logic abacus_issue_hold_stat,
	input logic abacus_issue_multi_source_stat,

    // Modified AXI-Lite Interface from Vivado IP Generator
    input wire [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_AWADDR,
    input wire  S_AXI_AWVALID,
    output wire  S_AXI_AWREADY,
    input wire [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_WDATA,
    input wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0] S_AXI_WSTRB,
    input wire  S_AXI_WVALID,
    output wire  S_AXI_WREADY,
    output wire [1 : 0] S_AXI_BRESP,
    output wire  S_AXI_BVALID,
    input wire  S_AXI_BREADY,
    input wire [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_ARADDR,
    input wire  S_AXI_ARVALID,
    output wire  S_AXI_ARREADY,
    output wire [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_RDATA,
    output wire [1 : 0] S_AXI_RRESP,
    output wire  S_AXI_RVALID,
    input wire  S_AXI_RREADY,
    
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
localparam logic [31:0] STALL_UNIT_ENABLE_ADDR       = ABACUS_BASE_ADDR + 16'h000C;

localparam logic [31:0] INSTRUCTION_PROFILE_UNIT_BASE_ADDR   = ABACUS_BASE_ADDR + 16'h0100;

// Read-only counter base addresses
localparam logic [31:0] LOAD_WORD_COUNTER_ADDR               = INSTRUCTION_PROFILE_UNIT_BASE_ADDR + 16'h0000;
localparam logic [31:0] STORE_WORD_COUNTER_ADDR              = INSTRUCTION_PROFILE_UNIT_BASE_ADDR + 16'h0004;
localparam logic [31:0] ADDITION_COUNTER_ADDR                = INSTRUCTION_PROFILE_UNIT_BASE_ADDR + 16'h0008;
localparam logic [31:0] SUBTRACTION_COUNTER_ADDR             = INSTRUCTION_PROFILE_UNIT_BASE_ADDR + 16'h000C;
localparam logic [31:0] BRANCH_COUNTER_ADDR                  = INSTRUCTION_PROFILE_UNIT_BASE_ADDR + 16'h0010;
localparam logic [31:0] JUMP_COUNTER_ADDR                    = INSTRUCTION_PROFILE_UNIT_BASE_ADDR + 16'h0014;
localparam logic [31:0] SYSTEM_PRIVILEGE_COUNTER_ADDR        = INSTRUCTION_PROFILE_UNIT_BASE_ADDR + 16'h0018;
localparam logic [31:0] ATOMIC_COUNTER_ADDR                  = INSTRUCTION_PROFILE_UNIT_BASE_ADDR + 16'h001C;

reg [31:0] instruction_profile_unit_enable_reg;
reg [31:0] load_word_counter_reg;
reg [31:0] store_word_counter_reg;
reg [31:0] addition_counter_reg;
reg [31:0] subtraction_counter_reg;
reg [31:0] branch_counter_reg;
reg [31:0] jump_counter_reg;
reg [31:0] system_privilege_counter_reg;
reg [31:0] atomic_counter_reg;


localparam logic [31:0] CACHE_PROFILE_UNIT_BASE_ADDR = ABACUS_BASE_ADDR + 16'h0200;

localparam logic [31:0] ICACHE_REQUEST_COUNTER_ADDR          = CACHE_PROFILE_UNIT_BASE_ADDR + 16'h0000;
localparam logic [31:0] ICACHE_HIT_COUNTER_ADDR              = CACHE_PROFILE_UNIT_BASE_ADDR + 16'h0004;
localparam logic [31:0] ICACHE_MISS_COUNTER_ADDR             = CACHE_PROFILE_UNIT_BASE_ADDR + 16'h0008;
localparam logic [31:0] ICACHE_LINE_FILL_LATENCY_ADDR        = CACHE_PROFILE_UNIT_BASE_ADDR + 16'h000C;

localparam logic [31:0] DCACHE_REQUEST_COUNTER_ADDR          = CACHE_PROFILE_UNIT_BASE_ADDR + 16'h0010;
localparam logic [31:0] DCACHE_HIT_COUNTER_ADDR              = CACHE_PROFILE_UNIT_BASE_ADDR + 16'h0014;
localparam logic [31:0] DCACHE_MISS_COUNTER_ADDR             = CACHE_PROFILE_UNIT_BASE_ADDR + 16'h0018;
localparam logic [31:0] DCACHE_LINE_FILL_LATENCY_ADDR        = CACHE_PROFILE_UNIT_BASE_ADDR + 16'h001C;

reg [31:0] cache_profile_unit_enable_reg;
reg [31:0] icache_request_counter_reg;
reg [31:0] icache_hit_counter_reg;
reg [31:0] icache_miss_counter_reg;
reg [31:0] icache_line_fill_latency_counter_reg;
reg [31:0] dcache_request_counter_reg;
reg [31:0] dcache_hit_counter_reg;
reg [31:0] dcache_miss_counter_reg;
reg [31:0] dcache_line_fill_latency_counter_reg;

localparam logic [31:0] STALL_UNIT_BASE_ADDR = ABACUS_BASE_ADDR + 16'h0300;

localparam logic [31:0] BRANCH_MISPREDICTION_COUNTER_ADDR 	= STALL_UNIT_BASE_ADDR + 16'h0000;
localparam logic [31:0] RAS_MISPREDICTION_COUNTER_ADDR 		= STALL_UNIT_BASE_ADDR + 16'h0004;
localparam logic [31:0] ISSUE_NO_INSTRUCTION_STAT_COUNTER_ADDR 	= STALL_UNIT_BASE_ADDR + 16'h0008;
localparam logic [31:0] ISSUE_NO_ID_STAT_COUNTER_ADDR 		= STALL_UNIT_BASE_ADDR + 16'h000C;
localparam logic [31:0] ISSUE_FLUSH_STAT_COUNTER_ADDR 		= STALL_UNIT_BASE_ADDR + 16'h0010;
localparam logic [31:0] ISSUE_UNIT_BUSY_STAT_COUNTER_ADDR 	= STALL_UNIT_BASE_ADDR + 16'h0014;
localparam logic [31:0] ISSUE_OPERANDS_NOT_READY_STAT_COUNTER_ADDR 	= STALL_UNIT_BASE_ADDR + 16'h0018;
localparam logic [31:0] ISSUE_HOLD_STAT_COUNTER_ADDR 		= STALL_UNIT_BASE_ADDR + 16'h001C;
localparam logic [31:0] ISSUE_MULTI_SOURCE_STAT_ADDR 		= STALL_UNIT_BASE_ADDR + 16'h0020;

reg [31:0] stall_unit_enable_reg;
reg [31:0] branch_misprediction_counter_reg;
reg [31:0] ras_misprediction_counter_reg;
reg [31:0] issue_no_instruction_stat_counter_reg;
reg [31:0] issue_no_id_stat_counter_reg;
reg [31:0] issue_flush_stat_counter_reg;
reg [31:0] issue_unit_busy_stat_counter_reg;
reg [31:0] issue_operands_not_ready_stat_counter_reg;
reg [31:0] issue_hold_stat_counter_reg;
reg [31:0] issue_multi_source_stat_counter_reg;

generate if (WITH_AXI) begin : gen_axi_if

	// AXI4LITE signals
	reg [C_S_AXI_ADDR_WIDTH-1 : 0] 	axi_awaddr;
	reg  	axi_awready;
	reg  	axi_wready;
	reg [1 : 0] 	axi_bresp;
	reg  	axi_bvalid;
	reg [C_S_AXI_ADDR_WIDTH-1 : 0] 	axi_araddr;
	reg  	axi_arready;
	reg [C_S_AXI_DATA_WIDTH-1 : 0] 	axi_rdata;
	reg [1 : 0] 	axi_rresp;
	reg  	axi_rvalid;
    
	wire	 slv_reg_rden;
	wire	 slv_reg_wren;
	reg [C_S_AXI_DATA_WIDTH-1:0]	 reg_data_out;
	integer	 byte_index;
	reg	 aw_en;

	// I/O Connections assignments

	assign S_AXI_AWREADY	= axi_awready;
	assign S_AXI_WREADY	= axi_wready;
	assign S_AXI_BRESP	= axi_bresp;
	assign S_AXI_BVALID	= axi_bvalid;
	assign S_AXI_ARREADY	= axi_arready;
	assign S_AXI_RDATA	= axi_rdata;
	assign S_AXI_RRESP	= axi_rresp;
	assign S_AXI_RVALID	= axi_rvalid;
	
	// Implement axi_awready generation
	// axi_awready is asserted for one S_AXI_ACLK clock cycle when both
	// S_AXI_AWVALID and S_AXI_WVALID are asserted. axi_awready is
	// de-asserted when reset is low.

	always @( posedge clk )
	begin
	  if ( rst == 1'b1 ) // revert
	    begin
	      axi_awready <= 1'b0;
	      aw_en <= 1'b1;
	    end 
	  else
	    begin    
	      if (~axi_awready && S_AXI_AWVALID && S_AXI_WVALID && aw_en)
	        begin
	          // slave is ready to accept write address when 
	          // there is a valid write address and write data
	          // on the write address and data bus. This design 
	          // expects no outstanding transactions. 
	          axi_awready <= 1'b1;
	          aw_en <= 1'b0;
	        end
	        else if (S_AXI_BREADY && axi_bvalid)
	            begin
	              aw_en <= 1'b1;
	              axi_awready <= 1'b0;
	            end
	      else           
	        begin
	          axi_awready <= 1'b0;
	        end
	    end 
	end       

	// Implement axi_awaddr latching
	// This process is used to latch the address when both 
	// S_AXI_AWVALID and S_AXI_WVALID are valid. 

	always @( posedge clk )
	begin
	  if ( rst == 1'b1 ) // revert
	    begin
	      axi_awaddr <= 0;
	    end 
	  else
	    begin    
	      if (~axi_awready && S_AXI_AWVALID && S_AXI_WVALID && aw_en)
	        begin
	          // Write Address latching 
	          axi_awaddr <= S_AXI_AWADDR;
	        end
	    end 
	end       

	// Implement axi_wready generation
	// axi_wready is asserted for one S_AXI_ACLK clock cycle when both
	// S_AXI_AWVALID and S_AXI_WVALID are asserted. axi_wready is 
	// de-asserted when reset is low. 

	always @( posedge clk )
	begin
	  if ( rst == 1'b1 ) // revert
	    begin
	      axi_wready <= 1'b0;
	    end 
	  else
	    begin    
	      if (~axi_wready && S_AXI_WVALID && S_AXI_AWVALID && aw_en )
	        begin
	          // slave is ready to accept write data when 
	          // there is a valid write address and write data
	          // on the write address and data bus. This design 
	          // expects no outstanding transactions. 
	          axi_wready <= 1'b1;
	        end
	      else
	        begin
	          axi_wready <= 1'b0;
	        end
	    end 
	end       

	// Implement memory mapped register select and write logic generation
	// The write data is accepted and written to memory mapped registers when
	// axi_awready, S_AXI_WVALID, axi_wready and S_AXI_WVALID are asserted. Write strobes are used to
	// select byte enables of slave registers while writing.
	// These registers are cleared when reset (active low) is applied.
	// Slave register write enable is asserted when valid address and data are available
	// and the slave is ready to accept the write address and write data.
	assign slv_reg_wren = axi_wready && S_AXI_WVALID && axi_awready && S_AXI_AWVALID;

	always @( posedge clk )
	begin
	  if ( rst == 1'b1 ) // revert
	    begin
            instruction_profile_unit_enable_reg <= 0;
            cache_profile_unit_enable_reg <= 0;
	    end 
	  else begin
	    if (slv_reg_wren)
	      begin
	        case ( axi_awaddr )
                INSTRUCTION_PROFILE_UNIT_ENABLE_ADDR:
	                instruction_profile_unit_enable_reg <= S_AXI_WDATA;
	                
                CACHE_PROFILE_UNIT_ENABLE_ADDR:
	                cache_profile_unit_enable_reg <= S_AXI_WDATA;

				  STALL_UNIT_ENABLE_ADDR:
					  stall_unit_enable_reg <= S_AXI_WDATA;

	          default : begin
                    instruction_profile_unit_enable_reg <= instruction_profile_unit_enable_reg;
                    cache_profile_unit_enable_reg <= cache_profile_unit_enable_reg;
					stall_unit_enable_reg <= stall_unit_enable_reg;
                    end
	        endcase
	      end
	  end
	end    

	// Implement write response logic generation
	// The write response and response valid signals are asserted by the slave 
	// when axi_wready, S_AXI_WVALID, axi_wready and S_AXI_WVALID are asserted.  
	// This marks the acceptance of address and indicates the status of 
	// write transaction.

	always @( posedge clk )
	begin
	  if ( rst == 1'b1 ) // revert
	    begin
	      axi_bvalid  <= 0;
	      axi_bresp   <= 2'b0;
	    end 
	  else
	    begin    
	      if (axi_awready && S_AXI_AWVALID && ~axi_bvalid && axi_wready && S_AXI_WVALID)
	        begin
	          // indicates a valid write response is available
	          axi_bvalid <= 1'b1;
	          axi_bresp  <= 2'b0; // 'OKAY' response 
	        end                   // work error responses in future
	      else
	        begin
	          if (S_AXI_BREADY && axi_bvalid) 
	            //check if bready is asserted while bvalid is high) 
	            //(there is a possibility that bready is always asserted high)   
	            begin
	              axi_bvalid <= 1'b0; 
	            end  
	        end
	    end
	end   

	// Implement axi_arready generation
	// axi_arready is asserted for one S_AXI_ACLK clock cycle when
	// S_AXI_ARVALID is asserted. axi_awready is 
	// de-asserted when reset (active low) is asserted. 
	// The read address is also latched when S_AXI_ARVALID is 
	// asserted. axi_araddr is reset to zero on reset assertion.

	always @( posedge clk )
	begin
	  if ( rst == 1'b1 ) // revert
	    begin
	      axi_arready <= 1'b0;
	      axi_araddr  <= 32'b0;
	    end 
	  else
	    begin    
	      if (~axi_arready && S_AXI_ARVALID)
	        begin
	          // indicates that the slave has acceped the valid read address
	          axi_arready <= 1'b1;
	          // Read address latching
	          axi_araddr  <= S_AXI_ARADDR;
	        end
	      else
	        begin
	          axi_arready <= 1'b0;
	        end
	    end 
	end       

	// Implement axi_arvalid generation
	// axi_rvalid is asserted for one S_AXI_ACLK clock cycle when both 
	// S_AXI_ARVALID and axi_arready are asserted. The slave registers 
	// data are available on the axi_rdata bus at this instance. The 
	// assertion of axi_rvalid marks the validity of read data on the 
	// bus and axi_rresp indicates the status of read transaction.axi_rvalid 
	// is deasserted on reset (active low). axi_rresp and axi_rdata are 
	// cleared to zero on reset (active low).  
	always @( posedge clk )
	begin
	  if ( rst == 1'b1 ) // revert
	    begin
	      axi_rvalid <= 0;
	      axi_rresp  <= 0;
	    end 
	  else
	    begin    
	      if (axi_arready && S_AXI_ARVALID && ~axi_rvalid)
	        begin
	          // Valid read data is available at the read data bus
	          axi_rvalid <= 1'b1;
	          axi_rresp  <= 2'b0; // 'OKAY' response
	        end   
	      else if (axi_rvalid && S_AXI_RREADY)
	        begin
	          // Read data is accepted by the master
	          axi_rvalid <= 1'b0;
	        end                
	    end
	end    

	// Implement memory mapped register select and read logic generation
	// Slave register read enable is asserted when valid address is available
	// and the slave is ready to accept the read address.
	assign slv_reg_rden = axi_arready & S_AXI_ARVALID & ~axi_rvalid;
	always @(*)
	begin
	      // Address decoding for reading registers
	      case ( axi_araddr )
            INSTRUCTION_PROFILE_UNIT_ENABLE_ADDR   : reg_data_out <= instruction_profile_unit_enable_reg;
            CACHE_PROFILE_UNIT_ENABLE_ADDR   : reg_data_out <= cache_profile_unit_enable_reg;
			STALL_UNIT_ENABLE_ADDR	: reg_data_out <= stall_unit_enable_reg;

            LOAD_WORD_COUNTER_ADDR   : reg_data_out <= load_word_counter_reg;
            STORE_WORD_COUNTER_ADDR   : reg_data_out <= store_word_counter_reg;
            ADDITION_COUNTER_ADDR   : reg_data_out <= addition_counter_reg;
            SUBTRACTION_COUNTER_ADDR   : reg_data_out <= subtraction_counter_reg;
            BRANCH_COUNTER_ADDR   : reg_data_out <= branch_counter_reg;
            JUMP_COUNTER_ADDR   : reg_data_out <= jump_counter_reg;
            SYSTEM_PRIVILEGE_COUNTER_ADDR   : reg_data_out <= system_privilege_counter_reg;
            ATOMIC_COUNTER_ADDR   : reg_data_out <= atomic_counter_reg;

            ICACHE_REQUEST_COUNTER_ADDR   : reg_data_out <= icache_request_counter_reg;
            ICACHE_HIT_COUNTER_ADDR   : reg_data_out <= icache_hit_counter_reg;
            ICACHE_MISS_COUNTER_ADDR   : reg_data_out <= icache_miss_counter_reg;
            ICACHE_LINE_FILL_LATENCY_ADDR   : reg_data_out <= icache_line_fill_latency_counter_reg;
            DCACHE_REQUEST_COUNTER_ADDR   : reg_data_out <= dcache_request_counter_reg;
            DCACHE_HIT_COUNTER_ADDR   : reg_data_out <= dcache_hit_counter_reg;
            DCACHE_MISS_COUNTER_ADDR   : reg_data_out <= dcache_miss_counter_reg;
            DCACHE_LINE_FILL_LATENCY_ADDR   : reg_data_out <= dcache_line_fill_latency_counter_reg;

			BRANCH_MISPREDICTION_COUNTER_ADDR	: reg_data_out <= branch_misprediction_counter_reg;
			RAS_MISPREDICTION_COUNTER_ADDR	: reg_data_out <= ras_misprediction_counter_reg;
			ISSUE_NO_INSTRUCTION_STAT_COUNTER_ADDR	: reg_data_out <= issue_no_instruction_stat_counter_reg;
			ISSUE_NO_ID_STAT_COUNTER_ADDR	: reg_data_out <= issue_no_id_stat_counter_reg;
			ISSUE_FLUSH_STAT_COUNTER_ADDR	: reg_data_out <= issue_flush_stat_counter_reg;
			ISSUE_UNIT_BUSY_STAT_COUNTER_ADDR	: reg_data_out <= issue_unit_busy_stat_counter_reg;
			ISSUE_OPERANDS_NOT_READY_STAT_COUNTER_ADDR	: reg_data_out <= issue_operands_not_ready_stat_counter_reg;
			ISSUE_HOLD_STAT_COUNTER_ADDR	: reg_data_out <= issue_hold_stat_counter_reg;
			ISSUE_MULTI_SOURCE_STAT_ADDR 	: reg_data_out <= issue_multi_source_stat_counter_reg;

	        default : reg_data_out <= 0;
	      endcase
	end

	// Output register or memory read data
	always @( posedge clk )
	begin
	  if ( rst == 1'b1 ) // revert
	    begin
	      axi_rdata  <= 0;
	    end 
	  else
	    begin    
	      // When there is a valid read address (S_AXI_ARVALID) with 
	      // acceptance of read address by the slave (axi_arready), 
	      // output the read dada 
	      if (slv_reg_rden)
	        begin
	          axi_rdata <= reg_data_out;     // register read data
	        end   
	    end
	end    

end endgenerate


generate if (~WITH_AXI) begin : gen_wishbone_if 
    // Wishbone Acknowledgement and Data Handling
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            wb_ack <= 1'b0;  // Clear acknowledge on reset

            instruction_profile_unit_enable_reg <= 32'h0;
            cache_profile_unit_enable_reg <= 32'h0;
			stall_unit_enable_reg <= 32'h0;

        end else begin
            // When a valid transaction is ongoing and acknowledged
            wb_ack <= wb_cyc & wb_stb & ~wb_ack;  // One-cycle acknowledge

            if (wb_cyc & wb_stb & wb_we) begin
                // Write operation
                case (wb_adr[31:0])
                    INSTRUCTION_PROFILE_UNIT_ENABLE_ADDR: instruction_profile_unit_enable_reg <= wb_dat_i;
                    CACHE_PROFILE_UNIT_ENABLE_ADDR: cache_profile_unit_enable_reg <= wb_dat_i;
					STALL_UNIT_ENABLE_ADDR: stall_unit_enable_reg <= wb_dat_i;
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
                STALL_UNIT_ENABLE_ADDR: wb_dat_o <= stall_unit_enable_reg;
				LOAD_WORD_COUNTER_ADDR: wb_dat_o <= load_word_counter_reg;
                STORE_WORD_COUNTER_ADDR: wb_dat_o <= store_word_counter_reg;
                ADDITION_COUNTER_ADDR: wb_dat_o <= addition_counter_reg;
                SUBTRACTION_COUNTER_ADDR: wb_dat_o <= subtraction_counter_reg;
                BRANCH_COUNTER_ADDR: wb_dat_o <= branch_counter_reg;
                JUMP_COUNTER_ADDR: wb_dat_o <= jump_counter_reg;
                SYSTEM_PRIVILEGE_COUNTER_ADDR: wb_dat_o <= system_privilege_counter_reg;
                ATOMIC_COUNTER_ADDR: wb_dat_o <= atomic_counter_reg;
                ICACHE_REQUEST_COUNTER_ADDR: wb_dat_o <= icache_request_counter_reg;
                ICACHE_HIT_COUNTER_ADDR: wb_dat_o <= icache_hit_counter_reg;
                ICACHE_MISS_COUNTER_ADDR: wb_dat_o <= icache_miss_counter_reg;
                ICACHE_LINE_FILL_LATENCY_ADDR: wb_dat_o <= icache_line_fill_latency_counter_reg;
                DCACHE_REQUEST_COUNTER_ADDR: wb_dat_o <= dcache_request_counter_reg;
                DCACHE_HIT_COUNTER_ADDR: wb_dat_o <= dcache_hit_counter_reg;
                DCACHE_MISS_COUNTER_ADDR: wb_dat_o <= dcache_miss_counter_reg;
                DCACHE_LINE_FILL_LATENCY_ADDR: wb_dat_o <= dcache_line_fill_latency_counter_reg;
				BRANCH_MISPREDICTION_COUNTER_ADDR: wb_dat_o <= branch_misprediction_counter_reg;
				RAS_MISPREDICTION_COUNTER_ADDR: wb_dat_o <= ras_misprediction_counter_reg;
				ISSUE_NO_INSTRUCTION_STAT_COUNTER_ADDR: wb_dat_o <= issue_no_instruction_stat_counter_reg;
				ISSUE_NO_ID_STAT_COUNTER_ADDR: wb_dat_o <= issue_no_id_stat_counter_reg;
				ISSUE_FLUSH_STAT_COUNTER_ADDR: wb_dat_o <= issue_flush_stat_counter_reg;
				ISSUE_UNIT_BUSY_STAT_COUNTER_ADDR: wb_dat_o <= issue_unit_busy_stat_counter_reg;
				ISSUE_OPERANDS_NOT_READY_STAT_COUNTER_ADDR: wb_dat_o <= issue_operands_not_ready_stat_counter_reg;
				ISSUE_HOLD_STAT_COUNTER_ADDR: wb_dat_o <= issue_hold_stat_counter_reg;
				ISSUE_MULTI_SOURCE_STAT_ADDR: wb_dat_o <= issue_multi_source_stat_counter_reg;
                default: wb_dat_o = 32'h0;   // Invalid address, return zero
            endcase
        end
    end
end endgenerate 

// Profiling Units

// Instruction Profiler
generate if (INCLUDE_INSTRUCTION_PROFILER) begin : gen_instruction_profiler_if
    instruction_profiler # ()
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
        .branch_counter(branch_counter_reg),
        .jump_counter(jump_counter_reg),
        .system_privilege_counter(system_privilege_counter_reg),
        .atomic_counter(atomic_counter_reg)
    );
end endgenerate

// Cache Profiler
generate if (INCLUDE_CACHE_PROFILER) begin : gen_cache_profiler_if
    cache_profiler # ()
    cache_profiler_block (
        .clk(clk),
        .rst(rst),
        .enable(cache_profile_unit_enable_reg[0]),
        .icache_request(abacus_icache_request),
        .dcache_request(abacus_dcache_request),
        .icache_miss(abacus_icache_miss),
        .dcache_hit(abacus_dcache_hit),
        .icache_line_fill_in_progress(abacus_icache_line_fill_in_progress),
        .dcache_line_fill_in_progress(abacus_dcache_line_fill_in_progress),
        .icache_request_counter(icache_request_counter_reg),
        .icache_hit_counter(icache_hit_counter_reg),
        .icache_miss_counter(icache_miss_counter_reg),
        .icache_line_fill_latency_counter(icache_line_fill_latency_counter_reg),
        .dcache_request_counter(dcache_request_counter_reg),
        .dcache_hit_counter(dcache_hit_counter_reg),
        .dcache_miss_counter(dcache_miss_counter_reg),
        .dcache_line_fill_latency_counter(dcache_line_fill_latency_counter_reg)
    );
end endgenerate

generate if (INCLUDE_STALL_UNIT) begin : gen_stall_unit_if
	stall_unit # ()
	stall_unit_block (
		.clk(clk),
		.rst(rst),
		.enable(stall_unit_enable_reg[0]),
		.branch_misprediction(abacus_branch_misprediction),
		.ras_misprediction(abacus_ras_misprediction),
		.issue_no_instruction_stat(abacus_issue_no_instruction_stat),
		.issue_no_id_stat(abacus_issue_no_id_stat),
		.issue_flush_stat(abacus_issue_flush_stat),
		.issue_unit_busy_stat(abacus_issue_unit_busy_stat),
		.issue_operands_not_ready_stat(abacus_issue_operands_not_ready_stat),
		.issue_hold_stat(abacus_issue_hold_stat),
		.issue_multi_source_stat(abacus_issue_multi_source_stat),
		.branch_misprediction_counter(branch_misprediction_counter_reg),
		.ras_misprediction_counter(ras_misprediction_counter_reg),
		.issue_no_instruction_stat_counter(issue_no_instruction_stat_counter_reg),
		.issue_no_id_stat_counter(issue_no_id_stat_counter_reg),
		.issue_flush_stat_counter(issue_flush_stat_counter_reg),
		.issue_unit_busy_stat_counter(issue_unit_busy_stat_counter_reg),
		.issue_operands_not_ready_stat_counter(issue_operands_not_ready_stat_counter_reg),
		.issue_hold_stat_counter(issue_hold_stat_counter_reg),
		.issue_multi_source_stat_counter(issue_multi_source_stat_counter_reg)
	);
end endgenerate

endmodule