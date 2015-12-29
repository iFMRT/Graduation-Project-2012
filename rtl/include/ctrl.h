/**
 * filename : ctrl.h
 * author   : cjh
 * time     : 2015-12-27 20:55:13
 */

 `ifndef  __CTRL_HEADER__
 	`define _CTRL_HEADER_ 				

// EX_OUT 输出选通
 	`define ALU_OUT 		1'b0 			// 选通 ALU 输出作为 EX 阶段的输出
 	`define CMP_OUT 		1'b1        	// 选通 CMP 输出作为 EX 阶段的输出
// EX 阶段的通用寄存器输入选通
 	`define EX_EX_OUT 			1'b0 		// 以 EX_OUT 作为 EX 阶段输出的通用寄存器输入信号
 	`define EX_ID_OUT 			1'b1 		// 以 ID_OUT 作为 EX 阶段输出的通用寄存器输入信号
// MEM 阶段的通用寄存器输入选通
	`define MEM_MEM_OUT 		1'b0		// 以 MEM_OUT 作为通用寄存器的输入信号
	`define MEM_EX_OUT			1'b1		// 以 EX_OUT  作为通用寄存器的输入信号
// 指令处理位宽
	`define INSN_OP				[6:0]
	`define INSN_RA				[19:15]
	`define INSN_RB				[24:20]
	`define INSN_RC				[11:7]
	`define INSN_F3				[14:12]
	`define INSN_F7				[31:25]
	`define INS_OP_B			[6:0]
	`define INS_F3_B			[2:0]
	`define INS_F7_B			[6:0]
`endif