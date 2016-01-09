## ID 阶段流水线寄存器

ID 阶段的流水寄存器负责把 ID 阶段的运算结果进行保存，然后在下一周期传给 EX 阶段。这其中包括解码器解码所得出的 EX 阶段的操作数和控制信号，MEM 阶段的操作数、操作数选通信号和控制信号，还有 WR 阶段的操作数、操作数在各个阶段的选通信号以及控制信号。

+ 信号线一览

分组                  |信号名         |信号类型  |数据类型   |位宽      |含义
:------               |:------        |:------   |:------    |:------   |:------ 
时钟复位              |clk            |输入信号  |wire       | 1        |时钟
时钟复位              |reset          |输入信号  |wire       | 1        |异步复位
解码结果              |alu_op         |输入信号  |wire       | 4        |ALU 操作
解码结果              |cmp_op         |输入信号  |wire       | 3        |CMP 操作
解码结果              |alu_in_0       |输入信号  |wire       | 32       |ALU 输入 0
解码结果              |alu_in_1       |输入信号  |wire       | 32       |ALU 输入 1
解码结果              |cmp_in_0       |输入信号  |wire       | 32       |CMP 输入 0
解码结果              |cmp_in_1       |输入信号  |wire       | 32       |CMP 输入 1
解码结果              |br_taken       |输入信号  |wire       | 1        |跳转发生信号
解码结果              |br_flag        |输入信号  |wire　     | 1        |分支标志位
解码结果              |mem_op         |输入信号  |wire       | 4        |存储器操作
解码结果              |mem_wr_data    |输入信号  |wire       | 32       |存储器写入数据
解码结果              |dst_addr       |输入信号  |wire       | 5        |目标寄存器地址
解码结果              |gpr_we_        |输入信号  |wire       | 1        |通用寄存器写入信号
解码结果              |gpr_mux_ex     |输入信号  |wire       | 1        |通用寄存器写入数据选通信号（EX）
解码结果              |gpr_mux_mem    |输入信号  |wire       | 1        |通用寄存器写入数据选通信号（MEM）
解码结果              |gpr_wr_data    |输入信号  |wire       | 32       |ID 阶段输出的 gpr 输入信号
流水线控制信号        |stall          |输入信号  |wire       | 1        |寄存器停顿
流水线控制信号        |flush          |输入信号  |wire       | 1        |寄存器刷新
IF/ID 流水线寄存器    |if_en          |输入信号  |wire       | 1        |流水线数据有效
ID/EX 流水线寄存器    |id_en          |输出信号  |reg        | 1        |流水线数据有效
ID/EX 流水线寄存器    |id_alu_op      |输出信号  |reg        | 4        |ALU 操作
ID/EX 流水线寄存器    |id_cmp_op      |输出信号  |reg        | 3        |CMP 操作
ID/EX 流水线寄存器    |id_alu_in_0    |输出信号  |reg        | 32       |ALU 输入 0
ID/EX 流水线寄存器    |id_alu_in_1    |输出信号  |reg        | 32       |ALU 输入 1
ID/EX 流水线寄存器    |id_cmp_in_0    |输出信号  |reg        | 32       |CMP 输入 0
ID/EX 流水线寄存器    |id_cmp_in_1    |输出信号  |reg        | 32       |CMP 输入 1
ID/EX 流水线寄存器    |id_br_taken    |输出信号  |reg        | 1        |跳转发生信号
ID/EX 流水线寄存器    |id_br_flag     |输出信号  |reg        | 1        |分支标志位
ID/EX 流水线寄存器    |id_mem_op      |输出信号  |reg        | 2        |存储器操作
ID/EX 流水线寄存器    |id_mem_wr_data |输出信号  |reg        | 32       |存储器写入数据
ID/EX 流水线寄存器    |id_dst_addr    |输出信号  |reg        | 5        |目标寄存器地址
ID/EX 流水线寄存器    |id_gpr_we_     |输出信号  |reg        | 1        |寄存器写入
ID/EX 流水线寄存器    |id_gpr_mux_ex  |输出信号  |reg        | 1        |gpr 写回数据选通（EX）
ID/EX 流水线寄存器    |id_gpr_mux_mem |输出信号  |reg        | 1        |gpr 写回数据选通（MEM）
ID/EX 流水线寄存器    |id_gpr_wr_data |输出信号  |reg        | 32       |ID 阶段输出的 gpr 写回数据

- 代码详解

+ 异步复位

```
    always @(posedge clk or reset) begin
        if (reset == `ENABLE) begin
            /* 异步复位 */
            id_en          <= #1 `DISABLE;
            id_alu_op      <= #1 `ALU_OP_NOP;
            id_cmp_op       <= #1 `CMP_OP_NOP;
            id_alu_in_0    <= #1 `WORD_DATA_W'h0;
            id_alu_in_1    <= #1 `WORD_DATA_W'h0;
            id_cmp_in_0     <= #1 `WORD_DATA_W'h0;
            id_cmp_in_1     <= #1 `WORD_DATA_W'h0;
            id_br_taken    <= #1 `DISABLE;
            id_br_flag      <= #1 `DISABLE;
            id_mem_op      <= #1 `MEM_OP_NOP;
            id_mem_wr_data <= #1 `WORD_DATA_W'h0;
            id_ex_out_mux  <= #1 `ALU_OUT;
            id_gpr_we_     <= #1 `DISABLE_;
            id_dst_addr    <= #1 5'h0;
            id_gpr_mux_ex  <= #1 `DISABLE;
            id_gpr_mux_mem <= #1 `DISABLE;
            id_gpr_wr_data <= #1 `WORD_DATA_W'h0;
```
异步复位为寄存器的复位信号，在异步复位时，流水线寄存器里的所有信号均赋值为无效或者默认值。

+ 数据更新

```
        /* 寄存器数据更新 */
        if (stall == `DISABLE) begin 
            if (flush == `ENABLE) begin // 清空寄存器
                id_en          <= #1 `DISABLE;
                id_alu_op      <= #1 `ALU_OP_NOP;
                id_cmp_op       <= #1 `CMP_OP_NOP;
                id_alu_in_0    <= #1 `WORD_DATA_W'h0;
                id_alu_in_1    <= #1 `WORD_DATA_W'h0;
                id_cmp_in_0     <= #1 `WORD_DATA_W'h0;
                id_cmp_in_1     <= #1 `WORD_DATA_W'h0;
                id_br_taken    <= #1 `DISABLE;
                id_br_flag      <= #1 `DISABLE;
                id_mem_op      <= #1 `MEM_OP_NOP;
                id_mem_wr_data <= #1 `WORD_DATA_W'h0;
                id_ex_out_mux  <= #1 `ALU_OUT;
                id_gpr_we_     <= #1 `DISABLE_;
                id_dst_addr    <= #1 5'h0;
                id_gpr_mux_ex  <= #1 `DISABLE;
                id_gpr_mux_mem <= #1 `DISABLE;
                id_gpr_wr_data <= #1 `WORD_DATA_W'h0;
            end else begin              // 给寄存器赋值
                id_en          <= #1 if_en;
                id_alu_op      <= #1 alu_op;
                id_cmp_op       <= #1 cmp_op;
                id_alu_in_0    <= #1 alu_in_0;
                id_alu_in_1    <= #1 alu_in_1;
                id_cmp_in_0     <= #1 cmp_in_0;
                id_cmp_in_1     <= #1 cmp_in_1;
                id_br_taken    <= #1 br_taken;
                id_br_flag      <= #1 br_flag;
                id_mem_op      <= #1 mem_op;
                id_mem_wr_data <= #1 mem_wr_data;
                id_ex_out_mux  <= #1 ex_out_mux;
                id_gpr_we_     <= #1 gpr_we_;
                id_dst_addr    <= #1 dst_addr;
                id_gpr_mux_ex  <= #1 gpr_mux_ex;
                id_gpr_mux_mem <= #1 gpr_mux_mem;
                id_gpr_wr_data <= #1 gpr_wr_data;
            end
        end
```
#### 寄存器数据的刷新

寄存器的刷新发生在跳转或分支发生或者 LOAD 冲突发生时，寄存器刷新时把所有的信号都置为无效或默认，使下一阶段不进行任何操作。当 flush 信号有效时进行寄存器刷新。

#### 寄存器赋值

时钟上升沿时，寄存器写入本周起的运算结果，存储 ID 阶段译码后传递过来的数据和控制信号。