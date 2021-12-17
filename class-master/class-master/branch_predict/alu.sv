module alu(a, b, alu_op, result, branch);
    input signed [31:0] a, b;
    input [3:0] alu_op;
    output logic signed [31:0] result;
    output logic branch;
	
	wire [64:0] mult;

	assign mult = a * b;

    always @(*)
        case(alu_op[1:0])
            4'b00 : branch = &alu_op[3:2] & ~|(a^b); // beq
            4'b01 : branch = &alu_op[3:2] & |(a^b); // bne
            4'b10 : branch = &alu_op[3:2] & (a > b); // a bgt b
			4'b11 : branch = &alu_op[3:2] & (a < b); // a blt b
            default : branch = 0; // don't branch
        endcase
    
    always @(*)
        case(alu_op)
            4'b0000 : result = a+b; // a + b
            4'b0001 : result = a-b; // a - b
            4'b0010 : result = a^b; // a ^ b
            4'b0011 : result = a|b; // a | b
            4'b0100 : result = a&b; // a & b
            4'b0101 : result = |(b[31:5]) ? 32'd0 : a << b; // a sll b
            4'b0110 : result = |(b[31:5]) ? 32'd0 : a >> b; // a srl b
            4'b0111 : result = |(b[31:5]) ? {32{a[31]}} : a >>> b; // a sra b
            4'b1000 : result = (a < b) ? 32'b1 : 32'b0; // set less than 
            4'b1001 : result = mult[31:0]; // a * b
			4'b1010 : result = b << 12; // load upper immediate
            4'b1011 : result = mult[63:32]; // load high 32 bits
			default : result  = {32{1'b1}}; // default all high
        endcase

endmodule
