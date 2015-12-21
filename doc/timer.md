# 定时器

##定时器的设计

CPU 通过访问 I/O 的控制寄存器对 I/O 进行控制。我们这里设计的定时器的控制寄存器的规格如表 1-1 所示。

|寄存器编号 |  说明  |偏移地址|访问类型 |
|:----      | :----  |:----  |:----     |
|0          |控制    |0x0    |读/写     |
|1          |中断    |0x4    |读/写     |
|2          |最大值  |0x8    |读/写     |
|3          |计数器  |0xc    |读/写     |

###控制寄存器 0 :控制寄存器**

**[0] :起始位(S)**

该位用来控制定时器的开 / 关。该位为 1 时定时器开始计数。

**[1] :模式位(M)**

该位用来设置定时器的动作模式。该位为 1 时定时器为循环定时模式。

控制寄存器 0 的结构如图 1.1。

![reg0](/doc/img/ctrl_reg_0.jpg)

###控制寄存器 1 :中断寄存器

**[0] :中断位(I)**

当定时器计数达到设定的最大值时该位变为 1。该位为 1 时向 CPU 发送中断请求。

控制寄存器 1 的结构如图 1.2。

![reg1](/doc/img/ctrl_reg_1.png)

###控制寄存器 2 :最大值寄存器

**[31:0] :最大值(EXPR_VAL)**

该寄存器用来设置计数的最大值。如果计数器累计到与该寄存器的值相等时,
表示定时时间到。

控制寄存器 2 的结构如图 1.3。

![reg2](/doc/img/ctrl_reg_2.png)

###控制寄存器 3 :计数器寄存器

**[31:0] :计数器(COUNTER)**

该寄存器为定时器的计数器。计时开始后该寄存器的值开始增长。

控制寄存器 3 的结构如图 1.4。

![reg3](/doc/img/ctrl_reg_1.png)

##定时器的实现

定时器的宏一览如表 1-2 所示。

| 宏名字            |值     |含义               |
| :----             |:----  | :----             |
|TIMER_ADDR_W       |2      |地址宽度           |
|TimerAddrBus       |1:0    |地址总线           |
|TimerAddrLoc       |1:0    |地址的位置         |
|TIMER_ADDR_CTRL    |2'h0   |控制寄存器 0:控制  |
|TIMER_ADDR_INTR    |2'h1   |控制寄存器 1:中断  |
|TIMER_ADDR_EXPR    |2'h2   |控制寄存器 2:最大值|
|TIMER_ADDR_COUNTER |2'h3   |控制寄存器 3:计数器|
|TimerStartLoc      |0      |起始位的位置       |
|TimerModeLoc       |1      |模式位的位置       |
|TIMER_MODE_ONE_SHOT|1'b0   |模式 :单次定时器   |
|TIMER_MODE_PERIODIC|1'b1   |模式 :循环定时器   |
|TimerIrqLoc        |0      |中断位的位置       |

信号线一览如表 1-3 所示。

| 分组       |信号      |信号类型       |数据类型|位宽 |含义       |
| :----      |:----     | :----         |:----   |:----| :----          |
|时钟        |clk       |输入端口       |wire	 |1    |时钟|
|复位        |reset     |输入端口       |wir	 |1    |异步复位|
|总线接口    |cs_       |输入端口       |wir	 |1    |片选|
|总线接口    |as_       |输入端口       |wir	 |1    |地址选通|
|总线接口    |rw        |输入端口       |wir	 |1    |读/写|
|总线接口    |addr      |输入端口       |wir	 |2    |地址|
|总线接口    |wr_data   |输入端口       |wir	 |32   |数据写入|
|总线接口    |rd_data   |输出端口       |re	 |32   | 数据读取|
|总线接口    |rdy_      |输出端口       |re	 |1    | 就绪信号|
|控制寄存器 0|mode      |内部信号 	|re	 |1    |控制寄存器 0 :模式位|
|控制寄存器 0|start     |内部信号 	|reg 	 |1    |控制寄存器 0 :起始位|
|控制寄存器 1|irq       |输出端口       |reg     |1    |控制寄存器 1 :中断请求信号|
|控制寄存器 2| expr_val |内部信号       |reg     |32   | 控制寄存器 2 :最大值|
|控制寄存器 3| counter  |内部信号       |reg     |32   |控制寄存器 3 :计数器|
|内部信号    | expr_flag|内部信号       |wire    |1    |计时完成标志位|

timer 端口连接图如图 1.5。

![timer](/doc/img/timer.png)

源程序如下所示。

```
/********** 计时完成标志位 **********/
	wire expr_flag = ((start == `ENABLE) && (counter == expr_val)) ? `ENABLE : `DISABLE;

	/********** 定时器控制 **********/
	always @(posedge clk or negedge reset) 
	begin
		if (reset == `ENABLE_) 
			begin
				/* 异步复位 */
				rd_data	 <= #1 `WORD_DATA_W'h0;
				rdy_	 <= #1 `DISABLE_;
				start	 <= #1 `DISABLE;
				mode	 <= #1 `TIMER_MODE_ONE_SHOT;
				irq		 <= #1 `DISABLE;
				expr_val <= #1 `WORD_DATA_W'h0;
				counter	 <= #1 `WORD_DATA_W'h0;
			end 
		else 
			begin
				/* 准备就续绪 */
				if ((cs_ == `ENABLE_) && (as_ == `ENABLE_)) 
					begin
						rdy_	 <= #1 `ENABLE_;
					end 
				else 
					begin
						rdy_	 <= #1 `DISABLE_;
					end
				/* 读访问 */
				if ((cs_ == `ENABLE_) && (as_ == `ENABLE_) && (rw == `READ)) 
					begin
						case (addr)
							`TIMER_ADDR_CTRL	: 
								begin // 控制寄存器 0
									rd_data	 <= #1 {{`WORD_DATA_W-2{1'b0}}, mode, start};
								end
							`TIMER_ADDR_INTR	: 
								begin // 控制寄存器 1
									rd_data	 <= #1 {{`WORD_DATA_W-1{1'b0}}, irq};
								end
							`TIMER_ADDR_EXPR	: 
								begin // 控制寄存器 2
									rd_data	 <= #1 expr_val;
								end
							`TIMER_ADDR_COUNTER : 
								begin // 控制寄存器 3
									rd_data	 <= #1 counter;
								end
						endcase
					end 
				else 
					begin
						rd_data	 <= #1 `WORD_DATA_W'h0;
					end
				/* 写访问 */
				// 控制寄存器 0
				if ((cs_ == `ENABLE_) && (as_ == `ENABLE_) && 
					(rw == `WRITE) && (addr == `TIMER_ADDR_CTRL)) 
					begin
						start	 <= #1 wr_data[`TIMER_START_LOC];
						mode	 <= #1 wr_data[`TIMER_MODE_LOC];
					end 
				else if ((expr_flag == `ENABLE)	 &&
							 (mode == `TIMER_MODE_ONE_SHOT)) 
					begin
						start	 <= #1 `DISABLE;
					end
				// 控制寄存器 1
				if (expr_flag == `ENABLE) 
					begin
						irq		 <= #1 `ENABLE;
					end 
				else if ((cs_ == `ENABLE_) && (as_ == `ENABLE_) && 
							 (rw == `WRITE) && (addr ==	 `TIMER_ADDR_INTR)) 
					begin
						irq		 <= #1 wr_data[`TimerIrqLoc];
					end
				// 控制寄存器 2
				if ((cs_ == `ENABLE_) && (as_ == `ENABLE_) && 
					(rw == `WRITE) && (addr == `TIMER_ADDR_EXPR)) 
					begin
						expr_val <= #1 wr_data;
					end
				// 控制寄存器 3
				if ((cs_ == `ENABLE_) && (as_ == `ENABLE_) && 
					(rw == `WRITE) && (addr == `TIMER_ADDR_COUNTER)) 
					begin
						counter	 <= #1 wr_data;
					end 
				else if (expr_flag == `ENABLE) 
					begin
						counter	 <= #1 `WORD_DATA_W'h0;
					end 
				else if (start == `ENABLE) 
					begin
						counter	 <= #1 counter + 1'd1;
					end
			end
	end
```






