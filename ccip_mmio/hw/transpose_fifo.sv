module transpose_fifo
	#(
	parameter DEPTH = 8,
	parameter BITS = 8
	)
	(
	input clk, rst_n, en, WrEn,
	input signed [BITS-1:0] d [DEPTH-1:0],
	output signed [BITS-1:0] q
	);
	
	// Transposed Load with Shifting
	
	// Store
	reg signed [BITS-1:0] tword [DEPTH-1:0];
	
	// Instance
	integer i;
	always_ff @(posedge clk) begin
		// Reset
		if (~rst_n) begin
			for (i = 0; i < DEPTH; i++) begin
				tword[i] <= 0;
			end
		end
		
		// Load
		else if (WrEn) begin
			// tword <= d;
			for (i = 0; i < DEPTH; i++) begin // Reversed?
				tword[i] <= d[i];
			end
		end
		
		// Shift
		else if (en) begin
			//tword <= {0, tword[DEPTH-1:0]};
			for (i = 0; i < DEPTH-1; i++) begin
				tword[i] <= tword[i+1];
			end
			// Last slot
			tword[DEPTH-1] <= 0;
		end
	end

	// Assign output
	assign q = tword[0];

endmodule
