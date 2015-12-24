/* 
  -- ============================================================================ 
  -- FILE NAME  : uart_rx_test.v 
  -- DESCRIPTION : UART 的接收模块
  -- ---------------------------------------------------------------------------- 
  -- Date：2015/12/23             Coding_by：kippy
  -- ============================================================================ 
*/ 

/********** 通用头文件 **********/
`include "stddef.h"

/********** 模块头文件 **********/
`include "uart.h"

module uart_rx_test;

    /********** 输入输出端口信号 **********/
    /* 时钟复位 */
    reg  clk;                            // 时钟
    reg  reset;                          // 异步复位
    /* 控制信号 */
    wire rx_busy;                        // 接收中标志信号
    wire rx_end;                         // 接收完成信号
    wire [`BYTE_DATA_BUS] rx_data;       // 接收的数据
    reg  rx;                             // UART 接收信号

    /******** 定义仿真循环 ********/ 
    parameter     STEP = 10;

    /********** 实例化测试模块 **********/
    uart_rx uart_rx(   /* 时钟复位 */
                       .clk             (clk),             // 时钟
                       .reset           (reset),           // 异步复位
                       /* 控制信号 */
                       .rx_busy         (rx_busy),         // 接收中标志信号
                       .rx_end          (rx_end),          // 接收完成信号
                       .rx_data         (rx_data),         // 接收数据兼移位寄存器
                       .rx              (rx)               // UART 接收信号
                       );

    /********** 生成时钟 **********/
    always #(STEP / 2)
        begin
            clk <= ~clk;  
        end

    /********** 测试用例 **********/
    initial
        begin
            /********** 接收信号测试 **********/
            #0  
            begin
                clk <= `ENABLE;
                reset <= `ENABLE_;
                rx <= `UART_START_BIT;
            end
            #(STEP * 3 / 4)
            #STEP 
            begin
                reset <= `DISABLE_;
            end
            #STEP 
            begin
                if (rx_busy == `ENABLE & rx_end == `DISABLE) 
                    begin
                        $display ("Simulation of UART_STATE_IDLE succeeded");       
                    end
                else 
                    begin
                        $display ("Simulation of UART_STATE_IDLE failed");
                    end
            end
            #( STEP * ( `UART_DIV_RATE / 2) )
            begin
                rx <= `UART_STOP_BIT;
            end
            #STEP
            begin
                if (rx_data == `BYTE_DATA_W'b1000_0000) 
                    begin
                        $display ("Simulation of first-bit reception succeeded");       
                    end
                else 
                    begin
                        $display ("Simulation of first-bit reception failed");
                    end
            end
            #(STEP * `UART_DIV_RATE)
            begin
                rx <= `UART_START_BIT;
            end
            #STEP
            begin
                if (rx_data == `BYTE_DATA_W'b0100_0000) 
                    begin
                        $display ("Simulation of second-bit reception succeeded");       
                    end
                else 
                    begin
                        $display ("Simulation of second-bit reception failed");
                    end
            end            
            #(STEP * `UART_DIV_RATE * 8)
            #(STEP * 7)
            begin
                rx <= `UART_STOP_BIT;
            end
            #STEP
            begin
                if (rx_end == `ENABLE & rx_busy == `DISABLE) 
                    begin
                        $display ("Simulation of last-bit reception succeeded");       
                    end
                else 
                    begin
                        $display ("Simulation of last-bit reception failed");
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
                $dumpfile("uart_rx.vcd");
                $dumpvars(0,uart_rx);
            end  
endmodule