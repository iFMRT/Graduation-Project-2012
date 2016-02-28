# general purpepos registers (gpr) 的设计与实现
##通用寄存器

FMC 的指令最大可以指定三个寄存器作为操作数，从其中两个寄存器读取值，然后向另一个寄存器写入值,因此寄存器组需要有两个读取端口和一个写入端口。这里采用先读后写的方式，通过一个转发来实现数据的有效性，合理利用时间，使 id 阶段在完成读寄存器之后的操作更有效率。


- gpr的信号线一览

分组          | 信号名    | 信号类型 | 数据类型 | 位宽     | 含义
:------:      | :------:  | :------: | :------: | :------: | :------:
时钟与复位    | clk       | 输入信号 | wire     | 1        | 时钟
时钟与复位    | reset     | 输入信号 | wire     | 1        | 异步复位
读取端口 0    | rd_addr_0 | 输入信号 | wire     | 5        | 读取的地址
读取端口 0    | rd_data_0 | 输出信号 | wire     | 32       | 读取的数据
读取端口 1    | rd_addr_1 | 输入信号 | wire     | 5        | 读取的地址
读取端口 1    | rd_data_1 | 输出信号 | wire     | 32       | 读取的数据
写入端口      | we_       | 输入信号 | wire     | 1        | 写入有效信号
写入端口      | wr_addr   | 输入信号 | wire     | 32       | 写入的地址
写入端口      | wr_data   | 输入信号 | wire     | 32       | 写入的数据
内部信号	  | data_0_tmp| 内部信号 | wire     | 32       | 临时读取的数据
内部信号	  | data_1_tmp| 内部信号 | wire     | 32       | 临时读取的数据
内部信号      | gpr       | 内部信号 | reg      | 32x32    | 寄存器序列
内部信号      | i         | 内部信号 | integer  | 32       | 初始化用迭代器

- 代码详解(gpr.v)

```
	// 零号寄存器的值为 0，不会改变。

	assign rd_data_0 = (rd_addr_0 != 0) ? rd_data_0_tmp : 0;
    assign rd_data_1 = (rd_addr_1 != 0) ? rd_data_1_tmp : 0;

    /********** 读取访问 (Write After Read) **********/

    // 读取端口 0
    assign rd_data_0 = ((we_ == `ENABLE_) && (wr_addr == rd_addr_0)) ? wr_data : 
                        gpr[rd_addr_0];

    // 读取端口 1
    assign rd_data_1 = ((we_ == `ENABLE_) && (wr_addr == rd_addr_1)) ? wr_data : 
                        gpr[rd_addr_1];
   
    /********** 写入访问 **********/
    always @ (posedge clk or `RESET_EDGE reset) 
        begin
            if (reset == `RESET_ENABLE) 
                begin 
                    /* 异步复位 */
                    for (i = 0; i < `REG_NUM; i = i + 1) 
                        begin
                            gpr[i]  <= #1 `WORD_DATA_W'h0;
                        end
                end 
        else 
            begin
                /* 写入访问 */
                if (we_ == `ENABLE_)
                    begin 
                        gpr[wr_addr] <= #1 wr_data;
                    end
            end
        end
```

#### [1] 读取访问 
如果在读取的同时对相同地址进行写入操作，则直接将写入的数据输出。当写入有效信号（we_）有效，并且写入地址（wr_addr）和读取地址（rd_addr_0 或 rd_addr_1）一致时，写入的数据（wr_data）输出到输出数据（rd_data_0 或 rd_data_1）。
#### [2] 异步复位
全部寄存器的值初始化为 0。使用 for 语句遍历所有寄存器进行初始化操作。
#### [3] 写入访问
当写入有效信号（we_）有效时，向指定的写入地址（wr_addr）写入数据（wr_data）。


###**Testbench**
首先保证通用寄存器的写入和读取（写入和读取不是相同的寄存器），之后再检测转发部件的可用性（写入和读取操作发生在相同的寄存器中）。

**输入输出信号**

| rd_addr_0 | rd_addr_1 | we_       | wr_addr   | wr_data   | rd_data_0 | rd_data_1 |
| :------:  | :------:  | :------:  | :------:  | :------:  | :------:  | :------:  |
| 0x5       | 0x6       | `ENABLE   | 0x4       | 0x21      | 0x0       | 0x0       |
| 0x5       | 0x6       | `ENABLE   | 0x1       | 0x12      | 0x0       | 0x0       |
| 0x4       | 0x1       | `DISABLE  | 0x2       | 0x18      | 0x21      | 0x12      |
| 0x1       | 0x2       | `ENABLE   | 0x0       | 0x7       | 0x12      | 0x0       |
| 0x0       | 0x2       | `ENABLE   | 0X4       | 0X17      | 0X0       | 0X0       |
| 0x4       | 0x3       | `ENABLE   | 0x3       | 0x66      | 0x17      | 0x66      |
| 0x3       | 0x1       | `DISABLE  | 0x1       | 0x66      | 0x66      | 0x12      |

//1. 在 4 号寄存器中写入 21，在 5 号寄存器中读取数据 0，在 6 号寄存器中读取数据 0；
//2. 在 1 号寄存器中写入 12，在 5 号寄存器中读取数据 0，在 6 号寄存器中读取数据 0；
//3. 在 2 号寄存器中写入 18（无效），在 4 号寄存器中读取数据 21，在 1 号寄存器中读取数据 12；
//4. 在 0 号寄存器中写入 7，在 1 号寄存器中读取数据 12，在 2 号寄存器中读取数据 0；
//5. 在 4 号寄存器中写入 17，在 0 号寄存器中读取数据 0，在 2 号寄存器中读取数据 0；
//5. 在 3 号寄存器中写入 66，在 0 号寄存器中读取数据 17，在 3 号寄存器中读取数据 66；
//6. 在 1 号寄存器中写入 34（无效），在 3 号寄存器中读取数据 66，在 1 号寄存器中读取数据 12； 


- 代码详解(gpr.v)

```
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
			$readmemb("example.tv",test_vectors);
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
```
本测试程序采用带测试向量的测试方法，在进行测试时，测试程序先从文件中读取测试向量，再对被测模块进行测试。只要将接口和测试向量进行修改，即可测试不同的模块。