/* 
  -- ============================================================================ 
  -- FILE NAME  : uart.v 
  -- DESCRIPTION : UART 的顶层模块
  -- ---------------------------------------------------------------------------- 
  -- Date：2015/12/22          
  -- ============================================================================ 
*/ 

/********** 通用头文件 **********/
`include "stddef.h"

/********** 模块头文件 **********/
`include "uart.h"

module uart(input  clk,                                 // 时钟
            input  reset,                               // 异步复位
            /* 总线接口 */
            input  cs_,                                 // 片选信号
            input  as_,                                 // 地址选通信号
            input  rw,                                  // 读 / 写
            input  addr,                                // 地址
            input  [`WORD_DATA_BUS]wr_data,             // 写入的数据
            output [`WORD_DATA_BUS]rd_data,             // 读取的数据
            output rdy_,                                // 就绪信号
            /* 中断 */
            output irq_rx,                              // 接收中断请求信号（控制寄存器 0）
            output irq_tx,                              // 发送中断请求信号（控制寄存器 0）
            /* UART 接收发送信号 */
            input  rx,                                  // UART 接收信号
            output tx                                   // UART 发送信号
            );

        /********** 内部信号 **********/
        wire tx_start;                                  // 发送开始信号
        wire [`BYTE_DATA_BUS]tx_data;                   // 发送的数据
        wire tx_busy;                                   // 发送中标志信号（控制寄存器 0）
        wire tx_end;                                    // 发送完成信号
        wire rx_busy;                                   // 接收中标志信号（控制寄存器 0）
        wire rx_end;                                    // 接收完成信号
        wire [`BYTE_DATA_BUS]rx_data;                   // 收的数据

        /********** UART 发送模块 **********/
        uart_tx uart_tx(/* 时钟复位信号 */
                        .clk            (clk),            // 时钟
                        .reset          (reset),          // 异步复位
                        /* 控制信号 */
                        .tx_start       (tx_start),       // 发送开始信号
                        .tx_data        (tx_data),        // 发送的数据
                        .tx_busy        (tx_busy),        // 发送中标志信号
                        .tx_end         (tx_end),         // 发送完成信号
                        /* UART 发送信号 */
                        .tx             (tx)              // UART 发送信号
                      );
        
        /********** UART 接收模块 **********/
        uart_rx uart_rx(/* 时钟复位 */
                       .clk             (clk),             // 时钟
                       .reset           (reset),           // 异步复位
                       /* 控制信号 */
                       .rx_busy         (rx_busy),         // 接收中标志信号
                       .rx_end          (rx_end),          // 接收完成信号
                       .rx_data         (rx_data),         // 接收数据兼移位寄存器
                       .rx              (rx)               // UART 接收信号
                       );

        /********** UART 控制模块 **********/
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

endmodule