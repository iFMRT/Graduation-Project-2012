//-------------------------------------------------------------
// FILENAME: decoder.v
// ESCRIPTION:The decoder module of id_stage
// AUTHOR:cjh
// DETA:2015-12-14 17:03:57
//-------------------------------------------------------------
`include "isa.h"
`include "alu.h"
`include "cmp.h"
`include "ctrl.h"
`include "stddef.h"
`include "cpu.h"
`include "mem.h"

module decoder (
    /********** IF/ID Pipeline Register **********/
    input wire [`WORD_DATA_BUS]  if_pc,          // Program counter
    input wire [`WORD_DATA_BUS]  if_pc_plus4,    // Jump adn link return address
    input wire [`WORD_DATA_BUS]  if_insn,        // Instruction
    input wire                   if_en,          // Pipeline data enable

    /********** GPR Interface **********/
    input wire [`WORD_DATA_BUS]  gpr_rd_data_0,  // Read data 0
    input wire [`WORD_DATA_BUS]  gpr_rd_data_1,  // Read data 1
    output wire [`REG_ADDR_BUS]  gpr_rd_addr_0,  // Read address 0
    output wire [`REG_ADDR_BUS]  gpr_rd_addr_1,  // Read address 1

    /********** 数据转发 **********/
    // LOAD冲突
    // input wire                   id_en,          // 流水线数据有效
    // input wire [`REG_ADDR_BUS]   id_dst_addr,    // 写入地址
    // input wire                   id_gpr_we_,     // 写入有效
    // input wire [`MEM_OP_B]       id_mem_op,      // 内存操作

    // 来自EX阶段的数据转发
    // input wire                   ex_en,          // 流水线数据有效
    // input wire [`REG_ADDR_BUS]   ex_dst_addr,    // 写入地址
    // input wire                   ex_gpr_we_,     // 写入有效
    // input wire [`WORD_DATA_BUS]  ex_fwd_data,    // 数据转发
    // 来自MEM阶段的数据转发
    // input wire [`WORD_DATA_BUS]  mem_fwd_data,   // 数据转发

    /********** 解码结果 **********/
    output reg [`ALU_OP_BUS]       alu_op,         // ALU 操作
    // output reg [`CMP_OP_B]       cmp_op,         // CMP 操作
    output reg [`WORD_DATA_BUS]  alu_in_0,       // ALU 输入 0
    output reg [`WORD_DATA_BUS]  alu_in_1,       // ALU 输入 1
    // output reg [`WORD_DATA_BUS]  cmp_in_0,       // CMP 输入 0
    // output reg [`WORD_DATA_BUS]  cmp_in_1,       // CMP 输入 1
    // output reg                   br_taken,       // 跳转成立
    // output reg                   br_flag,        // 分支标志位
    output reg [`MEM_OP_BUS]       mem_op,         // 内存操作
    output wire [`WORD_DATA_BUS] mem_wr_data,    // mem 写入数据
    output reg                   gpr_mux_ex,     // ex 阶段的 gpr 写入信号选通
    output reg                   gpr_mux_mem,    // mem 阶段的 gpr 写入信号选通
    output reg [`WORD_DATA_BUS]  gpr_wr_data,    // ID 阶段输出的 gpr 输入信号选通
    output wire [`REG_ADDR_BUS]  dst_addr,       // 通用寄存器写入地址
    output reg                   gpr_we_       // 通用寄存器写入操作
    // 第一阶段不考虑 output reg   [`IsaExpBus]     exp_code,      // 异常代码
    // output reg                   ld_hazard       // LOAD 冲突
);

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
    wire         [`WORD_DATA_BUS]    ra_data;                        // 第一个操作数
    wire         [`WORD_DATA_BUS]    rb_data;                        // 第二个操作数

    assign mem_wr_data      = rb_data;
    assign gpr_rd_addr_0    = ra_addr;
    assign gpr_rd_addr_1    = rb_addr;
    assign dst_addr         = if_insn[`INSN_RC];    // Rc 地址

    /********** 转发 **********/
    // always @(*) begin
    //     /* 关于 Ra 的转发 */
    //     if ((id_en       == `ENABLE)  &&
    //         (id_gpr_we_  == `ENABLE_) &&
    //         (id_dst_addr == ra_addr)
    //     ) begin

    //         ra_data = ex_fwd_data;   // 来自 EX 阶段的转发

    //     end else if (
    //         (ex_en       == `ENABLE)  &&
    //         (ex_gpr_we_  == `ENABLE_) &&
    //         (ex_dst_addr == ra_addr)
    //     ) begin

    //         ra_data = mem_fwd_data;  // 来自 MEM 阶段的转发

    //     end else begin

    //         ra_data = gpr_rd_data_0; // 没有发生流水线冲突

    //     end

    //     /* 关于 Rb 的转发*/
    //     if ((id_en       == `ENABLE)  &&
    //         (id_gpr_we_  == `ENABLE_) &&
    //         (id_dst_addr == rb_addr)
    //     ) begin

    //         rb_data = ex_fwd_data;   // 来自 EX 阶段的转发
    //     end else if (
    //         (ex_en       == `ENABLE)  &&
    //         (ex_gpr_we_  == `ENABLE_) &&
    //         (ex_dst_addr == rb_addr)
    //     ) begin

    //         rb_data = mem_fwd_data;  // 来自 MEM 阶段的转发

    //     end else begin

    //         rb_data = gpr_rd_data_1; // 没有发生流水线冲突

    //     end
    // end
    assign ra_data = gpr_rd_data_0; // 没有发生流水线冲突

    assign rb_data = gpr_rd_data_1; // 没有发生流水线冲突

    // /********** Load 冲突的检测 **********/
    // always @(*) begin
    //     if ((id_en == `ENABLE)         &&
    //         (id_mem_op != `MEM_OP_NOP) &&
    //         (    (id_dst_addr == ra_addr) ||
    //              (id_dst_addr == rb_addr)
    //         )
    //     ) begin

    //         ld_hazard = `ENABLE;  // 存在 Load 冲突

    //     end else begin

    //         ld_hazard = `DISABLE; // 不存在 Load 冲突

    //     end
    // end

    /********** 指令译码 **********/
    always @(*) begin
        /* 初始值 */
        alu_op      =   `ALU_OP_NOP;
        // cmp_op      =   `CMP_OP_NOP;
        alu_in_0    =   ra_data;
        alu_in_1    =   rb_data;
        // cmp_in_0    =   ra_data;
        // cmp_in_1    =   rb_data;
        // br_taken    =   `DISABLE;
        // br_flag     =   `DISABLE;
        mem_op      =   `MEM_OP_NOP;
        gpr_we_     =   `DISABLE_;
        gpr_mux_ex  =   `EX_ALU_OUT;
        gpr_mux_mem =   `MEM_MEM_OUT;
        gpr_wr_data = if_pc_plus4;

        //exp_code = `ISA_EXP_NO_EXP;
        /* 指令类型判别 */
        if (if_en == `ENABLE) begin
            case (op)
                `ISA_OP_NOP: begin
                    alu_op      =   `ALU_OP_NOP;
                end
            /* I格式 */
                `ISA_OP_LD: begin // LD指令
                    case(funct3)
                        `ISA_OP_LD_LB: begin       //LB指令
                            alu_op  = `ALU_OP_ADD;
                            alu_in_1 = imm_i;
                            mem_op  = `MEM_OP_LB;
                            gpr_we_ = `ENABLE_;
                        end
                        `ISA_OP_LD_LH: begin       //LH指令
                            alu_op  = `ALU_OP_ADD;
                            alu_in_1 = imm_i;
                            mem_op  = `MEM_OP_LH;
                            gpr_we_ = `ENABLE_;
                        end
                        `ISA_OP_LD_LW: begin       //LW指令
                            alu_op  = `ALU_OP_ADD;
                            alu_in_1 = imm_i;
                            mem_op  = `MEM_OP_LW;
                            gpr_we_ = `ENABLE_;
                        end
                        `ISA_OP_LD_LBU: begin       //LBU指令
                            alu_op  = `ALU_OP_ADD;
                            alu_in_1 = imm_i;
                            mem_op  = `MEM_OP_LBU;
                            gpr_we_ = `ENABLE_;
                        end
                        `ISA_OP_LD_LHU: begin       //LHU指令
                            alu_op  = `ALU_OP_ADD;
                            alu_in_1 = imm_i;
                            mem_op  = `MEM_OP_LHU;
                            gpr_we_ = `ENABLE_;
                        end
                        default       : begin // 未定义命令
                            $display("error");
                        end
                    endcase
                end
                `ISA_OP_ALSI  : begin // Arithmetic Logic Shift Immediate
                    case(funct3)
                        `ISA_OP_ALSI_ADDI :begin   //  ADDI 指令
                            alu_op      = `ALU_OP_ADD;
                            alu_in_1    = imm_i;
                            gpr_we_     = `ENABLE_;
                            gpr_mux_mem = `MEM_EX_OUT;
                        end
                        `ISA_OP_ALSI_SLLI :begin   // SLLI 指令
                            alu_op      = `ALU_OP_SLL;
                            alu_in_1    = imm_i;
                            gpr_we_     = `ENABLE_;
                            gpr_mux_mem = `MEM_EX_OUT;
                            gpr_mux_ex  = `EX_CMP_OUT;
                        end
                        `ISA_OP_ALSI_SLTI:begin   // SLTI 指令
                            // cmp_op      = `CMP_OP_LT;    //这里大概需要一个控制信号，将最后写回寄存器的选通为cmp输出
                            // cmp_in_1    = imm_i;
                            gpr_we_     = `ENABLE_;
                            gpr_mux_mem = `MEM_EX_OUT;
                            gpr_mux_ex  = `EX_CMP_OUT;
                        end
                        `ISA_OP_ALSI_SLTIU:begin   // SLTIU 指令
                            // cmp_op      = `CMP_OP_LTU;
                            // cmp_in_1    = imm_i;
                            gpr_we_     = `ENABLE_;
                            gpr_mux_mem = `MEM_EX_OUT;
                            gpr_mux_ex  = `EX_CMP_OUT;
                        end
                        `ISA_OP_ALSI_XORI:begin   // XORI 指令
                            alu_op      = `ALU_OP_XOR;
                            alu_in_1    = imm_i;
                            gpr_we_     = `ENABLE_;
                            gpr_mux_mem = `MEM_EX_OUT;
                        end
                        `ISA_OP_ALSI_SRI: begin
                            if (
                                funct7 == `ISA_OP_ALSI_SRI_SRLI
                            ) begin   //SRLI 指令
                                alu_op      = `ALU_OP_SRL;
                                alu_in_1    = imm_ir;
                                gpr_we_     = `ENABLE_;
                                gpr_mux_mem = `MEM_EX_OUT;
                            end else if (
                                funct7 == `ISA_OP_ALSI_SRI_SRAI
                            ) begin   //SRAI 指令
                                alu_op      = `ALU_OP_SRA;
                                alu_in_1    = imm_ir;
                                gpr_we_     = `ENABLE_;
                                gpr_mux_mem = `MEM_EX_OUT;
                            end else begin // 未定义命令
                                $display("error");
                            end
                        end
                        `ISA_OP_ALSI_ORI: begin   // ORI 指令
                            alu_op      = `ALU_OP_OR;
                            alu_in_1    = imm_i;
                            gpr_we_     = `ENABLE_;
                            gpr_mux_mem = `MEM_EX_OUT;
                        end
                        `ISA_OP_ALSI_ANDI: begin   // ANDI 指令
                            alu_op      = `ALU_OP_AND;
                            alu_in_1    = imm_i;
                            gpr_we_     = `ENABLE_;
                            gpr_mux_mem = `MEM_EX_OUT;
                        end
                        default       : begin // 未定义命令
                            $display("error");
                        end
                    endcase
                end
                // `ISA_OP_JALR      : begin // JALR指令
                //     alu_op      = `ALU_OP_ADD;
                //     alu_in_1    = imm_i;
                //     gpr_we_     = `ENABLE_;
                //     // br_taken    = `ENABLE;
                //     gpr_mux_ex  = `EX_ID_PCN; // pc + 4
                //     gpr_mux_mem = `MEM_EX_OUT;
                // end
                `ISA_OP_ALS   : begin
                    /* R 格式 */
                    case(funct3)
                        `ISA_OP_ALS_AS: begin
                            if (
                                funct7 == `ISA_OP_ALS_AS_ADD
                            ) begin   //ADD 指令
                                alu_op   = `ALU_OP_ADD;
                                gpr_we_  = `ENABLE_;
                                gpr_mux_mem = `MEM_EX_OUT;
                            end else if(funct7 == `ISA_OP_ALS_AS_SUB) begin   //SUB 指令
                                alu_op   = `ALU_OP_SUB;
                                gpr_we_  = `ENABLE_;
                                gpr_mux_mem = `MEM_EX_OUT;
                            end else begin // 未定义命令
                                $display("error");
                            end
                        end
                        `ISA_OP_ALS_SLL: begin
                            alu_op      = `ALU_OP_SLL;
                            gpr_we_     = `ENABLE_;
                            gpr_mux_mem = `MEM_EX_OUT;
                            gpr_mux_ex  = `EX_CMP_OUT;
                        end
                        `ISA_OP_ALS_SLT: begin
                            // cmp_op      = `CMP_OP_LT;
                            gpr_we_     = `ENABLE_;
                            gpr_mux_mem = `MEM_EX_OUT;
                            gpr_mux_ex  = `EX_CMP_OUT;
                        end
                        `ISA_OP_ALS_SLTU: begin
                            // cmp_op      = `CMP_OP_LTU;
                            gpr_we_     = `ENABLE_;
                            gpr_mux_mem = `MEM_EX_OUT;
                            gpr_mux_ex  = `EX_CMP_OUT;
                        end
                        `ISA_OP_ALS_XOR: begin
                            alu_op      = `ALU_OP_XOR;
                            gpr_we_     = `ENABLE_;
                            gpr_mux_mem = `MEM_EX_OUT;
                        end
                        `ISA_OP_ALS_SR: begin
                            if(funct7 == `ISA_OP_ALS_SR_SRL) begin
                                alu_op      = `ALU_OP_SRL;
                                gpr_we_     = `ENABLE_;
                                gpr_mux_mem = `MEM_EX_OUT;
                            end
                            else if(funct7 == `ISA_OP_ALS_SR_SRA) begin
                                alu_op      = `ALU_OP_SRA;
                                gpr_we_     = `ENABLE_;
                                gpr_mux_mem = `MEM_EX_OUT;
                            end
                                 else begin // 未定义命令
                                     $display("error");
                                 end
                        end
                        `ISA_OP_ALS_OR: begin
                            alu_op      = `ALU_OP_OR;
                            gpr_we_     = `ENABLE_;
                            gpr_mux_mem = `MEM_EX_OUT;
                        end
                        `ISA_OP_ALS_AND: begin
                            alu_op      = `ALU_OP_AND;
                            gpr_we_     = `ENABLE_;
                            gpr_mux_mem = `MEM_EX_OUT;
                        end
                        default       : begin // 未定义命令
                            $display("error");
                        end
                    endcase
                end
                // /* U 格式 */
                // `ISA_OP_LUI  : begin // LUI 指令
                //     gpr_we_     = `DISABLE_;// 选通imm_u作为结果
                //     gpr_wr_data = imm_u;
                //     gpr_mux_ex  = `EX_ID_PCN;
                //     gpr_mux_mem = `MEM_EX_OUT;
                // end
                // `ISA_OP_AUIPC  : begin // LUIPC 指令
                //     alu_op      = `ALU_OP_ADD;
                //     alu_in_0    = if_pc;
                //     alu_in_1    = imm_u;
                //     gpr_we_     = `ENABLE_;
                //     gpr_mux_mem = `MEM_EX_OUT;
                // end
                /* S 格式 */
                `ISA_OP_ST  : begin // SW 命令
                    case(funct3)
                        `ISA_OP_ST_SB   : begin
                            alu_op   = `ALU_OP_ADD;
                            alu_in_1 = imm_s;
                            mem_op   = `MEM_OP_SB;
                        end
                        `ISA_OP_ST_SH   : begin
                            alu_op   = `ALU_OP_ADD;
                            alu_in_1 = imm_s;
                            mem_op   = `MEM_OP_SH;
                        end
                        `ISA_OP_ST_SW   : begin
                            alu_op   = `ALU_OP_ADD;
                            alu_in_1 = imm_s;
                            mem_op   = `MEM_OP_SW;
                        end
                        default       : begin // 未定义命令
                            $display("error");
                        end
                    endcase
                end
                // /* B 格式 */
                // `ISA_OP_BR    : begin //
                //     case(funct3)
                //         `ISA_OP_BR_BEQ: begin
                //             alu_op   = `ALU_OP_ADD;
                //             cmp_op   = `CMP_OP_EQ;
                //             alu_in_0 = if_pc;
                //             alu_in_1 = imm_b;
                //             br_flag  = `ENABLE;
                //         end
                //         `ISA_OP_BR_BNE: begin
                //             alu_op   = `ALU_OP_ADD;
                //             cmp_op   = `CMP_OP_NE;
                //             alu_in_0 = if_pc;
                //             alu_in_1 = imm_b;
                //             br_flag  = `ENABLE;
                //         end
                //         `ISA_OP_BR_BLT: begin
                //             alu_op   = `ALU_OP_ADD;
                //             cmp_op   = `CMP_OP_LT;
                //             alu_in_0 = if_pc;
                //             alu_in_1 = imm_b;
                //             br_flag  = `ENABLE;
                //         end
                //         `ISA_OP_BR_BGE: begin
                //             alu_op   = `ALU_OP_ADD;
                //             cmp_op   = `CMP_OP_GE;
                //             alu_in_0 = if_pc;
                //             alu_in_1 = imm_b;
                //             br_flag  = `ENABLE;
                //         end
                //         `ISA_OP_BR_BLTU: begin
                //             alu_op   = `ALU_OP_ADD;
                //             cmp_op   = `CMP_OP_LTU;
                //             alu_in_0 = if_pc;
                //             alu_in_1 = imm_b;
                //             br_flag  = `ENABLE;
                //         end
                //         `ISA_OP_BR_BGEU: begin
                //             alu_op   = `ALU_OP_ADD;
                //             cmp_op   = `CMP_OP_GEU;
                //             alu_in_0 = if_pc;
                //             alu_in_1 = imm_b;
                //             br_flag  = `ENABLE;
                //         end
                //         default       : begin // 未定义命令
                //             $display("error");
                //         end
                //     endcase
                // end
                /* J 格式 */
                // `ISA_OP_JAL  : begin // JAL指令
                //     alu_op      = `ALU_OP_ADD;
                //     alu_in_0    = if_pc;
                //     alu_in_1    = imm_j;
                //     br_taken    = `ENABLE;
                //     gpr_we_     = `ENABLE_;
                //     gpr_mux_ex  = `EX_ID_PCN;
                //     gpr_mux_mem = `MEM_EX_OUT;
                // end
                /* 其它命令 */
                default       : begin // 未定义命令
                    $display("error");
                end
            endcase
        end
    end
    
endmodule