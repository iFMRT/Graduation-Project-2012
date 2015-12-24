/******** 头文件 ********/
`include "stddef.h"
`include "cpu.h"

/********** モジュール **********/
module mem_stage (
    /********** 时钟 & 复位 **********/
    input wire                   clk,            // 时钟
    input wire                   reset,          // 异步复位
    /********** SPM 接口 **********/
    input wire [`WORD_DATA_BUS]  spm_rd_data,    // SPM：读取的数据
    output wire [`WORD_ADDR_BUS] spm_addr,       // SPM：地址
    output wire                  spm_as_,        // SPM：地址选通
    output wire                  spm_rw,         // SPM：读/写
    output wire [`WORD_DATA_BUS] spm_wr_data,    // SPM：写入的数据
    /********** EX/MEM 流水线寄存器 **********/
    input wire [`MEM_OP_BUS]     ex_mem_op,      // 内存操作
    input wire [`WORD_DATA_BUS]  ex_mem_wr_data, // 内存写入数据
    input wire [`REG_ADDR_BUS]   ex_dst_addr,    // 通用寄存器写入地址
    input wire                   ex_gpr_we_,     // 通用寄存器写入有效
    input wire [`WORD_DATA_BUS]  ex_out,         // EX阶段处理结果
    /********** MEM/WB 流水线寄存器 **********/
    output wire [`REG_ADDR_BUS]  mem_dst_addr,   // 通用寄存器写入地址
    output wire                  mem_gpr_we_,    // 通用寄存器写入有效
    output wire [`WORD_DATA_BUS] mem_out         // 处理结果
);

    /********** 内部信号 **********/
    wire [`WORD_DATA_BUS]        rd_data;         // 读取的数据
    wire [`WORD_ADDR_BUS]        addr;            // 地址
    wire                         as_;             // 地址选通
    wire                         rw;              // 读/写
    wire [`WORD_DATA_BUS]        wr_data;         // 写入的数据
    wire [`WORD_DATA_BUS]        out;             // 内存访问结果
    wire                         miss_align;      // 未对齐

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

    // /********** 总线接口 **********/
    bus_if bus_if (
        /********** CPU 接口 **********/
        .addr             (addr),            // CPU：地址
        .as_              (as_),             // CPU：地址有效
        .rw               (rw),              // CPU：读/写
        .wr_data          (wr_data),         // CPU：写入的数据
        .rd_data          (rd_data),         // CPU：读入的数据
        /********** SPM接口 **********/
        .spm_rd_data      (spm_rd_data),     // SPM：读取的数据
        .spm_addr         (spm_addr),        // SPM：地址
        .spm_as_          (spm_as_),         // SPM：地址选通
        .spm_rw           (spm_rw),          // SPM：读/写
        .spm_wr_data      (spm_wr_data)      // SPM：写入的数据
    );

    // /********** MEM 阶段流水线寄存器 **********/
    mem_reg mem_reg (
        /********** 时钟 & 复位 **********/
        .clk              (clk),             // 时钟
        .reset            (reset),           // 异步复位
        /********** 内存访问结果 **********/
        .out              (out),             // 结果
        .miss_align       (miss_align),      // 未对齐
        /********** EX/MEM 流水线寄存器 **********/
        .ex_dst_addr      (ex_dst_addr),     // 通用寄存器写入地址
        .ex_gpr_we_       (ex_gpr_we_),      // 通用寄存器写入有效
        /********** MEM/WB 流水线寄存器 **********/
        .mem_dst_addr     (mem_dst_addr),    // 通用寄存器写入地址
        .mem_gpr_we_      (mem_gpr_we_),     // 通用寄存器写入有效
        .mem_out          (mem_out)          // 处理结果
    );

endmodule
