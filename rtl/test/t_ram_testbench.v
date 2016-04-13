//-------------------------------------------------------------
// FILE NAME : t_ram_testbench.v
// DESCRIPTION : A test module of t_ram.v
// AUTHOR : cjh
// TIME : 2016-03-30 10:23:55
//-------------------------------------------------------------

/******** Time scale ********/
`timescale 1ns/1ps

/******** 测试模块 ********/
module t_ram_testbench();
	reg			clk;
	reg 		reset;
	reg [8:0]	ram_addr;
	reg  		wr;
	reg [53:0]	wd;
	wire[53:0]	rd;
	reg [53:0]  exp_rd;

	/******** 测试参数 ********/
	reg 	[31:0]	vector_num;			// text times
	reg 	[31:0]	errors;				// error times
	reg 	[117:0]	test_vectors[6:0];	// text vectors	

	/******** 被测试模块的实例化 ********/
	t_ram #(54,9,512) dut(.clk		(clk),			// clock
		.ram_addr	(ram_addr),		// write_address
		.wr 		(wr),			// do write
		.wd 		(wd),			// write data
		.rd 		(rd));			// read data		

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
			$readmemb("tram_example.tv",test_vectors);

			vector_num 	= 	0;
			errors		=	0;
			reset		= 	1;	#27;
			reset		= 	0;
						$display("fuck = %b",test_vectors[vector_num]);
		end

	/******** 在时钟上升沿，把测试用例输入实例化模块 ******/
	always @ (posedge clk)
		begin
		 	#1; {ram_addr,wr,wd,exp_rd}	=	test_vectors[vector_num];
		end

		/********** output wave **********/
    initial
        begin
            $dumpfile("tram_testbench.vcd");
            $dumpvars(0,t_ram_testbench);
        end


	/******** 结果检测 ********/
	always @ (negedge clk)
		begin
			if(~reset)
				begin
					if(~({rd} === {exp_rd}))
						begin
							$display("error: vector_num = %d",vector_num);
							$display("output = %d(%d expected)",rd,exp_rd);
	
							errors = errors + 1;
						end
					vector_num = vector_num + 1;
					if(test_vectors[vector_num] === 118'bx)
						begin
							$display("%d test completed with %d errors",vector_num,errors);

							$finish;
						end
				end
		end

endmodule