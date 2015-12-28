/*
 -- ============================================================================
 -- FILE NAME	: timer.v
 -- DESCRIPTION : 定时器
 -- ----------------------------------------------------------------------------
 -- Date:2015/12/17		    
 -- ============================================================================
*/

/********** 通用头文件 **********/
`include "stddef.h"

/********** 模块头文件 **********/
`include "timer.h"

/********** 模块 **********/
module timer (
	/********** 时钟与复位 **********/
	input  wire					clk,	   // 时钟
	input  wire					reset,	   // 异步复位
	/********** 总线接口 **********/
	input  wire					cs_,	   // 片选信号
	input  wire					as_,	   // 地址选通
	input  wire					rw,	   // Read / Write
	input  wire [`TIMER_ADDR_BUS]                   addr,	   // 地址
	input  wire [`WordDataBus]	                wr_data,   // 写数据
	output reg  [`WordDataBus]	                rd_data,   // 读取数据
	output reg					rdy_,	   // 就绪信号
	/********** 中断输出 **********/
	output reg					irq	   // 中断请求（控制寄存器 1）
);

	/********** 控制寄存器 **********/
	// 控制寄存器 0 : 控制
	reg						mode;	   // 模式
	reg						start;	   // 起始位
	// 控制寄存器 2 : 最大值
	reg [`WordDataBus]			        expr_val;  // 最大值
	// 控制寄存器 3 : 计数器
	reg [`WordDataBus]			        counter;   // 计数器

	/********** 计时完成标志位 **********/
	wire expr_flag = ((start == `ENABLE) && (counter == expr_val)) ? `ENABLE : `DISABLE;

	/********** 定时器控制 **********/
	always @(posedge clk or negedge reset) 
	begin
		if (reset == `ENABLE_) 
			begin
				/* 异步复位 */
				rd_data	 <= #1 `WORD_DATA_W'h0;
				rdy_	 <= #1 `DISABLE_;
				start	 <= #1 `DISABLE;
				mode	 <= #1 `TIMER_MODE_ONE_SHOT;
				irq	 <= #1 `DISABLE;
				expr_val <= #1 `WORD_DATA_W'h0;
				counter	 <= #1 `WORD_DATA_W'h0;
			end 
		else 
			begin
				/* 准备就续绪 */
				if ((cs_ == `ENABLE_) && (as_ == `ENABLE_)) 
					begin
						rdy_  <= #1 `ENABLE_;
					end 
				else 
					begin
						rdy_  <= #1 `DISABLE_;
					end
				/* 读访问 */
				if ((cs_ == `ENABLE_) && (as_ == `ENABLE_) && (rw == `READ)) 
					begin
						case (addr)
							`TIMER_ADDR_CTRL	: 
								begin // 控制寄存器 0
									rd_data	 <= #1 {{`WORD_DATA_W-2{1'b0}}, mode, start};
								end
							`TIMER_ADDR_INTR	: 
								begin // 控制寄存器 1
									rd_data	 <= #1 {{`WORD_DATA_W-1{1'b0}}, irq};
								end
							`TIMER_ADDR_EXPR	: 
								begin // 控制寄存器 2
									rd_data	 <= #1 expr_val;
								end
							`TIMER_ADDR_COUNTER : 
								begin // 控制寄存器 3
									rd_data	 <= #1 counter;
								end
						endcase
					end 
				else 
					begin
						rd_data  <= #1 `WORD_DATA_W'h0;
					end
				/* 写访问 */
				// 控制寄存器 0
				if ((cs_ == `ENABLE_) && (as_ == `ENABLE_) && 
					(rw == `WRITE) && (addr == `TIMER_ADDR_CTRL)) 
					begin
						start  <= #1 wr_data[`TIMER_START_LOC];
						mode   <= #1 wr_data[`TIMER_MODE_LOC];
					end 
				else if ((expr_flag == `ENABLE)	 &&
							 (mode == `TIMER_MODE_ONE_SHOT)) 
					begin
					        start  <= #1 `DISABLE;
					end
				// 控制寄存器 1
				if (expr_flag == `ENABLE) 
					begin
						irq  <= #1 `ENABLE;
					end 
				else if ((cs_ == `ENABLE_) && (as_ == `ENABLE_) && 
							 (rw == `WRITE) && (addr ==	 `TIMER_ADDR_INTR)) 
					begin
						irq  <= #1 wr_data[`TimerIrqLoc];
					end
				// 控制寄存器 2
				if ((cs_ == `ENABLE_) && (as_ == `ENABLE_) && 
					(rw == `WRITE) && (addr == `TIMER_ADDR_EXPR)) 
					begin
						expr_val  <= #1 wr_data;
					end
				// 控制寄存器 3
				if ((cs_ == `ENABLE_) && (as_ == `ENABLE_) && 
					(rw == `WRITE) && (addr == `TIMER_ADDR_COUNTER)) 
					begin
						counter	 <= #1 wr_data;
					end 
				else if (expr_flag == `ENABLE) 
					begin
						counter	 <= #1 `WORD_DATA_W'h0;
					end 
				else if (start == `ENABLE) 
					begin
						counter	 <= #1 counter + `WORD_DATA_W'b1;
					end
			end
	end

endmodule
