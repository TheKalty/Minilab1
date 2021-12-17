task dcache_read;
	input [31:0] addr;

	begin
		integer i;
		reg [31:0] goldenMem;
		reg [511:0] DMA_request;
		reg [31:0] DMA_request_packed[15:0];
		reg hit;
		reg inMM;
		
		//$display("D Read Start");
		
		goldenMem = 0;
		for (i = 0; i < 4; i++) begin
			goldenMem |= Mem[{16'h0000, addr[15:2], 2'h0}+i] << (8*i);
		end
		
		DMA_request = 0;
		for (i = 0; i < 16*4; i++) begin
			DMA_request |= Mem[{16'h0000, addr[15:6], 6'h00}+i] << (8*i);
		end
		for (i = 0; i < 16; i++) begin
			DMA_request_packed[i] = DMA_request[i*32+:32];
		end
		
		// Check if requires DMA response
		hit = 0;
		inMM = 0;
		if (DUT.DCACHE.block_address[addr[7:6]] == {16'h0000, addr[15:8]} && DUT.DCACHE.valid_block[addr[7:6]]) begin
			hit = 1;
		end
		if (DUT.MMCACHE.block_address[addr[9:6]] == {16'h0000, addr[15:10]} && DUT.MMCACHE.valid_block[addr[9:6]]) begin
			hit = 1;
			inMM = 1;
		end
	
		// DCache read request
		@(negedge clk) begin
			addr_in_pipeline_dcache_i = {16'h0000, addr[15:0]};
			data_in_pipeline_dcache_i = 0;
			pipeline_wr_valid_dcache_i = 0;
			pipeline_valid_dcache_i = 1;
		end
		
		if (~hit) begin
			//$display("Miss");
		
			// Long wait
			repeat(50) @(posedge clk);
		
			// DMA response
			@(negedge clk) begin
				data_in_request_DMA_i = DMA_request;
				addr_in_request_DMA_i = {16'h0000, addr[15:6], 6'h00};
				request_valid_DMA_i = 1;
				evict_DMA_i = 0;
			end
			
			@(posedge pipeline_valid_dcache_o) begin
				// Check for correct read
				if (data_out_pipeline_dcache_o != goldenMem) begin
					$display("Error pipeline; Got: %d     Exp: %d", data_out_pipeline_dcache_o, goldenMem);
					$stop();
				end
			end
		end
		else begin
			$display("Hit");
			@(posedge pipeline_valid_dcache_o);
		end
		
		@(negedge clk) begin
			data_in_request_DMA_i = 0;
			addr_in_request_DMA_i = 0;
			request_valid_DMA_i = 0;
			evict_DMA_i = 0;
		
			// DCache Cache Check
			if (DUT.DCACHE.cache_line[addr[7:6]][addr[5:2]] != goldenMem) begin
				$display("Error 1");
				$stop();
			end
			if (DUT.DCACHE.block_address[addr[7:6]] != {16'h0000, addr[15:8]}) begin
				$display("Error 2");
				$stop();
			end
			
			if (inMM) begin
				// MMCache Cache Check
				if (DUT.MMCACHE.cache_line[addr[9:6]][addr[5:2]] != goldenMem) begin
					$display("Error 3");
					$stop();
				end
				if (DUT.MMCACHE.block_address[addr[9:6]] != {16'h0000, addr[15:10]}) begin
					$display("Error 4");
					$stop();
				end
			end
			
			if (inMM) begin
				// Check DCache Cache full Block
				for (i = 0; i < 16; i++) begin
					if (DUT.MMCACHE.cache_line[addr[9:6]][i] != DMA_request_packed[i]) begin
						$display("Error 5");
						$stop();
					end
				end
			end
			
			// Check MMCache Cache full Block
			for (i = 0; i < 16; i++) begin
				if (DUT.DCACHE.cache_line[addr[7:6]][i] != DMA_request_packed[i]) begin
					$display("Error 6");
					$stop();
				end
			end
		
			// Clean up
			addr_in_pipeline_dcache_i = 0;
			data_in_pipeline_dcache_i = 0;
			pipeline_wr_valid_dcache_i = 0;
			pipeline_valid_dcache_i = 0;
		end
		
		
		//$display("D Read End");
	end

endtask

//-----------------------------------------------------------------------------------------------

task dcache_write;
		input [31:0] addr;
		input [31:0] write_data;

	begin
		integer i;
		reg [511:0] DMA_request;
		reg [31:0] DMA_request_packed[15:0];
		reg resp;
		
		//$display("D Write Start");
		
		// Init Mem Block of interest
		DMA_request = 0;
		for (i = 0; i < 16*4; i++) begin
			DMA_request |= Mem[{16'h0000, addr[15:6], 6'h00}+i] << (8*i);
		end
		for (i = 0; i < 16; i++) begin
			DMA_request_packed[i] = DMA_request[i*32+:32];
		end
		
		// Check if requires MM Cache require DMA response
		resp = 0;
		if (DUT.DCACHE.block_address[addr[7:6]] != {16'h0000, addr[15:8]} || ~DUT.DCACHE.valid_block[addr[7:6]]) begin
			resp = 1;
		end
		if (DUT.MMCACHE.block_address[addr[9:6]] != {16'h0000, addr[15:10]} || ~DUT.MMCACHE.valid_block[addr[9:6]]) begin
			resp = 1;
		end
	
		// DCache write request
		@(negedge clk) begin
			addr_in_pipeline_dcache_i = {16'h0000, addr[15:0]};
			data_in_pipeline_dcache_i = write_data;
			pipeline_wr_valid_dcache_i = 1;
			pipeline_valid_dcache_i = 1;
		end
		
		// REQEUSTWRITE
		if (resp) begin
			//$display("Miss");
		
			// Long wait
			repeat(50) @(posedge clk);
		
			// DMA response
			@(negedge clk) begin
				data_in_request_DMA_i = DMA_request;
				addr_in_request_DMA_i = {16'h0000, addr[15:6], 6'h00};
				request_valid_DMA_i = 1;
				evict_DMA_i = 0;
			end
			@(negedge clk) begin
				data_in_request_DMA_i = 0;
				addr_in_request_DMA_i = 0;
				request_valid_DMA_i = 0;
				evict_DMA_i = 0;
			end
		end
		else begin
			$display("Hit");
		end
		
		// WriteHIGHER
		repeat(50) @(posedge clk);
		
		// DMA response to write
		@(negedge clk) begin
			// Do the write in DMA
			for (i = 0; i < 16*4; i++) begin
				Mem[addr_out_evict_DMA_o[15:0]+i] = data_out_evict_DMA_o[i*8+:8];
			end
			
			// Reinit Goldens
			DMA_request = 0;
			for (i = 0; i < 16*4; i++) begin
				DMA_request |= Mem[addr_out_evict_DMA_o[15:0]+i] << (8*i);
			end
			for (i = 0; i < 16; i++) begin
				DMA_request_packed[i] = DMA_request[i*32+:32];
			end
			
			evict_DMA_i = 1;
		end
		
		
		@(negedge clk) begin
			// Check If valid is out
			if (pipeline_valid_dcache_o != 1) begin
				$display("Error valid");
				$stop();
			end
		
			data_in_request_DMA_i = 0;
			addr_in_request_DMA_i = 0;
			request_valid_DMA_i = 0;
			evict_DMA_i = 0;
			
			// DCache Cache Check
			if (DUT.DCACHE.block_address[addr[7:6]] != {16'h0000, addr[15:8]}) begin
				$display("Error dcache block addr");
				$stop();
			end
			
			// MMCache Cache Check
			if (DUT.MMCACHE.block_address[addr[9:6]] != {16'h0000, addr[15:10]}) begin
				$display("Error mmcache block addr");
				$stop();
			end
			
			// Check DCache Cache full Block
			for (i = 0; i < 16; i++) begin
				if (DUT.DCACHE.cache_line[addr[7:6]][i] != DMA_request_packed[i]) begin
					$display("Error dcache block data");
					$stop();
				end
			end
			
			// Check MMCache Cache full Block
			for (i = 0; i < 16; i++) begin
				if (DUT.MMCACHE.cache_line[addr[9:6]][i] != DMA_request_packed[i]) begin
					$display("Error mmcache block data; Got: %d     Exp: %d", DUT.MMCACHE.cache_line[addr[9:6]][i], DMA_request_packed[i]);
					$stop();
				end
			end
		
			// Clean up
			addr_in_pipeline_dcache_i = 0;
			data_in_pipeline_dcache_i = 0;
			pipeline_wr_valid_dcache_i = 0;
			pipeline_valid_dcache_i = 0;
		end
		
		//$display("D Write End");
	end

endtask

//-----------------------------------------------------------------------------------------------

task icache_read;
	input [31:0] addr;

	begin
		integer i;
		reg [31:0] goldenMem;
		reg [511:0] DMA_request;
		reg [31:0] DMA_request_packed[15:0];
		reg hit;
		reg inMM;
		
		//$display("I Read Start");
		
		goldenMem = 0;
		for (i = 0; i < 4; i++) begin
			goldenMem |= Mem[{16'h0000, addr[15:2], 2'h0}+i] << (8*i);
		end
		
		DMA_request = 0;
		for (i = 0; i < 16*4; i++) begin
			DMA_request |= Mem[{16'h0000, addr[15:6], 6'h00}+i] << (8*i);
		end
		for (i = 0; i < 16; i++) begin
			DMA_request_packed[i] = DMA_request[i*32+:32];
		end
		
		// Check if requires DMA response
		hit = 0;
		inMM =0;
		if (DUT.ICACHE.block_address[addr[6]] == {16'h0000, addr[15:7]} && DUT.ICACHE.valid_block[addr[6]]) begin
			hit = 1;
		end
		if (DUT.MMCACHE.block_address[addr[9:6]] == {16'h0000, addr[15:10]} && DUT.MMCACHE.valid_block[addr[9:6]]) begin
			hit = 1;
			inMM = 1;
		end
	
		// DCache read request
		@(negedge clk) begin
			addr_in_pipeline_icache_i = {16'h0000, addr[15:0]};
			pipeline_valid_icache_i = 1;
		end
		
		if (~hit) begin
			//$display("Miss");
		
			// Long wait
			repeat(50) @(posedge clk);
		
			// DMA response
			@(negedge clk) begin
				data_in_request_DMA_i = DMA_request;
				addr_in_request_DMA_i = {16'h0000, addr[15:6], 6'h00};
				request_valid_DMA_i = 1;
				evict_DMA_i = 0;
			end
			@(negedge clk) begin
				data_in_request_DMA_i = 0;
				addr_in_request_DMA_i = 0;
				request_valid_DMA_i = 0;
				evict_DMA_i = 0;
			end
		end
		else begin
			$display("Hit");
		end
		
		// Test signals
		@(posedge pipeline_valid_icache_o) begin
			// Check for correct read
			if (data_out_pipeline_icache_o != goldenMem) begin
				$display("Error data report");
				$stop();
			end
		end
		@(negedge clk) begin
			// ICache Cache Check
			if (DUT.ICACHE.cache_line[addr[6]][addr[5:2]] != goldenMem) begin
				$display("Error icache block data");
				$stop();
			end
			if (DUT.ICACHE.block_address[addr[6]] != {16'h0000, addr[15:7]}) begin
				$display("Error icache block addr");
				$stop();
			end
			
			if (inMM) begin
				// MMCache Cache Check
				if (DUT.MMCACHE.cache_line[addr[9:6]][addr[5:2]] != goldenMem) begin
					$display("Error mmcache block data");
					$stop();
				end
				if (DUT.MMCACHE.block_address[addr[9:6]] != {16'h0000, addr[15:10]}) begin
					$display("Error mmcache block addr");
					$stop();
				end
			end
			
			// Check ICache Cache full Block
			for (i = 0; i < 16; i++) begin
				if (DUT.ICACHE.cache_line[addr[6]][i] != DMA_request_packed[i]) begin
					$display("Error icache block full");
					$stop();
				end
			end
			
			if (inMM) begin
				// Check MMCache Cache full Block
				for (i = 0; i < 16; i++) begin
					if (DUT.MMCACHE.cache_line[addr[9:6]][i] != DMA_request_packed[i]) begin
						$display("Error mmcache block full");
						$stop();
					end
				end
			end
		
			// Clean up
			addr_in_pipeline_icache_i = 0;
			pipeline_valid_icache_i = 0;
		end
		
		
		//$display("I Read End");
	end

endtask


//-----------------------------------------------------------------------------------------------

