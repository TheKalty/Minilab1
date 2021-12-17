module alu_tb();
	
	logic signed [31:0] a, b, result, expected;
	logic signed [63:0] mult_result;
	logic [3:0] alu_op;
	logic branch, expected_branch;
	
	parameter loop_checks = 1000;
	
	alu alu_DUT (.a(a), .b(b), .alu_op(alu_op), .result(result), .branch(branch));
	
	initial begin
		
		// Test 1: Add Test, Op: 4'b0000 //
		for (int i = 0; i < loop_checks; i++) begin
			a = $random();
			b = $random();
			expected = a + b;
			alu_op = 4'b0000;
			fork
				begin : timeout1
					repeat(70000) #1;
					$display("Timed out waiting for add result to change");
					$stop();
				end
				begin
					while (result !== expected) begin
						if (branch) begin
							$display("Branch should not be asserted on add instruction");
							$stop();
						end
						#1;
					end
					disable timeout1;
				end
			join
			
		end
		$display("Test 1 passed");
		
		// Test 2: Subtract Test, Op: 4'b0001 //
		for (int i = 0; i < loop_checks; i++) begin
			a = $random();
			b = $random();
			expected = a - b;
			alu_op = 4'b0001;
			fork
				begin : timeout1
					repeat(70000) #1;
					$display("Timed out waiting for subtract result to change");
					$stop();
				end
				begin
					while (result !== expected) begin
						if (branch) begin
							$display("Branch should not be asserted on subtract instruction");
							$stop();
						end
						#1;
					end
					disable timeout1;
				end
			join
			
		end
		$display("Test 2 passed");
		
		// Test 3: Xor Test, Op: 4'b0010 //
		for (int i = 0; i < loop_checks; i++) begin
			a = $random();
			b = $random();
			expected = a ^ b;
			alu_op = 4'b0010;
			fork
				begin : timeout1
					repeat(70000) #1;
					$display("Timed out waiting for xor result to change");
					$stop();
				end
				begin
					while (result !== expected) begin
						if (branch) begin
							$display("Branch should not be asserted on xor instruction");
							$stop();
						end
						#1;
					end
					disable timeout1;
				end
			join
			
		end
		$display("Test 3 passed");
		
		// Test 4: Or Test, Op: 4'b0011 //
		for (int i = 0; i < loop_checks; i++) begin
			a = $random();
			b = $random();
			expected = a | b;
			alu_op = 4'b0011;
			fork
				begin : timeout1
					repeat(70000) #1;
					$display("Timed out waiting for Or result to change");
					$stop();
				end
				begin
					while (result !== expected) begin
						if (branch) begin
							$display("Branch should not be asserted on Or instruction");
							$stop();
						end
						#1;
					end
					disable timeout1;
				end
			join
			
		end
		$display("Test 4 passed");
		
		// Test 5: And Test, Op: 4'b0loop_checks //
		for (int i = 0; i < loop_checks; i++) begin
			a = $random();
			b = $random();
			expected = a & b;
			alu_op = 4'b0100;
			fork
				begin : timeout1
					repeat(70000) #1;
					$display("Timed out waiting for And result to change");
					$stop();
				end
				begin
					while (result !== expected) begin
						if (branch) begin
							$display("Branch should not be asserted on And instruction");
							$stop();
						end
						#1;
					end
					disable timeout1;
				end
			join
			
		end
		$display("Test 5 passed");
		
		// Test 6: SLL Test, Op: 4'b0101 //
		for (int i = 0; i < loop_checks; i++) begin
			a = $random();
			b = $random();
			expected = a << b;
			alu_op = 4'b0101;
			fork
				begin : timeout1
					repeat(70000) #1;
					$display("Timed out waiting for SLL result to change");
					$stop();
				end
				begin
					while (result !== expected) begin
						if (branch) begin
							$display("Branch should not be asserted on SLL instruction");
							$stop();
						end
						#1;
					end
					disable timeout1;
				end
			join
			
		end
		$display("Test 6 passed");
		
		// Test 7: SRL Test, Op: 4'b0110 //
		for (int i = 0; i < loop_checks; i++) begin
			a = $random();
			b = $random();
			expected = a >> b;
			alu_op = 4'b0110;
			fork
				begin : timeout1
					repeat(70000) #1;
					$display("Timed out waiting for SRL result to change");
					$stop();
				end
				begin
					while (result !== expected) begin
						if (branch) begin
							$display("Branch should not be asserted on SRL instruction");
							$stop();
						end
						#1;
					end
					disable timeout1;
				end
			join
			
		end
		$display("Test 7 passed");
		
		// Test 8: SRA Test, Op: 4'b0111 //
		for (int i = 0; i < loop_checks; i++) begin
			a = $random();
			b = $random();
			expected = a >>> b;
			alu_op = 4'b0111;
			fork
				begin : timeout1
					repeat(70000) #1;
					$display("Timed out waiting for SRA result to change");
					$stop();
				end
				begin
					while (result !== expected) begin
						if (branch) begin
							$display("Branch should not be asserted on SRA instruction");
							$stop();
						end
						#1;
					end
					disable timeout1;
				end
			join
			
		end
		$display("Test 8 passed");
		
		// Test 9: SLT Test, Op: 4'bloop_checks0 //
		for (int i = 0; i < loop_checks; i++) begin
			a = $random();
			b = $random();
			expected = (a < b);
			alu_op = 4'b1000;
			fork
				begin : timeout1
					repeat(70000) #1;
					$display("Timed out waiting for SLT result to change");
					$stop();
				end
				begin
					while (result !== expected) begin
						if (branch) begin
							$display("Branch should not be asserted on SLT instruction");
							$stop();
						end
						#1;
					end
					disable timeout1;
				end
			join
			
		end
		$display("Test 9 passed");
		
		// Test 10: Multiply Test, Op: 4'bloop_checks1 //
		for (int i = 0; i < loop_checks; i++) begin
			a = $random();
			b = $random();
			mult_result = a*b;
			expected = mult_result[31:0];
			alu_op = 4'b1001;
			fork
				begin : timeout1
					repeat(70000) #1;
					$display("Timed out waiting for MULT result to change");
					$stop();
				end
				begin
					while (result !== expected) begin
						if (branch) begin
							$display("Branch should not be asserted on MULT instruction");
							$stop();
						end
						#1;
					end
					disable timeout1;
				end
			join
		end
		$display("Test 10 passed");
		
		// Test 11: LUI Test, Op: 4'b1010 //
		for (int i = 0; i < loop_checks; i++) begin
			a = $random();
			b = $random();
			expected = b << 12;
			alu_op = 4'b1010;
			fork
				begin : timeout1
					repeat(70000) #1;
					$display("Timed out waiting for LUI result to change");
					$stop();
				end
				begin
					while (result !== expected) begin
						if (branch) begin
							$display("Branch should not be asserted on LUI instruction");
							$stop();
						end
						#1;
					end
					disable timeout1;
				end
			join
		end
		$display("Test 11 passed");
		
		// Test 11: Beq Test //
		alu_op = 4'b1100;
		for (int i = 0; i < loop_checks; i++) begin
			expected_branch = $random() % 2; // two possible options: 1 or 0
			case (expected_branch)
				0: begin // set not equal should not branch here
					a = $random();
					b = $random();
				end
				default: begin // equal so sould branch here
					a = $random();
					b = a;
				end
			endcase
			fork
				begin : timeout1
					repeat(70000) #1;
					$display("Timed out waiting for Beq result to change");
					$stop();
				end
				begin
					while (branch !== expected_branch) begin
						#1;
						if (result !== 32'hFFFFFFFF) begin
							$display("Result should be default value of all 1's");
							$stop();
						end
					end
					disable timeout1;
				end
			join
		end
		$display("Test 11 passed");
		
		// Test 12: Bne Test //
		alu_op = 4'b1101;
		for (int i = 0; i < loop_checks; i++) begin
			expected_branch = $random() % 2; // two possible options: 1 or 0
			case (expected_branch)
				0: begin // set equal should not branch here
					a = $random();
					b = a;
				end
				default: begin // set not equal and should branch here
					a = $random();
					b = $random();
 				end
			endcase
			fork
				begin : timeout1
					repeat(70000) #1;
					$display("Timed out waiting for Beq result to change");
					$stop();
				end
				begin
					while (branch !== expected_branch) begin
						#1;
						if (result !== 32'hFFFFFFFF) begin
							$display("Result should be default value of all 1's");
							$stop();
						end
					end
					disable timeout1;
				end
			join
		end
		$display("Test 12 passed");
		
		// Test 13: Bgt Test //
		alu_op = 4'b1110;
		for (int i = 0; i < loop_checks; i++) begin
			expected_branch = $random() % 2; // two possible options: 1 or 0
			case (expected_branch)
				0: begin // set a less than or equal to b should not branch here
					a = $random();
					b = $random();
					while (a > b) begin
						b = $random();
						a--;	
					end
				end
				default: begin // set a greater than b should branch here
					a = $random();
					b = $random();
					while (a <= b) begin
						b = $random();
						a++;	
					end
 				end
			endcase
			fork
				begin : timeout1
					repeat(70000) #1;
					$display("Timed out waiting for Beq result to change");
					$stop();
				end
				begin
					while (branch !== expected_branch) begin
						#1;
						if (result !== 32'hFFFFFFFF) begin
							$display("Result should be default value of all 1's");
							$stop();
						end
					end
					disable timeout1;
				end
			join
		end
		$display("Test 13 passed");
		
		// Test 14: Blt Test //
		alu_op = 4'b1111;
		for (int i = 0; i < loop_checks; i++) begin
			expected_branch = $random() % 2; // two possible options: 1 or 0
			case (expected_branch)
				0: begin // set a greater than or equal to b should not branch here
					a = $random();
					b = $random();
					while (a < b) begin
						b = $random();
						a++;	
					end
				end
				default: begin // set a less than b should branch here
					a = $random();
					b = $random();
					while (a >= b) begin
						b = $random();
						a--;	
					end
 				end
			endcase
			fork
				begin : timeout1
					repeat(70000) #1;
					$display("Timed out waiting for Beq result to change");
					$stop();
				end
				begin
					while (branch !== expected_branch) begin
						#1;
						if (result !== 32'hFFFFFFFF) begin
							$display("Result should be default value of all 1's");
							$stop();
						end
					end
					disable timeout1;
				end
			join
		end
		$display("Test 14 passed");
		
		// Test 15: Mulh Test //
		for (int i = 0; i < loop_checks; i++) begin
			a = $random();
			b = $random();
			mult_result = a * b;
			expected = mult_result[63:32];
			alu_op = 4'b1011;
			fork
				begin : timeout1
					repeat(70000) #1;
					$display("Timed out waiting for MULT result to change");
					$stop();
				end
				begin
					while (result !== expected) begin
						#1;
						if (branch) begin
							$display("Branch should not be asserted on MULT instruction");
							$stop();
						end
					end
					disable timeout1;
				end
			join
		end
		$display("Test 15 passed");
		
		$display("Yahoo! All tests passed");
		$stop();
	end

endmodule