/******** 头文件 ********/
`include "stddef.h"
`include "cpu.h"
`include "bus.h"

/********** 内存访问控制模块 **********/
module mem_ctrl (
	/********** EX/MEM 流水线寄存器 **********/
	input wire [`MEM_OP_BUS]     ex_mem_op,      // 内存操作
	input wire [`WORD_DATA_BUS]  ex_mem_wr_data, // 内存写入数据
	input wire [`WORD_DATA_BUS]  ex_out,         // 处理结果
	/********** 内存访问接口 **********/
	input wire [`WORD_DATA_BUS]  rd_data,        // 读取的数据
	output wire [`WORD_ADDR_BUS] addr,           // 地址
	output reg                   as_,            // 地址选通
	output reg                   rw,             // 读/写
	output wire [`WORD_DATA_BUS] wr_data,        // 写入的数据
	/********** 内存访问  **********/
	output reg [`WORD_DATA_BUS]  out ,           // 内存访问结果
	output reg                   miss_align	     // 未对齐
);

	/********** 内部信号 **********/
  wire [`BYTE_OFFSET_BUS]      offset;		     // 字节偏移

	/********** 输出的赋值 **********/
	assign wr_data = ex_mem_wr_data;		         // 写入数据
	assign addr	   = ex_out[`WORD_ADDR_LOC];	   // 地址
	assign offset  = ex_out[`BYTE_OFFSET_LOC];   // 偏移

	/********** 内存访问的控制 **********/
	always @(*) begin
		/* 默认值 */
		miss_align = `DISABLE;
		out		     = `WORD_DATA_W'h0;
		as_		     = `DISABLE_;
		rw		     = `READ;
		/* 内存访问 */
		case (ex_mem_op)
			`MEM_OP_LDW : begin                      // 字读取
				/* 字节偏移的检测 */
				if (offset == `BYTE_OFFSET_WORD) begin // 对齐
					out			    = rd_data;
					as_		      = `ENABLE_;
				end else begin						   // 未对齐
					miss_align	= `ENABLE;
				end
			end
			  `MEM_OP_STW : begin                    // 字写入
				/* 字节偏移的检测 */
				if (offset == `BYTE_OFFSET_WORD) begin // 对齐
					rw		    	= `WRITE;
					as_		      = `ENABLE_;
				end else begin						             // 未对齐
					miss_align  = `ENABLE;
				end
			end
			default		: begin                        // 无内存访问
				out			      = ex_out;
			end
		endcase
	end

endmodule
