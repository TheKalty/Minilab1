module DCache
	#( 
		parameter INDEX = 4,
		parameter BLOCK_BITS = 512
	)
	(
	input clk_i,
	input rst_n_i,
	
	// Lower to self
	input [31:0] addr_in_pipeline_i, 		// Address request from CPU
	input [31:0] data_in_pipeline_i,		// Data from CPU
	input pipeline_wr_valid_i,				// CPU Signal for a write to cache
	input pipeline_valid_i, 				// CPU Signal of a real request
	output logic [31:0] data_out_pipeline_o,// Data out of CPU
	output logic pipeline_valid_o,				// Signal for a valid output of data to CPU
	
	// Higher Cache Block input
	input [511:0]data_in_request_i,		// Higher Cache data block
	input [31:0]addr_in_request_i,		// Higher Cache data address
	input request_valid_i,				// Higher Cache signal for valid data block
	
	// Self Block Request
	output logic [31:0]addr_out_request_o,	// Address of block of data requested to Higher cache
	output logic request_o,					// Signal to higher cache of a block request
	
	// Self Evict Request
	input evict_i, 								// Higher Cache response to evict request
	output logic [511:0]data_out_evict_o,		// Block of data to be written to higher cache
	output logic [31:0]addr_out_evict_o,		// Address of block of data to be written to higher cache
	output logic evict_o						// Signal that an evict is occuring
	);
	
	// Params
	localparam WORD_BITS = 32;
	
	//----------------------------------------------------------------------------------------------
	
	// Internal blocks
	reg [WORD_BITS-1:0] cache_line[INDEX-1:0][15:0];
	reg [WORD_BITS-1:$clog2(INDEX)+6] block_address[INDEX-1:0];
	reg [INDEX-1:0] valid_block;
	
	// ENUM STATES
	typedef enum {IDLE, READ, REQUESTREAD, REPORT, WRITE, REQUESTWRITE, WRITESELF, WRITEHIGHER} state_type;
	state_type curr_state, next_state;
	
	// Internal Signals
	wire hit, miss;
	logic [INDEX-1:0] hit_inter;
	always_comb begin
		integer i;
		for (i = 0; i < INDEX; i++) begin
			hit_inter[i] = (addr_in_pipeline_i[WORD_BITS-1:$clog2(INDEX)+6] == block_address[addr_in_pipeline_i[$clog2(INDEX)+5:6]]) & valid_block[i] & (i == addr_in_pipeline_i[$clog2(INDEX)+5:6]);
		end
	end
	
	assign hit = |hit_inter;
	assign miss = ~hit;
	
	// Writes
	logic [511:0] cache_write_inter;
	logic [WORD_BITS-1:$clog2(INDEX)+6] cache_addr_inter;
	
	// FMS Signals
	logic [INDEX-1:0] write_block;
	
	// CPU OUTPUT here
	always_comb begin
		integer i;
		data_out_pipeline_o = 32'h0000_0000;
		for (i = 0; i < INDEX; i++) begin
			if (hit_inter[i]) begin
				 data_out_pipeline_o = cache_line[i][addr_in_pipeline_i[5:2]];
			end
		end
	end
	
	//----------------------------------------------------------------------------------------------
	
	// Enum regs
	always_ff @(posedge clk_i) begin
		// reset 
		if (~rst_n_i) begin
			curr_state <= IDLE;
		end
	
		// Else
		curr_state <= next_state;
	end
	
	// FMS
	always_comb begin
	next_state = IDLE;
	write_block = 0;
	addr_out_request_o = 0;
	request_o = 0;
	data_out_evict_o = 0;
	addr_out_evict_o = 0;
	evict_o = 0;
	cache_write_inter = 0;
	cache_addr_inter = 0;
	pipeline_valid_o = 0;
	
		case (curr_state)
			IDLE: begin
				if (pipeline_wr_valid_i & pipeline_valid_i) begin
					next_state = WRITE;
				end
				else if (~pipeline_wr_valid_i & pipeline_valid_i) begin
					next_state = READ;
				end
			end
				
			WRITE: begin
				if (hit) begin
					next_state = WRITESELF;
				end
				else if (miss) begin
					next_state = REQUESTWRITE;
				end
			end
			
			REQUESTWRITE: begin
				next_state = REQUESTWRITE;
				
				addr_out_request_o = {addr_in_pipeline_i[WORD_BITS-1:6], 6'h00};
				request_o = 1;
				
				if (request_valid_i) begin
					next_state = WRITESELF;
					
					request_o = 0;
					write_block[addr_in_request_i[$clog2(INDEX)+5:6]] = 1;
					cache_write_inter = data_in_request_i;
					cache_addr_inter = addr_in_request_i[WORD_BITS-1:$clog2(INDEX)+6];
				end
			end
				
			WRITESELF: begin
				integer i;
				next_state = WRITEHIGHER;
				
				write_block[addr_in_pipeline_i[$clog2(INDEX)+5:6]] = 1;
				for (i = 15; i >= 0; i--) begin
					if (i == addr_in_pipeline_i[5:2]) begin
						cache_write_inter = (cache_write_inter << WORD_BITS) | data_in_pipeline_i;
					end
					else begin
						cache_write_inter = (cache_write_inter << WORD_BITS) | cache_line[addr_in_pipeline_i[$clog2(INDEX)+5:6]][i];
					end
				end
				cache_addr_inter = addr_in_pipeline_i[WORD_BITS-1:$clog2(INDEX)+6];
			end
				
			WRITEHIGHER: begin
				integer i;
				next_state = WRITEHIGHER;
				
				evict_o = 1;
				
				data_out_evict_o = 0;
				for (i = 0; i < 16; i++) begin
					data_out_evict_o |= cache_line[addr_in_pipeline_i[$clog2(INDEX)+5:6]][i] << (i*WORD_BITS);
				end 
				
				// If dont use evict addr;
				addr_out_evict_o = {addr_in_pipeline_i[WORD_BITS-1:6], 6'h00};
				addr_out_request_o = {addr_in_pipeline_i[WORD_BITS-1:6], 6'h00};
				
				if (evict_i) begin
					next_state = REPORT;
					
					evict_o = 0;
					
					// Not full cycle, is for reads tho
					//pipeline_valid_o = 1;
				end
			end
			
			READ: begin
				if (hit) begin
					next_state = REPORT;
				end
				else begin
					next_state = REQUESTREAD;
				end
			end
			
			REQUESTREAD: begin
				next_state = REQUESTREAD;
				
				addr_out_request_o = {addr_in_pipeline_i[WORD_BITS-1:6], 6'h00};
				request_o = 1;
				
				if (request_valid_i) begin
					next_state = REPORT;
					
					request_o = 0;
					write_block[addr_in_request_i[$clog2(INDEX)+5:6]] = 1;
					cache_write_inter = data_in_request_i;
					cache_addr_inter = addr_in_request_i[WORD_BITS-1:$clog2(INDEX)+6];
				end
			end
			
			REPORT: begin
				pipeline_valid_o = 1;
			end
			
		endcase
	
	end
	
	//----------------------------------------------------------------------------------------------
	
	// Block Instances(Hopefully in SRAM)
	always_ff @(posedge clk_i) begin
		// Reseting all cache lines
		if (~rst_n_i) begin
			integer i, j;
			for (i = 0; i < INDEX; i++) begin
				for (j = 0; j < 16; j++) begin
					cache_line[i][j] <= 0;
				end
			end
		end
		
		// If writing from request
		else if (|write_block) begin
			integer i, j;
			for (i = 0; i < INDEX; i++) begin
				if (write_block[i]) begin
					for (j = 0; j < 16; j++) begin
						cache_line[i][j] <= cache_write_inter[WORD_BITS*j+:WORD_BITS];
					end
				end 
			end
		end
	end
	
	// Block Address, byte addresable(3) and 512 bit blocks(4), 7 bits redundent
	always_ff @(posedge clk_i) begin
		// reset block address
		if (~rst_n_i) begin
			integer i;
			for (i = 0; i < INDEX; i++) begin
				block_address[i] <= 0;
			end
		end
	
		// If writing from request
		if (write_block) begin
			integer i;
			for (i = 0; i < INDEX; i++) begin
				if (write_block[i]) begin
					block_address[i] <= cache_addr_inter;
				end
			end
		end
	end
	
	// Valid block
	always_ff @(posedge clk_i) begin
		// reset block address
		if (~rst_n_i) begin
			valid_block <= 0;
		end
	
		// If writing from request
		if (write_block) begin
			integer i;
			for (i = 0; i < INDEX; i++) begin
				if (write_block[i]) begin
					valid_block[i] <= 1;
				end
			end
		end
	end
	
	//----------------------------------------------------------------------------------------------

endmodule