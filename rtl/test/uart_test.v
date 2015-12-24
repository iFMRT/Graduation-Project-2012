/* 
 -- ============================================================================
 -- FILE NAME : uart_test.v
 -- DESCRIPTION : UART模块测试 
 -- ----------------------------------------------------------------------------
 -- Date : 2015/12/22                       
 -- ============================================================================
*/

/********** 时间规格 **********/
`timescale 1ns/1ps

/********** 通用头文件 **********/
`include "stddef.h"

/********** 模块头文件 **********/
`include "uart.h"

module uart_test;

    /********** 输入输出端口信号 **********/
    reg   clk;                                // 时钟
    reg   reset;                              // 异步复位
    /* 总线接口 */
    reg   cs_;                                // 片选信号
    reg   as_;                                // 地址选通信号
    reg   rw;                                 // 读 / 写
    reg   addr;                               // 地址
    reg   [`WORD_DATA_BUS] wr_data;           // 写入的数据
    wire  [`WORD_DATA_BUS] rd_data;           // 读取的数据
    wire  rdy_;                               // 就绪信号
    /* 中断 */
    wire  irq_rx;                             // 接收中断请求信号（控制寄存器 0）
    wire  irq_tx;                             // 发送中断请求信号（控制寄存器 0）
    /* UART 接收发送信号 */
    reg   rx;                                 // UART 接收信号
    wire  tx;                                 // UART 发送信号
    
    /******** 定义仿真循环 ********/ 
    parameter     STEP = 10; 

    /********** 实例化测试模块 **********/
    uart uart(  .clk     (clk),               // 时钟
                .reset   (reset),             // 异步复位
                /* 总线接口 */
                .cs_     (cs_),               // 片选信号
                .as_     (as_),               // 地址选通信号
                .rw      (rw),                // 读 / 写
                .addr    (addr),              // 地址
                .wr_data (wr_data),           // 写入的数据
                .rd_data (rd_data),           // 读取的数据
                .rdy_    (rdy_),              // 就绪信号
                /* 中断 */
                .irq_rx  (irq_rx),            // 接收中断请求信号（控制寄存器 0）
                .irq_tx  (irq_tx),            // 发送中断请求信号（控制寄存器 0）
                .rx      (rx),                // UART 接收信号
                .tx      (tx)                 // UART 发送信号
                );
    
   /********** 生成时钟 **********/
    always #(STEP / 2)
        begin
            clk <= ~clk;  
        end

    /********** 测试用例 **********/
    initial
        begin
            /********** 发送信号测试 **********/
            #0  
            begin
                clk <= `ENABLE;
                reset <= `ENABLE_;
                cs_ <= `ENABLE_;
                as_ <= `ENABLE_;
                rw <= `WRITE;
                addr <= `UART_ADDR_DATA;
                wr_data <= `WORD_DATA_W'b1110_1101;
                rx <= `UART_START_BIT;
            end
            #(STEP * 3 / 4)
            #STEP 
            begin
                reset <= `DISABLE_;
            end
            #(STEP * 2)
            begin
                if (tx == `UART_START_BIT & rdy_ == `ENABLE_) 
                    begin
                        $display ("Simulation of transmission succeeded");       
                    end
                else 
                    begin
                        $display ("Simulation of transmission failed");
                    end
            end
            #STEP
            begin
                rx <= `UART_STOP_BIT;
            end
            #(STEP * (`UART_DIV_RATE))
            begin
                if (tx == `UART_STOP_BIT) 
                    begin
                        $display ("Simulation of first-bit transmission succeeded");       
                    end
                else 
                    begin
                        $display ("Simulation of first-bit transmission failed");
                    end
            end
            /********** irq 信号测试 **********/
            #STEP
            begin
            rw <= `WRITE;
            addr <= `UART_ADDR_STATUS;
            end
            #STEP
            begin
                if (irq_rx == `ENABLE & irq_tx == `DISABLE) 
                    begin
                        $display ("Simulation of irq succeeded");      
                    end
                else 
                    begin
                        $display ("Simulation of irq failed");
                    end
            end
            #(STEP* (`UART_DIV_RATE / 2))
            #(STEP * (`UART_DIV_RATE) * 8)
            rw <= `READ;
            addr <= `UART_ADDR_DATA;
            #(STEP * 8)
            begin
                if (rd_data == `WORD_DATA_W'b1111_1111) 
                    begin
                        $display ("Simulation of reception and reading succeeded");       
                    end
                else 
                    begin
                        $display ("Simulation of reception and reading failed");
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
                $dumpfile("uart.vcd");
                $dumpvars(0,uart);
            end
endmodule