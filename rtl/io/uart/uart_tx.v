/* 
  -- ============================================================================ 
  -- FILE NAME  : uart_tx.v 
  -- DESCRIPTION : UART 的发送模块
  -- ---------------------------------------------------------------------------- 
  -- Date：2015/12/19          
  -- ============================================================================ 
*/ 

/********** 通用头文件 **********/
`include "stddef.h"

/********** 模块头文件 **********/
`include "uart.h"

module uart_tx(
                /*时钟复位信号*/
               input  clk,                            // 时钟
               input  reset,                          // 异步复位
               /*控制信号*/
               input  tx_start,                       // 发送开始信号
               input  [`BYTE_DATA_BUS]tx_data,        // 发送的数据
               output tx_busy,                        // 发送中标志信号
               output reg tx_end,                     // 发送完成信号
               /* UART 发送信号 */
               output reg tx                          // UART 发送信号
              );

                reg  state;                           // 发送模块的状态
                reg  [`UART_DIV_CNT_BUS] div_cnt;     // 分频计数器
                reg  [`UART_BIT_CNT_BUS] bit_cnt;     // 比特计数器
                reg  [`BYTE_DATA_BUS]    sh_reg;      // 发送用移位寄存器

             /********** 发送中标志信号的生成 **********/
             assign tx_busy = ( state == `UART_STATE_TX ) ? `ENABLE : `DISABLE;

             /********** 发送逻辑电路 **********/
             always @(posedge clk or negedge reset) 
                 begin
                    if (reset == `ENABLE_) 
                        begin
                            state <= #1 `UART_STATE_IDLE;
                            div_cnt <= #1 `UART_DIV_RATE;
                            bit_cnt <= #1 `UART_BIT_CNT_START;
                            sh_reg <= #1 `BYTE_DATA_W'b0;   
                            tx_end <= #1 `DISABLE;
                            tx <= #1 `UART_STOP_BIT;
                        end
                    else  
                        begin
                            case(state)
                                `UART_STATE_IDLE: // 空闲状态 
                                    begin
                                        if(tx_start == `ENABLE)
                                            begin // 开始发送
                                                state <= #1 `UART_STATE_TX;
                                                sh_reg <= #1 tx_data;
                                                tx <= #1 `UART_START_BIT;
                                            end
                                        tx_end <= #1 `DISABLE;
                                    end
                                `UART_STATE_TX:   // 发送中
                                    /* 通过时钟分频调整波特率 */
                                    begin
                                        if(div_cnt == 9'b0)
                                            begin
                                                /* 发送下一个比特数据 */
                                                case(bit_cnt)
                                                    `UART_BIT_CNT_MSB:
                                                        begin // 发送停止位
                                                            bit_cnt <= #1 `UART_BIT_CNT_STOP;
                                                            tx <= #1 `UART_STOP_BIT;
                                                        end
                                                    `UART_BIT_CNT_STOP:
                                                        begin // 发送完成
                                                            state <= #1 `UART_STATE_IDLE;
                                                            bit_cnt <= #1 `UART_BIT_CNT_START;
                                                            tx_end <= #1 `ENABLE;
                                                        end
                                                    default:
                                                        begin // 数据的发送
                                                            bit_cnt <= #1 bit_cnt + 1;
                                                            sh_reg <= #1 sh_reg >> 1'b1;
                                                            tx <= #1 sh_reg[`LSB];
                                                        end
                                                endcase
                                                div_cnt <= `UART_DIV_RATE;
                                            end
                                        else 
                                            begin
                                                div_cnt <= div_cnt - 9'b0_0000_0001;
                                            end
                                    end
                            endcase
                        end
                 end

endmodule