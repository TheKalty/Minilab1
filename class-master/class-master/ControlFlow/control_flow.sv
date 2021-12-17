module control_flow#() (
	clk_i, 
	rst_n_i, 
	f_stall_o, 
	d_stall_o, 
	e_stall_o, 
	m_stall_o, 
	w_stall_o, 
	fd_flush_o, 
	de_flush_o, 
	em_flush_o, 
	mw_flush_o
	);
// Implementing bubbling first
// When bubbling, allow one instruction to enter the proc, then insert no ops and stall the PC until the operation is done
input logic clk_i, rst_n_i;
output f_stall_o, d_stall_o, e_stall_o, m_stall_o, w_stall_o, fd_flush_o, de_flush_o, em_flush_o, mw_flush_o;
logic f_stall, d_stall, e_stall, m_stall, w_stall, fd_flush, de_flush, em_flush, mw_flush;

assign f_stall_o = f_stall;
assign d_stall_o = d_stall;
assign e_stall_o = e_stall;
assign m_stall_o = m_stall;
assign w_stall_o = w_stall;
assign fd_flush_o = fd_flush;
assign de_flush_o = de_flush;
assign em_flush_o = em_flush;
assign mw_flush_o = mw_flush;

logic [2:0] timer;

always_ff@(posedge clk_i) begin
	if(!rst_n_i) begin
		timer <= 'b0;
	end
	else begin
		if(timer == 4) begin
			timer <= 'b0;
		end
		else begin
			timer <= timer + 1;
		end	
	end
end

always_comb begin
	f_stall = 1'b0;
	d_stall = 1'b0;
	e_stall = 1'b0;
	m_stall = 1'b0;
	w_stall = 1'b0;
	fd_flush = 1'b0;
	de_flush = 1'b0;
	em_flush = 1'b0;
	mw_flush = 1'b0;

	//Used for bubbling
	if(timer != 'b0) begin
		f_stall = 1'b1;
		fd_flush = 1'b1;
	end
end

endmodule
