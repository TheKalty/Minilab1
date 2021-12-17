module ICache_tb();

    localparam WORD_BITS = 32;
	localparam INDEX = 2;

    // Stims
    reg clk, rst_n;
	reg [31:0] addr_in_pipeline_i; 
	//reg [31:0] data_in_pipeline_i;
	//reg pipeline_wr_valid_i;
	reg pipeline_valid_i;
	reg [511:0] data_in_request_i;
	reg [31:0] addr_in_request_i;
	reg request_valid_i;
	//reg evict_i;
    
    // Monitor
    wire [31:0] data_out_pipeline_o;
	wire pipeline_valid_o;
	wire [31:0]addr_out_request_o;
	wire request_o;
	//wire [511:0]data_out_evict_o;
	//wire [31:0]addr_out_evict_o;
	//wire evict_o;
	
	// Tasks
	`include "ICache_tb_task.svh"

    // Instance of DUT
	ICache #(.INDEX(INDEX), .BLOCK_BITS(512)) DUT(
		.clk_i(clk),
		.rst_n_i(rst_n),
	
		// Lower to self
		.addr_in_pipeline_i(addr_in_pipeline_i), 		// Address request from CPU
		//.data_in_pipeline_i(data_in_pipeline_i),		// Data from CPU
		//.pipeline_wr_valid_i(pipeline_wr_valid_i),				// CPU Signal for a write to cache
		.pipeline_valid_i(pipeline_valid_i), 				// CPU Signal of a real request
		.data_out_pipeline_o(data_out_pipeline_o),// Data out of CPU
		.pipeline_valid_o(pipeline_valid_o),				// Signal for a valid output of data to CPU
	
		// Higher Cache Block input
		.data_in_request_i(data_in_request_i),		// Higher Cache data block
		.addr_in_request_i(addr_in_request_i),		// Higher Cache data address
		.request_valid_i(request_valid_i),				// Higher Cache signal for valid data block
	
		// Self Block Request
		.addr_out_request_o(addr_out_request_o),	// Address of block of data requested to Higher cache
		.request_o(request_o)					// Signal to higher cache of a block request
	
		// Self Evict Request
		//.evict_i(evict_i), 								// Higher Cache response to evict request
		//.data_out_evict_o(data_out_evict_o),		// Block of data to be written to higher cache
		//.addr_out_evict_o(addr_out_evict_o),		// Address of block of data to be written to higher cache
		//.evict_o(evict_o)						// Signal that an evict is occuring
	);
    
//------------------------------------------------------------------------------------------------------------------------------------

    integer i, j, error;
	reg rw;
    initial begin
		// Init
		clk = 1;
		rst_n = 1;
		addr_in_pipeline_i = 0;
		//data_in_pipeline_i = 0;
		//pipeline_wr_valid_i = 0;
		pipeline_valid_i = 0;
		data_in_request_i = 0;
		addr_in_request_i = 0;
		request_valid_i = 0;
		//evict_i = 0;
		
		// Start
		@(posedge clk);
		@(negedge clk) begin
			rst_n = 0;
		end
		@(negedge clk) begin
			rst_n = 1;
		end
		
		for (i = 0; i < 2**10; i++) begin
			read_test();
		end
		
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


