//-------------------------------------------------------------
// FILE NAME : id_reg_test.v
// DESCRIPTION : A test module of id_reg.v
// AUTHOR : cjh
// TIME : 2015-12-30 16:48:56
//-------------------------------------------------------------

/******** Time scale ********/
`timescale 1ns/1ps

/******** 测试模块 ********/
module id_reg_test();
	/******** 时钟和复位 ********/
	reg 			clk;				// 时钟
	reg				reset;				// 异步复位
	/********** 解码结果 **********/
	reg [3:0]			alu_op;		   	// ALU 操作
	reg [2:0]			cmp_op; 		// CMP 操作
	reg [31:0] 			alu_in_0;	   	// ALU 输入 0
	reg [31:0] 			alu_in_1;	   	// ALU 输入 1
	reg [31:0] 			cmp_in_0;	   	// CMP 输入 0
	reg [31:0] 			cmp_in_1;	   	// CMP 输入 1
	reg 				br_taken;		// 跳转成立
	reg				   	br_flag;		// 分支标志位
	reg [3:0]	   		mem_op;		   	// 内存操作
	reg [31:0]			mem_wr_data;	// mem 写入数据
	reg 				ex_out_mux;		// EX 阶段输出选通信号
	reg				   	gpr_we_;		// 寄存器写入有效
	reg [4:0]  			dst_addr;		// 寄存器写入地址
	reg  				gpr_mux_ex;
	reg 	 			gpr_mux_men;	// 通用寄存器输入选通信号
	reg [31:0] 			gpr_wr_data;	// ID 阶段输出的 gpr 输入值
	/********** 寄存器控制信号 **********/
	reg				   	stall;		   	// 停顿
	reg				   	flush;		   	// 刷新
	/********** IF/ID 直接输入 **********/
	reg				   	if_en;		   	// 流水线有效信号
	/********** ID/EX寄存器输出信号 **********/
	wire				   	id_en;		   	// 流水线寄存器有效
	wire	[3:0]	   		id_alu_op;	   	// ALU 操作
	wire  	[2:0] 			id_cmp_op; 		// CMP 操作
	wire	[31:0] 			id_alu_in_0;	// ALU 输入 0
	wire	[31:0] 			id_alu_in_1;	// ALU 输入 1
	wire	[31:0] 			id_cmp_in_0;	// CMP 输入 0
	wire	[31:0] 			id_cmp_in_1;	// CMP 输入 1
	wire  					id_br_taken;	// 跳转成立
	wire				   	id_br_flag;	   	// 分支标志位
	wire	[3:0]	   		id_mem_op;	   	// 存储器操作
	wire  	[31:0]			id_mem_wr_data; // 存储器写入数据
	wire 					id_ex_out_mux;	// EX 阶段输出选通信号	
	wire				   	id_gpr_we_;	   	// 寄存器写入信号
	wire  	[4:0]			id_dst_addr;	// 寄存器写入地址
	wire  					id_gpr_mux_ex;
	wire 					id_gpr_mux_mem;
	wire 	[31:0] 			id_gpr_wr_data;    // ID 阶段输出的 gpr 输入值

	reg 				   	exp_id_en;		   	// 流水线寄存器有效
	reg 	[3:0]	   		exp_id_alu_op;	   	// ALU 操作
	reg   	[2:0] 			exp_id_cmp_op; 		// CMP 操作
	reg 	[31:0] 			exp_id_alu_in_0;	// ALU 输入 0
	reg 	[31:0] 			exp_id_alu_in_1;	// ALU 输入 1
	reg 	[31:0] 			exp_id_cmp_in_0;	// CMP 输入 0
	reg 	[31:0] 			exp_id_cmp_in_1;	// CMP 输入 1
	reg   					exp_id_br_taken;	// 跳转成立
	reg 				   	exp_id_br_flag;	   	// 分支标志位
	reg 	[3:0]	   		exp_id_mem_op;	   	// 存储器操作
	reg   	[31:0]			exp_id_mem_wr_data; // 存储器写入数据
	reg  					exp_id_ex_out_mux;	// EX 阶段输出选通信号	
	reg 				   	exp_id_gpr_we_;	   	// 寄存器写入信号
	reg   	[4:0]			exp_id_dst_addr;	// 寄存器写入地址
	reg   					exp_id_gpr_mux_ex;
	reg  					exp_id_gpr_mux_mem;
	reg  	[31:0] 			exp_id_gpr_wr_data;    // ID 阶段输出的 gpr 输入值
	/******** 测试参数 ********/
	reg 	[31:0]	vector_num;			// 测试次数
	reg 	[31:0]	errors;				// 结果错误次数
	reg 	[428:0]	test_vectors[5:0];	// 测试向量存储	

	/******** 被测试模块的实例化 ********/
	id_reg dut(.clk			(clk),				// 时钟
	  			.reset		(reset),		   	// 异步复位
	/********** 解码结果 **********/
	   			.alu_op 		(alu_op),		   	// ALU 操作
	   			.cmp_op 		(cmp_op), 		// CMP 操作
			 	.alu_in_0 	(alu_in_0),	   	// ALU 输入 0
			 	.alu_in_1 	(alu_in_1),	   	// ALU 输入 1
			 	.cmp_in_0 	(cmp_in_0),	   	// CMP 输入 0
			 	.cmp_in_1 	(cmp_in_1),	   	// CMP 输入 1
	   			.br_taken 	(br_taken),		// 跳转成立
	  			.br_flag 	(br_flag),		// 分支标志位
				.mem_op 		(mem_op),		   	// 内存操作
				.mem_wr_data (mem_wr_data),	// mem 写入数据
	   			.ex_out_mux 	(ex_out_mux),		// EX 阶段输出选通信号
	  			.gpr_we_ 	(gpr_we_),		// 寄存器写入有效
		  		.dst_addr 	(dst_addr),		// 寄存器写入地址
	    		.gpr_mux_ex 	(gpr_mux_ex),
	   	 		.gpr_mux_men (gpr_mux_men),	// 通用寄存器输入选通信号
			 	.gpr_wr_data (gpr_wr_data),	// ID 阶段输出的 gpr 输入值
	/********** 寄存器控制信号 **********/
			   	.stall		(stall),		   	// 停顿
			   	.flush 		(flush),		   	// 刷新
	/********** IF/ID 直接输入 **********/
			   	.if_en 		(if_en),		   	// 流水线有效信号
	/********** ID/EX寄存器输出信号 **********/
				.id_en 		(id_en),		   	// 流水线寄存器有效
	   			.id_alu_op 	(id_alu_op),	   	// ALU 操作
  				.id_cmp_op 	(id_cmp_op),	// CMP 操作
	 			.id_alu_in_0 (id_alu_in_0),	// ALU 输入 0
	 			.id_alu_in_1 (id_alu_in_1),	// ALU 输入 1
	 			.id_cmp_in_0 (id_cmp_in_0),	// CMP 输入 0
	 			.id_cmp_in_1 (id_cmp_in_1),	// CMP 输入 1
  				.id_br_taken (id_br_taken),	// 跳转成立
				.id_br_flag 	(id_br_flag),	   	// 分支标志位
	   			.id_mem_op 	(id_mem_op),	   	// 存储器操作
  				.id_mem_wr_data (id_mem_wr_data), // 存储器写入数据
 				.id_ex_out_mux (id_ex_out_mux),	// EX 阶段输出选通信号	
				.id_gpr_we_ 	(id_gpr_we_),	   	// 寄存器写入信号
 				.id_dst_addr (id_dst_addr),	// 寄存器写入地址
  				.id_gpr_mux_ex (id_gpr_mux_ex),
 				.id_gpr_mux_mem (id_gpr_mux_mem),
 	 			.id_gpr_wr_data (id_gpr_wr_data)    // ID 阶段输出的 gpr 输入值
			);

	/******** 定义时钟信号 ********/
	always
		begin
			clk = 1; 
			#5;
			clk = 0; 
			#5;
		end

	/******** 读取测试用例，定义复位信号 ********/
	initial
		begin
			$readmemb("id_reg_exp.tv",test_vectors);
			vector_num 	= 	0;
			errors		=	0;
			reset		= 	1;	#27;
			reset		= 	0;
		end

	/******** 在时钟上升沿，把测试用例输入实例化模块 ******/
	always @ (posedge clk)
		begin
		 	#1; {alu_op,cmp_op,alu_in_0,alu_in_1,cmp_in_0,cmp_in_1,br_taken,br_flag,mem_op,mem_wr_data,ex_out_mux,gpr_we_,dst_addr,gpr_mux_ex,gpr_mux_men,gpr_wr_data,stall,flush,if_en,exp_id_en,exp_id_alu_op,exp_id_cmp_op,exp_id_alu_in_0,exp_id_alu_in_1,exp_id_cmp_in_0,exp_id_cmp_in_1,exp_id_br_taken,exp_id_br_flag,exp_id_mem_op,exp_id_mem_wr_data,exp_id_ex_out_mux,exp_id_gpr_we_,exp_id_dst_addr,exp_id_gpr_mux_ex,exp_id_gpr_mux_mem,exp_id_gpr_wr_data}	=	test_vectors[vector_num];
		end

		/********** output wave **********/
    initial
        begin
            $dumpfile("id_reg_test.vcd");
            $dumpvars(0,id_reg_test);
        end


	/******** 结果检测 ********/
	always @ (posedge clk)
		begin
			if(~reset)
				begin
					if(~({id_en,id_alu_op,id_cmp_op,id_alu_in_0,id_alu_in_1,id_cmp_in_0,id_cmp_in_1,id_br_taken,id_br_flag,id_mem_op,id_mem_wr_data,id_ex_out_mux,id_gpr_we_,id_dst_addr,id_gpr_mux_ex,id_gpr_mux_mem,id_gpr_wr_data} == {exp_id_en,exp_id_alu_op,exp_id_cmp_op,exp_id_alu_in_0,exp_id_alu_in_1,exp_id_cmp_in_0,exp_id_cmp_in_1,exp_id_br_taken,exp_id_br_flag,exp_id_mem_op,exp_id_mem_wr_data,exp_id_ex_out_mux,exp_id_gpr_we_,exp_id_dst_addr,exp_id_gpr_mux_ex,exp_id_gpr_mux_mem,exp_id_gpr_wr_data}))
						begin
							$display("error: vector_num = %d",vector_num);
							$display("output = %b(%b expected),%b(%b expected),%b(%b expected),%b(%b expected),%b(%b expected),%b(%b expected),%b(%b expected),%b(%b expected),%b(%b expected),%b(%b expected),%b(%b expected),%b(%b expected),%b(%b expected),%b(%b expected),%b(%b expected),%b(%b expected),%b(%b expected)",id_en,exp_id_en,id_alu_op,exp_id_alu_op,id_cmp_op,exp_id_cmp_op,id_alu_in_0,exp_id_alu_in_0,id_alu_in_1,exp_id_alu_in_1,id_cmp_in_0,exp_id_cmp_in_0,id_cmp_in_1,exp_id_cmp_in_1,id_br_taken,exp_id_br_taken,id_br_flag,exp_id_br_flag,id_mem_op,exp_id_mem_op,id_mem_wr_data,exp_id_mem_wr_data,id_ex_out_mux,exp_id_ex_out_mux,id_gpr_we_,exp_id_gpr_we_,id_dst_addr,exp_id_dst_addr,id_gpr_mux_ex,exp_id_gpr_mux_ex,id_gpr_mux_mem,exp_id_gpr_mux_mem,id_gpr_wr_data,exp_id_gpr_wr_data);
							errors = errors + 1;
						end
					vector_num = vector_num + 1;
					if(test_vectors[vector_num] === 429'bx)
						begin
							$display("%d test completed with %d errors",vector_num,errors);
							$finish;
						end
				end
		end

endmodule