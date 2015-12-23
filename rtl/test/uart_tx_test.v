/* 
  -- ============================================================================ 
  -- FILE NAME  : uart_tx_test.v 
  -- DESCRIPTION : UART 的发送模块
  -- ---------------------------------------------------------------------------- 
  -- Date：2015/12/23            Coding_by：kippy
  -- ============================================================================ 
*/ 

/********** 通用头文件 **********/
`include "stddef.h"

/********** 模块头文件 **********/
`include "uart.h"

module uart_tx_test;

    /********** 输入输出端口信号 **********/
    reg  clk;                            // 时钟
    reg  reset;                          // 异步复位
    /*控制信号*/
    reg  tx_start;                       // 发送开始信号
    reg  [`BYTE_DATA_BUS] tx_data;       // 发送的数据
    wire tx_busy;                        // 发送中标志信号
    wire tx_end;                         // 发送完成信号
    /* UART 发送信号 */
    wire tx;                             // UART 发送信号

    /******** 定义仿真循环 ********/ 
    parameter     STEP = 10;

    /********** 实例化测试模块 **********/
    uart_tx uart_tx(/*时钟复位信号*/
                            .clk            (clk),            // 时钟
                            .reset          (reset),          // 异步复位
                            /*控制信号*/
                            .tx_start       (tx_start),       // 发送开始信号
                            .tx_data        (tx_data),        // 发送的数据
                            .tx_busy        (tx_busy),        // 发送中标志信号
                            .tx_end         (tx_end),         // 发送完成信号
                            /* UART 发送信号 */
                            .tx             (tx)              // UART 发送信号
                          );

    /********** 生成时钟 **********/
    always #(STEP / 2)
        begin
            clk <= ~clk;  
        end

    /********** 测试用例 **********/
    initial
        begin
            /********** 发送信号测试 **********/
            #0  
            begin
                clk <= `ENABLE;
                reset <= `ENABLE_;
                tx_start <= `ENABLE;
                tx_data <= `BYTE_DATA_W'b1110_1101;
            end
            #(STEP * 3 / 4)
            #STEP 
            begin
                reset <= `DISABLE_;
            end
            #STEP 
            begin
                if (tx_busy == `ENABLE & tx == `UART_START_BIT & tx_end == `DISABLE) 
                    begin
                        $display ("Simulation of UART_STATE_IDLE succeeded");       
                    end
                else 
                    begin
                        $display ("Simulation of UART_STATE_IDLE failed");
                    end
            end
            #(STEP * (`UART_DIV_RATE + 1))
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
            #(STEP * (`UART_DIV_RATE + 1 ))
            begin
                if (tx == `UART_START_BIT) 
                    begin
                        $display ("Simulation of second-bit transmission succeeded");       
                    end
                else 
                    begin
                        $display ("Simulation of second-bit transmission failed");
                    end
            end
            #STEP 
            begin
                $finish;  
            end 
        end  

        /********** 输出波形 **********/
        initial
            begin
                $dumpfile("uart_tx.vcd");
                $dumpvars(0,uart_tx);
            end  
endmodule