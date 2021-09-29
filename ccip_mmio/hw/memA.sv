module memA
  #(
    parameter BITS_AB=8,
    parameter DIM=8
    )
   (
    input clk,rst_n,en,WrEn,
    input signed [BITS_AB-1:0] Ain [DIM-1:0],
    input [$clog2(DIM)-1:0] Arow,
    output signed [BITS_AB-1:0] Aout [DIM-1:0]
   );
	
	// Interconnects between loaders and Fifos
	wire signed [BITS_AB-1:0] interA [DIM-1:0];
   
	// Loaders/Transposers
	genvar x;
	generate
		for (x = 0; x < DIM; x++) begin
			transpose_fifo #(.DEPTH(DIM),.BITS(BITS_AB)) iTFIFOA [DIM-1:0](
				.clk(clk),
				.rst_n(rst_n),
				.en(en),
				.WrEn(WrEn & (Arow == x)),
				.d(Ain),
				.q(interA[x])
				);
		end
   endgenerate
   
	// Fifo instances to Aout
	assign Aout[0] = interA[0];
	generate
		for (x = 1; x < DIM; x++) begin
			fifo #(.DEPTH(x), .BITS(BITS_AB)) iFIFOA [DIM-1:0](
				.clk(clk),
				.rst_n(rst_n),
				.en(en),
				.d(interA[x]),
				.q(Aout[x])
				);
		
		end	
	endgenerate
   
endmodule