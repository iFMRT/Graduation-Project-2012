////////////////////////////////////////////////////////////////////
// Engineer:       Junhao Chen                                    //
//                                                                //
// Additional contributions by:                                   //
//                 Beyond Sky - fan-dave@163.com                  //
//                 Kippy Chen - 799182081@qq.com                  //
//                 Leway Colin - colin4124@gmail.com              //
//                                                                //
// Design Name:    Decoder                                        //
// Project Name:   FMRT Mini Core                                 //
// Language:       Verilog                                        //
//                                                                //
// Description:    Decoder.                                       //
//                                                                //
////////////////////////////////////////////////////////////////////

`include "common_defines.v"
`include "base_core_defines.v"

module decoder (
    /********** IF/ID Pipeline Register **********/
    input  wire [`WORD_DATA_BUS]  pc,            // Current PC
    input  wire [`WORD_DATA_BUS]  if_pc,         // Next PC
    input  wire [`WORD_DATA_BUS]  if_insn,       // Current Instruction
    input  wire                   if_en,         // Pipeline data enable
    /********** Two Operand **********/
    input  wire [`WORD_DATA_BUS]  rs1_data,      // The first operand
    input  wire [`WORD_DATA_BUS]  rs2_data,      // The second operand
    /********** GPR Interface **********/
    output wire [`REG_ADDR_BUS]   gpr_rs1_addr,  // Read rs1 address
    output wire [`REG_ADDR_BUS]   gpr_rs2_addr,  // Read rs2 address
    /********** CSRs Interface **********/
    input  wire [`WORD_DATA_BUS]  csr_rd_data,   // Read from CSRs
    output reg  [`CSR_OP_BUS]     csr_op,        // CSRs operation
    output wire [`CSR_ADDR_BUS]   csr_addr,      // Access CSRs address
    output reg  [`WORD_DATA_BUS]  csr_wr_data,   // Write to CSRs
    /********** Decoder Result **********/
    output reg  [`ALU_OP_BUS]     alu_op,        // ALU Operation
    output reg  [`WORD_DATA_BUS]  alu_in_0,      // ALU input 0
    output reg  [`WORD_DATA_BUS]  alu_in_1,      // ALU input 1
    output reg  [`CMP_OP_BUS]     cmp_op,        // CMP Operation
    output reg  [`WORD_DATA_BUS]  cmp_in_0,      // CMP input 0
    output reg  [`WORD_DATA_BUS]  cmp_in_1,      // CMP input 1
    output reg                    jump_taken,    // Jump taken

    output reg  [`MEM_OP_BUS]     mem_op,        // Memory operation
    output wire [`WORD_DATA_BUS]  mem_wr_data,   // Memory write data
    output reg  [`EX_OUT_SEL_BUS] ex_out_sel,    // Select EX stage outputs
    output reg  [`WORD_DATA_BUS]  gpr_wr_data,   // The data write to GPR
    output wire [`REG_ADDR_BUS]   rd_addr,       // GPR write address
    output reg                    gpr_we_,       // GPR write enable
    output reg                    is_jalr,       // is JALR instruction
    output reg  [`EXP_CODE_BUS]   exp_code,      // Exception code

    output wire [`INSN_OP_BUS]    op,            // OpCode
    output wire [`REG_ADDR_BUS]   rs1_addr,
    output wire [`REG_ADDR_BUS]   rs2_addr,
    output reg  [1:0]             src_reg_used,  // which source registers used
    output reg                    is_eret,       // is ERET instruction
    /********** Hart Control Interface **********/
    // input from Hart Control Unit
    input  wire                   get_hart_idle,     // is hart idle 1: idle, 0: non-idle
    input  wire [`HART_STT_B]     get_hart_val,      // is hart idle 1: idle, 0: non-idle
    input  wire [`HART_STATE_B]   hart_acti_hstate,   // 3:0
    input  wire [`HART_STATE_B]   hart_idle_hstate,   // 3:0
    // output to Hart Control Unit
    output reg                    hstart,
    output reg                    hkill,
    output reg  [`HART_ID_B]      set_hart_id,
    // input from IF stage
    input  wire [`HART_ID_B]      if_hart_id,
    // output to IF stage
    output reg  [`HART_ID_B]      hs_id,          // Hart start id
    output reg  [`WORD_DATA_BUS]  hs_pc           // Hart start pc
);

    /********** Instruction Field **********/
    assign               op       = if_insn[`INSN_OP];
    assign               rs1_addr = if_insn[`INSN_RS1];  // Rs1 address
    assign               rs2_addr = if_insn[`INSN_RS2];  // Rs2 address
    wire [`INSN_F3_BUS]  funct3   = if_insn[`INSN_F3];   // funct3
    wire [`INSN_F7_BUS]  funct7   = if_insn[`INSN_F7];   // funct7
    wire [`INSN_F12_BUS] funct12  = if_insn[`INSN_F12];  // funct12
    assign rd_addr                = if_insn[`INSN_RD];   // Rc address
    assign csr_addr               = if_insn[`INSN_CSR];  // CSRs address


    /********** Source Register Used State **********/
    assign mem_wr_data  = rs2_data;
    assign gpr_rs1_addr = rs1_addr;
    assign gpr_rs2_addr = rs2_addr;


    /********** Immediate **********/
    // U type
    wire [`WORD_DATA_BUS] imm_u  = {if_insn[31:12],12'b0};
    // I type
    wire [`WORD_DATA_BUS] imm_i  = {{20{if_insn[31]}},if_insn[31:20]};
    // I type shift right immediate
    wire [`WORD_DATA_BUS] imm_ir = {{26{if_insn[31]}},if_insn[24:20]};
    // S type
    wire [`WORD_DATA_BUS] imm_s  = {{20{if_insn[31]}},if_insn[31:25],if_insn[11:7]};
    // B type
    wire [`WORD_DATA_BUS] imm_b  = {{20{if_insn[31]}},if_insn[7],if_insn[30:25],if_insn[11:8],1'b0};
    // J type
    wire [`WORD_DATA_BUS] imm_j  = {{12{if_insn[31]}},if_insn[19:12],if_insn[20],if_insn[30:21],1'b0};
    // rs1 field is used as immediate, zero-extends
    wire [`WORD_DATA_BUS] rs1_zimm = {27'b0, if_insn[19:15]};


    /********** Instruction **********/
    always @(*) begin
        /* Default */
        src_reg_used = 2'b00;
        alu_op       = `ALU_OP_NOP;
        cmp_op       = `CMP_OP_NOP;
        alu_in_0     = rs1_data;
        alu_in_1     = rs2_data;
        cmp_in_0     = rs1_data;
        cmp_in_1     = rs2_data;
        jump_taken   = `DISABLE;
        mem_op       = `MEM_OP_NOP;
        gpr_we_      = `DISABLE_;
        is_jalr      = `DISABLE;
        ex_out_sel   = `EX_OUT_ALU;
        gpr_wr_data  = if_pc;

        exp_code     = `EXP_NO_EXP;
        is_eret      = `DISABLE;
        csr_op       = `CSR_OP_NOP;
        csr_wr_data  = `WORD_DATA_W'h0;

        hstart       = `DISABLE;
        hkill        = `DISABLE;
        hs_id        = `HART_ID_W'h0;
        hs_pc        = `WORD_DATA_W'h0;
        set_hart_id  = `HART_ID_W'h0;

        /* Decode instruction type */
        if (if_en == `ENABLE) begin
            case (op)
                // Warning: NOP should should use ADDI x0, x0, 0 instead

                //////////////////////////////////
                //  _     ____    ______ _____  //
                // | |   |  _ \  / / ___|_   _| //
                // | |   | | | |/ /\___ \ | |   //
                // | |___| |_| / /  ___) || |   //
                // |_____|____/_/  |____/ |_|   //
                //                              //
                //////////////////////////////////

                /******** Load type ********/
                `OP_LD: begin
                    src_reg_used   = 2'b01; // do not use rs2
                    alu_op  = `ALU_OP_ADD;
                    alu_in_1 = imm_i;
                    gpr_we_ = `ENABLE_;
                    case(funct3)
                        `OP_LD_LB : mem_op = `MEM_OP_LB;  // Load byte
                        `OP_LD_LH : mem_op = `MEM_OP_LH;  // Load half word
                        `OP_LD_LW : mem_op = `MEM_OP_LW;  // Load word
                        `OP_LD_LBU: mem_op = `MEM_OP_LBU; // Load byte unsigned
                        `OP_LD_LHU: mem_op = `MEM_OP_LHU; // Load half word unsigned
                        default   : begin                 // Undefined LD type instruction
                            exp_code = `EXP_ILLEGAL_INSN;
                            $display("ISA LD OP error");
                        end
                    endcase
                end

                /******** Store type ********/
                `OP_ST  : begin // SW instruction
                    src_reg_used   = 2'b11;       // use rs1 and rs2
                    alu_op         = `ALU_OP_ADD;
                    alu_in_1       = imm_s;
                    case(funct3)
                        `OP_ST_SB: mem_op = `MEM_OP_SB;
                        `OP_ST_SH: mem_op = `MEM_OP_SH;
                        `OP_ST_SW: mem_op = `MEM_OP_SW;
                        default      : begin      // Undefined instruction
                            exp_code = `EXP_ILLEGAL_INSN;
                            $display("OP_ST error");
                        end
                    endcase
                end


                //////////////////////////////////////
                //      _ _   _ __  __ ____  ____   //
                //     | | | | |  \/  |  _ \/ ___|  //
                //  _  | | | | | |\/| | |_) \___ \  //
                // | |_| | |_| | |  | |  __/ ___) | //
                //  \___/ \___/|_|  |_|_|   |____/  //
                //                                  //
                //////////////////////////////////////

                /******** Jump and Link Register ********/
                `OP_JALR      : begin
                    src_reg_used = 2'b01;       // do not use rs2
                    alu_op       = `ALU_OP_ADD;
                    alu_in_1     = imm_i;
                    gpr_we_      = `ENABLE_;
                    is_jalr      = `ENABLE;
                    jump_taken   = `ENABLE;
                    ex_out_sel   = `EX_OUT_PCN; // pc + 4
                    gpr_wr_data  = if_pc;
                end

                /******** Jump and Link ********/
                `OP_JAL  : begin
                    src_reg_used = 2'b00;       // do not use rs1 and rs2
                    alu_op       = `ALU_OP_ADD;
                    alu_in_0     = pc;
                    alu_in_1     = imm_j;
                    jump_taken   = `ENABLE;
                    gpr_we_      = `ENABLE_;
                    ex_out_sel   = `EX_OUT_PCN;
                    gpr_wr_data  = if_pc;
                end

                /******** Branch ********/
                `OP_BR    : begin
                    src_reg_used   = 2'b11;     // use rs1 and rs2
                    alu_op   = `ALU_OP_ADD;
                    alu_in_0 = pc;
                    alu_in_1 = imm_b;
                    case(funct3)
                        `OP_BR_BEQ : cmp_op = `CMP_OP_EQ;
                        `OP_BR_BNE : cmp_op = `CMP_OP_NE;
                        `OP_BR_BLT : cmp_op = `CMP_OP_LT;
                        `OP_BR_BGE : cmp_op = `CMP_OP_GE;
                        `OP_BR_BLTU: cmp_op = `CMP_OP_LTU;
                        `OP_BR_BGEU: cmp_op = `CMP_OP_GEU;
                        default    : begin      // Undefined instruction
                            exp_code = `EXP_ILLEGAL_INSN;
                            $display("error");
                        end
                    endcase
                end


                //////////////////////////
                //     _    _    _   _  //
                //    / \  | |  | | | | //
                //   / _ \ | |  | | | | //
                //  / ___ \| |__| |_| | //
                // /_/   \_\_____\___/  //
                //                      //
                //////////////////////////

                /******** Arithmetic Logic Shift Immediate ********/
                `OP_ALSI  : begin
                    src_reg_used = 2'b01;       // do not use rs2
                    gpr_we_      = `ENABLE_;
                    alu_in_1     = imm_i;
                    cmp_in_1     = imm_i;
                    case(funct3)
                        // ADDI instruction
                        `OP_ALSI_ADDI : alu_op = `ALU_OP_ADD;
                        // SLLI instruction
                        `OP_ALSI_SLLI : alu_op = `ALU_OP_SLL;
                        // XORI instruction
                        `OP_ALSI_XORI : alu_op = `ALU_OP_XOR;
                        // ORI instruction
                        `OP_ALSI_ORI  : alu_op = `ALU_OP_OR;
                        // ANDI instruction
                        `OP_ALSI_ANDI : alu_op = `ALU_OP_AND;
                        // SLTI instruction
                        `OP_ALSI_SLTI : begin
                            cmp_op     = `CMP_OP_LT;
                            ex_out_sel = `EX_OUT_CMP;
                        end
                        // SLTIU instruction
                        `OP_ALSI_SLTIU: begin
                            cmp_op     = `CMP_OP_LTU;
                            ex_out_sel = `EX_OUT_CMP;
                        end
                        `OP_ALSI_SRI  : begin
                            case(funct7)
                                //SRLI instruction
                                `OP_ALSI_SRI_SRLI: begin
                                    alu_op     = `ALU_OP_SRL;
                                    alu_in_1   = imm_ir;
                                end
                                //SRAI instruction
                                `OP_ALSI_SRI_SRAI: begin
                                    alu_op     = `ALU_OP_SRA;
                                    alu_in_1   = imm_ir;
                                end
                                // Undefined instruction
                                default          : begin
                                    exp_code = `EXP_ILLEGAL_INSN;
                                    $display("SRI error");
                                end
                            endcase
                        end
                        // undefined instruction
                        default       : begin
                            exp_code = `EXP_ILLEGAL_INSN;
                            $display("OP_ALSI error");
                        end
                    endcase
                end

                /******** Arithmetic Logic Shift ********/
                `OP_ALS   : begin
                    src_reg_used   = 2'b11;     // use rs1 and rs2
                    gpr_we_        = `ENABLE_;
                    case(funct3)
                        `OP_ALS_AS  : begin
                            case (funct7)
                                //ADD instruction
                                `OP_ALS_AS_ADD: alu_op = `ALU_OP_ADD;
                                //SUB instruction
                                `OP_ALS_AS_SUB: alu_op = `ALU_OP_SUB;
                                // Undefined instruction
                                default       : begin
                                    exp_code = `EXP_ILLEGAL_INSN;
                                    $display("AS error");
                                end
                            endcase
                        end
                        `OP_ALS_SLL : alu_op = `ALU_OP_SLL;
                        `OP_ALS_SLT : begin
                            cmp_op     = `CMP_OP_LT;
                            ex_out_sel = `EX_OUT_CMP;
                        end
                        `OP_ALS_SLTU: begin
                            cmp_op     = `CMP_OP_LTU;
                            ex_out_sel = `EX_OUT_CMP;
                        end
                        `OP_ALS_XOR : alu_op = `ALU_OP_XOR;
                        `OP_ALS_SR  : begin
                            case (funct7)
                                `OP_ALS_SR_SRL: alu_op = `ALU_OP_SRL;
                                `OP_ALS_SR_SRA: alu_op = `ALU_OP_SRA;
                                // Undefined instruction
                                default       : begin
                                    exp_code = `EXP_ILLEGAL_INSN;
                                    $display("SR error");
                                end
                            endcase
                        end
                        `OP_ALS_OR  : alu_op = `ALU_OP_OR;
                        `OP_ALS_AND : alu_op = `ALU_OP_AND;
                        // Undefined instruction
                        default     : begin
                            exp_code = `EXP_ILLEGAL_INSN;
                            $display("AS error");
                        end
                    endcase
                end

                /******** LUI instruction ********/
                `OP_LUI  : begin
                    src_reg_used = 2'b00;       // do not use rs1 and rs2
                    gpr_we_      = `ENABLE_;
                    gpr_wr_data  = imm_u;
                    ex_out_sel   = `EX_OUT_PCN;
                end

                /******** LUIPC instruction ********/
                `OP_AUIPC  : begin
                    src_reg_used = 2'b00;       // do not use rs1 and rs2
                    alu_op       = `ALU_OP_ADD;
                    alu_in_0     = pc;
                    alu_in_1     = imm_u;
                    gpr_we_      = `ENABLE_;
                end


                ////////////////////////////////////////////////
                //  ____  ____  _____ ____ ___    _    _      //
                // / ___||  _ \| ____/ ___|_ _|  / \  | |     //
                // \___ \| |_) |  _|| |    | |  / _ \ | |     //
                //  ___) |  __/| |__| |___ | | / ___ \| |___  //
                // |____/|_|   |_____\____|___/_/   \_\_____| //
                //                                            //
                ////////////////////////////////////////////////

                `OP_SYSTEM: begin
                    if (funct3 == 3'b000) begin
                        // non CSR related SYSTEM instructions
                        case(funct12)
                            `OP_ERET : is_eret = `ENABLE;
                            default  : begin
                                exp_code = `EXP_ILLEGAL_INSN;
                                $display("system instruction error");
                            end
                        endcase
                    end else begin
                        // instruction to read/modify CSR
                        src_reg_used = 2'b01;       // do not use rs2
                        gpr_we_      = `ENABLE_;
                        ex_out_sel   = `EX_OUT_PCN; // ex output gpr_wr_data
                        gpr_wr_data  = csr_rd_data;

                        if (funct3[2] == 1'b1) begin
                            // rs1 field is used as immediate, zero-extend
                            csr_wr_data = rs1_zimm;
                        end else begin
                            csr_wr_data = rs1_data;
                        end

                        if (funct3[1:0] == 2'b00) begin
                            exp_code = `EXP_ILLEGAL_INSN;
                            $display("CSR OP error");
                        end else begin
                            csr_op   = funct3[1:0];
                        end
                    end
                end
                default: begin // Undefined instruction
                    exp_code = `EXP_ILLEGAL_INSN;
                    $display("OP error");
                end

                // Hart control
                `OP_HART: begin
                    case(funct3)
                        `OP_HART_STA  : begin
                            src_reg_used = 2'b11;     // use rs1 and rs2
                            // to rd
                            gpr_we_  = `ENABLE_;
                            alu_op   = `ALU_OP_ADD;
                            alu_in_0 = {'b0, get_hart_idle};
                            // to IF stage: update pc
                            hs_id    = rs1_data;
                            hs_pc    = rs2_data;
                            // to Hart Control Unit: update state
                            hstart   = `ENABLE;
                            set_hart_id = rs1_data;
                        end
                        `OP_HART_STAC : begin
                            src_reg_used = 2'b10;     // use rs1 and rs2
                            // to IF stage: update pc
                            hs_id    = if_hart_id;
                            hs_pc    = rs2_data;
                            // to Hart Control Unit: update state
                            hstart   = `ENABLE;
                            set_hart_id = if_hart_id;
                        end
                        `OP_HART_KILL : begin
                            src_reg_used = 2'b01;
                            // to rd
                            gpr_we_  = `ENABLE_;
                            alu_op   = `ALU_OP_ADD;
                            alu_in_0 = {'b0, ~get_hart_idle};
                            // to Hart Control Unit: update state
                            hkill    = `ENABLE;
                            set_hart_id = rs1_data;
                        end
                        `OP_HART_KILLC: begin
                            // to Hart Control Unit: update state
                            hkill    = `ENABLE;
                            set_hart_id = if_hart_id;
                        end
                        `OP_HART_READ : begin
                            src_reg_used = 2'b01;
                            // to rd
                            gpr_we_  = `ENABLE_;
                            alu_op   = `ALU_OP_ADD;
                            alu_in_0 = {'b0, get_hart_val};
                            // to Hart Control Unit: specify hart id
                            set_hart_id = rs1_data;
                        end
                        `OP_HART_READA: begin
                            // to rd
                            gpr_we_  = `ENABLE_;
                            alu_op   = `ALU_OP_ADD;
                            alu_in_0 = {'b0, hart_acti_hstate};
                        end
                        `OP_HART_READI: begin
                            // to rd
                            gpr_we_  = `ENABLE_;
                            alu_op   = `ALU_OP_ADD;
                            alu_in_0 = {'b0, hart_idle_hstate};
                        end
                        default: exp_code = `EXP_ILLEGAL_INSN;
                    endcase
                end
                
            endcase
        end
    end

endmodule
