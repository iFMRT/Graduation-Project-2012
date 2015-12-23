/******** Time scale ********/
`timescale 1ns/1ps

/******** 头文件 ********/
`include "stddef.h"
`include "cpu.h"

/******** 测试模块 ********/
module bus_if_test;
    /************* CPU接口 *************/
    reg [29:0]      addr;        // 地址
    reg             as_;         // 地址选通信号
    reg             rw;          // 读／写
    reg [31:0]      wr_data;     // 写入的数据
    wire [31:0]     rd_data;     // 读取的数据
    /************* SPM接口 *************/
    reg [31:0]      spm_rd_data; // 读取的数据
    wire [29:0]     spm_addr;    // 地址
    wire            spm_as_;     // 地址选通信号
    wire            spm_rw;      // 读／写
    wire [31:0]     spm_wr_data;  // 读取的数据

    /******** 定义仿真循环 ********/
    parameter             STEP = 10;

    /******** 实例化 bus_if 测试模块 ********/
    bus_if bus_if (
        /************* CPU接口 *************/
        .addr(addr),        // 地址
        .as_(as_),          // 地址选通信号
        .rw(rw),          // 读／写
        .wr_data(wr_data),     // 写入的数据
        .rd_data(rd_data),     // 读取的数据
        /************* SPM接口 *************/
        .spm_rd_data(spm_rd_data), // 读取的数据
        .spm_addr(spm_addr),    // 地址
        .spm_as_(spm_as_),     // 地址选通信号
        .spm_rw(spm_rw),      // 读／写
        .spm_wr_data(spm_wr_data)  // 读取的数据
    );

    /******** 测试用例 ********/
    initial begin
        # 0 begin
            /******** 读取数据测试输入 ********/
            addr        <= `WORD_ADDR_W'h55;
            as_         <= `ENABLE_;
            rw          <= `READ;
            wr_data     <= `WORD_DATA_W'h999;        // don't care, e.g: 0x999
            spm_rd_data <= `WORD_DATA_W'h24;
        end
        # STEP begin
            /******** 读取数据测试输出 ********/
            if ( (rd_data      == `WORD_DATA_W'h24)  &&
                 (spm_addr     == `WORD_ADDR_W'h55)  &&
                 (spm_as_      == `ENABLE_)          &&
                 (spm_rw       == `READ)             &&
                 (spm_wr_data  == `WORD_DATA_W'h999)        // don't care, e.g: 0x999
               ) begin
                $display("Bus If module read data Test Succeeded !");
            end else begin
                $display("Bus If module read data Test Failed !");
            end
            /******** 无内存访问测试输入 ********/
            addr        <= `WORD_ADDR_W'h55;
            as_         <= `DISABLE_;
            rw          <= `READ;
            wr_data     <= `WORD_DATA_W'h999;        // don't care, e.g: 0x999
            spm_rd_data <= `WORD_DATA_W'h24;
        end
        # STEP begin
            /******** 无内存访问测试输出 ********/
            if ( (rd_data      == `WORD_DATA_W'h0)   &&
                 (spm_addr     == `WORD_ADDR_W'h55)  &&
                 (spm_as_      == `DISABLE_)         &&
                 (spm_rw       == `READ)             &&
                 (spm_wr_data  == `WORD_DATA_W'h999)        // don't care, e.g: 0x999
               ) begin
                $display("Bus If module no access Test Succeeded !");
            end else begin
                $display("Bus If module no access Test Failed !");
            end
            /******** 写入数据测试输入 ********/
            addr        <= `WORD_ADDR_W'h55;
            as_         <= `ENABLE_;
            rw          <= `WRITE;
            wr_data     <= `WORD_DATA_W'h59;        // don't care, e.g: 0x999
            spm_rd_data <= `WORD_DATA_W'h24;
        end
        # STEP begin
            /******** 写入数据测试输出 ********/
            if ( (rd_data      == `WORD_DATA_W'h0)   &&
                 (spm_addr     == `WORD_ADDR_W'h55)  &&
                 (spm_as_      == `ENABLE_)          &&
                 (spm_rw       == `WRITE)            &&
                 (spm_wr_data  == `WORD_DATA_W'h59)
                 ) begin
                $display("Bus If module write data Test Succeeded !");
            end else begin
                $display("Bus If module write data Test Failed !");
            end
            $finish;
        end
    end // initial begin

    /******** 输出波形 ********/
    initial begin
       $dumpfile("bus_if.vcd");
       $dumpvars(0,bus_if);
    end
endmodule // mem_stage_test
