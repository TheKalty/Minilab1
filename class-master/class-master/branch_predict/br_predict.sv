module br_predict(clk, rst_n, taken, take);
	input clk, rst_n;
	input taken;
	output logic take;
	
	typedef enum logic [1:0] {S_TAKEN, TAKEN, N_TAKEN, SN_TAKEN} state_t;
	state_t state, nxt_state;
	logic take_in;
	
	always_ff @(posedge clk, negedge rst_n) begin
		if (!rst_n)
			state <= S_TAKEN;
		else
			state <= nxt_state;
	end
	
	always_ff @(posedge clk, negedge rst_n) begin
		if (!rst_n)
			take <= 1;
		else
			take <= take_in;
	end
	
	always_comb begin
		nxt_state = state;
		case(state)
			S_TAKEN : begin
				if (~taken)
					nxt_state = TAKEN;
				take_in = 1;
			end
			TAKEN : begin
				if (taken) begin
					nxt_state = S_TAKEN;
					take_in = 1;
				end
				else begin
					nxt_state = N_TAKEN;
					take_in = 0;
				end
			end
			N_TAKEN : begin
				if (taken) begin
					nxt_state = TAKEN;
					take_in = 1;
				end
				else begin
					nxt_state = SN_TAKEN;
					take_in = 0;
				end
			end
			SN_TAKEN : begin
				if (taken)
					nxt_state = N_TAKEN;
				take_in = 0;
			end
		endcase
	end

endmodule