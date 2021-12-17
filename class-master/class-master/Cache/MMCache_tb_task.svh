task icache_read_miss;
	input [31:0] rand_addr;
	input [511:0] rand_data;

	begin
		reg [31:0] rand_data_packed[15:0];
		
		integer i;
		
		for (i = 0; i < 16; i++) begin
			rand_data_packed[i] = rand_data[i*32+:32];
		end
	
		// ICache Request
		@(negedge clk) begin
			addr_in_icache_i = rand_addr;
			ichache_request_i = 1;
		end
	
		// Long Wait
		repeat(10) @(posedge clk);
	
		// Test Signals
		@(posedge clk) begin
			if (addr_out_request_o != {rand_addr[31:6], 6'h00}) begin
				$display("Error addr");
			end
		
			if (request_o != 1) begin
				$display("Error DMA Request");
			end
		end
	
		// Long Wait
		repeat(50) @(posedge clk);
	
		// DMA Response
		@(negedge clk) begin
			data_in_request_i = rand_data;
			addr_in_request_i = {rand_addr[31:6], 6'h00};
			request_valid_i = 1;
		end
	
		@(negedge clk) begin
			if (request_o != 0) begin
				$display("Error DMA Request");
			end
		
			// Check in cache_line
			for (i = 0; i < 16; i++) begin
				if (DUT.cache_line[rand_addr[9:6]][i] != rand_data_packed[i]) begin
					$display("Error DMA Block data, Index: %d    DUT: %d      EXP: %d", rand_addr[9:6], DUT.cache_line[rand_addr[9:6]][i], rand_data_packed[i]);
				end
			end
		
			// Check to ICache response
			if (data_out_icache_request_o != rand_data) begin
				$display("Error ICACHE Block data");
			end
		
			if (addr_out_icache_request_o != {rand_addr[31:6], 6'h00}) begin
				$display("Error ICACHE Block addr");
			end
		
			if (icache_request_valid_o != 1) begin
				$display("Error ICACHE valid");
			end
	
			data_in_request_i = 0;
			addr_in_request_i = 0;
			request_valid_i = 0;
		
			// ICache Response
			ichache_request_i = 0;
		end

	end
	
endtask

//----------------------------------------------------------------------------

task icache_read_hit;
	input [31:0] rand_addr;

	begin
		reg [31:0] rand_data_packed[15:0];
		reg [511:0] rand_data;
		
		integer i;
		rand_data = 0;
		for (i = 0; i < 16; i++) begin
			rand_data |= DUT.cache_line[rand_addr[9:6]][i] << (32*i);
		end
		for (i = 0; i < 16; i++) begin
			rand_data_packed[i] = rand_data[i*32+:32];
		end
	
		// ICache Request
		@(negedge clk) begin
			addr_in_icache_i = rand_addr;
			ichache_request_i = 1;
		end
	
		// Report
		@(posedge icache_request_valid_o) begin
			// Check in cache_line
			for (i = 0; i < 16; i++) begin
				if (DUT.cache_line[rand_addr[9:6]][i] != rand_data_packed[i]) begin
					$display("Error DMA Block data, Index: %d    DUT: %d      EXP: %d", rand_addr[9:6], DUT.cache_line[rand_addr[9:6]][i], rand_data_packed[i]);
				end
			end
		
			// Check to ICache response
			if (data_out_icache_request_o != rand_data) begin
				$display("Error ICACHE Block data");
			end
		
			if (addr_out_icache_request_o != {rand_addr[31:6], 6'h00}) begin
				$display("Error ICACHE Block addr");
			end
		
			if (icache_request_valid_o != 1) begin
				$display("Error ICACHE valid");
			end
		end
		
		@(negedge clk) begin
			// ICache Response
			ichache_request_i = 0;
		end

	end
	
endtask

//----------------------------------------------------------------------------

task rand_icache_read;

	begin
		reg [31:0] rand_addr;
		reg [31:0] rand_data_packed[15:0];
		reg [511:0] rand_data;
		
		reg hit;
		
		integer i, j;
	
		hit = 0;
		// ICache Read Miss
		rand_addr = $random();
		rand_data = 0;
		for (i = 0; i < 16; i++) begin
			rand_data_packed[i] = $random();
			
			rand_data |= rand_data_packed[i] << (i*32);
		end
	
		// Check if Hit
		for (i = 0; i < INDEX; i++) begin
			if (DUT.block_address[i] == rand_addr[31:$clog2(INDEX)+6]) begin
				hit = 1;
			end
		end
		
		// read
		if (hit) begin
			$display("HIT");
			icache_read_hit(rand_addr);
		end
		else begin
			icache_read_miss(rand_addr, rand_data);
			
			// recall to do a hit
			icache_read_hit(rand_addr);
		end
	
	end

endtask

//----------------------------------------------------------------------------

task dcache_read_miss;
	input [31:0] rand_addr;
	input [511:0] rand_data;

	begin
		reg [31:0] rand_data_packed[15:0];
		integer i;
		
		for (i = 0; i < 16; i++) begin
			rand_data_packed[i] = rand_data[i*32+:32];
		end
	
		// DCache Request
		@(negedge clk) begin
			addr_in_dcache_i = rand_addr;
			dchache_request_i = 1;
		end
	
		// Long Wait
		repeat(10) @(posedge clk);
	
		// Test Signals
		@(posedge clk) begin
			if (addr_out_request_o != {rand_addr[31:6], 6'h00}) begin
				$display("Error addr");
			end
		
			if (request_o != 1) begin
				$display("Error DMA Request");
			end
		end
	
		// Long Wait
		repeat(50) @(posedge clk);
	
		// DMA Response
		@(negedge clk) begin
			data_in_request_i = rand_data;
			addr_in_request_i = {rand_addr[31:6], 6'h00};
			request_valid_i = 1;
		end
	
		@(negedge clk) begin
			if (request_o != 0) begin
				$display("Error DMA Request");
			end
		
			// Check in cache_line
			for (i = 0; i < 16; i++) begin
				if (DUT.cache_line[rand_addr[9:6]][i] != rand_data_packed[i]) begin
					$display("Error DMA Block data, Index: %d    DUT: %d      EXP: %d", rand_addr[9:6], DUT.cache_line[rand_addr[9:6]][i], rand_data_packed[i]);
				end
			end
		
			// Check to ICache response
			if (data_out_dcache_request_o != rand_data) begin
				$display("Error DCACHE Block data");
			end
		
			if (addr_out_dcache_request_o != {rand_addr[31:6], 6'h00}) begin
				$display("Error DCACHE Block addr");
			end
		
			if (dcache_request_valid_o != 1) begin
				$display("Error DCACHE valid");
			end
	
			data_in_request_i = 0;
			addr_in_request_i = 0;
			request_valid_i = 0;
		
			// ICache Response
			dchache_request_i = 0;
		end

	end
	
endtask

//----------------------------------------------------------------------------

task dcache_read_hit;
	input [31:0] rand_addr;

	begin
		reg [31:0] rand_data_packed[15:0];
		reg [511:0] rand_data;
		
		integer i;
		rand_data = 0;
		for (i = 0; i < 16; i++) begin
			rand_data |= DUT.cache_line[rand_addr[9:6]][i] << (32*i);
		end
		for (i = 0; i < 16; i++) begin
			rand_data_packed[i] = rand_data[i*32+:32];
		end
	
		// DCache Request
		@(negedge clk) begin
			addr_in_dcache_i = rand_addr;
			dchache_request_i = 1;
		end
	
		// Report
		@(posedge dcache_request_valid_o) begin
			// Check in cache_line
			for (i = 0; i < 16; i++) begin
				if (DUT.cache_line[rand_addr[9:6]][i] != rand_data_packed[i]) begin
					$display("Error DMA Block data, Index: %d    DUT: %d      EXP: %d", rand_addr[9:6], DUT.cache_line[rand_addr[9:6]][i], rand_data_packed[i]);
				end
			end
		
			// Check to ICache response
			if (data_out_dcache_request_o != rand_data) begin
				$display("Error DCACHE Block data");
			end
		
			if (addr_out_dcache_request_o != {rand_addr[31:6], 6'h00}) begin
				$display("Error DCACHE Block addr");
			end
		
			if (dcache_request_valid_o != 1) begin
				$display("Error DCACHE valid");
			end
		end
		
		@(negedge clk) begin
			// ICache Response
			dchache_request_i = 0;
		end

	end
	
endtask

//----------------------------------------------------------------------------

task rand_dcache_read;

	begin
		reg [31:0] rand_addr;
		reg [31:0] rand_data_packed[15:0];
		reg [511:0] rand_data;
		
		reg hit;
		
		integer i, j;
	
		hit = 0;
		// ICache Read Miss
		rand_addr = $random();
		rand_data = 0;
		for (i = 0; i < 16; i++) begin
			rand_data_packed[i] = $random();
			
			rand_data |= rand_data_packed[i] << (i*32);
		end
	
		// Check if Hit
		for (i = 0; i < INDEX; i++) begin
			if (DUT.block_address[i] == rand_addr[31:$clog2(INDEX)+6]) begin
				hit = 1;
			end
		end
		
		// read
		if (hit) begin
			$display("HIT");
			dcache_read_hit(rand_addr);
		end
		else begin
			dcache_read_miss(rand_addr, rand_data);
			
			// recall to do a hit
			dcache_read_hit(rand_addr);
		end
	
	end

endtask

//----------------------------------------------------------------------------

task dcache_write_miss;
	input [31:0] rand_addr;
	input [511:0] rand_data_lower;
	input [511:0] rand_data_higher;
	
	begin
		integer i;
		reg [31:0] rand_data_lower_packed[15:0];
		reg [31:0] rand_data_higher_packed[15:0];
		
		for (i = 0; i < 16; i++) begin
			rand_data_lower_packed[i] = rand_data_lower[32*i+:32];
			rand_data_higher_packed[i] = rand_data_higher[32*i+:32];
		end
	
	
		// DCache request
		@(negedge clk) begin
			addr_in_dcache_i = rand_addr;
			data_in_dcache_i = rand_data_lower;
			dcache_evict_i = 1;
		end
		
		// Long Wait
		repeat(10) @(posedge clk);
	
		// Test Signals
		@(posedge clk) begin
			if (addr_out_request_o != {rand_addr[31:6], 6'h00}) begin
				$display("Error addr");
			end
		
			if (request_o != 1) begin
				$display("Error DMA Request");
			end
		end
		
		// Long wait
		repeat(50) @(posedge clk);
		
		// Write Self from request
		// DMA Response, request block
		@(negedge clk) begin
			request_valid_i = 1;
			data_in_request_i = rand_data_higher;
			addr_in_request_i = {rand_addr[31:6], 6'h00};
		end
		@(negedge clk) begin
			request_valid_i = 0;
		
			if (request_o != 0) begin
				$display("Error DMA Request");
			end
		
			// Check in cache_line in Self
			for (i = 0; i < 16; i++) begin
				if (DUT.cache_line[rand_addr[9:6]][i] != rand_data_higher_packed[i]) begin
					$display("Error DMA Block data, Index: %d    DUT: %d      EXP: %d", rand_addr[9:6], DUT.cache_line[rand_addr[9:6]][i], rand_data_higher_packed[i]);
				end
			end
			
			// Check Block
			if (DUT.block_address[rand_addr[9:6]] != rand_addr[31:$clog2(INDEX)+6]) begin
				$display("Error DMA addr block");
			end
		end
		
		
		// Long wait
		repeat(50) @(posedge clk);
		
		// Write Self Check
		@(negedge clk) begin
			if (request_o != 0) begin
				$display("Error DMA Request");
			end
		
			// Check in cache_line in Self
			for (i = 0; i < 16; i++) begin
				if (DUT.cache_line[rand_addr[9:6]][i] != rand_data_lower_packed[i]) begin
					$display("Error DMA Block data, Index: %d    DUT: %d      EXP: %d", rand_addr[9:6], DUT.cache_line[rand_addr[9:6]][i], rand_data_higher_packed[i]);
				end
			end
			
			// Check Block
			if (DUT.block_address[rand_addr[9:6]] != rand_addr[31:$clog2(INDEX)+6]) begin
				$display("Error DMA addr block");
			end
		end
		
		// Signal test
		@(negedge clk) begin
			// Signal
			if (evict_o != 1) begin
				$display("Error DMA Evict");
			end
			
			// Addr
			if (addr_out_evict_o != {rand_addr[31:6], 6'h00}) begin
				$display("Error DMA Evict addr got: %d     exp: %d", addr_out_evict_o, rand_addr[31:$clog2(INDEX)+6]);
				$stop();
			end
			
			// data
			if (data_out_evict_o != rand_data_lower) begin
				$display("Error DMA Evict data");
			end
			
			
		end
		
		// DMA Response, write block 
		@(negedge clk) begin
			evict_i = 1;
		end
		@(posedge clk) begin
			evict_i = 0;
		end
		@(negedge clk) begin
			addr_in_dcache_i = 0;
			data_in_dcache_i = 0;
			dcache_evict_i = 0;
		end
		
	end
endtask


//----------------------------------------------------------------------------

task dcache_write_hit;
	input [31:0] rand_addr;
	input [511:0] rand_data_lower;
	
	begin
		integer i;
		reg [31:0] rand_data_lower_packed[15:0];
		
		for (i = 0; i < 16; i++) begin
			rand_data_lower_packed[i] = rand_data_lower[32*i+:32];
		end
	
	
		// DCache request
		@(negedge clk) begin
			addr_in_dcache_i = rand_addr;
			data_in_dcache_i = rand_data_lower;
			dcache_evict_i = 1;
		end
		
		// Long Wait
		repeat(10) @(posedge clk);
		
		// Write Self Check
		@(negedge clk) begin
			if (request_o != 0) begin
				$display("Error DMA Request");
			end
		
			// Check in cache_line in Self
			for (i = 0; i < 16; i++) begin
				if (DUT.cache_line[rand_addr[9:6]][i] != rand_data_lower_packed[i]) begin
					$display("Error DMA Block data, Index: %d    DUT: %d      EXP: %d", rand_addr[9:6], DUT.cache_line[rand_addr[9:6]][i], rand_data_lower_packed[i]);
				end
			end
			
			// Check Block
			if (DUT.block_address[rand_addr[9:6]] != rand_addr[31:$clog2(INDEX)+6]) begin
				$display("Error DMA addr block");
			end
		end
		
		// Signal test for in WriteHigher
		@(negedge clk) begin
			// Signal
			if (evict_o != 1) begin
				$display("Error DMA Evict");
			end
			
			// Addr
			if (addr_out_evict_o != {rand_addr[31:6], 6'h00}) begin
				$display("Error DMA Evict addr got: %d     exp: %d", addr_out_evict_o, rand_addr[31:$clog2(INDEX)+6]);
			end
			
			// data
			if (data_out_evict_o != rand_data_lower) begin
				$display("Error DMA Evict data");
			end
			
		end
		
		// DMA Response, write block 
		@(negedge clk) begin
			evict_i = 1;
		end
		@(posedge clk) begin
			evict_i = 0;
		end
		@(negedge clk) begin
			addr_in_dcache_i = 0;
			data_in_dcache_i = 0;
			dcache_evict_i = 0;
		end
		
	end

endtask

//----------------------------------------------------------------------------

task rand_dcache_write;

	begin
		reg [31:0] rand_addr;
		reg [31:0] rand_data_lower_packed[15:0];
		reg [511:0] rand_data_lower;
		reg [31:0] rand_data_higher_packed[15:0];
		reg [511:0] rand_data_higher;
		
		reg hit;
		
		integer i, j;
	
		hit = 0;
		// ICache Read Miss
		rand_addr = $random();
		rand_data_lower = 0;
		rand_data_higher = 0;
		
		for (i = 0; i < 16; i++) begin
			rand_data_lower_packed[i] = $random();
			rand_data_higher_packed[i] = $random();
			
			rand_data_lower |= rand_data_lower_packed[i] << (i*32);
			rand_data_higher |= rand_data_higher_packed[i] << (i*32);
		end
	
		// Check if Hit
		for (i = 0; i < INDEX; i++) begin
			if (DUT.block_address[i] == rand_addr[31:$clog2(INDEX)+6]) begin
				hit = 1;
			end
		end
		
		// read
		if (hit) begin
			dcache_write_hit(rand_addr, rand_data_lower);
		end
		else begin
			dcache_write_miss(rand_addr, rand_data_lower, rand_data_higher);
			
			// recall to do a hit
			dcache_write_hit(rand_addr, rand_data_lower);
		end
	
	end

endtask

//----------------------------------------------------------------------------

task both_rand_test;
	
	begin
		
		integer i;
		
		reg [1:0] r;
		for (i = 0; i < 2**10; i++) begin
			r = $random();
			
			if (r == 0) begin
				rand_dcache_read();
			end
			else if (r == 1) begin
				rand_dcache_write();
			end
			else begin
				rand_icache_read();
			end
		end
	end

endtask

//------------------------------------------------------------------------------

task both_readwrite;
	input [31:0] rand_addr_d;
	input [31:0] rand_addr_i;
	input [511:0] rand_data_lower;
	input [511:0] rand_data_higher;
	
	begin
		integer i;
		reg [31:0] rand_data_lower_packed[15:0];
		reg [31:0] rand_data_higher_packed[15:0];
		
		for (i = 0; i < 16; i++) begin
			rand_data_lower_packed[i] = rand_data_lower[32*i+:32];
			rand_data_higher_packed[i] = rand_data_higher[32*i+:32];
		end
	
	
		// Requests
		@(negedge clk) begin
			// DCache
			addr_in_dcache_i = rand_addr_d;
			data_in_dcache_i = rand_data_lower;
			dcache_evict_i = 1;
			
			// ICache
			addr_in_icache_i = rand_addr_i;
			ichache_request_i = 1;
		end
		
		// Long Wait
		repeat(10) @(posedge clk);
	
		// Test Signals
		@(posedge clk) begin
			if (addr_out_request_o != {rand_addr_d[31:6], 6'h00}) begin
				$display("Error addr");
			end
		
			if (request_o != 1) begin
				$display("Error DMA Request");
			end
		end
		
		// Long wait
		repeat(50) @(posedge clk);
		
		// Write Self from request
		// DMA Response, request block
		@(negedge clk) begin
			request_valid_i = 1;
			data_in_request_i = rand_data_higher;
			addr_in_request_i = {rand_addr_d[31:6], 6'h00};
		end
		@(negedge clk) begin
			request_valid_i = 0;
		
			if (request_o != 0) begin
				$display("Error DMA Request");
			end
		
			// Check in cache_line in Self
			for (i = 0; i < 16; i++) begin
				if (DUT.cache_line[rand_addr_d[9:6]][i] != rand_data_higher_packed[i]) begin
					$display("Error DMA Block data, Index: %d    DUT: %d      EXP: %d", rand_addr_d[9:6], DUT.cache_line[rand_addr_d[9:6]][i], rand_data_higher_packed[i]);
				end
			end
			
			// Check Block
			if (DUT.block_address[rand_addr_d[9:6]] != rand_addr_d[31:$clog2(INDEX)+6]) begin
				$display("Error DMA addr block");
			end
		end
		
		
		// Long wait
		repeat(50) @(posedge clk);
		
		// Write Self Check
		@(negedge clk) begin
			if (request_o != 0) begin
				$display("Error DMA Request");
			end
		
			// Check in cache_line in Self
			for (i = 0; i < 16; i++) begin
				if (DUT.cache_line[rand_addr_d[9:6]][i] != rand_data_lower_packed[i]) begin
					$display("Error DMA Block data, Index: %d    DUT: %d      EXP: %d", rand_addr_d[9:6], DUT.cache_line[rand_addr_d[9:6]][i], rand_data_higher_packed[i]);
				end
			end
			
			// Check Block
			if (DUT.block_address[rand_addr_d[9:6]] != rand_addr_d[31:$clog2(INDEX)+6]) begin
				$display("Error DMA addr block");
			end
		end
		
		// Signal test
		@(negedge clk) begin
			// Signal
			if (evict_o != 1) begin
				$display("Error DMA Evict");
			end
			
			// Addr
			if (addr_out_evict_o != {rand_addr_d[31:6], 6'h00}) begin
				$display("Error DMA Evict addr got: %d     exp: %d", addr_out_evict_o, rand_addr_d[31:$clog2(INDEX)+6]);
				$stop();
			end
			
			// data
			if (data_out_evict_o != rand_data_lower) begin
				$display("Error DMA Evict data");
			end
			
			
		end
		
		// DMA Response, write block 
		@(negedge clk) begin
			evict_i = 1;
		end
		@(posedge clk) begin
			evict_i = 0;
		end
		@(negedge clk) begin
			addr_in_dcache_i = 0;
			data_in_dcache_i = 0;
			dcache_evict_i = 0;
		end
		
	end

endtask