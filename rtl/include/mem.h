/**
 * filename : ctrl.h
 * author   : cjh
 * time     : 2015-12-28 15:50:16
 */

 `ifndef  __MEM_HEADER__
 	`define _MEM_HEADER_ 				

// mem_op 操作信号比特位
 	`define MEM_OP_B 		3:0 			// mem_op 位宽

 	`define MEM_OP_NOP 			4'h0 		
 	`define MEM_OP_LB 			4'h1
 	`define MEM_OP_LH			4'h2
 	`define MEM_OP_LW			4'h3
 	`define MEM_OP_LBU			4'h4
 	`define MEM_OP_LHU			4'h5
 	`define MEM_OP_SB			4'h6
 	`define MEM_OP_SH			4'h7
 	`define MEM_OP_SW			4'h8 
`endif