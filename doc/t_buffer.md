# 目标地址缓存器模块

目标地址缓存器是分支预测器中比较重要的一部分，其主要工作是当分支发生时，把分支目标地址进行保存，等下次再次遇到同一 PC 并且分支预测器再次预测发生后，提供之前所保存的分支目标地址，作为下一 PC。本次设计的目标地址缓存器包括了四个 RAM 用来保存分支目标地址及 TAG，一个 RAM 作为最近最少使用算法计数器，用以控制要更新的模块，另外还有一个刷新模块，负责控制对目标缓存器中五个 RAM 的刷新逻辑。最后是顶层模块，把我们的分支目标地址缓存器的逻辑进行封装。

+ 信号线一览

信号名 		|信号类型 	|数据类型	|位宽 		|含义
:------		|:------	|:------	|:------	|:------
  clk		|输入信号	| wire 		| 1 		|时钟信号
  pc 		|输入信号	| wire 		| 32 		|要写入或者读出的 PC 值
  is_hit 	|输入信号	| wire 		| 1 		|写入使能信号
  tar_addr 	|输入信号	| wire 		| 32 		|写入的目标地址
  tar_data 	|输出信号	| reg 		| 32 		|输出的目标地址
  tar_en 	|输出信号	| reg 		| 1  		|目标地址有效标志

> 注：这里的信号名介绍没有涉及到内部信号，内部信号在之后的子模块信号一览中会有说明。

- 代码详解

1、 RAM 和 FLUSH_RAM 的实例化部分

```
	t_ram #(54,9,512) t_ram0( 								// block0
		.clk 			(clk),
		.ram_addr		(ram_addr),
		.wr 			(block0_wr),
		.wd 			(write_data),
		.rd 			(block0_data)
		);

	t_ram #(54,9,512) t_ram1( 								// block1
		.clk 			(clk),
		.ram_addr		(ram_addr),
		.wr				(block1_wr),
		.wd 			(write_data),
		.rd 			(block1_data)
		);

	t_ram #(54,9,512) t_ram2( 								// block2
		.clk 			(clk),
		.ram_addr		(ram_addr),
		.wr				(block2_wr),
		.wd 			(write_data),
		.rd 			(block2_data)
		);

	t_ram #(54,9,512) t_ram3( 								// block3
		.clk 			(clk),
		.ram_addr		(ram_addr),
		.wr 			(block3_wr),
		.wd 			(write_data),
		.rd 		 	(block3_data)
		);

	t_ram #(3,9,512) plru_ram( 								// clock plru
		.clk 			(clk),
		.ram_addr		(ram_addr),
		.wr 			(we_plru),
		.wd 			(write_plru),
		.rd 	 		(plru_data)
		);
	assign 	we_plru = ~is_hit;

	flush_ram	flush_ram( 									// ram flush contral unit
		/****** input *******/
		.is_hit			(is_hit),
		.pc				(pc),
		.tar_addr		(tar_addr),
		.block0_tag		(block0_tag),
		.block1_tag		(block1_tag),
		.block2_tag		(block2_tag),
		.block3_tag		(block3_tag),
		.plru_data		(plru_data),

		/****** output ******/
		.ram_addr		(ram_addr),
		.write_data		(write_data),
		.write_plru 	(write_plru),
		.block0_wr		(block0_wr),
		.block1_wr		(block1_wr),
		.block2_wr		(block2_wr),
		.block3_wr		(block3_wr)
		);

```

这一部分主要是对我们的 RAM 和 FLUSH_RAM 的实例化，其中，实例化出的五个 RAM 模块，前四个是作为分支目标地址缓存（9位地址，每个存储单元大小为54位，共有512个存储空间），最后一个用来缓存最近最少使用算法的计数（9位地址，每个存储单元大小为3位，共有512个存储空间），最后实例化的是 RAM_FLUSH 模块，此模块作为本次设计的分支目标地址缓存器的刷新逻辑。关于 RAM 和 FLUSH_RAM 的内部逻辑，在后面的子模块部分会有详细说明。

2、 分支目标缓存器的输出部分

```
	always @(*) begin

		case (tag)
			block0_tag:begin 						// if block0 tag == tag,output block0 
				tar_data = block0_tar;
				tar_en = block0_en;
			end

			block1_tag:begin 						// if block1 tag == tag,output block1
				tar_data = block1_tar;
				tar_en = block1_en;
			end

			block2_tag:begin 						// if block2 tag == tag,output block2
				tar_data = block2_tar;
				tar_en = block2_en;
			end

			block3_tag:begin 						// if block3 tag == tag,output block3
				tar_data = block3_tar;
				tar_en = block3_en;
			end

			default:begin
				tar_data = 32'b0;
				tar_en = `DISABLE;
			end
		endcase
	end
```

这一部分是分支目标缓存器在分支预测分支发生时，输出的分支目标地址，作为下一 PC，首先要根据当前 PC 的 10 到 2 位来确定取出数据的地址，然后通过校对 TAG 从正确的模块中取值，同时输入地址有效位，标识输入的目标地址有效。如若没有匹配的数据，则输入 32 位的 0，并将有效标志置为 0，标识该目标地址无效。

## RAM 的设计

这里设计的是一个比较通用的 RAM，地址空间、寻址能力和存储空间的大小都作为活动的参数，可以被任意一个需要 RAM 的模块调用并实例化。这里的 RAM 设计为单端口，输入地址后，如果写入使能位有效，则对相应的地址进行写入，若写入使能位无效，则输出相应地址对应的存储空间中的数据。

+ 信号线一览

信号名         |信号类型  |数据类型   |位宽          |含义
:------ 	   |:------   |:------    |:------       |:------
 clk           |输入信号  | wire 	  | 1 		     | 时钟信号
 ram_addr      |输入信号  | wire      | n            | 读出地址
 wr 		   |输入信号  | wire 	  | 1  	         | 写入标志信号
 wd  		   |输入信号  | wire 	  | x  	 	     | 写入的数据
 rd 		   |输出信号  | wire 	  | x  		     | 读出的数据
 ram           |内部信号  | reg       | x * 2的n次方 | RAM

 - 代码详解

1、 读取数据

```
	assign rd = (wr == `ENBALE) ? wd : ram[rd_addr];

```

读取数据是不需要时钟信号的，在 RAM 的读取端口，任何时间都输出对应于输出地址的数据，在有数据写入时，则直接输出写入的数据。

2、 写入数据

```
	/****** 	write data to ram 		******/
	always @(posedge clk && wr == `ENABLE) begin
		ram [wr_addr] <= wd;
	end
```

时钟上升沿时，如果写入信号有效，则在写入地址对应的存储空间内写入数据。

+ 测试用例如下表

读地址   | 写有效信号 | 写入的数据 | 读出的数据 | 测试方向
:------  | :------    | :------    | :------    | :------
2        | 0          | 3          | x          | 不写入时，读出 x
4        | 1          | 4          | 4          | 在 4 存储空间中写入 4
2        | 1          | 3          | 3          | 在 2 存储空间中写入 3
4        | 0          | 3          | 4          | 在 4 存储空间中的数据保存成功
4        | 0          | 5          | 4          | 写信号无效时更新失败
4        | 1          | 6          | 6          | 更新 4 存储空间的内容
4 		 | 0 		  | 0 		   | 6  		| 更新成功

用以上测试用例测试模块通过，证明该模块可以实现预期功能。

## FLUSH_RAM 模块设计

FLUSH_RAM 作为分支目标缓存器的刷新逻辑而独立为一个子模块，其作用是有效刷新目标地址缓存器。当分支预测不正确而产生刷新的时候，分支预测器会给目标缓存器一个更新信号，更新信号有效时，目标地址缓存器开始更新相应的 RAM，本次设计中共有 4 个存储目标地址的 RAM，都以 PC 的 10 到 2 位作为索引，同时以 PC 的高 21 位作为 TAG，存放于 RAM 中，这里如果检测到四个 RAM 中的某个 TAG 与该 PC 相匹配，则更新该 RAM 中的内容，如没有匹配，则取出 PLRU 中的数据进行检测，用最近最少使用算法进行更新。

+ 信号线一览


信号名         |信号类型  |数据类型   |位宽		|含义
:------ 	   |:------   |:------    |:------  |:------
 is_hit        |输入信号  | wire 	  | 1 		|缓存器更新标志
 pc 	       |输入信号  | wire      | 32      |PC
 tar_addr	   |输入信号  | wire 	  | 9       |写入的目标地址
 block0_tag	   |输入信号  | wire 	  | 21      |RAM0 的 TAG 位
 block1_tag    |输入信号  | wire 	  | 21      |RAM1 的 TAG 位
 block2_tag    |输入信号  | wire      | 21		|RAM2 的 TAG 位
 block3_tag    |输入信号  | wire	  | 21 		|RAM3 的 TAG 位
 plru_data     |输入信号  | wire	  |	3 		|读到的 PLRU 值
 ram_addr 	   |输出信号  | wire	  | 9 		|访问 RAM 地址
 write_data    |输出信号  | wire	  |	54 		|写入 RAM 的数据
 write_plru    |输出信号  | wire	  |	3 		|写入 PLRU 的数据
 block0_wr     |输出信号  | wire	  |	1 		|BLOCK0 写入信号
 block1_wr	   |输出信号  | wire	  |	1 		|BLOCK1 写入信号
 block2_wr	   |输出信号  | wire	  |	1 		|BLOCK2 写入信号
 block3_wr 	   |输出信号  | wire	  |	1 		|BLOCK3 写入信号

- 代码详解

1、 写入地址和数据

```
	assign ram_addr 	= 	pc[`PcAddress];
	assign write_data 	= 	{pc[`PcTag],tar_addr,1'b1};

```

对 RAM 的读写地址恒为 PC 的 10 到 2 位，写入 RAM 的值为 54 比特位，其中高 21 位为 TAG 位，中间 32 位为分支目标地址位，最后 1 位标识分支目标地址是否有效。

2、 更新逻辑

```
	always @(pc or is_hit) begin
		block0_wr = `DISABLE;
		block1_wr = `DISABLE;
		block2_wr = `DISABLE;
		block3_wr = `DISABLE;

		if(is_hit == `DISABLE) begin

			case (pc [`PcTag])
				block0_tag:begin 								// update block0
					write_plru = {plru_data[2],2'b11};			// change the plru to x11
					block0_wr = `ENABLE;						// block0 write is enable
				end

				block1_tag:begin 								// update block1
					write_plru = {plru_data[2],2'b01};			// change the plru to x01
					block1_wr = `ENABLE;						// block1 write is enable
				end

				block2_tag:begin 								// update block2
					write_plru = {1'b1,plru_data[1],1'b0};		// change the plru to 1x0
					block2_wr = `ENABLE;						// block2 write is enable
				end

				block3_tag:begin 								// update block3
					write_plru = {1'b0,plru_data[1],1'b0};		// change the plru to 0x0
					block3_wr = `ENABLE;						// block3 write is enable

				end

				default:begin

					if (plru_data[0] === 1'b1) begin 				// update block2 or block3

						if (plru_data[2] === 1'b1) begin 			// update block3
							write_plru = {1'b0,plru_data[1],1'b0};	// change the plru to 0x0
							block3_wr = `ENABLE;					// block3 write is enable
						end else begin 								// update block2
							write_plru = {1'b1,plru_data[1],1'b0};	// change the plru to 1x0
							block2_wr = `ENABLE;					// block2 write is enable
						end
						
					end else begin 								// update block0 or block1

						if (plru_data[1] === 1'b1) begin 		// update block1
							write_plru = {plru_data[2],2'b01};	// change the plru to x01
							block1_wr = `ENABLE;				// block1 write is enable
						end else begin 							// update block0
							write_plru = {plru_data[2],2'b11};	// change the plru to x11
							block0_wr = `ENABLE;				// block0 write is enable
						end

					end

				end
			endcase
		end
	end
```

当 PC 值发生改变时，如果更新标志位有效，检测 PC 的高 21 位是否与某个 RAM 的 TAG 位相同，如果相同，则更新该 RAM 的相应内容，同时要更新 PLRU RAM 的内容。如果 4 个 RAM 的 TAG 都不匹配，则开始检测 PLRU，用 LRU （最近最少使用）算法选择更新哪个 RAM，同时也要更新 PLRU 计数的内容。