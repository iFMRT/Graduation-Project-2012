/* 
 -- ============================================================================
 -- FILE NAME : uart_ctrl_test.v
 -- DESCRIPTION : uart_ctrl 模块测试 
 -- ----------------------------------------------------------------------------
 -- Date : 2015/12/23                       
 -- ============================================================================
*/

/********** 时间规格 **********/
`timescale 1ns/1ps

/********** 通用头文件 **********/
`include "stddef.h"

/********** 模块头文件 **********/
`include "uart.h"

module uart_ctrl_test;

    /********** 输入输出端口信号 **********/
    /* 时钟复位 */
    reg  clk;                         // 时钟
    reg  reset;                       // 异步复位
    /* 总线接口 */
    reg  cs_;                         // 片选信号
    reg  as_;                         // 地址选通信号
    reg  rw;                          // 读 / 写
    reg  addr;                        // 地址
    reg  [`WORD_DATA_BUS] wr_data;     // 写入的数据
    wire [`WORD_DATA_BUS] rd_data;  // 读取的数据
    wire rdy_;                    // 就绪信号
    /* 中断 */
    wire irq_rx;                  // 接收中断请求信号（控制寄存器 0）
    wire irq_tx;                  // 发送中断请求信号（控制寄存器 0）
    /* 控制信号 */
    reg  rx_busy;                     // 接收中标志信号（控制寄存器 0）
    reg  rx_end;                      // 接收完成信号
    reg  [`BYTE_DATA_BUS] rx_data;     // 收的数据
    reg  tx_busy;                     // 发送中标志信号（控制寄存器 0）
    reg  tx_end;                      // 发送完成信号
    wire tx_start;                // 发送开始信号
    wire [`BYTE_DATA_BUS] tx_data;   // 发送的数据

    /******** 定义仿真循环 ********/ 
    parameter     STEP = 10; 

    /********** 实例化测试模块 **********/
    uart_ctrl uart_ctrl(
                        /* 时钟复位 */
                        .clk        (clk),             // 时钟
                        .reset      (reset),           // 异步复位
                        /* 总线接口 */
                        .cs_        (cs_),             // 片选信号
                        .as_        (as_),                         // 地址选通信号
                        .rw         (rw),              // 读 / 写
                        .addr       (addr),                        // 地址
                        .wr_data    (wr_data),         // 写入的数据
                        .rd_data    (rd_data),         // 读取的数据
                        .rdy_       (rdy_),            // 就绪信号
                        /* 中断 */
                        .irq_rx     (irq_rx),          // 接收中断请求信号（控制寄存器 0）
                        .irq_tx     (irq_tx),          // 发送中断请求信号（控制寄存器 0）
                        /* 控制信号 */
                        .rx_busy    (rx_busy),         // 接收中标志信号（控制寄存器 0）
                        .rx_end     (rx_end),          // 接收完成信号
                        .rx_data    (rx_data),         // 收的数据
                        .tx_busy    (tx_busy),         // 发送中标志信号（控制寄存器 0）
                        .tx_end     (tx_end),          // 发送完成信号
                        .tx_start   (tx_start),        // 发送开始信号
                        .tx_data    (tx_data)          // 发送的数据
                        );

   /********** 生成时钟 **********/
    always #(STEP / 2)
        begin
            clk <= ~clk;  
        end

    /********** 测试用例 **********/
    initial
        begin
            /*********** 读取访问测试 ************/
            #0  
            begin
                clk <= `ENABLE;
                reset <= `ENABLE_;
                cs_ <= `ENABLE_;
                as_ <= `ENABLE_;
                rw <= `WRITE;
                addr <= `UART_ADDR_STATUS;
                tx_end <= `ENABLE;
                tx_busy <= `ENABLE;
                rx_busy <= `DISABLE;
                rx_data <= `BYTE_DATA_W'b0101_1010;
                wr_data <= `WORD_DATA_W'b0101_0101;
            end
            #(STEP * 3 / 4)
            #STEP 
            begin
                reset <= `DISABLE_;
            end
            /*********** 写入访问测试 ************/
            #STEP
            begin
                if (irq_tx == `ENABLE & rdy_ == `ENABLE_) 
                    begin
                        $display ("Simulation of first writing Reg_0 succeeded");       
                    end
                else 
                    begin
                        $display ("Simulation of first writing Reg_0 failed");
                    end
            end
            #STEP
            begin
                tx_end <= `DISABLE;
            end
            #STEP 
            begin
                if (rd_data == `WORD_DATA_W'b0 & irq_tx == `DISABLE) 
                    begin
                        $display ("Simulation of writing Reg_0 succeeded");       
                    end
                else 
                    begin
                        $display ("Simulation of writing Reg_0 failed");
                    end
            end
            #STEP 
            begin
                rx_end <= `ENABLE;
            end
            #STEP
            begin
                if (irq_rx == `ENABLE) 
                    begin
                        $display ("Simulation of first writing Reg_0 succeeded");       
                    end
                else 
                    begin
                        $display ("Simulation of first writing Reg_0 failed");
                    end
            end
            /*********** 读取访问测试 ************/
            #STEP 
            begin
                rw <= `READ;
            end
            #STEP 
            begin
                if (rd_data == `WORD_DATA_W'b0000_1001) 
                    begin
                        $display ("Simulation of reading Reg_0 succeeded");       
                    end
                else 
                    begin
                        $display ("Simulation of reading Reg_0 failed");
                    end
            end
             #STEP 
            begin
                addr <= `UART_ADDR_DATA;
            end
            #STEP 
            begin
                if (rd_data == `WORD_DATA_W'b0101_1010) 
                    begin
                        $display ("Simulation of reading Reg_1 succeeded");       
                    end
                else 
                    begin
                        $display ("Simulation of reading Reg_1 failed");
                    end
            end
            #STEP
            begin
                rw <= `WRITE;
            end
            #STEP 
            begin
                if (tx_data == `BYTE_DATA_W'b0101_0101 & tx_start == `ENABLE) 
                    begin
                        $display ("Simulation of writing Reg_1 succeeded");       
                    end
                else 
                    begin
                        $display ("Simulation of writing Reg_1 failed");
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
                $dumpfile("uart_ctrl.vcd");
                $dumpvars(0,uart_ctrl);
            end 
endmodule