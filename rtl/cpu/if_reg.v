/******************************************************************************
 -- FILE NAME	: if_reg.v
 -- DESCRIPTION : IF/ID 流水线寄存器的实现
 -- ----------------------------------------------------------------------------
 -- Date : 2015/12/8                       Wrier : kippy
 ******************************************************************************/
`include "stddef.h"
`include "isa.h"
module if_reg(input  reset,clk,stall,flush,br_taken
              input  [29:0] new_pc,br_addr,
              input  [31:0] insn,
              output [29:0] if_pc,
              output [31:0] if_insn,
              output if_en);

always @(posedge clk)
    begin
          if (reset == 1)
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
