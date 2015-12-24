/******** Time scale ********/
`timescale 1ns/1ps

/******** 头文件 ********/
`include "stddef.h"
`include "cpu.h"

/******** 测试模块 ********/
module mem_stage_test;
    /******** 输入输出端口信号 ********/
    // 时钟 & 复位
    reg clk;                              // 时钟
    reg reset;                            // 异步复位
    // SPM 接口
    reg [`WORD_DATA_BUS] spm_rd_data;     // SPM：读取的数据
    wire [`WORD_ADDR_BUS] spm_addr;       // SPM：地址
    wire                  spm_as_;        // SPM：地址选通
    wire                  spm_rw;         // SPM：读/写
    wire [`WORD_DATA_BUS] spm_wr_data;    // SPM：写入的数据
    /********** EX/MEM 流水线寄存器 **********/
    reg [`MEM_OP_BUS]     ex_mem_op;      // 内存操作
    reg [`WORD_DATA_BUS]  ex_mem_wr_data; // 内存写入数据
    reg [`REG_ADDR_BUS]   ex_dst_addr;    // 通用寄存器写入地址
    reg                   ex_gpr_we_;     // 通用寄存器写入有效
    reg [`WORD_DATA_BUS]  ex_out;         // EX阶段处理结果
    /********** MEM/WB 流水线寄存器 **********/
    wire [`REG_ADDR_BUS]  mem_dst_addr;   // 通用寄存器写入地址
    wire                  mem_gpr_we_;    // 通用寄存器写入有效
    wire [`WORD_DATA_BUS] mem_out;        // 处理结果

    /******** 定义仿真循环 ********/
    parameter             STEP = 10;

    /******** 生成时钟 ********/
    always #(STEP / 2) begin
        clk <= ~clk;
    end

    /******** 实例化测试模块 ********/
    mem_stage mem_stage(
        // 时钟 & 复位
        .clk(clk),                      // 时钟
        .reset(reset),                  // 复位
        // SPM 接口
        .spm_rd_data(spm_rd_data),
        .spm_addr(spm_addr),             // SPM：地址
        .spm_as_(spm_as_),               // SPM：地址选通
        .spm_rw(spm_rw),                 // SPM：读/写
        .spm_wr_data(spm_wr_data),       // SPM：写入的数据
        /********* EX/MEM 流水线寄存器 *********/
        .ex_mem_op(ex_mem_op),           // 内存操作
        .ex_mem_wr_data(ex_mem_wr_data), // 内存写入数据
        .ex_dst_addr(ex_dst_addr),       // 通用寄存器写入地址
        .ex_gpr_we_(ex_gpr_we_),         // 通用寄存器写入有效
        .ex_out(ex_out),                 // EX阶段处理结果
        /********** MEM/WB 流水线寄存器 **********/
        .mem_dst_addr(mem_dst_addr),     // 通用寄存器写入地址
        .mem_gpr_we_(mem_gpr_we_),       // 通用寄存器写入有效
        .mem_out(mem_out)                // 处理结果
    );

    /******** Test Case ********/
    initial begin
        # 0 begin
            // Case: read the value 0x24 from address 0x154
            /******** Initialize Test Input********/
            clk            <= 1'h1;
            reset          <= `ENABLE;
            spm_rd_data    <= `WORD_DATA_W'h24;
            ex_mem_op      <= `MEM_OP_LDW;       // when `MEM_OP_LDW, vvp will be infinite loop!
            ex_mem_wr_data <= `WORD_DATA_W'h999; // don't care, e.g: 0x999
            ex_dst_addr    <= `REG_ADDR_W'h7;    // don't care, e.g: 0x7
            ex_gpr_we_     <= `DISABLE_;
            ex_out         <= `WORD_DATA_W'h154;
        end
        # (STEP * 3/4)
        # STEP begin
            /******** Initialize Test Output ********/
            if ( (spm_addr     == `WORD_ADDR_W'h55)     &&
                 (spm_as_      == `ENABLE_)             &&
                 (spm_rw       == `READ)                &&
                 (spm_wr_data  == `WORD_DATA_W'h999)    &&
                 (mem_dst_addr == `REG_ADDR_W'h0)       &&
                 (mem_gpr_we_  == `DISABLE_)            &&
                 (mem_out      == `WORD_DATA_W'h0)
               ) begin
                $display("MEM Stage Initialize Test Succeeded !");
            end else begin
                $display("MEM Stage Initialize Test Failed !");
            end
            // Case: read the value 0x24 from address 0x154
            /******** Read Data(align) Test Input ********/
            reset          <= `DISABLE;
        end
        # STEP begin
            /******** Read Data(align) Test Output ********/
            if ( (spm_addr     == `WORD_ADDR_W'h55)     &&
                 (spm_as_      == `ENABLE_)             &&
                 (spm_rw       == `READ)                &&
                 (spm_wr_data  == `WORD_DATA_W'h999)    &&
                 (mem_dst_addr == `REG_ADDR_W'h7)       &&
                 (mem_gpr_we_  == `DISABLE_)            &&
                 (mem_out      == `WORD_DATA_W'h24)
               ) begin
                $display("MEM Stage Read Data(align) Test Succeeded !");
            end else begin
                $display("MEM Stage Read Data(align) Test Failed !");
            end
            // Case: read the value 0x24 from address 0x59
            /******** Read Data(miss align) Test Input ********/
            ex_out         <= `WORD_DATA_W'h59;
        end
        # STEP begin
            /******** Read Data(miss align) Test Output ********/
            if ( (spm_addr     == `WORD_ADDR_W'h16)     &&
                 (spm_as_      == `DISABLE_)            &&
                 (spm_rw       == `READ)                &&
                 (spm_wr_data  == `WORD_DATA_W'h999)    &&
                 (mem_dst_addr == `REG_ADDR_W'h0)       &&
                 (mem_gpr_we_  == `DISABLE_)            &&
                 (mem_out      == `WORD_DATA_W'h0)
               ) begin
                $display("MEM Stage Read Data(miss align) Test Succeeded !");
            end else begin
                $display("MEM Stage Read Data(miss align) Test Failed !");
            end   ex_out       <= `WORD_DATA_W'h59;
            // Case: write the value 0x13 to address 0x154 which hold value 0x24
            /******** Write Data(align) Test Input ********/
            ex_mem_op      <= `MEM_OP_STW;       // when `MEM_OP_LDW, vvp can't finish! 
            ex_out         <= `WORD_DATA_W'h154;
            ex_mem_wr_data <= `WORD_DATA_W'h13;
        end
        # STEP begin
            /******** Write Data(align) Test Output ********/
            if ( (spm_addr     == `WORD_ADDR_W'h55)     &&
                 (spm_as_      == `ENABLE_)             &&
                 (spm_rw       == `WRITE)               &&
                 (spm_wr_data  == `WORD_DATA_W'h13)     &&
                 (mem_dst_addr == `REG_ADDR_W'h7)       &&
                 (mem_gpr_we_  == `DISABLE_)            &&
                 (mem_out      == `WORD_DATA_W'h0)
               ) begin
                $display("MEM Stage Write Data(align) Test Succeeded !");
            end else begin
                $display("MEM Stage Write Data(align) Test Failed !");
            end
            // Case: write the value 0x13 to address 0x59 which hold value 0x24
            /******** Write Data(miss align) Test Input ********/
            ex_out         <= `WORD_DATA_W'h59;
        end
        # STEP begin
            /******** Write Data(miss align) Test Output ********/
            if ( (spm_addr     == `WORD_ADDR_W'h16)     &&
                 (spm_as_      == `DISABLE_)            &&
                 (spm_rw       == `READ)                &&
                 (spm_wr_data  == `WORD_DATA_W'h13)     &&
                 (mem_dst_addr == `REG_ADDR_W'h0)       &&
                 (mem_gpr_we_  == `DISABLE_)            &&
                 (mem_out      == `WORD_DATA_W'h0)
               ) begin
                $display("MEM Stage Write Data(miss align) Test Succeeded !");
            end else begin
                $display("MEM Stage Write Data(miss align) Test Failed !");
            end
            // Case: EX Stage out is 0x59, and the address 0x59 hold value 0x24
            /******** No Access Test Input ********/
            ex_mem_op      <= `MEM_OP_NOP;       // when `MEM_OP_LDW, vvp can't finish! 
            ex_mem_wr_data <= `WORD_DATA_W'h999; // don't care, e.g: 0x999
            ex_gpr_we_     <= `ENABLE_;
        end
        # STEP begin
            /******** No Access Test Output ********/
            if ((spm_addr     == `WORD_ADDR_W'h16)      &&
                (spm_as_      == `DISABLE_)             &&
                (spm_rw       == `READ)                 &&
                (spm_wr_data  == `WORD_DATA_W'h999)     &&
                (mem_dst_addr == `REG_ADDR_W'h7)        &&
                (mem_gpr_we_  == `ENABLE_)              &&
                (mem_out  == `WORD_DATA_W'h59)
                ) begin
                $display("MEM Stage No Access Test Succeeded !");
            end else begin
                $display("MEM Stage No Access Test Failed !");
            end
            $finish;
        end
    end // initial begin

    /******** 输出波形 ********/
    initial begin
       $dumpfile("mem_stage.vcd");
       $dumpvars(0,mem_stage);
    end
endmodule // mem_stage_test
