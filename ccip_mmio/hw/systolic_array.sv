module systolic_array
#(
   parameter BITS_AB=8,
   parameter BITS_C=16,
   parameter DIM=8
   )
  (
   input                      clk,rst_n,WrEn,en,
   input signed [BITS_AB-1:0] A [DIM-1:0],
   input signed [BITS_AB-1:0] B [DIM-1:0],
   input signed [BITS_C-1:0]  Cin [DIM-1:0],
   input [$clog2(DIM)-1:0]    Crow,
   output signed [BITS_C-1:0] Cout [DIM-1:0]
   );
   

	// Interconnects of MACs
	wire signed [BITS_AB-1:0] macAOut[DIM-1:0][DIM:0];
	wire signed [BITS_AB-1:0] macBOut[DIM:0][DIM-1:0];
	wire signed [BITS_C-1:0] macCOut[DIM-1:0][DIM-1:0];

	// Connecting
	// Input connect to macs connects
	genvar in;
	generate
		for (in = 0; in < DIM; in++) begin
			assign macAOut[in][0] = A[in];
			assign macBOut[0][in] = B[in];
		end
	endgenerate

	// interconnect of macs and macs themselves
	genvar x,y; // MAC[x][y]
	generate
		for (x = 0; x < DIM; x++) begin
			for (y = 0; y < DIM; y++) begin
				tpumac #(.BITS_AB(BITS_AB), .BITS_C(BITS_C)) iMAC(
					.clk(clk),
					.rst_n(rst_n), 
					.WrEn( (Crow == x) & (WrEn) ), 
					.en(en), 
					.Ain(macAOut[x][y]), 
					.Bin(macBOut[x][y]), 
					.Cin(Cin[y]), 
					.Aout(macAOut[x][y+1]), 
					.Bout(macBOut[x+1][y]), 
					.Cout(macCOut[x][y])
				);
			end
		end
	endgenerate

	// Assigning Cout based on Crow
	generate
		for (x = 0; x < DIM; x++) begin
			for (y = 0; y < DIM; y++) begin
				assign Cout[y] = (Crow == x) ? (macCOut[x][y]) : ('z);
			end
		end
	endgenerate
	
	// Assigning Cout based on Crow
	//generate
	//	for (x = 0; x < DIM; x++) begin
	//		assign Cout[x] = macCOut[Crow][x];
	//	end
	//endgenerate


endmodule