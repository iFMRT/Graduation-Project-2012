/*
 -- ============================================================================
 -- FILE NAME	: cpu.h
 -- DESCRIPTION : CPU 头文件
 -- ----------------------------------------------------------------------------
 -- Date:2015/12/15		  Coding_by:kippy
 -- ============================================================================
*/

 `ifndef __CPU_HEADER__
	`define __CPU_HEADER__	// インクルードガード

//------------------------------------------------------------------------------
// Operation
//------------------------------------------------------------------------------
  /********** 寄存器 **********/
  `define REG_NUM				 32	  // 寄存器数
  `define REG_ADDR_W			 5	  // 寄存器地址宽度
  `define REG_ADDR_BUS			 4:0  // 寄存器地址总线

  /********** 内存操作码 **********/
  // 总线
  `define MEM_OP_W			 2	  // 内存操作码
  `define MEM_OP_BUS			 1:0  // 内存操作码总线
  // 操作码
  `define MEM_OP_NOP			 2'h0 // No Operation
	`define MEM_OP_LDW			 2'h1 // 字读取
  `define MEM_OP_STW			 2'h2 // 字写入

	// 总线接口状态
	`define BUS_IF_STATE_IDLE	 2'h0  // 空闲
	`define BUS_IF_STATE_REQ	 2'h1  // 请求总线
	`define BUS_IF_STATE_ACCESS	 2'h2  // 访问总线
	`define BUS_IF_STATE_STALL	 2'h3  // 停顿

`endif
