/* 
 -- ============================================================================
 -- FILE NAME   : isa.h
 -- DESCRIPTION : the instruction set that we need to implement
 -- ----------------------------------------------------------------------------
 -- Date : 2015/12/8                       Coding_by : kippy
 -- ============================================================================
*/

`ifndef __ISA_HEADER__
    `define __ISA_HEADER__                   // Include Guard

//------------------------------------------------------------------------------
// 初始化
//------------------------------------------------------------------------------
    /********** 初始化 **********/
    `define ISA_NOP                   32'h0         // No Operation
    /********** 定义 **********/

    /******** 操作类型的定义 ********/
    /******** 操作码字段的定义 ********/
    // 定义位数
    `define ISA_OP_W                   7            // 操作码位数
    
    // 定义操作码内容
    // NOP Opcode
    // `define ISA_OP_NOP              7'b0000000   // NOP should use ADDI x0, x0, 0
    // I 格式
    `define ISA_OP_LD                  7'b0000011   // LoaD  
    `define ISA_OP_ALSI                7'b0010011   // Arithmetic Logic Shift Immediate
    `define ISA_OP_JALR                7'b1100111   // Jump And Link Register
    // R 格式
    `define ISA_OP_ALS                 7'b0110011   // Arithmetic Logic Shift
    // U 格式       
    `define ISA_OP_LUI                 7'b0110111   // Load Upper Immediate
    `define ISA_OP_AUIPC               7'b0010111   // Add Upper Immediate to PC 
    // S 格式
    `define ISA_OP_ST                  7'b0100011   // STore
    // B 格式
    `define ISA_OP_BR                  7'b1100011   // BRanch
    // J 格式
    `define ISA_OP_JAL                 7'b1101111   // Jump And Link

    /******** 功能码3字段的定义 ********/
    // 定义位数
    `define ISA_Funct3_W                3            // Funct3 位数
    // 定义功能码3字段内容
    // ISA_OP_LD
    `define ISA_OP_LD_LB                3'b000   // 读取有符号的字节
    `define ISA_OP_LD_LH                3'b001   // 读取有符号的半字
    `define ISA_OP_LD_LW                3'b010   // 读取有符号的字
    `define ISA_OP_LD_LBU               3'b100   // 读取无符号的字节
    `define ISA_OP_LD_LHU               3'b101   // 读取无符号的半字
    // ISA_OP_ALSI
    `define ISA_OP_ALSI_ADDI            3'b000   // 寄存器与常数间的加法
    `define ISA_OP_ALSI_SLLI            3'b001   // 寄存器与常数间的逻辑左移
    `define ISA_OP_ALSI_SLTI            3'b010   // 寄存器与常数间的有符号比较（<）
    `define ISA_OP_ALSI_SLTIU           3'b011   // 寄存器与常数间的无符号比较（<）
    `define ISA_OP_ALSI_XORI            3'b100   // 寄存器与常数间的逻辑异或
    `define ISA_OP_ALSI_SRI             3'b101   // 寄存器与常数间的右移
    `define ISA_OP_ALSI_ORI             3'b110   // 寄存器与常数间的逻辑或
    `define ISA_OP_ALSI_ANDI            3'b111   // 寄存器与常数间的逻辑与
    // ISA_OP_ST    
    `define ISA_OP_ST_SB                3'b000   // 写入字节
    `define ISA_OP_ST_SH                3'b001   // 写入半字
    `define ISA_OP_ST_SW                3'b010   // 写入字
    // ISA_OP_ALS   
    `define ISA_OP_ALS_AS               3'b000   // 寄存器间的有符号加减法
    `define ISA_OP_ALS_SLL              3'b001   // 寄存器间的逻辑左移
    `define ISA_OP_ALS_SLT              3'b010   // 寄存器间的有符号比较（<）
    `define ISA_OP_ALS_SLTU             3'b011   // 寄存器间的无符号比较（<）
    `define ISA_OP_ALS_XOR              3'b100   // 寄存器间的逻辑异或
    `define ISA_OP_ALS_SR               3'b101   // 寄存器间的右移
    `define ISA_OP_ALS_OR               3'b110   // 寄存器间的逻辑或
    `define ISA_OP_ALS_AND              3'b111   // 寄存器间的逻辑与
    // ISA_OP_BR        
    `define ISA_OP_BR_BEQ               3'b000   // 寄存器间的比较（==）
    `define ISA_OP_BR_BNE               3'b001   // 寄存器间的比较（!=） 
    `define ISA_OP_BR_BLT               3'b100   // 寄存器间的有符号比较（<）
    `define ISA_OP_BR_BGE               3'b101   // 寄存器间的有符号比较（>=）
    `define ISA_OP_BR_BLTU              3'b110   // 寄存器间的无符号比较（<）
    `define ISA_OP_BR_BGEU              3'b111   // 寄存器间的无符号比较（>=）
    
    /******** 功能码7字段的定义 ********/
    // 定义位数
    `define ISA_Funct7_W                7            // Funct7 位数
    // 定义功能码7字段内容
    // ISA_OP_ALSI_SRI
    `define ISA_OP_ALSI_SRI_SRLI        7'b0000000   // 寄存器与常数间的逻辑右移
    `define ISA_OP_ALSI_SRI_SRAI        7'b0100000   // 寄存器与常数间的算术右移
    // ISA_OP_ALS_AS
    `define ISA_OP_ALS_AS_ADD           7'b0000000   // 寄存器间的有符号加法
    `define ISA_OP_ALS_AS_SUB           7'b0100000   // 寄存器间的有符号减法
    // ISA_OP_ALS_SR    
    `define ISA_OP_ALS_SR_SRL           7'b0000000   // 寄存器间的逻辑右移
    `define ISA_OP_ALS_SR_SRA           7'b0100000   // 寄存器间的算术右移

`endif
