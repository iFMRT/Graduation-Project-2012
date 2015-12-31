//---------------------------------------------------------
// FILENAME: decoder.v
// ESCRIPTION: The stage regist module of id_stage
// AUTHOR: cjh
// DETA: 2015-12-18 08:35:48
//---------------------------------------------------------
`include "alu.h"
`include "cmp.h"
`include "ctrl.h"
`include "stddef.h"
`include "cpu.h"
`include "mem.h"


/********** id 阶段状态寄存器模块 **********/
module id_reg (
	/********** 时钟和复位 **********/
	input  wire				   	clk,			// 时钟
	input  wire				   	reset,		   	// 异步复位
	/********** 解码结果 **********/
	input  wire [3:0]			alu_op,		   	// ALU 操作
	input  wire [2:0]			cmp_op, 		// CMP 操作
	input  wire [31:0] 			alu_in_0,	   	// ALU 输入 0
	input  wire [31:0] 			alu_in_1,	   	// ALU 输入 1
	input  wire [31:0] 			cmp_in_0,	   	// CMP 输入 0
	input  wire [31:0] 			cmp_in_1,	   	// CMP 输入 1
	input  wire 				br_taken,		// 跳转成立
	input  wire				   	br_flag,		// 分支标志位
	input  wire [1:0]	   		mem_op,		   	// 内存操作
	input  wire [31:0]			mem_wr_data,	// mem 写入数据
	input  wire 				ex_out_mux,		// EX 阶段输出选通信号
	input  wire				   	gpr_we_,		// 寄存器写入有效
	input  wire [4:0]  			dst_addr,		// 寄存器写入地址
	input  wire  				gpr_mux_ex,
	input  wire 	 			gpr_mux_men,		// 通用寄存器输入选通信号
	input  wire [31:0] 			gpr_wr_data,	// ID 阶段输出的 gpr 输入值
	//input  wire [`IsaExpBus]  exp_code,	   	// 异常代码
	/********** 寄存器控制信号 **********/
	input  wire				   	stall,		   	// 停顿
	input  wire				   	flush,		   	// 刷新
	/********** IF/ID 直接输入 **********/
	input  wire				   	if_en,		   	// 流水线有效信号
	/********** ID/EX寄存器输出信号 **********/
	output reg				   	id_en,		   	// 流水线寄存器有效
	output reg	[3:0]	   		id_alu_op,	   	// ALU 操作
	output reg  [2:0] 			id_cmp_op, 		// CMP 操作
	output reg	[31:0] 			id_alu_in_0,	// ALU 输入 0
	output reg	[31:0] 			id_alu_in_1,	// ALU 输入 1
	output reg	[31:0] 			id_cmp_in_0,	// CMP 输入 0
	output reg	[31:0] 			id_cmp_in_1,	// CMP 输入 1
	output reg  				id_br_taken,	// 跳转成立
	output reg				   	id_br_flag,	   	// 分支标志位
	output reg	[1:0]	   		id_mem_op,	   	// 存储器操作
	output reg  [31:0]			id_mem_wr_data, // 存储器写入数据
	output reg 					id_ex_out_mux,	// EX 阶段输出选通信号	
	output reg				   	id_gpr_we_,	   	// 寄存器写入信号
	output reg  [4:0]			id_dst_addr,	// 寄存器写入地址
	output reg  				id_gpr_mux_ex,
	output reg 					id_gpr_mux_mem,
	output reg 	[31:0] 			id_gpr_wr_data   // ID 阶段输出的 gpr 输入值
	//output reg  [`IsaExpBus]  id_exp_code	   	// 异常代码
);

	/********** 寄存器操作 **********/
	always @(posedge clk or reset) begin
		if (reset == `ENABLE) begin 
			/* 异步复位 */
			id_en		   <= #1 `DISABLE;
			id_alu_op	   <= #1 `ALU_OP_NOP;
			id_cmp_op	   <= #1 `CMP_OP_NOP;
			id_alu_in_0	   <= #1 `WORD_DATA_W'h0;
			id_alu_in_1	   <= #1 `WORD_DATA_W'h0;
			id_cmp_in_0	   <= #1 `WORD_DATA_W'h0;
			id_cmp_in_1	   <= #1 `WORD_DATA_W'h0;
			id_br_taken    <= #1 `DISABLE;
			id_br_flag	   <= #1 `DISABLE;
			id_mem_op	   <= #1 `MEM_OP_NOP;
			id_mem_wr_data <= #1 `WORD_DATA_W'h0;
			id_ex_out_mux  <= #1 `ALU_OUT;
			id_gpr_we_	   <= #1 `DISABLE_;
			id_dst_addr    <= #1 5'h0;
			id_gpr_mux_ex  <= #1 `DISABLE;
			id_gpr_mux_mem <= #1 `DISABLE;
			id_gpr_wr_data	   <= #1 `WORD_DATA_W'h0;

		end else begin
			/* 寄存器数据更新 */
			if (stall == `DISABLE) begin 
				if (flush == `ENABLE) begin // 清空寄存器
				  	id_en		   <= #1 `DISABLE;
					id_alu_op	   <= #1 `ALU_OP_NOP;
					id_cmp_op	   <= #1 `CMP_OP_NOP;
					id_alu_in_0	   <= #1 `WORD_DATA_W'h0;
					id_alu_in_1	   <= #1 `WORD_DATA_W'h0;
					id_cmp_in_0	   <= #1 `WORD_DATA_W'h0;
					id_cmp_in_1	   <= #1 `WORD_DATA_W'h0;
					id_br_taken    <= #1 `DISABLE;
					id_br_flag	   <= #1 `DISABLE;
					id_mem_op	   <= #1 `MEM_OP_NOP;
					id_mem_wr_data <= #1 `WORD_DATA_W'h0;
					id_ex_out_mux  <= #1 `ALU_OUT;
					id_gpr_we_	   <= #1 `DISABLE_;
					id_dst_addr    <= #1 5'h0;
					id_gpr_mux_ex  <= #1 `DISABLE;
					id_gpr_mux_mem <= #1 `DISABLE;
					id_gpr_wr_data <= #1 `WORD_DATA_W'h0;
		//id_exp_code	   <= #1 `ISA_EXP_NO_EXP;
				end else begin				// 给寄存器赋值
				   	id_en		   <= #1 if_en;
				   	id_alu_op	   <= #1 alu_op;
				   	id_cmp_op	   <= #1 cmp_op;
				   	id_alu_in_0	   <= #1 alu_in_0;
				   	id_alu_in_1	   <= #1 alu_in_1;
				   	id_cmp_in_0	   <= #1 cmp_in_0;
				   	id_cmp_in_1	   <= #1 cmp_in_1;
				   	id_br_taken    <= #1 br_taken;
				   	id_br_flag	   <= #1 br_flag;
				   	id_mem_op	   <= #1 mem_op;
				   	id_mem_wr_data <= #1 mem_wr_data;
				   	id_ex_out_mux  <= #1 ex_out_mux;
				   	id_gpr_we_	   <= #1 gpr_we_;
				   	id_dst_addr	   <= #1 dst_addr;
				   	id_gpr_mux_ex  <= #1 gpr_mux_ex;
				   	id_gpr_mux_mem <= #1 gpr_mux_men;
				   	id_gpr_wr_data <= #1 gpr_wr_data;
		//id_exp_code	  <= #1 exp_code;
				end
			end
		end
	end
endmodule
