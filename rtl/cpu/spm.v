/*
 -- ============================================================================
 -- FILE NAME	: spm.v
 -- DESCRIPTION : spm RAM模块
 -- ----------------------------------------------------------------------------
    Date:2015/12/15
 -- ============================================================================
*/

/********** 通用头文件 **********/
`include "stddef.h"

/********** 模块 **********/
/********** 输入输出参数 **********/
module spm (
    input         clk,            // 时钟
    /********** 端口A : IF阶段 **********/
    input [11:0]  if_spm_addr,    // 地址
	  input         if_spm_as_,     // 地址选通
	  input         if_spm_rw,      // 读/写
	  input [31:0]  if_spm_wr_data, // 写入的数据
	  output [31:0] if_spm_rd_data, // 读取的数据
	/********** 端口B : MEM阶段 **********/
	  input [11:0]  mem_spm_addr,   // 地址
	  input         mem_spm_as_,    // 地址选通
	  input         mem_spm_rw,     // 读/写
	  input [31:0]  mem_spm_wr_data,// 写入的数据
	  output [31:0] mem_spm_rd_data // 读取的数据SS
);

    /********** 内部信号 **********/
    reg           wea;	          // 端口 A 写入有效
    reg           web;	          // 端口 B 写入有效

    /********** 写入有效信号的生成 **********/
    always @(*) begin
	      /* 端口A 写入有效信号的生成 */
	      if ((if_spm_as_ == `ENABLE_) && (if_spm_rw == `WRITE)) begin
		        wea = `ENABLE;	      // 写入有效
	      end else begin
		        wea = `DISABLE;       // 写入无效
	      end
	      /* 端口B 写入有效信号的生成 */
	      if ((mem_spm_as_ == `ENABLE_) && (mem_spm_rw == `WRITE)) begin
		        web = `ENABLE;	      // 写入有效
	      end else begin
		        web = `DISABLE;       // 写入无效
	      end
	  end
endmodule
