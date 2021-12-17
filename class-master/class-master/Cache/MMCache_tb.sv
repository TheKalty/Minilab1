module MMCache_tb();

    localparam WORD_BITS = 32;
	localparam INDEX = 16;
	localparam BLOCK_BITS = 512;

    // Stims
    reg clk, rst_n;
	
	reg [31:0] addr_in_icache_i;
	reg ichache_request_i;
	
	reg [31:0] addr_in_dcache_i; 					// Address request from ICache
	reg [BLOCK_BITS-1:0] data_in_dcache_i;					// Data from icache
	reg dchache_request_i;						// CPU Signal for a write to cache
	reg dcache_evict_i; 							// CPU Signal of a real request
	
	reg [BLOCK_BITS-1:0] data_in_request_i;		// Higher Cache data block
	reg [31:0] addr_in_request_i;		// Higher Cache data address
	reg request_valid_i;				// Higher Cache signal for valid data block
	
	reg evict_i; 								// Higher Cache response to evict request
	
	// Monitor
	wire [BLOCK_BITS-1:0] data_out_icache_request_o;
	wire [31:0] addr_out_icache_request_o;
	wire icache_request_valid_o;
	
	wire [31:0] addr_out_dcache_request_o;
	wire [BLOCK_BITS-1:0] data_out_dcache_request_o;	// Data out of CPU
	wire dcache_request_valid_o;			// Signal for a valid output of data to CPU
	wire dcache_evict_o;
	
	wire [31:0] addr_out_request_o;	// Address of block of data requested to Higher cache
	wire request_o;					// Signal to higher cache of a block request
	
	wire [BLOCK_BITS-1:0] data_out_evict_o;		// Block of data to be written to higher cache
	wire [31:0] addr_out_evict_o;		// Address of block of data to be written to higher cache
	wire evict_o;						// Signal that an evict is occuring
    
    // Monitor
	
	// Tasks
	`include "MMCache_tb_task.svh"

    // Instance of DUT
	MMCache #(.INDEX(16), .BLOCK_BITS(512)) DUT(
	.clk_i(clk),
	.rst_n_i(rst_n),
	
	// Lower to self, ICache
	.addr_in_icache_i(addr_in_icache_i), 					// Address request from ICache
	.ichache_request_i(ichache_request_i),						// CPU Signal for a write to cache
	.data_out_icache_request_o(data_out_icache_request_o),	// Data out of CPU
	.addr_out_icache_request_o(addr_out_icache_request_o),
	.icache_request_valid_o(icache_request_valid_o),			// Signal for a valid output of data to CPU
	
	// Lower to self, DCache
	.addr_in_dcache_i(addr_in_dcache_i), 					// Address request from ICache
	.data_in_dcache_i(data_in_dcache_i),					// Data from icache
	.dchache_request_i(dchache_request_i),						// CPU Signal for a write to cache
	.dcache_evict_i(dcache_evict_i), 							// CPU Signal of a real request
	.addr_out_dcache_request_o(addr_out_dcache_request_o),
	.data_out_dcache_request_o(data_out_dcache_request_o),	// Data out of CPU
	.dcache_request_valid_o(dcache_request_valid_o),			// Signal for a valid output of data to CPU
	.dcache_evict_o(dcache_evict_o),
	
	// Higher Cache Block input
	.data_in_request_i(data_in_request_i),		// Higher Cache data block
	.addr_in_request_i(addr_in_request_i),		// Higher Cache data address
	.request_valid_i(request_valid_i),				// Higher Cache signal for valid data block
	
	// Self Block Request
	.addr_out_request_o(addr_out_request_o),	// Address of block of data requested to Higher cache
	.request_o(request_o),					// Signal to higher cache of a block request
	
	// Self Evict Request
	.evict_i(evict_i), 								// Higher Cache response to evict request
	.data_out_evict_o(data_out_evict_o),		// Block of data to be written to higher cache
	.addr_out_evict_o(addr_out_evict_o),		// Address of block of data to be written to higher cache
	.evict_o(evict_o)						// Signal that an evict is occuring
	);
    
//------------------------------------------------------------------------------------------------------------------------------------

    integer i, j, error;
	reg rw;
    initial begin
		// Init
		clk = 1;
		rst_n = 1;
		
		addr_in_icache_i = 0;
		ichache_request_i = 0;
	
		addr_in_dcache_i = 0;
		data_in_dcache_i = 0;
		dchache_request_i = 0;
		dcache_evict_i = 0;
	
		data_in_request_i = 0;
		addr_in_request_i = 0;
		request_valid_i = 0;
	
		evict_i = 0;
		
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

		both_rand_test();

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


