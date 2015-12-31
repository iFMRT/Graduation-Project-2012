//-------------------------------------------------------------
// FILE NAME : gpr_testbench.v
// DESCRIPTION : A test module of gpr.v
// AUTHOR : cjh
// TIME : 2015-12-25 15:53:27
//-------------------------------------------------------------

/******** Time scale ********/
`timescale 1ns/1ps

/******** 测试模块 ********/
module gpr_testbench();
	/******** 时钟和复位 ********/
	reg 			clk;				// 时钟
	reg				reset;				// 异步复位
	/******** 读取端口 0 ********/
	reg 	[4:0]	rd_addr_0;			// 读取地址 0
	wire	[31:0]	rd_data_0;			// 读取数据 0
	/******** 读取端口 1 ********/
	reg 	[4:0]	rd_addr_1;			// 读取地址 1
	wire	[31:0]	rd_data_1;			// 读取数据 1
	/******** 写入端口 ********/
	reg 			we_;				// 写入有效信号
	reg 	[4:0]	wr_addr;			// 写入地址
	reg 	[31:0]	wr_data;			// 写入数据
	/******** 预测结果 ********/
	reg 	[31:0]	rd_data_0_exp;		// 应读取数据 0
	reg 	[31:0]	rd_data_1_exp;		// 应读取数据 1
	/******** 测试参数 ********/
	reg 	[31:0]	vector_num;			// 测试次数
	reg 	[31:0]	errors;				// 结果错误次数
	reg 	[111:0]	test_vectors[5:0];	// 测试向量存储	

	/******** 被测试模块的实例化 ********/
	gpr dut(.clk		(clk),			// 时钟
			.reset		(reset),		// 异步复位
			.rd_addr_0	(rd_addr_0),	// 读取的地址 0
			.rd_data_0 	(rd_data_0),	// 读取的数据 0
			.rd_addr_1	(rd_addr_1),	// 读取的地址 1
			.rd_data_1 	(rd_data_1),	// 读取的数据 1
			.we_		(we_),			// 写入有效信号
			.wr_addr	(wr_addr),		// 写入的地址
			.wr_data	(wr_data)		// 写入的数据
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
			$readmemb("gpr_example.tv",test_vectors);
			vector_num 	= 	0;
			errors		=	0;
			reset		= 	1;	#27;
			reset		= 	0;
		end

	/******** 在时钟上升沿，把测试用例输入实例化模块 ******/
	always @ (posedge clk)
		begin
		 	#1; {rd_addr_0,rd_data_0_exp,rd_addr_1,rd_data_1_exp,we_,wr_addr,wr_data}	=	test_vectors[vector_num];
		end

		/********** output wave **********/
    initial
        begin
            $dumpfile("gpr_testbench.vcd");
            $dumpvars(0,gpr_testbench);
        end


	/******** 结果检测 ********/
	always @ (negedge clk)
		begin
			if(~reset)
				begin
					if(rd_data_0 !== rd_data_0_exp  ||	rd_data_1 !== rd_data_1_exp)
						begin
							$display("error: vector_num = %d",vector_num);
							$display("output = %d(%d expected),%d(%d expected)", rd_data_0,rd_data_0_exp,rd_data_1,rd_data_1_exp);
							errors = errors + 1;
						end
					vector_num = vector_num + 1;
					if(test_vectors[vector_num] === 112'bx)
						begin
							$display("%d test completed with %d errors",vector_num,errors);
							$finish;
						end
				end
		end

endmodule