module memB
  #(
    parameter BITS_AB=8,
    parameter DIM=8
    )
   (
    input                      clk,rst_n,en,
    input signed [BITS_AB-1:0] Bin [DIM-1:0],
    output signed [BITS_AB-1:0] Bout [DIM-1:0]
    );
	
	// Fifo instances with stagering
	genvar x;
	generate
		for (x = 0; x < DIM; x++) begin
			fifo #(.DEPTH(DIM+x), .BITS(BITS_AB)) iFIFOB(
				.clk(clk),
				.rst_n(rst_n),
				.en(en),
				.d(Bin[x]),
				.q(Bout[x])
				);
		end	
	endgenerate
	
endmodule