module MMCache
	#( 
		parameter INDEX = 16,
		parameter BLOCK_BITS = 512
	)
	(
	input clk_i,
	input rst_n_i,
	
	// Lower to self, ICache
	input [31:0] addr_in_icache_i, 					// Address request from ICache
	input ichache_request_i,						// CPU Signal for a write to cache
	output logic [BLOCK_BITS-1:0] data_out_icache_request_o,	// Data out of CPU
	output logic [31:0] addr_out_icache_request_o,
	output logic icache_request_valid_o,			// Signal for a valid output of data to CPU
	
	// Lower to self, DCache
	input [31:0] addr_in_dcache_i, 					// Address request from ICache
	input [BLOCK_BITS-1:0] data_in_dcache_i,					// Data from icache
	input dchache_request_i,						// CPU Signal for a write to cache
	input dcache_evict_i, 							// CPU Signal of a real request
	output logic [31:0] addr_out_dcache_request_o,
	output logic [BLOCK_BITS-1:0] data_out_dcache_request_o,	// Data out of CPU
	output logic dcache_request_valid_o,			// Signal for a valid output of data to CPU
	output logic dcache_evict_o,
	
	// Higher Cache Block input
	input [BLOCK_BITS-1:0] data_in_request_i,		// Higher Cache data block
	input [31:0] addr_in_request_i,		// Higher Cache data address
	input request_valid_i,				// Higher Cache signal for valid data block
	
	// Self Block Request
	output logic [31:0] addr_out_request_o,	// Address of block of data requested to Higher cache
	output logic request_o,					// Signal to higher cache of a block request
	
	// Self Evict Request
	input evict_i, 								// Higher Cache response to evict request
	output logic [BLOCK_BITS-1:0] data_out_evict_o,		// Block of data to be written to higher cache
	output logic [31:0] addr_out_evict_o,		// Address of block of data to be written to higher cache
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
	typedef enum {IDLE, READ_I, REQUESTREAD_I, REPORT_I, READ_D, REQUESTREAD_D, REPORT_D, WRITE_D, REQUESTWRITE_D, WRITESELF_D, WRITEHIGHER_D} state_type;
	state_type curr_state, next_state;
	
	// Internal Signals
	wire hit_i, miss_i, hit_d, miss_d;
	logic [INDEX-1:0] hit_inter_i;
	logic [INDEX-1:0] hit_inter_d;
	
	always_comb begin
		integer i;
		for (i = 0; i < INDEX; i++) begin
			hit_inter_i[i] = (addr_in_icache_i[WORD_BITS-1:$clog2(INDEX)+6] == block_address[addr_in_icache_i[$clog2(INDEX)+5:6]]) & valid_block[i] & (i == addr_in_icache_i[$clog2(INDEX)+5:6]);
			hit_inter_d[i] = (addr_in_dcache_i[WORD_BITS-1:$clog2(INDEX)+6] == block_address[addr_in_dcache_i[$clog2(INDEX)+5:6]]) & valid_block[i] & (i == addr_in_dcache_i[$clog2(INDEX)+5:6]);
		end
	end
	
	assign hit_i = |hit_inter_i;
	assign miss_i = ~hit_i;
	assign hit_d = |hit_inter_d;
	assign miss_d = ~hit_d;
	
	// Writes
	logic [511:0] cache_write_inter;
	logic [WORD_BITS-1:$clog2(INDEX)+6] cache_addr_inter;
	
	// FMS Signals
	logic [INDEX-1:0] write_block;
	
	// ICache OUTPUT here
	always_comb begin
		integer i, j;
		data_out_icache_request_o = 32'h0000_0000;
		data_out_dcache_request_o = 32'h0000_0000;
		for (i = 0; i < INDEX; i++) begin
			if (hit_inter_i[i]) begin
				for (j = 0; j < 16; j++) begin
					data_out_icache_request_o |= cache_line[i][j] << (j*32);
				end
			end
			
			if (hit_inter_d[i]) begin
				for (j = 0; j < 16; j++) begin
					data_out_dcache_request_o |= cache_line[i][j] << (j*32);
				end
			end
		end
		addr_out_icache_request_o = {addr_in_icache_i[31:6], 6'h00};
		addr_out_dcache_request_o = {addr_in_dcache_i[31:6], 6'h00};
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
	icache_request_valid_o = 0;
	dcache_evict_o = 0;
	dcache_request_valid_o = 0;
	
		case (curr_state)
			IDLE: begin
				// DCache Takes Precedence
				if (dchache_request_i) begin // Read
					next_state = READ_D;
				end
				else if (dcache_evict_i) begin // Write
					next_state = WRITE_D;
				end
				else if (ichache_request_i) begin // READ
					next_state = READ_I;
				end
			end
			
//---------------------------------------------------------------------------------------------------------------

			// ICache
			
			READ_I: begin
				if (hit_i) begin
					next_state = REPORT_I;
				end
				else begin
					next_state = REQUESTREAD_I;
				end
			end
			
			REQUESTREAD_I: begin
				next_state = REQUESTREAD_I;
				
				addr_out_request_o = {addr_in_icache_i[WORD_BITS-1:6], 6'h00};
				request_o = 1;
				
				if (request_valid_i) begin
					next_state = REPORT_I;
					
					request_o = 0;
					write_block[addr_in_icache_i[$clog2(INDEX)+5:6]] = 1;
					cache_write_inter = data_in_request_i;
					cache_addr_inter = addr_in_icache_i[WORD_BITS-1:$clog2(INDEX)+6];
				end
			end
			
			REPORT_I: begin
				icache_request_valid_o = 1;
			end
			
//---------------------------------------------------------------------------------------------------------------

			// DCache
				
			WRITE_D: begin
				if (hit_d) begin
					next_state = WRITESELF_D;
				end
				else if (miss_d) begin
					next_state = REQUESTWRITE_D;
				end
			end
			
			REQUESTWRITE_D: begin
				next_state = REQUESTWRITE_D;
				
				addr_out_request_o = {addr_in_dcache_i[WORD_BITS-1:6], 6'h00};
				request_o = 1;
				
				if (request_valid_i) begin
					next_state = WRITESELF_D;
					
					request_o = 0;
					write_block[addr_in_dcache_i[$clog2(INDEX)+5:6]] = 1;
					cache_write_inter = data_in_request_i;
					cache_addr_inter = addr_in_dcache_i[WORD_BITS-1:$clog2(INDEX)+6];
				end
			end
				
			WRITESELF_D: begin
				integer i;
				next_state = WRITEHIGHER_D;
				
				write_block[addr_in_dcache_i[$clog2(INDEX)+5:6]] = 1;
				
				cache_write_inter = data_in_dcache_i;
				cache_addr_inter = addr_in_dcache_i[WORD_BITS-1:$clog2(INDEX)+6];
			end
				
			WRITEHIGHER_D: begin
				integer i;
				next_state = WRITEHIGHER_D;
				
				evict_o = 1;
				
				data_out_evict_o = data_in_dcache_i;
				addr_out_request_o = {addr_in_dcache_i[WORD_BITS-1:6], 6'h00};
				addr_out_evict_o = {addr_in_dcache_i[WORD_BITS-1:6], 6'h00};
				
				if (evict_i) begin
					next_state = IDLE;
					
					evict_o = 0;
					
					// Not full cycle, is for reads tho
					dcache_evict_o = 1;
				end
			end
			
			READ_D: begin
				if (hit_d) begin
					next_state = REPORT_D;
				end
				else begin
					next_state = REQUESTREAD_D;
				end
			end
			
			REQUESTREAD_D: begin
				next_state = REQUESTREAD_D;
				
				addr_out_request_o = {addr_in_dcache_i[WORD_BITS-1:6], 6'h00};
				request_o = 1;
				
				if (request_valid_i) begin
					next_state = REPORT_D;
					
					request_o = 0;
					write_block[addr_in_dcache_i[$clog2(INDEX)+5:6]] = 1;
					cache_write_inter = data_in_request_i;
					cache_addr_inter = addr_in_dcache_i[WORD_BITS-1:$clog2(INDEX)+6];
				end
			end
			
			REPORT_D: begin
				dcache_request_valid_o = 1;
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