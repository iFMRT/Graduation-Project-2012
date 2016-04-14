//-------------------------------------------------------------
// FILE NAME : tb_testbench.v
// DESCRIPTION : A test module of t_buffer.v
// AUTHOR : cjh
// TIME : 2016-04-11 09:53:02
//-------------------------------------------------------------

/******** Time scale ********/
`timescale 1ns/1ps

/******** 测试模块 ********/
module tb_testbench();
	reg			clk;
	reg 		reset;
	reg [31:0] 	pc; 
	reg  		is_hit;
	reg [31:0]	tar_addr;
	wire[31:0]	tar_data;
	wire 		tar_en;
	reg [31:0]  exp_tar_data;
	reg 		exp_tar_en;

	/******** 测试参数 ********/
	reg 	[31:0]	vector_num;			// text times
	reg 	[31:0]	errors;				// error times
	reg 	[97:0]	test_vectors[13:0];	// text vectors	

	/******** 被测试模块的实例化 ********/
	t_buffer #(54,9,512) dut(.clk		(clk),			// clock
		.pc			(pc),
		.is_hit		(is_hit),
		.tar_addr 	(tar_addr),
		.tar_data 	(tar_data),
		.tar_en 	(tar_en)
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
			$readmemb("tb_example.tv",test_vectors);

			vector_num 	= 	0;
			errors		=	0;
			reset		= 	1;	#27;
			reset		= 	0;
		end

	/******** 在时钟上升沿，把测试用例输入实例化模块 ******/
	always @ (posedge clk)
		begin
		 	#1; {pc,is_hit,tar_addr,exp_tar_data,exp_tar_en}	=	test_vectors[vector_num];
		end

		/********** output wave **********/
    initial
        begin
            $dumpfile("tb_testbench.vcd");
            $dumpvars(0,tb_testbench);
        end


	/******** 结果检测 ********/
	always @ (negedge clk)
		begin
			if(~reset)
				begin
					if(~({tar_data,tar_en} == {exp_tar_data,exp_tar_en}))
						begin
							$display("error: vector_num = %d",vector_num);
							$display("output = %h(%h expected),output = %h(%h expected)",tar_data,exp_tar_data,tar_en,exp_tar_en);
	
							errors = errors + 1;
						end
					vector_num = vector_num + 1;
					if(test_vectors[vector_num] === 98'bx)
						begin
							$display("%d test completed with %d errors",vector_num,errors);
							$finish;
						end
				end
		end

endmodule