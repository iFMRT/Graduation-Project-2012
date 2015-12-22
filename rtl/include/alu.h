/**
 * filename: alu.h
 * author  : besky
 * time    : 2015-12-15 11:39:05
 */

`ifndef __ALU_HEADER__
	`define __ALU_HEADER__			         // Include Guard
	
	`define ALU_OP_NOP        4'h0
	`define ALU_OP_AND        4'h1
	`define ALU_OP_OR         4'h2
	`define ALU_OP_XOR        4'h3
	`define ALU_OP_SLL        4'h4
	`define ALU_OP_SRL        4'h5
	`define ALU_OP_SRA        4'h6
	`define ALU_OP_ADD        4'h7
	`define ALU_OP_SUB        4'h8

	`define ALU_OP_W          4
	`define ALU_OP_B          3:0
`endif

