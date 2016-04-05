/**
 * filename : ctrl.h
 * author   : cjh
 * time     : 2015-12-28 15:50:16
 */

 `ifndef  __MEM_HEADER__
 	`define _MEM_HEADER_ 				

    // mem_op 操作信号比特位
 	`define MEM_OP_BUS 		    3:0 			// mem_op 位宽

 	// NOP  : 0000
 	// STORE: 01XX
 	// LOAD : 1XXX
 	`define MEM_OP_NOP 			4'b0000 	
 	`define MEM_OP_SB			4'b0100
 	`define MEM_OP_SH			4'b0101
 	`define MEM_OP_SW			4'b0110 
 	`define MEM_OP_LB 			4'b1000
 	`define MEM_OP_LH			4'b1001
 	`define MEM_OP_LW			4'b1010
 	`define MEM_OP_LBU			4'b1011
 	`define MEM_OP_LHU			4'b1100

 	// byte choose
 	`define BYTE0 			    2'b00 	
 	`define BYTE1			    2'b01
 	`define BYTE2			    2'b10
 	`define BYTE3			    2'b11

`endif