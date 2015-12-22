/* 
 -- ============================================================================
 -- FILE NAME : if_reg_test.v
 -- DESCRIPTION : 测试 if_reg 模块的正确性
 -- ----------------------------------------------------------------------------
 -- Date : 2015/12/21                       Coding_by : kippy
 -- ============================================================================
*/

/********** 时间规格 **********/
`timescale 1ns/1ps

/********** 通用头文件 **********/
`include "stddef.h"

/********** 模块头文件 **********/
`include "isa.h"

module if_reg_test;

    /********** 输入输出端口信号 **********/
    // 时钟 & 复位
    reg clk;                      // 时钟
    reg reset;                    // 异步复位
    // 输入信号
    reg stall;                    // 延迟
    reg flush;                    // 刷新
    reg br_taken;                 // 分支成立
    reg [`WORD_DATA_BUS] new_pc;  // 新程序计数器值
    reg [`WORD_DATA_BUS] br_addr; // 分支目标地址
    reg [`WORD_DATA_BUS] insn;    // 读取的指令
    // 输出信号
    wire[`WORD_DATA_BUS] if_pc;   // 程序计数器
    wire[`WORD_DATA_BUS] if_insn; // 指令
    wire if_en;                   // 流水线数据有效标志位

    /******** 定义仿真循环 ********/ 
    parameter     STEP = 10; 

    /********** 实例化测试模块 **********/
    if_reg if_reg(.clk      (clk),               // 时钟
                  .reset    (reset),             // 异步复位
                  .stall    (stall),             // 延迟
                  .flush    (flush),             // 刷新
                  .br_taken (br_taken),          // 分支成立
                  .new_pc   (new_pc),            // 新程序计数器值
                  .br_addr  (br_addr),           // 分支目标地址
                  .insn     (insn),              // 读取的指令
                  .if_pc    (if_pc),             // 程序计数器
                  .if_insn  (if_insn),           // 指令
                  .if_en    (if_en)              // 流水线数据有效标志位
                  ); 

    /********** 生成时钟 **********/
    always #(STEP / 2)
        begin
            clk <= ~clk;  
        end

    /********** 测试用例 **********/
    initial
    begin
        /************* 刷新 ***************/
        #0  
        begin
        clk <= `ENABLE;
        reset <= `ENABLE_;
        insn <= `WORD_DATA_W'h124;
        stall <= `DISABLE;
        flush <= `ENABLE;
        new_pc <= `WORD_DATA_W'h154;
        br_taken <= `DISABLE;
        br_addr <= `WORD_DATA_W'h100;
        end
        #(STEP * 3 / 4)
        #STEP 
        begin
            reset <= `DISABLE_;
        end
        #STEP 
        begin
            if (if_pc === 32'h154 & if_insn === `ISA_NOP & if_en === `DISABLE) 
                begin
                    $display ("Simulation of flush succeeded");      
                end
            else 
                begin
                    $display ("Simulation of flush failed");
                end
        end
        /************* 分支成立 ***************/
        #STEP
        begin
            insn <= `WORD_DATA_W'h124;
            stall <= `DISABLE;
            flush <= `DISABLE;
            new_pc <= `WORD_DATA_W'h154;
            br_taken <= `ENABLE;
            br_addr <= `WORD_DATA_W'h100;
        end
        #STEP
        begin
            if (if_pc === `WORD_DATA_W'h100 & if_insn === `WORD_DATA_W'h124 & if_en === `ENABLE) 
                begin
                    $display ("Simulation of branch succeeded");        
                end
            else 
                begin
                    $display ("Simulation of branch failed");
                end
        end
        /************* 下一条地址 ***************/
        #STEP
        begin
            insn <= `WORD_DATA_W'h124;
            stall <= `DISABLE;
            flush <= `DISABLE;
            new_pc <= `WORD_DATA_W'h154;
            br_taken <= `DISABLE;
            br_addr <= `WORD_DATA_W'h100;
        end
        #STEP
        begin
            if (if_pc === `WORD_DATA_W'h104 & if_insn === `WORD_DATA_W'h124 & if_en === `ENABLE) 
                begin
                    $display ("Simulation of next pc succeeded");        
                end
            else 
                begin
                    $display ("Simulation of next pc failed");
                end
        end
        #STEP
        begin
            $finish;
        end
    end     

    /********** 输出波形 **********/
    initial
        begin
            $dumpfile("if_reg.vcd");
            $dumpvars(0,if_reg);
        end
endmodule