module Cache_tb();

    localparam WORD_BITS = 32;
	localparam INDEX = 16;
	localparam BLOCK_BITS = 512;

    // Stims
    reg clk, rst_n;
	reg [31:0] addr_in_pipeline_icache_i;
	reg pipeline_valid_icache_i;
	reg [31:0] addr_in_pipeline_dcache_i;
	reg [31:0] data_in_pipeline_dcache_i;
	reg pipeline_wr_valid_dcache_i;
	reg pipeline_valid_dcache_i;
	reg [511:0] data_in_request_DMA_i;
	reg [31:0] addr_in_request_DMA_i;
	reg request_valid_DMA_i;
	reg evict_DMA_i;
	
	// Monitor
	wire [31:0] data_out_pipeline_icache_o;
	wire pipeline_valid_icache_o;
	wire [31:0] data_out_pipeline_dcache_o;
	wire pipeline_valid_dcache_o;
	
	wire [31:0] addr_out_request_DMA_o;
	wire request_DMA_o;
	
	wire [511:0] data_out_evict_DMA_o;
	wire [31:0] addr_out_evict_DMA_o;
	wire evict_DMA_o;
	
	// Use for later
	integer i, j, error;
	// DMA Cache
	reg [7:0] Mem[(2**16)-1:0];
	reg rand_instr;
	reg [31:0] rand_addr;
	reg [31:0] rand_data;
	
	// Tasks
	`include "Cache_tb_task.svh"

    // Instance of DUT
	Cache #( .BLOCK_BITS(512)) DUT(
		.clk_i(clk),
		.rst_n_i(rst_n),
	
		// Inputs to ICache from CPU
		.addr_in_pipeline_icache_i(addr_in_pipeline_icache_i),
		.pipeline_valid_icache_i(pipeline_valid_icache_i),
	
		// Outputs from ICache to CPU
		.data_out_pipeline_icache_o(data_out_pipeline_icache_o),
		.pipeline_valid_icache_o(pipeline_valid_icache_o),
	
		// Inputs to DCache from CPU
		.addr_in_pipeline_dcache_i(addr_in_pipeline_dcache_i),
		.data_in_pipeline_dcache_i(data_in_pipeline_dcache_i),
		.pipeline_wr_valid_dcache_i(pipeline_wr_valid_dcache_i),
		.pipeline_valid_dcache_i(pipeline_valid_dcache_i),
	
		// Outputs from DCache to CPU
		.data_out_pipeline_dcache_o(data_out_pipeline_dcache_o),
		.pipeline_valid_dcache_o(pipeline_valid_dcache_o),
	
		// Inputs from DMA Interface
		.data_in_request_DMA_i(data_in_request_DMA_i),
		.addr_in_request_DMA_i(addr_in_request_DMA_i),
		.request_valid_DMA_i(request_valid_DMA_i),
		.evict_DMA_i(evict_DMA_i),
	
		// Outputs to DMA Interface
		.addr_out_request_DMA_o(addr_out_request_DMA_o),
		.request_DMA_o(request_DMA_o),
		.data_out_evict_DMA_o(data_out_evict_DMA_o),
		.addr_out_evict_DMA_o(addr_out_evict_DMA_o),
		.evict_DMA_o(evict_DMA_o)
	);
    
//------------------------------------------------------------------------------------------------------------------------------------
    
    initial begin
	
		for (i = 0; i < (2**16); i++) begin
			Mem[i] = $random();
		end
	
		// Init
		clk = 1;
		rst_n = 1;
		
		addr_in_pipeline_icache_i = 0;
		pipeline_valid_icache_i = 0;
		
		addr_in_pipeline_dcache_i = 0;
		data_in_pipeline_dcache_i = 0;
		pipeline_wr_valid_dcache_i = 0;
		pipeline_valid_dcache_i = 0;
		
		data_in_request_DMA_i = 0;
		addr_in_request_DMA_i = 0;
		request_valid_DMA_i = 0;
		evict_DMA_i = 0;
		
		// Start
		@(posedge clk);
		@(negedge clk) begin
			rst_n = 0;
		end
		@(negedge clk) begin
			rst_n = 1;
		end
		
		// Long wait
		repeat(50) @(posedge clk);
		
//------------------------------------------------------------------------------------------------------------------------------------

		for (i = 0; i < 2**14; i++) begin
			rand_instr = $random();
			rand_addr = $random();
			rand_data = $random();
			
			if (rand_addr[15:0] < 16'h0F00) begin
				icache_read({16'h0000, rand_addr[15:0]});
			end
			else begin
				if (rand_instr) begin
					dcache_read({16'h0000, rand_addr[15:0]});
				end
				else begin
					dcache_write({16'h0000, rand_addr[15:0]}, rand_data);
				end
			end
		end

//------------------------------------------------------------------------------------------------------------------------------------		
		
		// Long wait
		repeat(50) @(posedge clk);
		
		$stop();

	end
	
//------------------------------------------------------------------------------------------------------------------------------------

    // clk
    always @( clk ) begin
        clk <= #5 ~clk;
    end

//------------------------------------------------------------------------------------------------------------------------------------

endmodule


