/* 
  -- ============================================================================ 
  -- FILE NAME	: timer.h 
  -- DESCRIPTION : 定时器 
  -- ---------------------------------------------------------------------------- 
  -- Date：2015/12/17		  Coding_by：kippy
  -- ============================================================================ 
*/ 
 
 
 `ifndef __TIMER_HEADER__ 
 	`define __TIMER_HEADER__             // 定时器头文件
 
 
 	/********** 总线 **********/ 
 	`define TIMER_ADDR_W         2       // 计时器地址宽度 
 	`define TIMER_ADDR_BUS       1:0     // 计时器地址总线 
 	`define TIMER_ADDR_LOC       1:0     // 计时器地址位置 
 	/********** 地址选择 **********/ 
 	`define TIMER_ADDR_CTRL      2'h0    // 控制寄存器 0 ：控制 
 	`define TIMER_ADDR_INTR      2'h1    // 控制寄存器 1 ：中断 
 	`define TIMER_ADDR_EXPR      2'h2    // 控制寄存器 2 ：最大值 
 	`define TIMER_ADDR_COUNTER   2'h3    // 控制寄存器 3 ：计数器  	
 	/********** 处理 **********/ 
 	// 控制寄存器 0 ：控制  
 	`define TIMER_START_LOC      0       // 起始位的位置 
 	`define TIMER_MODE_LOC       1       // 模式位的位置 
 	`define TIMER_MODE_ONE_SHOT  1'b0    // 模式 ：单次定时器 
 	`define TIMER_MODE_PERIODIC  1'b1    // 模式 ：循环定时器 
 	// 控制寄存器 1 ：中断 
 	`define TimerIrqLoc          0       // 中断位的位置
 	
 `endif 
