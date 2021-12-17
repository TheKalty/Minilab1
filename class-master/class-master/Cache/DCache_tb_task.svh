task write_miss;
	input [31:0] addr;
	input [31:0] data_pipeline;
	input [511:0] data_higher;
	
	begin
		// Write at 0x0000_0000, CPU ask
		@(negedge clk) begin
			addr_in_pipeline_i = addr;
			data_in_pipeline_i = data_pipeline;
			pipeline_valid_i = 1;
			pipeline_wr_valid_i = 1;
		end
		
		// Long wait
		repeat(50) @(posedge clk);
		
		// L1 Response, request block
		@(negedge clk) begin
			request_valid_i = 1;
			data_in_request_i = data_higher;
			addr_in_request_i = {addr[31:6], 6'h00};
		end
		@(negedge clk) begin
			request_valid_i = 0;
		end
		
		// Long wait
		repeat(50) @(posedge clk);
		
		// L1 Response, write block 
		@(negedge clk) begin
			evict_i = 1;
		end
		@(posedge clk) begin
			evict_i = 0;
			pipeline_valid_i = 0;
			pipeline_wr_valid_i = 0;
		end
		
	end
endtask

//----------------------------------------------------------------------------

task write_hit;
	input [31:0] addr;
	input [31:0] data_pipeline;
	
	begin
		// Write at 0x0000_0000, CPU ask
		@(negedge clk) begin
			addr_in_pipeline_i = addr;
			data_in_pipeline_i = data_pipeline;
			pipeline_valid_i = 1;
			pipeline_wr_valid_i = 1;
		end
		
		// Till self asks for higher write
		@(posedge evict_o);
		repeat(50) @(posedge clk);
		
		// L1 Response, write block 
		@(negedge clk) begin
			evict_i = 1;
		end
		@(posedge clk) begin
			evict_i = 0;
			pipeline_valid_i = 0;
			pipeline_wr_valid_i = 0;
		end
	end

endtask

//----------------------------------------------------------------------------

task read_miss;
	input [31:0] addr;
	input [511:0] data;
	
	begin
		// Read at 0x0000_0000, cpu ask
		@(negedge clk) begin
			addr_in_pipeline_i = addr;
			pipeline_valid_i = 1;
			pipeline_wr_valid_i = 0;
		end
		
		// Long wait
		repeat(50) @(posedge clk);
		
		// L1 Response, request block
		@(negedge clk) begin
			request_valid_i = 1;
			data_in_request_i = data;
			addr_in_request_i = {addr[31:6], 6'h00};
		end
		@(posedge pipeline_valid_o) begin
			request_valid_i = 0;
		end
		@(negedge clk) begin
			pipeline_valid_i = 0;
		end
	end

endtask

//----------------------------------------------------------------------------

task read_hit;
	input [31:0] addr;
	
	begin
		// Read at 0x0000_0000, cpu ask
		@(negedge clk) begin
			addr_in_pipeline_i = addr;
			pipeline_valid_i = 1;
			pipeline_wr_valid_i = 0;
		end
		
		@(posedge pipeline_valid_o);
		@(negedge clk) begin
			pipeline_valid_i = 0;
		end
	end
	
endtask

//----------------------------------------------------------------------------

task write_test;
	
	begin
		reg [31:0] rand_addr;
		reg [31:0] rand_data_pipe;
		reg [31:0] rand_data_higher_packed [15:0];
		reg [511:0] rand_data_higher;
		reg [511:0] rand_data_higher_gold;
		
		integer i, hit, error;
		error = 0;
		hit = 0;
		for (i = 0; i < 16; i++) begin
			rand_data_higher_packed[i] = $random();
		end
		rand_addr = $random();
		rand_data_pipe = $random();
		
		rand_data_higher = 0;
		rand_data_higher_gold = 0;
		for (i = 0; i < 16; i++) begin
			rand_data_higher |= rand_data_higher_packed[i] << (32*i);
			
			if (i == rand_addr[5:2]) begin
				rand_data_higher_gold |= rand_data_pipe << (32*i);
			end
			else begin
				rand_data_higher_gold |= rand_data_higher_packed[i] << (32*i);
			end
		end
	
		// Check if it is a miss
		for (i = 0; i < 4; i++) begin
			if (DUT.block_address[i] == rand_addr[31:8]) begin
				hit = 1;
			end
		end
		
		if (hit) begin
			// Write at 0x0000_0000, CPU ask
			@(negedge clk) begin
				addr_in_pipeline_i = rand_addr;
				data_in_pipeline_i = rand_data_pipe;
				pipeline_valid_i = 1;
				pipeline_wr_valid_i = 1;
			end
			
			// Till self asks for higher write
			@(posedge evict_o);
			repeat(50) @(posedge clk);
		
			// L1 Response, write block 
			@(negedge clk) begin
				// Test to see if outputing correct addr and val
				if ({rand_addr[31:8], 8'h00} != addr_out_evict_o) begin
					error++;
					$display("Error evict addr");
				end
				
				if (rand_data_higher_gold != data_out_evict_o) begin
					error++;
					$display("Error evict data");
				end
			
				evict_i = 1;
			end
			
			// TEST
			@(posedge pipeline_valid_o) begin
				for (i = 0; i < 16; i++) begin
					if (rand_addr[5:2] == i) begin
						if (DUT.cache_line[rand_addr[7:6]][rand_addr[5:2]] != rand_data_pipe) begin
							error++;
							$display("Error not touched");
						end
					end
					else begin
						if (DUT.cache_line[rand_addr[7:6]][i] != rand_data_higher_packed[i]) begin
							error++;
							$display("Error touched");
						end
					end
				end
			end
			
			@(posedge clk) begin
				evict_i = 0;
				pipeline_valid_i = 0;
				pipeline_wr_valid_i = 0;
			end
		end
		
		else begin
			@(negedge clk) begin
				addr_in_pipeline_i = rand_addr;
				data_in_pipeline_i = rand_data_pipe;
				pipeline_valid_i = 1;
				pipeline_wr_valid_i = 1;
			end
		
			// Long wait
			repeat(50) @(posedge clk);
		
			// L1 Response, request block
			@(negedge clk) begin
				request_valid_i = 1;
				data_in_request_i = rand_data_higher;
				addr_in_request_i = {rand_addr[31:6], 6'h00};
			end
			@(negedge clk) begin
				request_valid_i = 0;
			end
		
			// Long wait
			repeat(50) @(posedge clk);
		
			// L1 Response, write block 
			@(negedge clk) begin
				// Test to see if outputing correct addr and val
				if ({rand_addr[31:8], 8'h00} != addr_out_evict_o) begin
					error++;
					$display("Error evict addr");
				end
				
				if (rand_data_higher_gold != data_out_evict_o) begin
					error++;
					$display("Error evict data");
				end
			
				evict_i = 1;
			end
		
			// TEST
			@(posedge pipeline_valid_o) begin
				for (i = 0; i < 16; i++) begin
					if (rand_addr[5:2] == i) begin
						if (DUT.cache_line[rand_addr[7:6]][rand_addr[5:2]] != rand_data_pipe) begin
							error++;
							$display("Error");
						end
					end
					else begin
						if (DUT.cache_line[rand_addr[7:6]][i] != rand_data_higher_packed[i]) begin
							error++;
							$display("Error");
						end
					end
				end
			end
		
			@(posedge clk) begin
				evict_i = 0;
				pipeline_valid_i = 0;
				pipeline_wr_valid_i = 0;
			end
		end
		
		if (error == 0) begin
			// $display("Passed");
		end
		
	end
endtask

//----------------------------------------------------------------------------

task read_test;

	begin
		reg [31:0] rand_addr;
		reg [31:0] rand_data_higher_packed [15:0];
		reg [511:0] rand_data_higher;
		
		integer i, hit, error;
		error = 0;
		hit = 0;
		for (i = 0; i < 16; i++) begin
			rand_data_higher_packed[i] = $random();
		end
		rand_addr = $random();
		
		rand_data_higher = 0;
		for (i = 0; i < 16; i++) begin
			rand_data_higher |= rand_data_higher_packed[i] << (32*i);
		end
	
		// Check if it is a miss
		for (i = 0; i < 4; i++) begin
			if (DUT.block_address[i] == rand_addr[31:8]) begin
				hit = 1;
			end
		end
		
		// hit
		if (hit) begin
			// Read at 0x0000_0000, cpu ask
			@(negedge clk) begin
				addr_in_pipeline_i = rand_addr;
				pipeline_valid_i = 1;
				pipeline_wr_valid_i = 0;
			end
		
			// test value
			@(posedge pipeline_valid_o) begin
				if (DUT.cache_line[rand_addr[7:6]][rand_addr[5:2]] != data_out_pipeline_o) begin
					error++;
					$display("Error data read");
				end
			end
			
			@(negedge clk) begin
				pipeline_valid_i = 0;
			end
			
		end
		
		// Miss
		else begin
			// Read at 0x0000_0000, cpu ask
			@(negedge clk) begin
				addr_in_pipeline_i = rand_addr;
				pipeline_valid_i = 1;
				pipeline_wr_valid_i = 0;
			end
		
			// Long wait
			repeat(50) @(posedge clk);
		
			// L1 Response, request block
			@(negedge clk) begin
				request_valid_i = 1;
				data_in_request_i = rand_data_higher;
				addr_in_request_i = {rand_addr[31:6], 6'h00};
			end
			
			
			@(posedge pipeline_valid_o) begin
				if ((DUT.cache_line[rand_addr[7:6]][rand_addr[5:2]] != data_out_pipeline_o) || 
						(rand_data_higher_packed[rand_addr[5:2]] != data_out_pipeline_o) ) begin
					error++;
					$display("Error data read");
				end
			
				request_valid_i = 0;
			end
			@(negedge clk) begin
				pipeline_valid_i = 0;
			end
			
		end
		
		if (error == 0) begin
			// $display("Passed");
		end
		
	end


endtask