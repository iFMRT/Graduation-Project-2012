/******** Time scale ********/
`timescale 1ns/1ps

/******** 头文件 ********/
`include "stddef.h"
`include "cpu.h"

/******** 测试模块 ********/
module mem_ctrl_test;
    /******** 输入输出端口信号 ********/

    /********** EX/MEM 流水线寄存器 **********/
    reg [`MEM_OP_BUS]     ex_mem_op;      // 内存操作
    reg [`WORD_DATA_BUS]  ex_mem_wr_data; // 内存写入数据
    reg [`WORD_DATA_BUS]  ex_out;         // EX阶段处理结果
    reg [`WORD_DATA_BUS]  rd_data;        // 读取的数据

    wire [`WORD_ADDR_BUS] addr;           // 地址
    wire                  as_;            // 地址选通
    wire                  rw;             // 读/写
    wire [`WORD_DATA_BUS] wr_data;        // 写入的数据
    /********** 内存访问  **********/
    wire[`WORD_DATA_BUS]  out;           // 内存访问结果
    wire                  miss_align;      // 未对齐

    /******** 定义仿真循环 ********/
    parameter             STEP = 10;


    /******** 实例化测试模块 ********/
   // /********** 内存访问控制模块 **********/
    mem_ctrl mem_ctrl (
        /********** EX/MEM 流水线寄存器 **********/
        .ex_mem_op        (ex_mem_op),       // 内存操作(空操作/字读取/字写入)
        .ex_mem_wr_data   (ex_mem_wr_data),  // 内存写入数据
        .ex_out           (ex_out),          // EX 阶段处理结果
        /********** 内存访问接口 **********/
        .rd_data          (rd_data),         // 读取的数据
        .addr             (addr),            // 地址
        .as_              (as_),             // 地址选通
        .rw               (rw),              // 读/写
        .wr_data          (wr_data),         // 写入的数据
        /********** 内存访问结果 **********/
        .out              (out),             // 内存访问结果
        .miss_align       (miss_align)       // 未对齐
    );

    /******** 测试用例 ********/
    initial begin
        # 0 begin
            /******** 字读取（对齐）测试输入 ********/
            ex_mem_op      <= `MEM_OP_LDW;
            ex_mem_wr_data <= `WORD_DATA_W'h999;        // don't care, e.g: 0x999
            ex_out         <= `WORD_DATA_W'h154;
            rd_data        <= `WORD_DATA_W'h24;
        end
        # STEP begin
            /******** 字读取（对齐）测试输出 ********/
            if ( (addr     == `WORD_ADDR_W'h55)           &&
                 (as_      == `ENABLE_)         &&
                 (rw       == `READ)            &&
                 (wr_data  == `WORD_DATA_W'h999)&&
                 (out == 32'h24)                &&
                 (miss_align  == `DISABLE)
                 ) begin
                $display("mem ctrl 模块【字读取（对齐）】测试通过！ ");
            end else begin
                $display("mem ctrl 模块【字读取（对齐）】测试没有通过！！！");
            end
            /******** 字读取（未对齐）测试输入 ********/
            ex_mem_op      <= `MEM_OP_LDW;
            ex_mem_wr_data <= `WORD_ADDR_W'h999;        // don't care, e.g: 0x999
            ex_out         <= `WORD_DATA_W'h59;
            rd_data        <= `WORD_DATA_W'h24;
        end
        # STEP begin
            /******** 字读取（未对齐）测试输出 ********/
                  if ( (addr  == `WORD_ADDR_W'h16)           &&
                 (as_         == `DISABLE_)        &&
                 (rw          == `READ)            &&
                 (wr_data     == `WORD_DATA_W'h999)&&
                 (out         == `WORD_DATA_W'h0)  &&
                 (miss_align  == `ENABLE)
               ) begin
                $display("mem ctrl 模块【字读取（未对齐）】测试通过！ ");
            end else begin
                $display("mem ctrl 模块【字读取（未对齐）】测试没有通过！！！");
            end
        end
        # STEP begin
            /******** 字读取（未对齐）测试输出 ********/
            if ( (addr        == `WORD_ADDR_W'h16)           &&
                 (as_         == `DISABLE_)        &&
                 (rw          == `READ)            &&
                 (wr_data     == `WORD_DATA_W'h999)&&
                 (out         == `WORD_DATA_W'h0)  &&
                 (miss_align  == `ENABLE)
                 ) begin
                $display("mem ctrl 模块【字读取（未对齐）】测试通过！ ");
            end else begin
                $display("mem ctrl 模块【字读取（未对齐）】测试没有通过！！！");
            end
            /******** 字写入（对齐）测试输入 ********/
            // 假设写入的地址是 0x154，地址的值是 0x24，写入的数据是 0x13。
            ex_mem_op      <= `MEM_OP_STW;
            ex_mem_wr_data <= `WORD_DATA_W'h13;
            ex_out         <= `WORD_DATA_W'h154;
            rd_data        <= `WORD_DATA_W'h24;
        end
        # STEP begin
            /******** 字写入（对齐）测试输出 ********/
            if ( (addr        == `WORD_ADDR_W'h55)            &&
                 (as_         == `ENABLE_)          &&
                 (rw          == `WRITE)            &&
                 (wr_data     == `WORD_DATA_W'h13)  &&
                 (out         == `WORD_DATA_W'h0)   &&
                 (miss_align  == `DISABLE)
                 ) begin
                $display("mem ctrl 模块【字写入（对齐）】测试通过！ ");
            end else begin
                $display("mem ctrl 模块【字写入（对齐）】测试没有通过！！！");
            end
            /******** 字写入（未对齐）测试输入 ********/
            // 假设读取的地址是 0x59，该地址的值是 0x24，写入的数据是 0x13。
            ex_mem_op      <= `MEM_OP_STW;
            ex_mem_wr_data <= `WORD_DATA_W'h13;
            ex_out         <= `WORD_DATA_W'h59;
            rd_data        <= `WORD_DATA_W'h24;
        end
        # STEP begin
            /******** 字写入（未对齐）测试输出 ********/
            if ( (addr        == `WORD_ADDR_W'h16)            &&
                 (as_         == `DISABLE_)         &&
                 (rw          == `READ)             &&
                 (wr_data     == `WORD_DATA_W'h13)  &&
                 (out         == `WORD_DATA_W'h0)   &&
                 (miss_align  == `ENABLE)
                 ) begin
                $display("mem ctrl 模块【字写入（未对齐）】测试通过！ ");
            end else begin
                $display("mem ctrl 模块【字写入（未对齐）】测试没有通过！！！");
            end
            /******** 无内存访问测试输入 ********/
            // 假设 EX 阶段运算的结果是 0x59，当被视作地址时，该地址的值是 0x24。
            ex_mem_op      <= `MEM_OP_NOP;
            ex_mem_wr_data <= `WORD_DATA_W'h999;
            ex_out         <= `WORD_DATA_W'h59;
            rd_data        <= `WORD_DATA_W'h24;
        end
        # STEP begin
            /******** 无内存访问测试输出 ********/
            if ( (addr        == `WORD_ADDR_W'h16)  &&
                 (as_         == `DISABLE_)         &&
                 (rw          == `READ)             &&
                 (wr_data     == `WORD_DATA_W'h999) &&
                 (out         == `WORD_DATA_W'h59)  &&
                 (miss_align  == `DISABLE)
                 ) begin
                $display("mem ctrl 模块【无内存访问】测试通过！ ");
            end else begin
                $display("mem ctrl 模块【无内存访问】测试没有通过！！！");
            end
        end
        # STEP begin
            $finish;
        end
    end // initial begin

    /******** 输出波形 ********/
    initial begin
       $dumpfile("mem_ctrl.vcd");
       $dumpvars(0,mem_ctrl);
    end
endmodule // mem_stage_test
