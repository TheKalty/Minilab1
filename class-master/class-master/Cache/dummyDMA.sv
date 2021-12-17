module dummyDMA
	#( 
		parameter BLOCK_BITS = 512
	)
	(
	input clk_i,
	input rst_n_i,
	
	// Outputs to DMA Interface
	input [31:0] addr_out_request_DMA_i,
	input request_DMA_i,
	input [511:0] data_out_evict_DMA_i,
	//input [31:0] addr_out_evict_DMA_i, // redundant
	input evict_DMA_i,
	
	// Inputs from DMA Interface
	output logic [511:0] data_in_request_DMA_o,
	output logic [31:0] addr_in_request_DMA_o,
	output logic request_valid_DMA_o,
	output logic evict_DMA_o
	);
	
//----------------------------------------------------------------------------------------------

	// Mem
	logic [7:0] Mem[(2**16)-1:0];
	logic [7:0] temp[16*4-1:0];
	logic [511:0] tempBlock;
	logic [31:0] dum[15:0];
	integer i, j;
	
	
	logic [31:0] mem_32 [(2**16)-1:0];
	
	// Reset
	initial begin
		// Init Mem
		for (i = 0; i < (2**16); i++) begin
			Mem[i] = 0;
		end
		$readmemh("test_cache.txt", Mem);
		$readmemh("prog.hex", mem_32);
		for (int i = 0; i < 2**10; i++) begin
			Mem[(i*4)] = mem_32[i][31:24];
			Mem[(i*4) + 1] = mem_32[i][23:16];
			Mem[(i*4) + 2] = mem_32[i][15:8];
			Mem[(i*4) + 3] = mem_32[i][7:0];
		
		end
		data_in_request_DMA_o = 0;
		addr_in_request_DMA_o = 0;
		request_valid_DMA_o = 0;
		evict_DMA_o = 0;
	end
	
	// Write to DMA
	always @(posedge evict_DMA_i) begin
		// Write
		for (i = 0; i < 16*4; i++) begin
			temp[i] = Mem[i];
			
			Mem[addr_out_request_DMA_i+i] = data_out_evict_DMA_i[i*8+:8];
			//$display("Addr: %h      data: %d", addr_out_request_DMA_i+i, Mem[addr_out_request_DMA_i+i]);
		end
		
		// Long wait
		repeat(50) @(negedge clk_i);
		
		// Report
		data_in_request_DMA_o = 0;
		addr_in_request_DMA_o = 0;
		request_valid_DMA_o = 0;
		evict_DMA_o = 1;
		
		@(negedge clk_i) begin
			data_in_request_DMA_o = 0;
			addr_in_request_DMA_o = 0;
			request_valid_DMA_o = 0;
			evict_DMA_o = 0;
		end
		
	end
	
	// Read from DMA
	always @(posedge request_DMA_i) begin
		
		// Read
		tempBlock = 0;
		for (i = 0; i < 16*4; i++) begin
			temp[i] = Mem[addr_out_request_DMA_i+i];
		
			tempBlock |= Mem[addr_out_request_DMA_i+i] << (8*i);
			//$display("Addr: %h      data: %d", addr_out_request_DMA_i+i, Mem[addr_out_request_DMA_i+i]);
		end
		
		// dummy
		for (i = 0; i < 16; i++) begin
			dum[i] = tempBlock[i*32+:32];
		end
		
		// Long wait
		repeat(50) @(negedge clk_i);
		
		// Report
		data_in_request_DMA_o = tempBlock;
		addr_in_request_DMA_o = addr_out_request_DMA_i;
		request_valid_DMA_o = 1;
		evict_DMA_o = 0;
		
		@(negedge clk_i) begin
			data_in_request_DMA_o = 0;
			addr_in_request_DMA_o = 0;
			request_valid_DMA_o = 0;
			evict_DMA_o = 0;
		end
	end


endmodule