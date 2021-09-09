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
  reg [DEPTH*BITS-1:0] queue;
  
  // Reg Control
  always_ff @(posedge clk) begin
	if (!rst_n)
		queue <= 0;
		
	else if (en)
		queue = {queue[(DEPTH-1)*BITS-1:0], d};
  
  end
  
  // Assign output
  assign q = queue[DEPTH*BITS-1:(DEPTH-1)*BITS];
  
endmodule // fifo
