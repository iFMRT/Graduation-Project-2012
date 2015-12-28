// ----------------------------------------------------------------------------
// FILE NAME	: gpr.v
// DESCRIPTION :  general purpose register module of pipeline
// AUTHOR : cjh
// TIME : 2015-12-18 09:23:28
// 
// -----------------------------------------------------------------------------

`include "stddef.h"
`include "cpu.h"

/********** 通用寄存器 **********/
module gpr (
	/********** 时钟与复位 **********/
	input  wire				   		clk,				// 时钟
	input  wire				   		reset,			   	// 异步复位
	/********** 读取端口 0 **********/
	input  wire [`REG_ADDR_BUS]  	rd_addr_0,		   	// 读取的地址
	output wire [`WORD_DATA_BUS] 	rd_data_0,		   	// 读取的数据
	/********** 读取端口 1 **********/
	input  wire [`REG_ADDR_BUS]		rd_addr_1,		   	// 读取的地址
	output wire [`WORD_DATA_BUS] 	rd_data_1,		   	// 读取的数据
	/********** 写入端口 **********/
	input  wire				   		we_,				// 写入有效信号
	input  wire [`REG_ADDR_BUS]		wr_addr,			// 写入的地址
	input  wire [`WORD_DATA_BUS] 	wr_data				// 写入的数据
);

	/********** 内部信号 **********/
	reg [`WORD_DATA_BUS]		   	gpr [`REG_LIST]; 		// 寄存器序列
	integer							i;					// 初始化用迭代器

	/********** 读取访问 (先读后写) **********/
	// 读取端口 0
	assign rd_data_0 = ((we_ == `ENABLE_) && (wr_addr == rd_addr_0)) ? wr_data : gpr[rd_addr_0];
	// 读取端口 1
	assign rd_data_1 = ((we_ == `ENABLE_) && (wr_addr == rd_addr_1)) ? wr_data : gpr[rd_addr_1];
   
	/********** 写入访问 **********/
	always @ (posedge clk or reset) 
		begin
			if (reset == `ENABLE) 
				begin 
					/* 异步复位 */
					for (i = 0; i < 32; i = i + 1) 
						begin
							gpr[i]	<= #1 32'b0;
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

endmodule 