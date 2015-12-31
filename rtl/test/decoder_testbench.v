//-------------------------------------------------------------
// FILE NAME : decoder_testbench.v
// DESCRIPTION : A test module of gpr.v
// AUTHOR : cjh
// TIME : 2015-12-28 09:05:56
//-------------------------------------------------------------

/******** Time scale ********/
`timescale 1ns/1ps

`include "isa.h"
`include "alu.h"
`include "cmp.h"
`include "ctrl.h"
`include "stddef.h"
`include "cpu.h"
`include "mem.h"

/******** 测试模块 ********/
module decoder_testbench();
	reg 					clk;
	reg 					reset;
	reg  [`WORD_DATA_BUS]	if_pc;			// 程序计数器
	reg  [`WORD_DATA_BUS]	if_pc_plus4;	// 返回地址
	reg  [`WORD_DATA_BUS]	if_insn;		// 指令
	reg 			 		if_en;			// 流水线数据有效

	/********** GPR 接口 **********/
	reg  [`WORD_DATA_BUS]	gpr_rd_data_0; 		// 读取数据 0
	reg  [`WORD_DATA_BUS]	gpr_rd_data_1; 		// 读取数据 1
	wire [`REG_ADDR_BUS]	gpr_rd_addr_0; 		// 读取地址 0
	wire [`REG_ADDR_BUS]	gpr_rd_addr_1; 		// 读取地址 1
	
	/********** 数据转发 **********/
	reg 							id_en;			// 流水线数据有效
	reg  [`REG_ADDR_BUS]	 		id_dst_addr;	// 写入地址
	reg 							id_gpr_we_;		// 写入有效
	reg  [`MEM_OP_B]				id_mem_op;		// 内存操作

	// 来自EX阶段的数据转发
	reg 						ex_en;			// 流水线数据有效
	reg  [`REG_ADDR_BUS]		ex_dst_addr;	// 写入地址
	reg 						ex_gpr_we_;		// 写入有效
	reg  [`WORD_DATA_BUS]		ex_fwd_data;	// 数据转发 
	// 来自MEM阶段的数据转发
	reg  [`WORD_DATA_BUS]		mem_fwd_data;	// 数据转发 
	
	/********** 解码结果 **********/
	wire	[`ALU_OP_B]				alu_op;			// ALU 操作
	wire  	[`CMP_OP_B] 			cmp_op;			// CMP 操作
	wire	[`WORD_DATA_BUS]	 	alu_in_0;		// ALU 输入 0
	wire	[`WORD_DATA_BUS]	 	alu_in_1;		// ALU 输入 1
	wire	[`WORD_DATA_BUS]	 	cmp_in_0;		// CMP 输入 0 
	wire	[`WORD_DATA_BUS]	 	cmp_in_1;		// CMP 输入 1
	wire							br_taken;		// 跳转成立
	wire							br_flag;		// 分支标志位
	wire	[`MEM_OP_B]				mem_op;			// 内存操作
	wire	[`WORD_DATA_BUS]		mem_wr_data;	// mem 写入数据
	wire 							ex_out_mux;		// EX 阶段输出选通
	wire			 				gpr_we_;		// 通用寄存器写入操作
	wire	[`REG_ADDR_BUS]			dst_addr;		// 通用寄存器写入地址
	wire  							gpr_mux_ex;		// ex 阶段的 gpr 写入信号选通
	wire							gpr_mux_mem;	// mem 阶段的 gpr 写入信号选通
	wire 	[`WORD_DATA_BUS]		gpr_wr_data;		// ID 阶段输出的 gpr 输入信号选通
	// 第一阶段不考虑 wire	[`IsaExpBus]	 exp_code;		// 异常代码
	wire							ld_hazard;		// LOAD 冲突

	reg [`REG_ADDR_BUS]			gpr_rd_addr_0_exp; 	// 读取地址 0
	reg [`REG_ADDR_BUS]			gpr_rd_addr_1_exp; 	// 读取地址 1
	reg	[`ALU_OP_B]				alu_op_exp;			// ALU 操作
	reg [`CMP_OP_B] 			cmp_op_exp;			// CMP 操作
	reg	[`WORD_DATA_BUS]	 	alu_in_0_exp;		// ALU 输入 0
	reg	[`WORD_DATA_BUS]	 	alu_in_1_exp;		// ALU 输入 1
	reg	[`WORD_DATA_BUS]	 	cmp_in_0_exp;		// CMP 输入 0 
	reg	[`WORD_DATA_BUS]	 	cmp_in_1_exp;		// CMP 输入 1
	reg							br_taken_exp;		// 跳转成立
	reg							br_flag_exp;		// 分支标志位
	reg	[`MEM_OP_B]				mem_op_exp;			// 内存操作
	reg	[`WORD_DATA_BUS]		mem_wr_data_exp;	// mem 写入数据
	reg 						ex_out_mux_exp;		// EX 阶段输出选通
	reg			 				gpr_we_exp_;		// 通用寄存器写入操作
	reg	[`REG_ADDR_BUS]			dst_addr_exp;		// 通用寄存器写入地址
	reg  						gpr_mux_ex_exp;		// ex 阶段的 gpr 写入信号选通
	reg							gpr_mux_mem_exp;	// mem 阶段的 gpr 写入信号选通
	reg [`WORD_DATA_BUS]		gpr_wr_data_exp;	// ID 阶段输出的 gpr 输入信号选通
	reg 						ld_hazard_exp;  	// 冲突检测

	/******** 测试参数 ********/
	reg 	[31:0]	vector_num;			// 测试次数
	reg 	[31:0]	errors;				// 结果错误次数
	reg 	[467:0]	test_vectors[7:0];	// 测试向量存储	

	/******** 被测试模块的实例化 ********/
	decoder dut(.if_pc		(if_pc),			// 程序计数器
			.if_pc_plus4	(if_pc_plus4),		// 下一指令地址
			.if_insn		(if_insn),			// 指令
			.if_en 			(if_en),			// 流水线信号有效

			.gpr_rd_data_0	(gpr_rd_data_0),	// 寄存器读取数据 0
			.gpr_rd_data_1 	(gpr_rd_data_1),	// 寄存器读取数据 1
			.gpr_rd_addr_0	(gpr_rd_addr_0),	// 寄存器读取地址 0
			.gpr_rd_addr_1	(gpr_rd_addr_1),	// 寄存器读取地址 1
			
			.id_en			(id_en),			// id 流水线寄存器有效
			.id_dst_addr 	(id_dst_addr),		// id 流水线寄存器中 通用寄存器写入地址
			.id_gpr_we_		(id_gpr_we_),		// 通用寄存器写入有效
			.id_mem_op		(id_mem_op),		// 存储器操作

			.ex_en			(ex_en),			// ex 寄存器有效 
			.ex_dst_addr	(ex_dst_addr),		// 通用寄存器写入地址
			.ex_gpr_we_		(ex_gpr_we_),		// 通用寄存器写入有效
			.ex_fwd_data 	(ex_fwd_data),		// ex 阶段转发数据

			.mem_fwd_data	(mem_fwd_data),		// mem 阶段转发数据

			.alu_op			(alu_op),			// alu 操作
			.cmp_op			(cmp_op),			// cmp 操作
			.alu_in_0		(alu_in_0),			// alu 输入 0
			.alu_in_1		(alu_in_1),			// alu 输入 1
			.cmp_in_0		(cmp_in_0),			// cmp 输入 0
			.cmp_in_1		(cmp_in_1),			// cmp 输入 1
			.br_taken		(br_taken),			// 跳转标志
			.br_flag		(br_flag),			// 分支标志
			.mem_op 		(mem_op),			// 存储器操作
			.mem_wr_data	(mem_wr_data),		// 存储器写回数据
			.ex_out_mux		(ex_out_mux),		// ex 阶段输出选通
			.gpr_we_ 		(gpr_we_),			// 寄存器写入有效
			.dst_addr 		(dst_addr),			// 寄存器写入地址
			.gpr_mux_ex		(gpr_mux_ex),		// ex 阶段的 gpr 写入数据选通
			.gpr_mux_mem	(gpr_mux_mem),		// mem 阶段的 gpr 写入数据选通
			.gpr_wr_data 	(gpr_wr_data),		// gpr 写入数据
			.ld_hazard		(ld_hazard)			// 冲突信号
			);

	/******** 定义时钟信号 ********/
	always
		begin
			clk = 1; 
			#10;
			clk = 0; 
			#10;
		end

	/******** 读取测试用例，定义复位信号 ********/
	initial
		begin
			$readmemb("dec_example.tv",test_vectors);
			vector_num 	= 	0;
			errors		=	0;
			reset		= 	1;	#27;
			reset		= 	0;
		end

	/******** 在时钟上升沿，把测试用例输入实例化模块 ******/
	always @ (posedge clk)
		begin
		 	#1; {if_pc,if_pc_plus4,if_insn,if_en,gpr_rd_data_0,gpr_rd_data_1,gpr_rd_addr_0_exp,gpr_rd_addr_1_exp,id_en,id_dst_addr,id_gpr_we_,id_mem_op,ex_en,ex_dst_addr,ex_gpr_we_,ex_fwd_data,mem_fwd_data,alu_op_exp,cmp_op_exp,alu_in_0_exp,alu_in_1_exp,cmp_in_0_exp,cmp_in_1_exp,br_taken_exp,br_flag_exp,mem_op_exp,mem_wr_data_exp,ex_out_mux_exp,gpr_we_exp_,dst_addr_exp,gpr_mux_ex_exp,gpr_mux_mem_exp,gpr_wr_data_exp,ld_hazard_exp}	=	test_vectors[vector_num];
		end

		/********** output wave **********/
    initial
        begin
            $dumpfile("decoder_testbench.vcd");
            $dumpvars(0,decoder_testbench);
        end


	/******** 结果检测 ********/
	always @ (negedge clk)
		begin
			if(~reset)
				begin
					if(~({gpr_rd_addr_0,gpr_rd_addr_1,alu_op,cmp_op,alu_in_0,alu_in_1,cmp_in_0,cmp_in_1,br_taken,br_flag,mem_op,mem_wr_data,ex_out_mux,gpr_we_,dst_addr,gpr_mux_ex,gpr_mux_mem,gpr_wr_data,ld_hazard} == {gpr_rd_addr_0_exp,gpr_rd_addr_1_exp,alu_op_exp,cmp_op_exp,alu_in_0_exp,alu_in_1_exp,cmp_in_0_exp,cmp_in_1_exp,br_taken_exp,br_flag_exp,mem_op_exp,mem_wr_data_exp,ex_out_mux_exp,gpr_we_exp_,dst_addr_exp,gpr_mux_ex_exp,gpr_mux_mem_exp,gpr_wr_data_exp,ld_hazard_exp}))
						begin
							$display("error: vector_num = %d",vector_num);
							$display("output = %d(%d expected),%d(%d expected),%d(%d expected),%d(%d expected),%d(%d expected),%d(%d expected),%d(%d expected),%d(%d expected),%d(%d expected),%d(%d expected),%d(%d expected),%d(%d expected),%d(%d expected),%d(%d expected),%d(%d expected),%d(%d expected),%d(%d expected),%d(%d expected),%d(%d expected)", gpr_rd_addr_0,gpr_rd_addr_0_exp,gpr_rd_addr_1,gpr_rd_addr_1_exp,alu_op,alu_op_exp,cmp_op,cmp_op_exp,alu_in_0,alu_in_0_exp,alu_in_1,alu_in_1_exp,cmp_in_0,cmp_in_0_exp,cmp_in_1,cmp_in_1_exp,br_taken,br_taken_exp,br_flag,br_flag_exp,mem_op,mem_op_exp,mem_wr_data,mem_wr_data_exp,ex_out_mux,ex_out_mux_exp,gpr_we_,gpr_we_exp_,dst_addr,dst_addr_exp,gpr_mux_ex,gpr_mux_ex_exp,gpr_mux_mem,gpr_mux_mem_exp,gpr_wr_data,gpr_wr_data_exp,ld_hazard,ld_hazard_exp);
							errors = errors + 1;
						end
					vector_num = vector_num + 1;
					if(test_vectors[vector_num] === 468'bx)
						begin
							$display("%d test completed with %d errors",vector_num,errors);
							$finish;
						end
				end
		end

endmodule