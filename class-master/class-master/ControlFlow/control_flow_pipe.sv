module control_flow_pipe#() (
	input clk_i,
	input rst_n_i,
	input branch_dec_i,
	input inst_cache_stall_i,
	input data_cache_stall_i,
	input tpu_busy_stall_i,
	input [4:0] d_op1_reg_i,
	input [4:0] d_op2_reg_i,
	input [4:0] e_dest_reg_i,
	input 		e_reg_write_en,
	input [4:0] m_dest_reg_i,
	input		m_reg_write_en,
	input [4:0] w_dest_reg_i,
	input		w_reg_write_en,
	output f_stall_o,
	output d_stall_o,
	output e_stall_o,
	output m_stall_o,
	output w_stall_o,
	output f_flush_o,
	output d_flush_o,
	output e_flush_o,
	output m_flush_o,
	output w_flush_o
	);


logic f_stall, d_stall, e_stall, m_stall, w_stall, f_flush, d_flush, e_flush, m_flush, w_flush;

assign f_stall_o = f_stall;
assign d_stall_o = d_stall;
assign e_stall_o = e_stall;
assign m_stall_o = m_stall;
assign w_stall_o = w_stall;
assign f_flush_o = f_flush;
assign d_flush_o = d_flush;
assign e_flush_o = e_flush;
assign m_flush_o = m_flush;
assign w_flush_o = w_flush;


always_comb begin
	f_stall = 1'b0;
	d_stall = 1'b0;
	e_stall = 1'b0;
	m_stall = 1'b0;
	w_stall = 1'b0;
	f_flush = 1'b0;
	d_flush = 1'b0;
	e_flush = 1'b0;
	m_flush = 1'b0;
	w_flush = 1'b0;
	
	// FE stalls/hazards
	if(inst_cache_stall_i) begin
		f_stall = 1'b1;
		f_flush = 1'b1;
	end
	
	// DE stalls/hazards
	// This will be Read after Write hazards (stall)
	if(	(e_reg_write_en && ((d_op1_reg_i == e_dest_reg_i) || (d_op2_reg_i == e_dest_reg_i))) ||
		(m_reg_write_en && ((d_op1_reg_i == m_dest_reg_i) || (d_op2_reg_i == m_dest_reg_i))) || 
		(w_reg_write_en && ((d_op1_reg_i == w_dest_reg_i) || (d_op2_reg_i == w_dest_reg_i)))
		) begin
		f_stall = 1'b1;
		f_flush = 1'b0;
		d_stall = 1'b1;
		d_flush = 1'b1;
	
	end
	
	// EX stalls/hazards
	if(~tpu_busy_stall_i) begin
		f_stall = 1'b1;
		f_flush = 1'b0;
		d_stall = 1'b1;
		d_flush = 1'b0;
		e_stall = 1'b1;
		e_flush = 1'b1;
	end
	
	// Clear if brach is taken
	if(branch_dec_i) begin
		f_flush = 1'b1;
		d_flush = 1'b1;
	
	end
	
	// ME stall/hazards
	if(data_cache_stall_i) begin
		f_stall = 1'b1;
		f_flush = 1'b0;
		d_stall = 1'b1;
		d_flush = 1'b0;
		e_stall = 1'b1;
		e_flush = 1'b0;
		m_stall = 1'b1;
		m_flush = 1'b1;
	end
	
end

endmodule
