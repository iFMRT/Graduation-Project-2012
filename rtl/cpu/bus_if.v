/*
 -- ============================================================================
 -- FILE NAME	: bus_if.v
 -- DESCRIPTION : 内存访问控制
 -- ----------------------------------------------------------------------------
 -- Date:2015/12/15		  Coding_by:kippy
 -- ============================================================================
*/

/********** 通用头文件 **********/
`include "stddef.h"

/********** 模块头文件 **********/
`include "cpu.h"

/********** 模块 **********/
/********** 输入输出参数 **********/
module bus_if (	input  			 clk,			// 时钟
				input  			 reset,		   	// 异步复位
				/********** 流水线控制信号 **********/
				input  			 stall,		   	// 停顿信号
				input  			 flush,		   	// 刷新信号
				output reg		 busy,		   	// 总线忙信号
				/************* CPU接口 *************/
				input      [29:0]addr,		   	// 地址
				input  			 as_,			// 地址选通信号
				input  			 rw,			// 读／写
				input      [31:0]wr_data,		// 写入的数据
				output reg [31:0]rd_data,		// 读取的数据
				/************* SPM接口 *************/
				input      [31:0]spm_rd_data,	// 读取的数据
				output     [29:0]spm_addr,	   	// 地址
				output reg		 spm_as_,		// 地址选通信号
				output 			 spm_rw,		// 读／写
				output     [31:0]spm_wr_data,	// 读取的数据
				/************* 总线接口 ************/
				input      [31:0]bus_rd_data,	// 读取的数据
				input  			 bus_rdy_,	    // 就绪
				input  			 bus_grnt_,	    // 许可
				output reg		 bus_req_,	    // 请求
				output reg [29:0]bus_addr,	    // 地址
				output reg		 bus_as_,		// 地址选通信号
				output reg		 bus_rw,		// 读／写
				output reg [31:0]bus_wr_data	// 写入的数据				
				);

	/********** 内部信号 **********/
	reg	 [1:0] state;		   // 总线接口状态
	reg	 [31:0]rd_buf;		   // 读取的缓冲数据
//	wire [2:0] s_index;	       // 总线从属索引

	/********** 生成总线从属索引 *********/
  //assign s_index	   = addr[`BusSlaveIndexLoc]; //BusSlaveIndexLoc:总线从属索引位置

	/********** 输出的赋值 **********/
	assign spm_addr	   = addr;
	assign spm_rw	   = rw;
	assign spm_wr_data = wr_data;
						 
	/********* 内存访问控制 *********/
	always @(*) begin
		/* 默认值*/
		rd_data	 = 32'h0;
		spm_as_	 = `DISABLE_;
		busy	 = `DISABLE;
		/* 总线接口的状态 */
		case (state)
		    /*     空闲      */
			`BUS_IF_STATE_IDLE:  
				begin 
					/* 内存访问 */
					if ((flush == `DISABLE) && (as_ == `ENABLE_)) 
						begin
							/* 选择访问目标 */
							if (s_index == `BUS_SLAVE_1) 
								begin // 访问SPM
									if (stall == `DISABLE) 
										begin // 检测延迟的发生
											spm_as_	 = `ENABLE_;
											if (rw == `READ) 
												begin // 读取访问
													rd_data	 = spm_rd_data;
												end
										end
								end 
							else 
								begin // 访问总线
									busy  = `ENABLE;
								end
						end
				end
			/*  请求总线   */
			`BUS_IF_STATE_REQ: 
				begin // 请求总线
					busy  = `ENABLE;
				end
			/*  访问总线   */
			`BUS_IF_STATE_ACCESS : 
				begin // 访问总线
					/* 等待就绪信号 */
					if (bus_rdy_ == `ENABLE_) 
						begin // 就绪信号有效
							if (rw == `READ) 
								begin // 读取访问
									rd_data	 = bus_rd_data;
								end
						end 
					else 
						begin // 就绪信号无效
							busy = `ENABLE;
						end
				end
            /*     停顿      */
			`BUS_IF_STATE_STALL	 : 
				begin // 停顿 
					if (rw == `READ) 
						begin // 读取访问
							rd_data  = rd_buf;
						end
				end
		endcase
	end

endmodule