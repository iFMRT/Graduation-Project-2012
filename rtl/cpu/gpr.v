// ----------------------------------------------------------------------------
// FILE NAME    : gpr.v
// DESCRIPTION :  general purpose register module of pipeline
// AUTHOR : cjh
// TIME : 2015-12-18 09:23:28
//
// -----------------------------------------------------------------------------

`include "stddef.h"
`include "cpu.h"

/********** 通用寄存器 **********/
module gpr (
    /********** 时钟与复位 **********/
    input  wire                     clk,                // 时钟
    input  wire                     reset,              // 异步复位
    /********** 读取端口 0 **********/
    input  wire [`REG_ADDR_BUS]     rd_addr_0,          // 读取的地址
    output wire [`WORD_DATA_BUS]    rd_data_0,          // 读取的数据
    /********** 读取端口 1 **********/
    input  wire [`REG_ADDR_BUS]     rd_addr_1,          // 读取的地址
    output wire [`WORD_DATA_BUS]    rd_data_1,          // 读取的数据
    /********** 写入端口 **********/
    input  wire                      we_,                // 写入有效信号
    input  wire [`REG_ADDR_BUS]      wr_addr,            // 写入的地址
    input  wire [`WORD_DATA_BUS]     wr_data             // 写入的数据
);

    /********** 内部信号 **********/
    wire [`WORD_DATA_BUS]     rd_data_0_tmp;          // 临时读取的数据
    wire [`WORD_DATA_BUS]     rd_data_1_tmp;          // 临时读取的数据
    reg  [`WORD_DATA_BUS]     gpr [`REG_LIST];        // 寄存器序列
    integer                   i;                      // 初始化用迭代器

    assign rd_data_0 = (rd_addr_0 != 0) ? rd_data_0_tmp : 0;
    assign rd_data_1 = (rd_addr_1 != 0) ? rd_data_1_tmp : 0;

    /********** 读取访问 (先读后写) **********/
    // 读取端口 0
    assign rd_data_0_tmp = ((we_ == `ENABLE_) && (wr_addr == rd_addr_0)) ? wr_data : gpr[rd_addr_0];

    // 读取端口 1
    assign rd_data_1_tmp = ((we_ == `ENABLE_) && (wr_addr == rd_addr_1)) ? wr_data : gpr[rd_addr_1];

    /********** 写入访问 **********/
    always @ (posedge clk) begin
        if (reset != `ENABLE) begin
            if (we_ == `ENABLE_) begin
                // 写入访问
                gpr[wr_addr] <= #1 wr_data;
            end
        end
    end

endmodule
