// fifo.sv
// Implements delay buffer (fifo)
// On reset all entries are set to 0
// Shift causes fifo to shift out oldest entry to q, shift in d

module fifo
  #(
  parameter DEPTH=8,
  parameter BITS=64
  )
  (
  input clk,rst_n,en,
  input [BITS-1:0] d,
  output [BITS-1:0] q
  );
  // your RTL code here
  
  // Cache Queue
  reg [BITS-1:0] queue [DEPTH-1:0];
  
  // Reg Control
  integer x;
  always_ff @(posedge clk) begin
	if (!rst_n) begin
		for (x = 0; x < DEPTH; x++) begin
			queue[x] <= 0;
		end
	end
		
	else if (en) begin
		for (x = 1; x < DEPTH; x++) begin
			queue[x] <= queue[x-1];
		end
		queue[0] <= d;
	end
  
  end
  
  // Assign output
  assign q = queue[DEPTH-1];
  
endmodule // fifo
