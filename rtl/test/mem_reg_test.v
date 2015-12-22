/******** Time scale ********/
`timescale 1ns/1ps

/******** 头文件 ********/
`include "stddef.h"
`include "cpu.h"

/******** 测试模块 ********/
module mem_reg_test;
    /********** 时钟& 复位 **********/
    reg                  clk;          // 时钟
    reg                  reset;        // 异步复位
    /********** 内存访问结果 **********/
    reg [`WORD_DATA_BUS] out;          // 内存访问结果
    reg                  miss_align;   // 未对齐
    /********** EX/MEM 流水线寄存器 **********/
    reg [`REG_ADDR_BUS]  ex_dst_addr;  // 通用寄存器写入地址
    reg                  ex_gpr_we_;   // 通用寄存器写入有效
    /********** MEM/WB 流水线寄存器 **********/
    wire [`REG_ADDR_BUS]  mem_dst_addr;// 通用寄存器写入地址
    wire                  mem_gpr_we_; // 通用寄存器写入有效
    wire [`WORD_DATA_BUS] mem_out;       //　处理结果

    /******** 定义仿真循环 ********/
    parameter             STEP = 10;

    /******** 生成时钟 ********/
    always #(STEP / 2) begin
        clk <= ~clk;
    end

    /******** 实例化测试模块 ********/
    // /********** MEM 阶段流水线寄存器模块 **********/
    mem_reg mem_reg (
        .clk(clk),                   // 时钟
        .reset(reset),               // 异步复位
        /********** 内存访问结果 **********/
        .out(out),                   // 内存访问结果
        .miss_align(miss_align),     // 未对齐
        /********** EX/MEM 流水线寄存器 **********/
        .ex_dst_addr(ex_dst_addr),   // 通用寄存器写入地址
        .ex_gpr_we_(ex_gpr_we_),     // 通用寄存器写入有效
        /********** MEM/WB 流水线寄存器 **********/
        .mem_dst_addr(mem_dst_addr), // 通用寄存器写入地址
        .mem_gpr_we_(mem_gpr_we_),   // 通用寄存器写入有效
        .mem_out(mem_out)            //　处理结果
    );

    /******** 测试用例 ********/
    initial begin
        # 0 begin
            /******** 初始化测试输入 ********/
            clk            <= 1'h1;
            reset          <= `ENABLE;
            out            <= `WORD_DATA_W'h999; // don't care, e.g: 0x999
            miss_align     <= 1'h0;              // don't care, e.g: 0x1
            ex_dst_addr    <= `REG_ADDR_W'h7;    // don't care, e.g: 0x7
            ex_gpr_we_     <= `ENABLE_;              // don't care, e.g: 0x0
        end
        # (STEP * 3/4)
        # STEP begin
            /******** 初始化测试输出 ********/
            if ( (mem_dst_addr     == `WORD_ADDR_W'h0)   &&
                 (mem_gpr_we_      == `DISABLE_)         &&
                 (mem_out          == `WORD_DATA_W'h0)   
               ) begin
                $display("MEM Stage Reg module Initialize Test Succeed !");
            end else begin
                $display("MEM Stage Reg module Initialize Test Failure !");
            end

            reset <= `DISABLE;
        end
        # STEP begin
             /******** 更新流水线到下一个数据 测试输出 ********/
            if ( (mem_dst_addr     == `WORD_ADDR_W'h7)   &&
                 (mem_gpr_we_      == `ENABLE_)           &&
                 (mem_out          == `WORD_DATA_W'h999)  
               ) begin
                $display("MEM Stage Reg module Update Test Succeed !");
            end else begin
                $display("MEM Stage Reg module Update Test Failure !");
            end
            /******** 未对齐异常测试输入 ********/
            miss_align <= 1'h1;
        end
        # STEP begin
            /******** 未对齐异常测试输出 ********/
            if ( (mem_dst_addr     == `WORD_ADDR_W'h0)   &&
                 (mem_gpr_we_      == `DISABLE_)           &&
                 (mem_out          == `WORD_DATA_W'h0)  
               ) begin
                $display("MEM Stage Reg module Miss Align Test Succeed !");
            end else begin
                $display("MEM Stage Reg module Miss Align Test Failure !");
            end
        end
        # STEP begin
            $finish;
        end
    end // initial begin

    /******** 输出波形 ********/
    initial begin
       $dumpfile("mem_reg.vcd");
       $dumpvars(0,mem_reg);
    end
endmodule // mem_stage_test
