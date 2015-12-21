/* 
 -- ============================================================================
 -- FILE NAME : if_reg.v
 -- DESCRIPTION : IF/ID 流水线寄存器的实现
 -- ----------------------------------------------------------------------------
 -- Date : 2015/12/8                       Coding_by : kippy
 -- ============================================================================
*/

/*通用头文件*/
`include "stddef.h"

/*模块头文件*/
`include "isa.h"

module if_reg(input  clk,               // 时钟
              input  reset,             // 异步复位
              input  stall,             // 延迟
              input  flush,             // 刷新
              input  br_taken,          // 分支成立
              input  [29:0] new_pc,     // 新程序计数器值
              input  [29:0] br_addr,    // 分支目标地址
              input  [31:0] insn,       // 读取的指令
              output reg[29:0] if_pc,   // 程序计数器
              output reg[31:0] if_insn, // 指令
              output reg if_en          // 流水线数据有效标志位
              ); 

always @(posedge clk)
    begin
          if (reset == `ENABLE_)
              begin
    /********************异步复位********************/
                  if_pc = #1 30'b0;                    // 初始化PC为全零
                  if_insn = #1 `ISA_NOP;               // 初始化指令为空
                  if_en = #1 `DISABLE;                 // 初始化取指使能位为无效
              end
          else
            begin
    /*************更新流水线寄存器***************/
                if (stall == `DISABLE)
                    begin
                      if (flush == `ENABLE)                
                      //刷新
                          begin
                              if_pc = #1 new_pc;       // 更新 PC 为新程序计数器值
                              if_insn = #1 `ISA_NOP;   // 设置读取的指令为空
                              if_en = #1 `DISABLE;     // 设置取指使能位为无效
                          end 
                      else if (br_taken == `ENABLE)
                          //分支成立
                          begin 
                              if_pc = #1 br_addr;      // 更新 PC 为分支目标地址
                              if_insn = #1 insn;       // 设置对应地址的指令为读取的指令
                              if_en = #1 `ENABLE;      // 设置取指使能位为有效
                         end
                      else                                     
                          /*************下一条地址***************/
                          begin
                              if_pc = #1 if_pc + 1'd1; // 更新 PC 为下一条地址
                              if_insn = #1 insn;       // 设置对应地址的指令为读取的指令
                              if_en = #1 `ENABLE;      // 设置取指使能位为有效
                          end
                    end
        end
    end
endmodule
