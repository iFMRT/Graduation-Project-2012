/* 
  -- ============================================================================ 
  -- FILE NAME  : uart_rx.v 
  -- DESCRIPTION : UART 的接收模块
  -- ---------------------------------------------------------------------------- 
  -- Date：2015/12/21          
  -- ============================================================================ 
*/ 

/********** 通用头文件 **********/
`include "stddef.h"

/********** 模块头文件 **********/
`include "uart.h"

module uart_rx(/* 时钟复位 */
               input clk,                            // 时钟
               input reset,                          // 异步复位
               /* 控制信号 */
               output rx_busy,                       // 接收中标志信号
               output reg rx_end,                    // 接收完成信号
               output reg[`BYTE_DATA_BUS] rx_data,   // 接收数据兼移位寄存器
               input  rx                             // UART 接收信号
               );

               reg state;                            // 接收模块的状态
               reg [`UART_DIV_CNT_BUS] div_cnt;      // 分频计数器
               reg [`UART_BIT_CNT_BUS] bit_cnt;      // 比特计数器

               /********** 接收中标志信号的生成 **********/
               assign rx_busy = (state != `UART_STATE_IDLE) ? `ENABLE :`DISABLE;

               /********** 接收逻辑电路 **********/
               always @(posedge clk or negedge reset) 
                    begin
                        if (reset == `ENABLE_) 
                            begin
                                /* 异步复位 */
                                rx_end <= #1 `DISABLE;
                                rx_data <= #1 `BYTE_DATA_W'b0;
                                state <= `UART_STATE_IDLE;
                                div_cnt <= #1 `UART_DIV_RATE / 2;
                                bit_cnt <= #1 `UART_BIT_CNT_W'b0;           
                            end
                        else 
                            begin
                                case(state)
                                    `UART_STATE_IDLE: // 空闲状态
                                        begin
                                            if(rx == `UART_START_BIT)
                                            begin // 接收开始
                                                state <= #1 `UART_STATE_RX;
                                            end
                                            rx_end <= `DISABLE;
                                        end
                                    `UART_STATE_RX:
                                        begin // 接收中
                                            /* 依据时钟分配调整波特率 */
                                            if(div_cnt == `UART_DIV_CNT_W'b0)
                                                begin
                                                    /* 接收下一个比特数据 */
                                                    case(bit_cnt)
                                                        `UART_BIT_CNT_STOP:
                                                            begin // 接收停止位
                                                                state <= #1 `UART_STATE_IDLE;
                                                                bit_cnt <= #1 `UART_BIT_CNT_START;
                                                                div_cnt <= #1 `UART_DIV_RATE / 2;
                                                                /* 帧错误的检测 */
                                                                if(rx == `UART_STOP_BIT)
                                                                    begin
                                                                        rx_end <= #1 `ENABLE;
                                                                    end
                                                            end
                                                        default:
                                                            begin // 接收数据
                                                                bit_cnt <= #1 bit_cnt + 4'b0001;
                                                                rx_data <= #1 {rx,rx_data[`BYTE_MSB:`LSB+1]};
                                                                div_cnt <= #1 `UART_DIV_RATE;
                                                            end
                                                    endcase
                                                end
                                            else 
                                                begin // 倒数计数
                                                    div_cnt <= #1 div_cnt - 9'b0_0000_0001;       
                                                end 
                                        end
                                endcase
                            end
                    end
                    
endmodule