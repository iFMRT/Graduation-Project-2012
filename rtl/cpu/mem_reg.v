`include "stddef.h"
`include "cpu.h"

/********** MEM阶段寄存器模块 **********/
module mem_reg (
	  /********** 时钟& 复位 **********/
	  input wire                  clk,          // 时钟
	  input wire                  reset,        // 异步复位
	  /********** 内存访问结果 **********/
	  input wire [`WORD_DATA_BUS] out,          // 内存访问结果
	  input wire                  miss_align,   // 未对齐
	  /********** EX/MEM 流水线寄存器 **********/
	  input wire [`REG_ADDR_BUS]    ex_dst_addr,  // 通用寄存器写入地址
	  input wire                  ex_gpr_we_,   // 通用寄存器写入有效
	  /********** MEM/WB 流水线寄存器 **********/
	  output reg [`REG_ADDR_BUS]    mem_dst_addr, // 通用寄存器写入地址
	  output reg                  mem_gpr_we_,  // 通用寄存器写入有效
	  output reg [`WORD_DATA_BUS] mem_out		    //　处理结果
);

	 /********** 流水线寄存器 **********/
	  always @(posedge clk or negedge reset) begin
	     if (reset == `ENABLE) begin
			     /* 异步复位 */
			     mem_dst_addr <= #1 `REG_ADDR_W'h0;
			     mem_gpr_we_  <= #1 `DISABLE_;
			     mem_out	  <= #1 `WORD_DATA_W'h0;
		   end else begin
		       /* 流水线寄存器的更新 */
				   if (miss_align == `ENABLE) begin    // 未对齐异常
					     mem_dst_addr <= #1 `REG_ADDR_W'h0;
					     mem_gpr_we_  <= #1 `DISABLE_;
					     mem_out	  <= #1 `WORD_DATA_W'h0;
				   end else begin							         // 下一个数据
					     mem_dst_addr <= #1 ex_dst_addr;
					     mem_gpr_we_  <= #1 ex_gpr_we_;
					     mem_out	  <= #1 out;
				   end
		   end
	 end

endmodule
