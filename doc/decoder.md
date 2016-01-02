## 指令解码器

指令解码器从输入的指令码中分解出各个指令字段，生成地址、数据和控制信号，数据的转发、load 冲突的检测，分支的判定也在这个指令解码器中进行。

- 信号线一览

分组                  | 信号名         | 信号类型 | 数据类型 | 位宽   |  含义
:------               | :------        | :------  | :------  |:------ | :------
IF/ID流水线寄存器     | if_pc          | 输入端口 | wire     | 32     | 程序计数器
IF/ID流水线寄存器     | if_pc_plus4    | 输入端口 | wire     | 32     | 返回地址
IF/ID流水线寄存器     | if_insn        | 输入端口 | wire     | 32     | 指令
IF/ID流水线寄存器     | if_en          | 输入端口 | wire     | 1      | 流水线数据的有效标志位
GPR接口               | gpr_rd_data_0  | 输入端口 | wire     | 32     | 读取数据0
GPR接口               | gpr_rd_data_1  | 输入端口 | wire     | 32     | 读取数据1
GPR接口               | gpr_rd_addr_0  | 输出端口 | wire     | 5      | 读取地址0
GPR接口               | gpr_rd_addr_1  | 输出端口 | wire     | 5      | 读取地址1
LOAD 冲突的检测       | id_en          | 输入端口 | wire     | 1      | 流水线数据有效
LOAD 冲突的检测       | id_dst_addr    | 输入端口 | wire     | 5      | 写入地址
LOAD 冲突的检测       | id_gpr_we_     | 输入端口 | wire     | 1      | 写入有效
LOAD 冲突的检测       | id_mem_op      | 输入端口 | wire     | 2      | 内存操作
来自EX阶段的数据转发  | ex_en          | 输入端口 | wire     | 1      | 流水线数据的有效
来自EX阶段的数据转发  | ex_dst_addr    | 输入端口 | wire     | 5      | 写入地址
来自EX阶段的数据转发  | ex_gpr_we_     | 输入端口 | wire     | 1      | 写入有效
来自EX阶段的数据转发  | ex_fwd_we      | 输入端口 | wire     | 32     | 数据转发
来自MEM阶段的数据转发 | mem_fwd_data   | 输入端口 | wire     | 32     | 数据转发
解码结果              | alu_op         | 输出端口 | reg      | 4      | ALU 操作
解码结果              | cmp_op         | 输出端口 | reg      | 3      | CMP 操作
解码结果              | alu_in_0       | 输出端口 | reg      | 32     | ALU 输入 0
解码结果              | alu_in_1       | 输出端口 | reg      | 32     | ALU 输入 1
解码结果              | cmp_in_0       | 输出端口 | reg      | 32     | CMP 输入 0
解码结果              | cmp_in_1       | 输出端口 | reg      | 32     | CMP 输入 2
解码结果              | br_addr        | 输出端口 | reg      | 32     | 分支地址
解码结果              | br_taken       | 输出端口 | reg      | 1      | 分支成立
解码结果              | br_flag        | 输出端口 | reg      | 1      | 分支标志位
解码结果              | mem_op         | 输出端口 | reg      | 4      | 内存操作
解码结果              | mem_wr_data    | 输出端口 | wire     | 32     | 内存写入数据
解码结果              | gpr_we_        | 输出端口 | reg      | 1      | 通用寄存器写入有效
解码结果              | dst_addr       | 输出端口 | reg      | 5      | 通用寄存器写入地址
解码结果              | gpr_mux_ex     | 输出端口 | reg      | 1      | ex 阶段的通用寄存器写回选通信号
解码结果              | gpr_mux_mem    | 输出端口 | reg      | 1      | mem 阶段的通用寄存器写回选通信号
解码结果              | gpr_wr_data    | 输出端口 | reg      | 32     | ID 阶段输出的 gpr 写入信号
解码结果              | ld_hazard      | 输出端口 | reg      | 1      | Load冲突
指令字段              | op             | 内部信号 | wire     | 7      | 操作码
指令字段              | ra_addr        | 内部信号 | wire     | 5      | Ra地址
指令字段              | rb_addr        | 内部信号 | wire     | 5      | Rb地址
指令字段              | rc_addr        | 内部信号 | wire     | 5      | Rc地址
指令字段              | funct3         | 内部信号 | wire     | 3      | 部件功能
指令字段              | funct7         | 内部信号 | wire     | 7      | 有符号无符号和加减操作区分 
立即数处理            | imm_u          | 输出信号 | wire     | 32     | U 格式立即数
立即数处理            | imm_i          | 内部信号 | wire     | 32     | I 格式立即数
立即数处理            | imm_s          | 内部信号 | wire     | 32     | S 格式立即数
立即数处理            | imm_b          | 内部信号 | wire     | 32     | B 格式立即数
立即数处理            | imm_j          | 内部信号 | wire     | 32     | J 格式立即数

- 代码详解

+ 指令字段的分解

```
    /********** 指令字段 **********/
    wire [`INS_OP_B]        op      = if_insn[`INSN_OP];    // 操作码
    wire [`REG_ADDR_BUS]    ra_addr = if_insn[`INSN_RA];    // Ra 地址
    wire [`REG_ADDR_BUS]    rb_addr = if_insn[`INSN_RB];    // Rb 地址    
    wire [`INS_F3_B]        funct3  = if_insn[`INSN_F3];    // funct3
    wire [`INS_F7_B]        funct7  = if_insn[`INSN_F7];    // funct7
    
    /********** 立即数 **********/
    // U 格式立即数处理
    wire [`WORD_DATA_BUS] imm_u  = {if_insn[31:12],12'b0}; 
    // I 格式立即数处理
    wire [`WORD_DATA_BUS] imm_i  = {{20{if_insn[31]}},if_insn[31:20]};
    // I 格式右移指令立即数处理
    wire [`WORD_DATA_BUS] imm_ir = {{26{if_insn[31]}},if_insn[24:20]};
    // S 格式立即数处理
    wire [`WORD_DATA_BUS] imm_s  = {{20{if_insn[31]}},if_insn[31:25],if_insn[11:7]};
    // B 格式立即数处理
    wire [`WORD_DATA_BUS] imm_b  = {{20{if_insn[31]}},if_insn[7],if_insn[30:25],if_insn[11:8],1'b0};
    // J 格式立即数处理
    wire [`WORD_DATA_BUS] imm_j  = {{12{if_insn[31]}},if_insn[19:12],if_insn[20],if_insn[30:21],1'b0};
    /********** 两个操作数 **********/
    reg         [`WORD_DATA_BUS]    ra_data;                        // 第一个操作数
    reg         [`WORD_DATA_BUS]    rb_data;                        // 第二个操作数
    /********** 直接赋值 **********/
    assign mem_wr_data      = rb_data;
    assign gpr_rd_addr_0    = ra_addr;
    assign gpr_rd_addr_1    = rb_addr;
    assign dst_addr         = if_insn[`INSN_RC];    // Rc 地址

```

#### [1] 指令字段的分解

此处从输入的指令码中分解出各个指令字段。

#### [2] 立即数字段的扩充

各种格式的立即数在指令中长短不一，这里将各种格式的立即数扩充为 32 位，便于接下来对立即数进行的运算。

#### [3] 两个操作数

两个操作数即为经过转发部件后确定的两个寄存器操作数，如果无需转发，这里的两个操作数就是从寄存器读取的两个操作数。

#### [4] 直接赋值

此处对寄存器读取地址进行赋值。通用寄存器读取地址使用指令的 Ra 字段（ra_addr）和 Rb 字段（rb_addr）。存储器写回数据恒为第二操作数，而得益于 riscv 指令集编码的特色，通用寄存器写回地址总是在 Rc 字段。

+ 数据转发

```
    /********** 转发 **********/
    always @(*) 
        begin
            /* 关于 Ra 的转发 */
            if ((id_en == `ENABLE) && (id_gpr_we_ == `ENABLE_) && (id_dst_addr == ra_addr)) 
                begin
                    ra_data = ex_fwd_data;   // 来自 EX 阶段的转发
                end 
            else if ((ex_en == `ENABLE) && (ex_gpr_we_ == `ENABLE_) && (ex_dst_addr == ra_addr)) 
                begin
                    ra_data = mem_fwd_data;  // 来自 MEM 阶段的转发
                end 
            else 
                begin
                    ra_data = gpr_rd_data_0; // 没有发生流水线冲突
                end
            /* 关于 Rb 的转发*/
            if ((id_en == `ENABLE) && (id_gpr_we_ == `ENABLE_) && (id_dst_addr == rb_addr)) 
                begin
                    rb_data = ex_fwd_data;   // 来自 EX 阶段的转发
                end 
            else if ((ex_en == `ENABLE) && (ex_gpr_we_ == `ENABLE_) && (ex_dst_addr == rb_addr)) 
                begin
                    rb_data = mem_fwd_data;  // 来自 MEM 阶段的转发
                end 
            else 
                begin
                    rb_data = gpr_rd_data_1; // 没有发生流水线冲突
                end
        end
```

#### [1] Ra 寄存器的数据转发

因为流水线前的结果会成为最新值，转发的比较按 EX 阶段、 MEM 阶段的顺序进行。

来自 EX 阶段的数据转发的产生条件为： ID/EX 流水线寄存器有效、 Ra 寄存器的读取地址（ra_addr）与寄存器写入地址（id_dst_addr）相等，且寄存器的写入有效信号（id_gpr_we_）为有效。

来自 MEM 阶段的数据转发的产生条件为： EX/MEM 流水线寄存器有效、 Ra 寄存器的读取地址（ra_addr）与寄存器写入地址（ex_dst_addr）相等，且寄存器的写入有效信号（ex_gpr_we_）为有效。无法进行转发时，直接使用寄存器堆读取值。

####[2] Rb 寄存器的数据转发

来自 EX 阶段的数据转发的产生条件为： ID/EX 流水线寄存器有效、 Rb 寄存器的读取地址（rb_addr）与寄存器写入地址（id_dst_addr）相等，且寄存器的写入有效信号（id_gpr_we_）为有效。来自 MEM 阶段的数据转发的产生条件为： EX/MEM 流水线寄存器有效、 Rb 寄存器的读取地址（rb_addr）与寄存器写入地址（ex_dst_addr）相等，且寄存器的写入有效信号（ex_gpr_we_）为有效。无需进行数据转发时，直接使用寄存器堆读取值。

+ Load 冲突检测

```
    /********** Load 冲突的检测 **********/
    always @(*) 
        begin
            if ((id_en == `ENABLE) && (id_gpr_we_ = `ENABLE) && (id_mem_op != `MEM_OP_NOP) && ((id_dst_addr == ra_addr) || (id_dst_addr == rb_addr))) 
                begin
                    ld_hazard = `ENABLE;  // 存在 Load 冲突
                end 
            else 
                begin
                    ld_hazard = `DISABLE; // 不存在 Load 冲突
                end
        end
```

#### [1] Load 冲突检测

Load 冲突产生的条件为： ID/EX 流水线寄存器中存放的之前的指令的内存操作不为空，通用寄存器写入有效且写入地址与当前指令的读取地址相等。 ID/EX 流水线寄存器有效、内存操作（id_mem_op）为 Load 指令（MEM_OP_LDW），且之前指令的写入地址（id_dst_addr）与 Ra 寄存器的地址（ra_addr）或 Rb 寄存器的地址（rb_addr）相等时使能 Load 冲突信号（ld_hazard）。

+ 内部信号的初始化

```
    always @(*) begin
        /* 初始值 */
        alu_op      =   `ALU_OP_NOP;
        cmp_op      =   `CMP_OP_NOP;
        alu_in_0    =   ra_data;
        alu_in_1    =   rb_data;
        cmp_in_0    =   ra_data;
        cmp_in_1    =   rb_data;
        br_taken    =   `DISABLE;
        br_flag     =   `DISABLE;
        mem_op      =   `MEM_OP_NOP;
        gpr_we_     =   `DISABLE_;
        gpr_mux_ex  =   `EX_ALU_OUT;
        gpr_mux_mem =   `MEM_MEM_OUT;
        gpr_wr_data =   if_pc_plus4;
```
#### [1] ALU 部分

ALU 部分分出 ALU 和 CMP 两个基础部件，其中，ALU 用来进行算术逻辑运算，而 CMP 用来进行比较运算，满足 riscv 的算术逻辑运算和比较运算在同一指令中同时进行的需求。所以在 EX 阶段需要给出 ALU 和 CMP 两个控制信号，它们各自的两个操作数输入也在 ID 阶段直接分出。在初始状态下，ALU 和 CMP 的默认操作为空操作，两个端口的默认输入为 ra_data 和 rb_data。

#### [2] 跳转和分支控制信号

跳转信号可直接给出，在 EX 计算出目标地址之后直接实现跳转，分支信号则要和条件分支的条件判断信号一起决定是否跳转。初始状态下，跳转发生信号和分支标志位均置为无效，避免指令跳转的无端发生。

#### [3] 选通控制信号

在写入存储器的指令中，写入数据恒为 Rb 寄存器中的操作数，所以对于写入存储器的数据信号无需选通，而写入寄存器的数据可能来自不同的阶段，所以这里进行选通，在每个阶段的选通结果要放在转发数据之前得出。

+ 各条指令功能上的实现

初步设计没有精确到部件细节，对于 risc-v 基本指令集的实现只涉及到功能层次，在下一阶段的优化设计中，将会结合性能、功耗、时间损耗等多方面因素，对这些逻辑功能的进行硬件细节化。

###**Testbench**

对译码阶段的验证比较复杂，由于整条流水线还没有完成整合，所以这里对译码阶段的验证不作基本指令集的完全覆盖，我们采用的测试向量包括每一种类型的指令以及转发和冲突检测的功能实现。

** 输入输出信号 **

信号名          | JAL          | BEQ           | SW            | AUIPC         | ADD          |JALR          | ADDI          | lw            |
:------         | :------      | :------       | :------       | :------       | :------      |:------       | :------       | :------       |
if_pc           | 32'd32       | 32'd32        | 32'd32        | 32'd32        | 32'd32       | 32'd32       | 32'd32        | 32'o32        |
if_pc_plus4     | 32'd36       | 32'd36        | 32'd36        | 32'd36        | 32'd36       | 32'd36       | 32'd36        | 32'o36        |
if_insn         | 32'h004002ef | 32'h00430263  | 32'h00432223  | 32'h00008297  | 32'h004302b3 | 32'h002302e7 | 32'h00230293  | 32'h00232283  |
if_en           |  ENABLE      |  ENABLE       |  ENABLE       |  ENABLE       |  ENABLE      |  ENABLE      |  ENABLE       |  ENABLE       |
gpr_rd_data_0   | 32'd20       | 32'd20        | 32'd20        | 32'd20        | 32'd20       | 32'd20       | 32'd20        | 32'o20        |
gpr_rd_data_1   | 32'd16       | 32'd16        | 32'd16        | 32'd16        | 32'd16       | 32'd16       | 32'd16        | 32'o16        |
gpr_rd_addr_0   | 5'b00000     | 5'b00110      | 5'b00110      | 5'b00001      | 5'b00110     | 5'b00110     | 5'b00110      | 5'b00110      |
gpr_rd_addr_1   | 5'b00100     | 5'b00100      | 5'b00100      | 5'b00000      | 5'b00100     | 5'b00010     | 5'b00010      | 5'b00010      |
id_en           |  DISABLE     |  ENABLE       |  ENABLE       |  ENABLE       |  ENABLE      |  ENABLE      |  ENABLE       |  ENABLE       |
id_dst_addr     | 5'b00001     | 5'b00001      | 5'b00001      | 5'b00001      | 5'b00001     | 5'b00110     | 5'b00110      | 5'b00110      |
id_gpr_we_      |  DISABLE_    |  DISABLE_     |  DISABLE_     |  DISABLE_     |  DISABLE_    |  ENABLE_     |  ENABLE_      |  ENABLE_      |
id_mem_op       |  MEM_OP_NOP  |  MEM_OP_NOP   |  MEM_OP_NOP   |  MEM_OP_NOP   |  MEM_OP_NOP  |  MEM_OP_LW   |  MEM_OP_NOP   |  MEM_OP_NOP   |
ex_en           |  DISABLE     |  ENABLE       |  ENABLE       |  ENABLE       |  ENABLE      |  ENABLE      |  ENABLE       |  ENABLE       |
ex_dst_addr     | 5'b00010     | 5'b00010      | 5'b00010      | 5'b00010      | 5'b00100     | 5'b00110     | 5'b00110      | 5'b00110      |
ex_gpr_we_      |  DISABLE_    |  DISABLE_     |  DISABLE_     |  ENABLE_      |  ENABLE_     |  DISABLE_    |  ENABLE_      |  ENABLE_      |
ex_fwd_data     | 32'd12       | 32'd12        | 32'd12        | 32'd12        | 32'd12       | 32'd12       | 32'd12        | 32'd12        |
mem_fwd_data    | 32'd8        | 32'd8         | 32'd8         | 32'd8         | 32'd8        | 32'd8        | 32'd8         | 32'd8         |
alu_op          |  ALU_OP_ADD  |  ALU_OP_ADD   |  ALU_OP_ADD   |  ALU_OP_ADD   |  ALU_OP_ADD  |  ALU_OP_ADD  |  ALU_OP_ADD   |  ALU_OP_ADD   |
cmp_op          |  CMP_OP_NOP  |  CMP_OP_EQ    |  CMP_OP_NOP   |  CMP_OP_NOP   |  CMP_OP_NOP  |  CMP_OP_NOP  |  CMP_OP_NOP   |  CMP_OP_NOP   |
alu_in_0        | 32'd32       | 32'd32        | 32'd20        | 32'd32        | 32'd20       | 32'd12       | 32'd12        | 32'd12        |
alu_in_1        | 32'd4        | 32'd4         | 32'd4         | 32'd32768     | 32'd8        | 32'd2        | 32'd2         | 32'd2         |
cmp_in_0        | 32'd20       | 32'd20        | 32'd20        | 32'd20        | 32'd20       | 32'd12       | 32'd12        | 32'd12        |
cmp_in_1        | 32'd16       | 32'd16        | 32'd16        | 32'd16        | 32'd8        | 32'd16       | 32'd16        | 32'd16        |
br_taken        |  ENABLE      |  DISABLE      |  DISABLE      |  DISABLE      |  DISABLE     |  ENABLE      |  DISABLE      |  DISABLE      |
br_flag         |  DISABLE     |  ENABLE       |  DISABLE      |  DISABLE      |  DISABLE     |  DISABLE     |  DISABLE      |  DISABLE      |
mem_op          |  MEM_OP_NOP  |  MEM_OP_NOP   |  MEM_OP_SW    |  MEM_OP_NOP   |  MEM_OP_NOP  |  MEM_OP_NOP  |  MEM_OP_NOP   |  MEM_OP_LW    |
mem_wr_data     | 32'd16       | 32'd16        | 32'd16        | 32'd16        | 32'd8        | 32'd16       | 32'd16        | 32'd16        |
gpr_we_         |  ENABLE_     |  DISABLE_     |  DISABLE_     |  ENABLE_      |  ENABLE_     |  ENABLE_     |  ENABLE_      |  ENABLE_      |
dst_addr        | 5'b00101     | 5'b00100      | 5'b00100      | 5'b00101      | 5'b00101     | 5'b00101     | 5'b00101      | 5'b00101      |
gpr_mux_ex      |  EX_ID_PCN   |  EX_EX_OUT    |  EX_EX_OUT    |  EX_ALU_OUT   |  EX_ALU_OUT  |  EX_ID_PCN   |  EX_ALU_OUT   |  EX_ALU_OUT   |
gpr_mux_mem     |  MEM_EX_OUT  |  MEM_MEM_OUT  |  MEM_MEM_OUT  |  MEM_EX_OUT   |  MEM_EX_OUT  |  MEM_EX_OUT  |  MEM_EX_OUT   |  MEM_MEM_OUT  |
gpr_wr_data     | 32'd36       | 32'd36        | 32'd36        | 32'd36        | 32'd36       | 32'd36       | 32'd36        | 32'd36        |
ld_hazard       |  DISABLE     |  DISABLE      |  DISABLE      |  DISABLE      |  DISABLE     |  ENABLE      |  DISABLE      |  DISABLE      |

#### 测试用例简介

本次测试共用到八条指令作为测试用例，J 格式、B 格式、S 格式、R 格式、U 格式各用一条指令作为测试用例，验证其逻辑功能实现的正确性。I 格式又根据不同的功能类型分出 lw,addi 和 jalr 三条测试用例。

（1）JAL 指令，JAL 指令实现指令计数器以当前 PC 加偏移量为地址的的跳转，跳转地址由 ALU 计算，同时将 PC + 4 的值写回通用寄存器，所以在这里，寄存器写回数据选通 PCN，ALU 进行加法操作，跳转有效。在本测试用例中，转发和 LOAD 冲突停顿无效。

（2）BEQ 指令，B 格式的指令是唯一一种同时用到 ALU 和 CMP 两种 EX 部件的指令。其中 ALU 部件计算分支目标地址，CMP 部件判断是否符合分支条件。CMP 的判断结果结合分支标志来确定分支是否成立。在这里，把当前 PC 值和立即数作为 ALU 的两个操作数，而把两个寄存器操作数作为 CMP 的两个操作数。在本测试用例中，转发和 LOAD 冲突停顿无效。

（3）SW 指令，这里选用 SW 指令测试 S 格式的指令。在本测试用例中，存储器写入设置为字写入，写入地址为第一个操作数加立即数，这里把两个操作数交给 ALU 进行计算。在本测试用例中，转发和 LOAD 冲突停顿无效。

（4）AUIPC 指令，AUIPC 属于 U 格式，本条指令提取 PC，并将其与立即数的和存入到目的寄存器，所以在这里寄存器写入有效，PC 和立即数作为两个操作数传给 ALU 来计算寄存器写入数据。在本测试用例中，转发和 LOAD 冲突停顿无效。

（5）ADD 指令，R 格式的指令将寄存器读取的两个数据作为操作数进行计算，最后结果写入目的寄存器。在这里 ALU 进行加法操作，寄存器写入有效，写回数据选通的是 ALU 输出。需要注意的是，这里的第二操作数并不是寄存器的 Rb 端口读出的数据，因为这里设置了数据冲突，mem阶段所执行指令的写回地址与第二操作数的取数地址相同，所以第二操作数从 MEM 阶段转发。

（6）JALR 指令， JALR 指令编码格式属于 I 格式，但其功能与其它的 I 格式指令完全不同。解码 JALR 格式指令要先给出 ALU 信号来计算跳转地址，同时要给出寄存器写入信号，以写回 PC + 4 的值。这里出现了 EX 阶段的转发，并且 LOAD 冲突停顿有效。

（7）ADDI 指令，代表了 I 格式指令的另一种功能类别，即寄存器同立即数的运算指令，结果写回目的寄存器。在这条测试用例中，两个转发同时有效，默认为 EX 阶段的转发有效。LOAD 冲突停顿无效。

（8）LW 指令，I 格式指令的第三种功能类别，从存储器中取数，取数地址由寄存器操作数加立即数偏移量构成，由 ALU 计算得出，在这里同样设置两个转发同时有效，验证转发部件逻辑功能的正确性。