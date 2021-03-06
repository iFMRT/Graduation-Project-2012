////////////////////////////////////////////////////////////////////
// Engineer:       Leway Colin - colin4124@gmail.com              //
//                                                                //
// Additional contributions by:                                   //
//                 Beyond Sky - fan-dave@163.com                  //
//                 Junhao Chen                                    //
//                 Kippy Chen - 799182081@qq.com                  //
//                                                                //
// Design Name:    ID Pipeline Stage                              //
// Project Name:   FMRT Mini Core                                 //
// Language:       Verilog                                        //
//                                                                //
// Description:    ID Pipeline Stage.                             //
//                                                                //
////////////////////////////////////////////////////////////////////

`include "common_defines.v"
`include "base_core_defines.v"
`include "hart_ctrl.h"

module id_stage (
    /********** Clock & Reset **********/
    input  wire                   clk, // Clock
    input  wire                   reset, // Reset
    /********** GPR Interface **********/
    input  wire [`WORD_DATA_BUS]  gpr_rs1_data, // Read rs1 data
    input  wire [`WORD_DATA_BUS]  gpr_rs2_data, // Read rs2 data
    output wire [`REG_ADDR_BUS]   gpr_rs1_addr, // Read rs1 address
    output wire [`REG_ADDR_BUS]   gpr_rs2_addr, // Read rs2 address
    /********** Forward **********/
    input  wire [`WORD_DATA_BUS]  ex_fwd_data, // Forward data from EX Stage
    input  wire [`WORD_DATA_BUS]  mem_fwd_data, // Forward data from MEM Stage
    /********** CSRs Interface **********/
    input  wire [`WORD_DATA_BUS]  csr_rd_data, // Read from CSRs
    output wire [`CSR_OP_BUS]     csr_op, // CSRs operation
    output wire [`CSR_ADDR_BUS]   csr_addr, // Access CSRs address
    output wire [`WORD_DATA_BUS]  csr_wr_data, // Write to CSRs
    /********** Pipeline Control Signal **********/
    input  wire                   stall,          // Stall
    input  wire                   flush,          // Flush
    /********** Forward Signal **********/
    input  wire [`FWD_CTRL_BUS]   rs1_fwd_ctrl,
    input  wire [`FWD_CTRL_BUS]   rs2_fwd_ctrl,
    /********** IF/ID Pipeline Register **********/
    input  wire [`WORD_DATA_BUS]  pc,             // Current PC
    input  wire [`WORD_DATA_BUS]  if_npc,         // Next PC
    input  wire [`WORD_DATA_BUS]  if_insn,        // Instruction
    input  wire                   if_en,          // Pipeline data enable
    input  wire [`HART_ID_B]      if_hart_id,     // Hart state
    /********** ID/EX Pipeline Register  **********/
    output wire                   id_is_jalr,     // is JALR instruction
    output wire [`EXP_CODE_BUS]   id_exp_code,    // Exception code
    output wire [`WORD_DATA_BUS]  id_pc,
    output wire                   id_en,          // Pipeline data enable
    output wire [`ALU_OP_BUS]     id_alu_op,      // ALU Operation
    output wire [`WORD_DATA_BUS]  id_alu_in_0,    // ALU input 0
    output wire [`WORD_DATA_BUS]  id_alu_in_1,    // ALU input 1
    output wire [`CMP_OP_BUS]     id_cmp_op,      // CMP Operation
    output wire [`WORD_DATA_BUS]  id_cmp_in_0,    // CMP input 0
    output wire [`WORD_DATA_BUS]  id_cmp_in_1,    // CMP input 1
    output wire                   id_jump_taken,
    output wire [`MEM_OP_BUS]     id_mem_op,      // Memory Operation
    output wire [`WORD_DATA_BUS]  id_mem_wr_data, // Memory write data
    output wire [`REG_ADDR_BUS]   id_rd_addr,     // GPR write address
    output wire                   id_gpr_we_,     // GPR write enable
    output wire [`EX_OUT_SEL_BUS] id_ex_out_sel,
    output wire [`WORD_DATA_BUS]  id_gpr_wr_data,
    output wire [`HART_ID_B]      id_hart_id,     // ID stage hart state
    // output to Control Unit
    output wire                   is_eret,        // is ERET instruction
    output wire [`INSN_OP_BUS]    op,
    output wire [`REG_ADDR_BUS]   id_rs1_addr,
    output wire [`REG_ADDR_BUS]   id_rs2_addr,
    output wire [`REG_ADDR_BUS]   rs1_addr,
    output wire [`REG_ADDR_BUS]   rs2_addr,
    output wire [1:0]             src_reg_used,   // How many source registers instruction used
    /********** Hart Control Interface **********/
    // input from Hart Control
    input  wire                   get_hart_idle,     // is hart idle 1: idle, 0: non-idle
    input  wire [`HART_SST_B]     get_hart_val,      // state value of get_hart_id 2: pend, 1: active, 0:idle
    input  wire [`HART_STATE_B]   hart_acti_hstate,  // 3:0
    input  wire [`HART_STATE_B]   hart_idle_hstate,  // 3:0
    // output to Hart Control
    output wire                   is_branch,
    output wire                   is_load,
    output wire [`HART_ID_B]      spec_hid,

    output wire                   id_hkill,
    output wire [`HART_ID_B]      id_set_hid,        // ID_reg set hart id
    // output to IF stage
    output wire                   id_hstart,
    output wire                   id_hidle,
    output wire [`HART_ID_B]      id_hs_id,          // Hart start id
    output wire [`WORD_DATA_BUS]  id_hs_pc           // Hart start pc
);

    wire [`ALU_OP_BUS]     alu_op;          // ALU Operation
    wire [`WORD_DATA_BUS]  alu_in_0;        // ALU input 0
    wire [`WORD_DATA_BUS]  alu_in_1;        // ALU input 1
    wire [`CMP_OP_BUS]     cmp_op;          // CMP Operation
    wire [`WORD_DATA_BUS]  cmp_in_0;        // CMP input 0
    wire [`WORD_DATA_BUS]  cmp_in_1;        // CMP input 1

    wire                   jump_taken;

    wire [`MEM_OP_BUS]     mem_op;          // Memory operation
    wire [`WORD_DATA_BUS]  mem_wr_data;     // Memory write data
    wire [`EX_OUT_SEL_BUS] ex_out_sel;      // EX stage gpr write multiplexer
    wire [`WORD_DATA_BUS]  gpr_wr_data;     // ID stage output gpr write data
    wire [`REG_ADDR_BUS]   rd_addr;         // GPR write address
    wire                   gpr_we_;         // GPR write enable
    wire                   is_jalr;         // is JALR instruction
    wire [`EXP_CODE_BUS]   exp_code;

    /********** To Hart Control Unit **********/
    wire                  hstart;
    wire                  hkill;
    wire [`HART_ID_B]     hs_id;
    wire [`WORD_DATA_BUS] hs_pc;

    /********** Two Operand **********/
    reg  [`WORD_DATA_BUS] rs1_data;         // The first operand
    reg  [`WORD_DATA_BUS] rs2_data;         // The second operand

    /********** Forward **********/
    always @(*) begin
        /* Forward Rs1 */
        case (rs1_fwd_ctrl)
            `FWD_CTRL_EX : begin
                rs1_data = ex_fwd_data;   // Forward from EX stage
            end
            `FWD_CTRL_MEM: begin
                rs1_data = mem_fwd_data;  // Forward from MEM stage
            end
            default      : begin
                rs1_data = gpr_rs1_data;  // Don't need forward
            end
        endcase

        /* Forward Rs2 */
        case (rs2_fwd_ctrl)
            `FWD_CTRL_EX : begin
                rs2_data = ex_fwd_data;   // Forward from EX stage
            end
            `FWD_CTRL_MEM: begin
                rs2_data = mem_fwd_data;  // Forward from MEM stage
            end
            default      : begin
                rs2_data = gpr_rs2_data;  // Don't need forward
            end
        endcase
    end

    decoder decoder (
        /********** IF/ID Pipeline Register **********/
        .pc             (pc),             // Current PC
        .if_npc         (if_npc),         // Next PC
        .if_insn        (if_insn),        // Current Instruction
        .if_en          (if_en),          // Pipeline data enable
        /********** Two Operand **********/
        .rs1_data       (rs1_data),       // Read data 0
        .rs2_data       (rs2_data),       // Read data 1
        /********** GPR Interface **********/
        .gpr_rs1_addr   (gpr_rs1_addr),   // Read address 0
        .gpr_rs2_addr   (gpr_rs2_addr),   // Read address 1
        /********** CSRs Interface **********/
        .csr_rd_data    (csr_rd_data),    // Read from CSRs
        .csr_op         (csr_op),         // CSRs operation
        .csr_addr       (csr_addr),       // CSRs address
        .csr_wr_data    (csr_wr_data),    // Write to CSRs
        /********** Decoder Result **********/
        .alu_op         (alu_op),         // ALU Operation
        .alu_in_0       (alu_in_0),       // ALU input 0
        .alu_in_1       (alu_in_1),       // ALU input 1
        .cmp_op         (cmp_op),         // CMP Operation
        .cmp_in_0       (cmp_in_0),       // CMP input 0
        .cmp_in_1       (cmp_in_1),       // CMP input 1
        .jump_taken     (jump_taken),     // Branch taken enable

        .mem_op         (mem_op),         // Memory operation
        .mem_wr_data    (mem_wr_data),    // Memory write data
        .ex_out_sel     (ex_out_sel),     // Select EX stage outputs

        .gpr_wr_data    (gpr_wr_data),    // The data write to GPR
        .rd_addr        (rd_addr),        // GPR write address
        .gpr_we_        (gpr_we_),        // GPR write enable
        .is_jalr        (is_jalr),        // is JALR instruction
        .is_eret        (is_eret),        // is ERET instruction
        .exp_code       (exp_code),       // Exception code

        .op             (op),             // OpCode
        .rs1_addr       (rs1_addr),
        .rs2_addr       (rs2_addr),
        .src_reg_used   (src_reg_used),   // which source registers used

        /********** Hart Control Interface **********/
        // input from Hart Control
        .get_hart_idle    (get_hart_idle),
        .get_hart_val     (get_hart_val),
        .hart_acti_hstate (hart_acti_hstate),
        .hart_idle_hstate (hart_idle_hstate),
        // input from IF stage
        .if_hart_id     (if_hart_id),
        // output to Hart Control
        .is_branch      (is_branch),
        .is_load        (is_load),
        // output to id_reg
        .hkill          (hkill),
        .hstart         (hstart),
        .spec_hid       (spec_hid),
        .hs_id          (hs_id),          // Hart start id
        .hs_pc          (hs_pc)           // Hart start pc
    );

    id_reg id_reg (
        /********** Clock & Reset **********/
        .clk            (clk),            // Clock
        .reset          (reset),          // Asynchronous Reset
        /********** Decode Result **********/
        .alu_op         (alu_op),         // ALU Operation
        .alu_in_0       (alu_in_0),       // ALU input 0
        .alu_in_1       (alu_in_1),       // ALU input 1
        .cmp_op         (cmp_op),
        .cmp_in_0       (cmp_in_0),
        .cmp_in_1       (cmp_in_1),
        .rs1_addr       (rs1_addr),
        .rs2_addr       (rs2_addr),

        .jump_taken     (jump_taken),     // Branch taken enable
        .mem_op         (mem_op),         // Memory operation
        .mem_wr_data    (mem_wr_data),    // Memory write data
        .rd_addr        (rd_addr),        // General purpose Register write address
        .gpr_we_        (gpr_we_),        // General purpose Register write enable
        .ex_out_sel     (ex_out_sel),
        .gpr_wr_data    (gpr_wr_data),    // ID stage output gpr write data
        .is_jalr        (is_jalr),        // is JALR instruction
        .exp_code       (exp_code),       // Exception code

        .stall          (stall),          // Stall
        .flush          (flush),          // Flush

        /********** IF/ID Pipeline  Register  **********/
        .pc             (pc),             // Current program counter
        .if_en          (if_en),          // Pipeline data enable
        .if_hart_id     (if_hart_id),     // IF stage hart id
        /********** ID/EX Pipeline  Register  **********/
        .id_is_jalr     (id_is_jalr),     // is JALR instruction
        .id_exp_code    (id_exp_code),    // Exception code
        .id_pc          (id_pc),
        .id_en          (id_en),          // Pipeline data enable
        .id_alu_op      (id_alu_op),      // ALU Operation
        .id_alu_in_0    (id_alu_in_0),    // ALU input 0
        .id_alu_in_1    (id_alu_in_1),    // ALU input 1
        .id_cmp_op      (id_cmp_op),
        .id_cmp_in_0    (id_cmp_in_0),
        .id_cmp_in_1    (id_cmp_in_1),
        .id_ex_out_sel  (id_ex_out_sel),
        .id_rs1_addr    (id_rs1_addr),
        .id_rs2_addr    (id_rs2_addr),
        .id_jump_taken  (id_jump_taken),  // Branch taken enable

        .id_mem_op      (id_mem_op),      // Memory operation
        .id_mem_wr_data (id_mem_wr_data), // Memory write data
        .id_rd_addr     (id_rd_addr),     // General purpose Register write address
        .id_gpr_we_     (id_gpr_we_),     // General purpose Register write enable
        .id_gpr_wr_data (id_gpr_wr_data),

        .id_hart_id     (id_hart_id),     // ID stage hart id
        //from Hart Control Unit
        .hkill          (hkill),
        .hstart         (hstart),
        .hidle          (get_hart_idle),
        .hs_id          (hs_id),
        .hs_pc          (hs_pc),
        .spec_hid       (spec_hid),
        //to IF stage
        .id_hkill       (id_hkill),
        .id_hstart      (id_hstart),
        .id_hidle       (id_hidle),
        .id_set_hid     (id_set_hid),
        .id_hs_id       (id_hs_id),
        .id_hs_pc       (id_hs_pc)
    );

endmodule
