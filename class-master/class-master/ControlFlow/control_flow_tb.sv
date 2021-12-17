module control_flow_tb();
	logic clk, rst_n;
	logic f_stall, d_stall, e_stall, m_stall, w_stall, fd_flush, de_flush, em_flush, mw_flush;
	
	
	
	control_flow cf(
		.clk_i(clk),
		.rst_n_i(rst_n), 
		.f_stall_o(f_stall), 
		.d_stall_o(d_stall), 
		.e_stall_o(e_stall), 
		.m_stall_o(m_stall), 
		.w_stall_o(w_stall), 
		.fd_flush_o(fd_flush), 
		.de_flush_o(de_flush), 
		.em_flush_o(em_flush), 
		.mw_flush_o(mw_flush)
		);
	
	always begin
		#5 clk = ~clk;
	end

	initial begin
		clk = 0;
		rst_n = 0;
		@(posedge clk) rst_n = 1;
		#1 if((f_stall | fd_flush)) begin
			$display("Instruction not allowed to pass through!");
			$stop();
		end
		@(posedge clk);
		#1 if(!(f_stall & fd_flush)) begin
			$display("Next instruction not stopped!");
			$stop();
		end
		@(posedge clk);
		#1 if(!(f_stall & fd_flush)) begin
			$display("Next instruction not stopped!");
			$stop();
		end
		@(posedge clk);
		#1 if(!(f_stall & fd_flush)) begin
			$display("Next instruction not stopped!");
			$stop();
		end
		@(posedge clk);
		#1 if(!(f_stall & fd_flush)) begin
			$display("Next instruction not stopped!");
			$stop();
		end
		@(posedge clk);
		#1 if((f_stall | fd_flush)) begin
			$display("Instruction not allowed to pass through!");
			$stop();
		end
		@(posedge clk);
		#1 if(!(f_stall & fd_flush)) begin
			$display("Next instruction not stopped!");
			$stop();
		end
		@(posedge clk);
		#1 if(!(f_stall & fd_flush)) begin
			$display("Next instruction not stopped!");
			$stop();
		end
		@(posedge clk);
		#1 if(!(f_stall & fd_flush)) begin
			$display("Next instruction not stopped!");
			$stop();
		end
			@(posedge clk);
		#1 if(!(f_stall & fd_flush)) begin
			$display("Next instruction not stopped!");
			$stop();
		end
		$stop();
	end
	

endmodule
