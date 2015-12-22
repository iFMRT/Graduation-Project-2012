/* 
  -- ============================================================================ 
  -- FILE NAME  : uart.h 
  -- DESCRIPTION : UART 头文件
  -- ---------------------------------------------------------------------------- 
  -- Date：2015/12/19          
  -- ============================================================================ 
*/ 
 
 
 `ifndef __UART_HEADER__
    `define __UART_HEADER__                 // 包含文件防范用的宏

    /********** 分频计数器 *********/
    `define UART_DIV_RATE          9'd260   // 分频比率
    `define UART_DIV_CNT_W         9        // 分频计数器位宽
    `define UART_DIV_CNT_BUS       8:0      // 分频计数器总线
    /********** 地址 **********/
    `define UART_ADDR_BUS          0:0      // 地址总线
    `define UART_ADDR_W            1        // 地址宽
    `define UART_ADDR_LOC          0:0      // 地址位置
    /********** 控制寄存器 **********/
    `define UART_ADDR_STATUS       1'h0     // 控制寄存器 0 ：状态
    `define UART_ADDR_DATA         1'h1     // 控制寄存器 1 ：收发的数据
    /********** 发送或者接收 **********/
    `define UART_CTRL_IRQ_RX       0        // 接收完成中断
    `define UART_CTRL_IRQ_TX       1        // 发送完成中断
    `define UART_CTRL_BUSY_RX      2        // 接收中标志位
    `define UART_CTRL_BUSY_TX      3        // 发送中标志位
    /********** 总线状态 **********/
    `define UART_STATE_BUS         0:0      // 状态总线
    `define UART_STATE_IDLE        1'b0     // 状态 ：空闲状态
    `define UART_STATE_TX          1'b1     // 状态 ：发送中
    `define UART_STATE_RX          1'b1     // 状态 ：接收中
    /********** 计时器值 **********/
    `define UART_BIT_CNT_BUS       3:0      // 比特计数器总线
    `define UART_BIT_CNT_W         4        // 比特计数器位宽
    `define UART_BIT_CNT_START     4'h0     // 计数器值 ：起始位
    `define UART_BIT_CNT_MSB       4'h8     // 计数器值 ：数据的 MSB
    `define UART_BIT_CNT_STOP      4'h9     // 计时器值 ：停止位
    /********** 发送信号的值 **********/
    `define UART_START_BIT         1'b0     // 起始位
    `define UART_STOP_BIT          1'b1     // 停止位

`endif