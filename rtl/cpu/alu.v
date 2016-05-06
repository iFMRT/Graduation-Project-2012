/**
 * filename: alu.v
 * author  : besky
 * time    : 2015-12-14 20:07:54
 */
`timescale 1ns/1ps
 
`include "stddef.h"
`include "isa.h"
`include "alu.h"

module alu (
	input  wire signed [31:0] arg0,
	input  wire signed [31:0] arg1,
	input  wire        [ 3:0] op,
	output reg  signed [31:0] val
	);

	always @(*) begin
		case(op)
			`ALU_OP_AND : val = arg0 & arg1;
			`ALU_OP_OR  : val = arg0 | arg1;
			`ALU_OP_XOR : val = arg0 ^ arg1;
			`ALU_OP_SLL : val = arg0 << arg1;
			`ALU_OP_SRL : val = arg0 >> arg1;
			`ALU_OP_SRA : val = arg0 >>> arg1;
			`ALU_OP_ADD : val = arg0 + arg1;
			`ALU_OP_SUB : val = arg0 - arg1;
			default     : val = 32'b0;
		endcase
	end
endmodule
