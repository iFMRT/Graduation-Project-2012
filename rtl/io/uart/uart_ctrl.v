/* 
  -- ============================================================================ 
  -- FILE NAME  : uart_ctrl.v 
  -- DESCRIPTION : UART 的控制模块
  -- ---------------------------------------------------------------------------- 
  -- Date：2015/12/21         
  -- ============================================================================ 
*/ 

/********** 通用头文件 **********/
`include "stddef.h"

/********** 模块头文件 **********/
`include "uart.h"

module uart_ctrl(
                /* 时钟复位 */
                input  clk,                         // 时钟
                input  reset,                       // 异步复位
                /* 总线接口 */
                input  cs_,                         // 片选信号
                input  as_,                         // 地址选通信号
                input  rw,                          // 读 / 写
                input  addr,                        // 地址
                input  [`WORD_DATA_BUS]wr_data,     // 写入的数据
                output reg[`WORD_DATA_BUS]rd_data,  // 读取的数据
                output reg rdy_,                    // 就绪信号
                /* 中断 */
                output reg irq_rx,                  // 接收中断请求信号（控制寄存器 0）
                output reg irq_tx,                  // 发送中断请求信号（控制寄存器 0）
                /* 控制信号 */
                input  rx_busy,                     // 接收中标志信号（控制寄存器 0）
                input  rx_end,                      // 接收完成信号
                input  [`BYTE_DATA_BUS]rx_data,     // 收的数据
                input  tx_busy,                     // 发送中标志信号（控制寄存器 0）
                input  tx_end,                      // 发送完成信号
                output reg tx_start,                // 发送开始信号
                output reg[`BYTE_DATA_BUS]tx_data   // 发送的数据
                );

                /* 控制寄存器1 */
                reg [`BYTE_DATA_BUS]rx_buf;         // 接收用数据缓冲区


    /********** UART控制逻辑电路 **********/
    always @(posedge clk or negedge reset) 
        begin
            if (reset == `ENABLE_) 
                begin
                    /* 异步复位 */
                    rd_data <= #1 `WORD_DATA_W'b0;
                    rdy_ <= #1 `DISABLE;
                    irq_tx <= #1 `DISABLE;
                    irq_rx <= #1 `DISABLE;
                    tx_start <= #1 `DISABLE;
                    tx_data <= #1 `BYTE_DATA_W'b0;
                end
            else 
                begin
                    /* 就绪信号的生成 */
                    if ((cs_ == `ENABLE_) && (as_ == `ENABLE_))
                        begin
                            rdy_ <= #1 `ENABLE_;
                        end
                    else 
                        begin
                            rdy_ <= #1 `DISABLE_;
                        end
                    /* 读取访问 */
                    if((cs_ == `ENABLE_) && (as_ == `ENABLE_) && (rw == `READ))
                        begin
                            case(addr)
                                `UART_ADDR_STATUS: // 控制寄存器0
                                    begin
                                        rd_data <= #1 {{`WORD_DATA_W-4{ 1'b0 }},tx_busy,rx_busy,irq_tx,irq_rx};
                                    end
                                `UART_ADDR_DATA: // 控制寄存器1
                                    begin
                                        rd_data <= #1 {{`WORD_DATA_W-8{ 1'b0 }},rx_buf};
                                    end
                            endcase
                        end
                    else 
                        begin
                            rd_data <= #1 `WORD_DATA_W'b0;
                        end
                    /* 写入访问 */
                    // 控制寄存器0：发送完成中断
                    if (tx_end == `ENABLE)
                        begin
                            irq_tx <= #1 `ENABLE;
                        end
                    else if ((cs_ == `ENABLE_) && (as_ == `ENABLE_) && (rw == `WRITE) && (addr == `UART_ADDR_STATUS))
                        begin
                            irq_tx <= #1 wr_data[`UART_CTRL_IRQ_TX];
                        end
                    // 控制寄存器0：接收完成中断
                    if (rx_end == `ENABLE)
                        begin
                            irq_rx <= #1 `ENABLE;
                        end
                    else if ((cs_ == `ENABLE_) && (as_ == `ENABLE_) && (rw == `WRITE) && (addr == `UART_ADDR_STATUS))
                        begin
                            irq_rx <= #1 wr_data[`UART_CTRL_IRQ_RX];
                        end
                    // 写入控制寄存器1
                    if ((cs_ == `ENABLE_) && (as_ == `ENABLE_) && (rw == `WRITE) && (addr == `UART_ADDR_DATA))
                        begin // 发送开始
                            tx_start <= #1 `ENABLE;
                            tx_data <= #1 wr_data[`BYTE_MSB:`LSB];
                        end
                    else
                        begin
                            tx_start <= #1 `DISABLE;
                            tx_data <= #1 `BYTE_DATA_W'b0;
                        end
                    /* 接收数据 */
                    if(rx_end == `ENABLE)
                        begin
                            rx_buf <= #1 rx_data;
                        end
                end
        end
endmodule