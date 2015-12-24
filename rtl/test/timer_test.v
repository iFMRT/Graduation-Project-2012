/*
 -- ============================================================================
 -- FILE NAME   : timer_test.v
 -- DESCRIPTION : 定时器测试模块
 -- ----------------------------------------------------------------------------
 -- Date:2015/12/24         Coding_by:kippy
 -- ============================================================================
*/

/********** 通用头文件 **********/
`include "stddef.h"

/********** 模块头文件 **********/
`include "timer.h"

module timer_test;

    /********** 输入输出端口信号 **********/
    /* 时钟与复位 */
    reg  clk;                       // 时钟
    reg  reset;                     // 异步复位
    /* 总线接口 */
    reg  cs_;                       // 片选信号
    reg  as_;                       // 地址选通
    reg  rw;                        // Read / Write
    reg  [`TIMER_ADDR_BUS] addr;    // 地址
    reg  [`WORD_DATA_BUS] wr_data;      // 写数据
    wire [`WORD_DATA_BUS] rd_data;      // 读取数据
    wire rdy_;                      // 就绪信号
    /* 中断输出 */
    wire irq;                       // 中断请求（控制寄存器 1）

    /******** 定义仿真循环 ********/ 
    parameter     STEP = 10; 

    /********** 实例化测试模块 **********/
    timer timer(
                /* 时钟与复位 */
                clk,                // 时钟
                reset,              // 异步复位
                /* 总线接口 */
                cs_,                // 片选信号
                as_,                // 地址选通
                rw,                 // Read / Write
                addr,               // 地址
                wr_data,            // 写数据
                rd_data,            // 读取数据
                rdy_,               // 就绪信号
                /* 中断输出 */
                irq                 // 中断请求（控制寄存器 1）
                );

    /********** 生成时钟 **********/
    always #(STEP / 2)
        begin
            clk <= ~clk;  
        end

    /********** 测试用例 **********/
    initial
    begin
        /* 写访问测试 */
        #0  
        begin // 写入控制寄存器 2：expr_val = `WORD_DATA_W'b0001_0101;
            clk <= `ENABLE;
            reset <= `ENABLE_;
            cs_ <= `ENABLE_;
            as_ <= `ENABLE_;
            rw <= `WRITE;
            addr <= `TIMER_ADDR_EXPR;
            wr_data <= `WORD_DATA_W'b0001_0101;
        end
        #(STEP * 3 / 4)
        #STEP 
        begin
            reset <= `DISABLE_;
        end
        #STEP 
        begin // 写入控制寄存器 0：start = 1; mode = 0;
            addr <= `TIMER_ADDR_CTRL;
        end
        #STEP 
        begin
            if (rdy_ == `ENABLE_) 
                    begin
                        $display ("Simulation of writing Reg_0 succeeded");       
                    end
                else 
                    begin
                        $display ("Simulation of writing Reg_0 failed");
                    end
        end
        /* 读访问 */
        #(STEP * wr_data)
        begin
            rw <= `READ;
        end
        #STEP // 读取控制寄存器 0：rd_data = {{`WORD_DATA_W-2{1'b0}}, mode, start} =`WORD_DATA_W'b01;
        begin // 计数完成：expr_flag = `ENABLE;
            if (irq == `ENABLE & rd_data == `WORD_DATA_W'b1) 
                    begin
                        $display ("Simulation of counter succeeded");       
                    end
                else 
                    begin
                        $display ("Simulation of counter failed");
                    end
        end
        #STEP // start = 0;
        #STEP
        begin // 读取控制寄存器 0：rd_data = `WORD_DATA_W'b0;
            if (rd_data == `WORD_DATA_W'b0) 
                    begin
                        $display ("Simulation of reading Reg_0 succeeded");       
                    end
                else 
                    begin
                        $display ("Simulation of reading Reg_0 failed");
                    end
        end
        #STEP 
        begin // 读取控制寄存器 1：rd_data = {{`WORD_DATA_W-1{1'b0}}, irq};
            addr <= `TIMER_ADDR_INTR;
        end
        #STEP 
        begin
            if (rd_data == `WORD_DATA_W'b1) 
                    begin
                        $display ("Simulation of reading Reg_1 succeeded");       
                    end
                else 
                    begin
                        $display ("Simulation of reading Reg_1 failed");
                    end
        end
        #STEP 
        begin // 读取控制寄存器 2：rd_data = expr_val = `WORD_DATA_W'b0001_0101;
            addr <= `TIMER_ADDR_EXPR;
        end
        #STEP 
        begin 
            if (rd_data == `WORD_DATA_W'b0001_0101) 
                    begin
                        $display ("Simulation of reading Reg_2 succeeded");       
                    end
                else 
                    begin
                        $display ("Simulation of reading Reg_2 failed");
                    end
        end
        #STEP 
        begin // 读取控制寄存器 3：rd_data = `WORD_DATA_W'b0;
            addr <= `TIMER_ADDR_COUNTER;
        end
        #STEP 
        begin
            if (rd_data == `WORD_DATA_W'b0) 
                    begin
                        $display ("Simulation of reading Reg_3 succeeded");       
                    end
                else 
                    begin
                        $display ("Simulation of reading Reg_3 failed");
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
                $dumpfile("timer.vcd");
                $dumpvars(0,timer);
            end 
endmodule