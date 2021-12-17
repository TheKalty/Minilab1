module br_predict_tb();

	logic clk, rst_n;
	logic taken, take;

	br_predict pred_dut (.clk(clk), .rst_n(rst_n), .taken(taken), .take(take));

	initial begin
		clk = 0;
		rst_n = 0;
		@(posedge clk);
		rst_n = 1;
		if (~take) // should start of strongly taken and so take should be high
			$stop();
		taken = 1;
		@(posedge clk);
		if (~take) // should stay in strongly taken and so take should be high
			$stop();
		taken = 0;
		@(posedge clk);
		if (~take) // should be in taken and so take should be high
			$stop();
		taken = 0;
		@(posedge clk);
		if (take) // should be in not taken and so take should be low
			$stop();
		taken = 0;
		@(posedge clk);
		if (take) // should be in strongly not taken and so take should be low
			$stop();
		taken = 1;
		@(posedge clk);
		if (take) // should be in not taken and so take should be low
			$stop();
		taken = 1;
		@(posedge clk);
		if (~take) // should be in taken and so take should be high
			$stop();
		taken = 1;
		@(posedge clk);
		if (~take) // should be in strongly taken and so take should be high
			$stop();
		
		$display("Yahoo! Test Passed.");
		$stop();
	end
	
	always #5 clk = ~clk;


endmodule