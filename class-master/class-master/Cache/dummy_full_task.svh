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
		
		// What CPU should see
		goldenMem = 0;
		for (i = 0; i < 4; i++) begin
			goldenMem |= DMA.Mem[{16'h0000, addr[15:2], 2'h0}+i] << (8*i);
		end
		
		// What the Block should be
		DMA_request = 0;
		for (i = 0; i < 16*4; i++) begin
			DMA_request |= DMA.Mem[{16'h0000, addr[15:6], 6'h00}+i] << (8*i);
		end
		for (i = 0; i < 16; i++) begin
			DMA_request_packed[i] = DMA_request[i*32+:32];
		end
	
		// DCache read request
		@(negedge clk) begin
			addr_in_pipeline_dcache_i = {16'h0000, addr[15:0]};
			data_in_pipeline_dcache_i = 0;
			pipeline_wr_valid_dcache_i = 0;
			pipeline_valid_dcache_i = 1;
		end
		
		// Wait till done
		@(posedge pipeline_valid_dcache_o) begin
			// Check for correct read
			if (data_out_pipeline_dcache_o != goldenMem) begin
				$display("Error pipeline; Got: %d     Exp: %d", data_out_pipeline_dcache_o, goldenMem);
				$stop();
			end
		end
		
		// Rest of Checks
		@(negedge clk) begin
			// DCache Cache Check
			if (DUT.DCACHE.cache_line[addr[7:6]][addr[5:2]] != goldenMem) begin
				$display("Error 1");
				$stop();
			end
			if (DUT.DCACHE.block_address[addr[7:6]] != {16'h0000, addr[15:8]}) begin
				$display("Error 2");
				$stop();
			end
			
			// clear
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
		reg [511:0] DMA_regrab;
		reg [31:0] DMA_request_packed[15:0];
		reg resp;
		
		//$display("D Write Start");
		
		// Golden Mem Block of interest
		DMA_request = 0;
		for (i = 0; i < 16*4; i++) begin
			DMA_request |= DMA.Mem[{16'h0000, addr[15:6], 6'h00}+i] << (8*i);
		end
		for (i = 0; i < 16; i++) begin
			DMA_request_packed[i] = DMA_request[i*32+:32];
		end
		
		// Correct
		DMA_request[addr[5:2]*32+:32] = write_data;
		DMA_request_packed[addr[5:2]] = write_data;
	
		// DCache write request
		@(negedge clk) begin
			addr_in_pipeline_dcache_i = {16'h0000, addr[15:0]};
			data_in_pipeline_dcache_i = write_data;
			pipeline_wr_valid_dcache_i = 1;
			pipeline_valid_dcache_i = 1;
		end
		
		// Wait till done
		@(posedge pipeline_valid_dcache_o);
		
		// Test
		@(negedge clk) begin
			// Check If valid is out
			if (pipeline_valid_dcache_o != 1) begin
				$display("Error valid");
				$stop();
			end
			
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
					//$stop();
				end
			end
			
			// Check MMCache Cache full Block
			for (i = 0; i < 16; i++) begin
				if (DUT.MMCACHE.cache_line[addr[9:6]][i] != DMA_request_packed[i]) begin
					$display("Error mmcache block data; Got: %d     Exp: %d", DUT.MMCACHE.cache_line[addr[9:6]][i], DMA_request_packed[i]);
					//$stop();
				end
			end
			
			// Check DMA
			DMA_regrab = 0;
			for (i = 0; i < 16*4; i++) begin
				DMA_regrab |= DMA.Mem[{16'h0000, addr[15:6], 6'h00}+i] << (8*i);
			end
			for (i = 0; i < 16; i++) begin
				DMA_request_packed[i] = DMA_regrab[i*32+:32];
			end
			
			if (DMA_regrab != DMA_request) begin
				$display("Error DMA block data; Got:      Exp: ");
				$stop();
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
			goldenMem |= DMA.Mem[{16'h0000, addr[15:2], 2'h0}+i] << (8*i);
		end
		
		DMA_request = 0;
		for (i = 0; i < 16*4; i++) begin
			DMA_request |= DMA.Mem[{16'h0000, addr[15:6], 6'h00}+i] << (8*i);
		end
		for (i = 0; i < 16; i++) begin
			DMA_request_packed[i] = DMA_request[i*32+:32];
		end
	
		// DCache read request
		@(negedge clk) begin
			addr_in_pipeline_icache_i = {16'h0000, addr[15:0]};
			pipeline_valid_icache_i = 1;
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
			
			// Check ICache Cache full Block
			for (i = 0; i < 16; i++) begin
				if (DUT.ICACHE.cache_line[addr[6]][i] != DMA_request_packed[i]) begin
					$display("Error icache block full");
					$stop();
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

