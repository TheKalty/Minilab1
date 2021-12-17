module Cache
	#( 
		parameter BLOCK_BITS = 512
	)
	(
	input clk_i,
	input rst_n_i,
	
	// Inputs to ICache from CPU
	input [31:0] addr_in_pipeline_icache_i,
	input pipeline_valid_icache_i,
	
	// Outputs from ICache to CPU
	output [31:0] data_out_pipeline_icache_o,
	output pipeline_valid_icache_o,
	
	
	// Inputs to DCache from CPU
	input [31:0] addr_in_pipeline_dcache_i,
	input [31:0] data_in_pipeline_dcache_i,
	input pipeline_wr_valid_dcache_i,
	input pipeline_valid_dcache_i,
	
	// Outputs from DCache to CPU
	output [31:0] data_out_pipeline_dcache_o,
	output pipeline_valid_dcache_o,
	
	
	// Inputs from DMA Interface
	input [511:0] data_in_request_DMA_i,
	input [31:0] addr_in_request_DMA_i,
	input request_valid_DMA_i,
	input evict_DMA_i,
	
	// Outputs to DMA Interface
	output [31:0] addr_out_request_DMA_o,
	output request_DMA_o,
	output [511:0] data_out_evict_DMA_o,
	output [31:0] addr_out_evict_DMA_o,
	output evict_DMA_o
	);
	
//----------------------------------------------------------------------------------------------
		
	// Interconnects
	
	// ICache to MMCache
	logic [511:0] data_in_request_icache;
	logic [31:0] addr_in_request_icache;
	logic request_valid_icache;
	logic [31:0] addr_out_request_icache;
	logic request_icache;
	
	// DCache to MMCache
	logic [511:0] data_in_request_dcache;
	logic [31:0] addr_in_request_dcache;
	logic request_valid_dcache;
	logic [31:0] addr_out_request_dcache;
	logic request_dcache;
	logic evict_dcache_in;
	logic [511:0] data_out_evict_dcache;
	logic evict_dcache_out;

//----------------------------------------------------------------------------------------------
	
	// ICache
	ICache #(.INDEX(2), .BLOCK_BITS(512)) ICACHE(
		.clk_i(clk_i),
		.rst_n_i(rst_n_i),
	
		// Lower to self
		.addr_in_pipeline_i(addr_in_pipeline_icache_i), 		// Address request from CPU
		.pipeline_valid_i(pipeline_valid_icache_i), 				// CPU Signal of a real request
		.data_out_pipeline_o(data_out_pipeline_icache_o),		// Data out of CPU
		.pipeline_valid_o(pipeline_valid_icache_o),				// Signal for a valid output of data to CPU
	
		// Higher Cache Block input
		.data_in_request_i(data_in_request_icache),		// Higher Cache data block
		.addr_in_request_i(addr_in_request_icache),		// Higher Cache data address
		.request_valid_i(request_valid_icache),				// Higher Cache signal for valid data block
	
		// Self Block Request
		.addr_out_request_o(addr_out_request_icache),	// Address of block of data requested to Higher cache
		.request_o(request_icache)					// Signal to higher cache of a block request
	);
	
//----------------------------------------------------------------------------------------------
	
	// DCache
	DCache #(.INDEX(4), .BLOCK_BITS(512)) DCACHE(
		.clk_i(clk_i),
		.rst_n_i(rst_n_i),
	
		// Lower to self
		.addr_in_pipeline_i(addr_in_pipeline_dcache_i), 		// Address request from CPU
		.data_in_pipeline_i(data_in_pipeline_dcache_i),		// Data from CPU
		.pipeline_wr_valid_i(pipeline_wr_valid_dcache_i),				// CPU Signal for a write to cache
		.pipeline_valid_i(pipeline_valid_dcache_i), 				// CPU Signal of a real request
		.data_out_pipeline_o(data_out_pipeline_dcache_o),// Data out of CPU
		.pipeline_valid_o(pipeline_valid_dcache_o),				// Signal for a valid output of data to CPU
	
		// Higher Cache Block input
		.data_in_request_i(data_in_request_dcache),		// Higher Cache data block
		.addr_in_request_i(addr_in_request_dcache),		// Higher Cache data address
		.request_valid_i(request_valid_dcache),				// Higher Cache signal for valid data block
	
		// Self Block Request
		.addr_out_request_o(addr_out_request_dcache),	// Address of block of data requested to Higher cache
		.request_o(request_dcache),					// Signal to higher cache of a block request
	
		// Self Evict Request
		.evict_i(evict_dcache_in), 								// Higher Cache response to evict request
		.data_out_evict_o(data_out_evict_dcache),		// Block of data to be written to higher cache
		.addr_out_evict_o(/* DC */),		// Address of block of data to be written to higher cache
		.evict_o(evict_dcache_out)						// Signal that an evict is occuring
	);
	
//----------------------------------------------------------------------------------------------
	
	// MMCache
	MMCache #(.INDEX(16), .BLOCK_BITS(512)) MMCACHE(
		.clk_i(clk_i),
		.rst_n_i(rst_n_i),
	
		// Lower to self, ICache
		.addr_in_icache_i(addr_out_request_icache), 					// Address request from ICache
		.ichache_request_i(request_icache),						// CPU Signal for a write to cache
		.data_out_icache_request_o(data_in_request_icache),	// Data out of CPU
		.addr_out_icache_request_o(addr_in_request_icache),
		.icache_request_valid_o(request_valid_icache),			// Signal for a valid output of data to CPU
	
		// Lower to self, DCache
		.addr_in_dcache_i(addr_out_request_dcache), 					// Address request from ICache
		.data_in_dcache_i(data_out_evict_dcache),					// Data from icache
		.dchache_request_i(request_dcache),						// CPU Signal for a write to cache
		.dcache_evict_i(evict_dcache_out), 							// CPU Signal of a real request
		.addr_out_dcache_request_o(addr_in_request_dcache),
		.data_out_dcache_request_o(data_in_request_dcache),	// Data out of CPU
		.dcache_request_valid_o(request_valid_dcache),			// Signal for a valid output of data to CPU
		.dcache_evict_o(evict_dcache_in),
	
		// Higher Cache Block input
		.data_in_request_i(data_in_request_DMA_i),		// Higher Cache data block
		.addr_in_request_i(addr_in_request_DMA_i),		// Higher Cache data address
		.request_valid_i(request_valid_DMA_i),				// Higher Cache signal for valid data block
	
		// Self Block Request
		.addr_out_request_o(addr_out_request_DMA_o),	// Address of block of data requested to Higher cache
		.request_o(request_DMA_o),					// Signal to higher cache of a block request
	
		// Self Evict Request
		.evict_i(evict_DMA_i), 								// Higher Cache response to evict request
		.data_out_evict_o(data_out_evict_DMA_o),		// Block of data to be written to higher cache
		.addr_out_evict_o(addr_out_evict_DMA_o),		// Address of block of data to be written to higher cache
		.evict_o(evict_DMA_o)						// Signal that an evict is occuring					// Signal that an evict is occuring
	);
	
//----------------------------------------------------------------------------------------------

endmodule