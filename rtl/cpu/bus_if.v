`include "stddef.h"
`include "cpu.h"

/********** 模块 **********/
/********** 输入输出参数 **********/
module bus_if (
	/************* CPU接口 *************/
	input [29:0]      addr,        // 地址
	input             as_,         // 地址选通信号
	input             rw,          // 读／写
	input [31:0]      wr_data,     // 写入的数据
	output reg [31:0] rd_data,     // 读取的数据
	/************* SPM接口 *************/
	input [31:0]      spm_rd_data, // 读取的数据
	output [29:0]     spm_addr,    // 地址
	output reg        spm_as_,     // 地址选通信号
	output            spm_rw,      // 读／写
	output [31:0]     spm_wr_data  // 读取的数据
);

	/********** 内部信号 **********/
	reg [31:0]        rd_buf;		    // 读取的缓冲数据

	/********** 输出的赋值 **********/
	assign spm_addr	   = addr;
	assign spm_rw	   = rw;
	assign spm_wr_data = wr_data;

	/********* 内存访问控制 *********/
	always @(*) begin
	    /* 默认值*/
	    rd_data	 = 32'h0;
	    spm_as_	 = `DISABLE_;
		/* 内存访问 */
	    if (as_ == `ENABLE_) begin
	        spm_as_	 = `ENABLE_;
		    if (rw == `READ) begin  // 读取访问
				rd_data	 = spm_rd_data;
		    end
	    end
	end

endmodule
