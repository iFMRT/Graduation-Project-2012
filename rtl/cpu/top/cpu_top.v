////////////////////////////////////////////////////////////////////////
// Engineer:       Leway Colin - colin4124@gmail.com                  //
//                                                                    //
// Additional contributions by:                                       //
//                 Beyond Sky - fan-dave@163.com                      //
//                 Kippy Chen - 799182081@qq.com                      //
//                 Junhao Chen                                        //
//                                                                    //
// Design Name:    Top of CPU                                         //
// Project Name:   FMRT Mini Core                                     //
// Language:       Verilog                                            //
//                                                                    //
// Description:    Combine all the CPU components together.           //
//                                                                    //
////////////////////////////////////////////////////////////////////////

`include "common_defines.v"
`include "base_core_defines.v"
`include "hart_ctrl.h"
`include "l1_cache.h"

`timescale 1ns/1ps

module cpu_top(
    input wire                   clk,          // Clock
    input wire                   reset,        // Asynchronous Reset
    /********** General Purpose Register Signal **********/
    output wire [`WORD_DATA_BUS] gpr_rs1_data, // Read data 0
    output wire [`WORD_DATA_BUS] gpr_rs2_data, // Read data 1
    output wire [`REG_ADDR_BUS]  gpr_rs1_addr, // Read address 0
    output wire [`REG_ADDR_BUS]  gpr_rs2_addr, // Read address 1
    output wire [`REG_ADDR_BUS]  mem_rd_addr,  // General purpose register write address
    output wire [`WORD_DATA_BUS] mem_out,      // Operating result
    output wire                  mem_gpr_we_,
    output wire [`WORD_DATA_BUS] if_pc,
    output wire [`WORD_DATA_BUS] pc,
    output wire [`HART_ID_B]     hart_issue_hid,
    output wire [`HART_ID_B]     if_hart_id,
    output wire [`HART_ID_B]     ex_hart_id,
    output wire [`HART_ID_B]     mem_hart_id,
    // mem stage
    // output wire [`WORD_DATA_BUS] alu_out,
    output wire [`WORD_DATA_BUS] ex_out,
    output wire [`WORD_DATA_BUS] wr_data,
    output wire                  rw,
    // Cache Miss Test
    output wire                  i_cache_miss,
    output wire                  i_cache_fin,
    output wire [`HART_ID_B]     i_cache_fin_hid,
    output wire                  d_cache_miss,
    output wire                  d_cache_fin,
    output wire [`HART_ID_B]     d_cache_fin_hid 
);
    /********** Clock & Reset **********/
    wire                   clk_;           // Reverse Clock
    /**********  Pipeline  Register **********/
    // IF/ID
    // wire [`WORD_DATA_BUS]  if_pc;       // PC
    // wire [`WORD_DATA_BUS]  pc;             // PC in if_reg
    wire [`WORD_DATA_BUS]  if_npc;         // Next PC in if_reg
    wire [`WORD_DATA_BUS]  if_insn;        // Instruction
    wire                   if_en;          // Pipeline data enable
    // wire [`HART_ID_B]      if_hart_id;

    // ID/EX Pipeline  Register
    wire                   id_is_jalr;     // is JALR instruction
    wire [`EXP_CODE_BUS]   id_exp_code;    // Exception code
    wire [`WORD_DATA_BUS]  id_pc;          // Program count
    wire                   id_en;          // Pipeline data enable
    wire [`ALU_OP_BUS]     id_alu_op;      // ALU operation
    wire [`WORD_DATA_BUS]  id_alu_in_0;    // ALU input 0
    wire [`WORD_DATA_BUS]  id_alu_in_1;    // ALU input 1
    wire [`CMP_OP_BUS]     id_cmp_op;      // CMP Operation
    wire [`WORD_DATA_BUS]  id_cmp_in_0;    // CMP input 0
    wire [`WORD_DATA_BUS]  id_cmp_in_1;    // CMP input 1
    wire                   id_jump_taken;
    wire [`MEM_OP_BUS]     id_mem_op;      // Memory operation
    wire [`WORD_DATA_BUS]  id_mem_wr_data; // Memory Write data
    wire [`REG_ADDR_BUS]   id_rd_addr;     // GPRWrite address
    wire                   id_gpr_we_;     // GPRWrite enable
    wire [`HART_ID_B]      id_hart_id;
    wire [`EX_OUT_SEL_BUS] id_ex_out_sel;
    wire [`WORD_DATA_BUS]  id_gpr_wr_data;
    // output to Control Unit
    wire                   is_eret;        // is ERET instruction
    wire [`INSN_OP_BUS]    op;
    wire [`REG_ADDR_BUS]   id_rs1_addr;
    wire [`REG_ADDR_BUS]   id_rs2_addr;
    wire [`REG_ADDR_BUS]   rs1_addr;
    wire [`REG_ADDR_BUS]   rs2_addr;
    wire [1:0]             src_reg_used;
    // EX/MEM Pipeline  Register
    wire [`EXP_CODE_BUS]   ex_exp_code;    // Exception code
    wire [`WORD_DATA_BUS]  ex_pc;
    wire                   ex_en;          //  Pipeline data enable
    wire [`MEM_OP_BUS]     ex_mem_op;      // Memory operation
    wire [`WORD_DATA_BUS]  ex_mem_wr_data; // Memory Write data
    wire [`REG_ADDR_BUS]   ex_rd_addr;    // General purpose RegisterWrite  address
    wire                   ex_gpr_we_;     // General purpose RegisterWrite enable
    // wire [`WORD_DATA_BUS]  ex_out;         // Operating result
    // wire [`HART_ID_B]      ex_hart_id;
    // MEM/WB Pipeline  Register
    wire [`EXP_CODE_BUS]   mem_exp_code;   // Exception code
    wire [`WORD_DATA_BUS]  mem_pc;
    wire                   mem_en;         // If Pipeline data enables
    // wire                   mem_gpr_we_;    // General purpose register write enable
    // wire [`HART_ID_B]      mem_hart_id;
    // Use to CPU TOP ports for test
    // wire [`REG_ADDR_BUS]   mem_rd_addr;    // General purpose register write  address
    // wire [`WORD_DATA_BUS]  mem_out;        // Operating result
    /**********  Pipeline Control Signal **********/
    // Stall  Signal
    wire                   if_stall;       // IF Stage
    wire                   id_stall;       // ID Stage
    wire                   ex_stall;       // EX Stage
    wire                   mem_stall;      // MEM Stage
    // Flush Signal
    wire                   if_flush;       // IF Stage
    wire                   id_flush;       // ID Stage
    wire                   ex_flush;       // EX Stage
    wire                   mem_flush;      // MEM Stage
    // Control Signal
    wire [`WORD_DATA_BUS]  new_pc;         // New PC
    wire                   cache_miss;     // Cache miss occur
    wire [`HART_ID_B]      cm_hart_id;     // Cache miss hart id
    wire [`WORD_DATA_BUS]  cm_addr;        // Cache miss address
    wire [`WORD_DATA_BUS]  br_addr;        // Branch  address
    wire                   br_taken;       // Branch taken
    // wire                   ld_hazard;      // Hazard
    /********** Forward Control **********/
    wire [`FWD_CTRL_BUS]   rs1_fwd_ctrl;
    wire [`FWD_CTRL_BUS]   rs2_fwd_ctrl;
    wire                   ex_rs1_fwd_en;
    wire                   ex_rs2_fwd_en;
    /********** Forward  Data **********/
    wire [`WORD_DATA_BUS]  ex_fwd_data;     // EX Stage
    wire [`WORD_DATA_BUS]  mem_fwd_data;    // MEM Stage
    /********** CSRs Interface **********/
    wire [`CSR_OP_BUS]     csr_op;          // CSRs operation
    wire [`CSR_ADDR_BUS]   csr_addr;        // Access CSRs address
    wire [`WORD_DATA_BUS]  csr_rd_data;     // Read from CSRs
    wire [`WORD_DATA_BUS]  csr_wr_data;     // Write to CSRs
    wire [`EXP_CODE_BUS]   exp_code;
    // wire                   save_exp_code;
    wire                   save_exp;
    wire                   restore_exp;

    wire [`WORD_DATA_BUS]  ctrl_mepc;       // Output from control unit
    wire [`WORD_DATA_BUS]  csr_mepc;        // Output from CSRs uni

    /********** Hart control signal **********/
    // to ID stage
    wire [`HART_ID_B]      spec_hid;          // specified hart id to get hart val
    wire [`HART_SST_B]     get_hart_val;      // state value of id_set_hid 2: pend, 1: active, 0:idle
    wire                   get_hart_idle;     // is hart idle 1: idle, 0: non-idle

    wire                   hart_ic_stall;     // Need to stall pipeline
    wire                   hart_dc_stall;     // Need to stall pipeline
    wire                   hart_ic_flush;     // Need to flush pipeline
    wire                   hart_dc_flush;     // Need to flush pipeline
    wire [`HART_STATE_B]   hart_acti_hstate;  // 3:0
    wire [`HART_STATE_B]   hart_idle_hstate;  // 3:0
    // from ID stage
    wire                   is_branch;
    wire                   is_load;

    wire                   id_hstart;
    wire                   id_hidle;
    wire                   id_hkill;
    wire [`HART_ID_B]      id_hs_id;
    wire [`WORD_DATA_BUS]  id_hs_pc;
    wire [`HART_ID_B]      id_set_hid;
    // to IF stage
    // wire [`HART_ID_B]      hart_issue_hid;
    wire [`HART_STATE_B]   hart_issue_hstate;
    // wire                   hidle;
    // wire [`HART_ID_B]      hs_id;          // Hart start id
    // wire [`WORD_DATA_BUS]  hs_pc;          // Hart start pc
    // wire                   i_cache_miss;
    // wire                   i_cache_fin;
    // wire [`HART_ID_B]      i_cache_fin_hid;
    // wire                   d_cache_miss;
    // wire                   d_cache_fin;
    // wire [`HART_ID_B]      d_cache_fin_hid;

    /********** Storage **********/
    wire [`WORD_DATA_BUS]  insn;        // read data of CPU
    wire                   data_rdy;    // hang up
    wire                   ic_busy;
    wire                   dc_busy;
    wire [`WORD_DATA_BUS]  alu_out;
    wire                   access_mem;
    // wire                   rw;
    // wire [`WORD_DATA_BUS]  wr_data;     // write data from CPU
    wire                   out_rdy;
    wire [`WORD_DATA_BUS]  rd_to_write_m;
    wire [`WORD_DATA_BUS]  rd_data;     // read data of CPU

    assign clk_ = ~clk;

    /********** IF Stage **********/
    if_stage if_stage (
        /* clock & reset *************************/
        .clk            (clk),              // Clock
        .reset          (reset),            // Asynchronous Reset
        /* Pipeline control **********************/
        .stall          (if_stall),         // Stall
        .flush          (if_flush),         // Flush
        .new_pc         (new_pc),           // New PC
        .cache_miss     (cache_miss),       // Cache miss occur
        .cm_hart_id     (cm_hart_id),       // Cache miss hart ID
        .cm_addr        (cm_addr),          // Cache miss address
        .br_hart_id     (id_hart_id),       // Branch Hart ID
        .br_taken       (br_taken),         // Branch taken
        .br_addr        (br_addr),          // Branch address
        /* I Cache ***************************/
        .insn           (insn),                 // Reading instruction
        .if_pc          (if_pc),                // PC
        .data_rdy       (data_rdy),
        /* Hart select ***************************/
        .hart_id        (hart_issue_hid),   // Hart ID to issue ins
        .id_hstart      (id_hstart),        // Hart start
        .id_hidle       (id_hidle),         // Hart idle
        .id_hs_id       (id_hs_id),         // Hart start id
        .id_hs_pc       (id_hs_pc),         // Hart start pc
        /* IF/ID Pipeline Register ***************/
        .pc             (pc),               // PC in if_reg
        .if_npc         (if_npc),           // Next PC in if_reg
        .if_insn        (if_insn),          // Instruction
        .if_en          (if_en),            // Pipeline data enable
        .if_hart_id     (if_hart_id)        // Hart state
    );

    /********** ID Stage **********/
    id_stage id_stage (
        /********** Clock & Reset **********/
        .clk            (clk),              // Clock
        .reset          (reset),            // Asynchronous Reset
        /********** GPR Interface **********/
        .gpr_rs1_data   (gpr_rs1_data),     // Read data 0
        .gpr_rs2_data   (gpr_rs2_data),     // Read data 1
        .gpr_rs1_addr   (gpr_rs1_addr),     // Read  address 0
        .gpr_rs2_addr   (gpr_rs2_addr),     // Read  address 1
        /********** Forward  **********/
        .ex_fwd_data    (ex_fwd_data),      // Forward data from EX Stage
        .mem_fwd_data   (mem_fwd_data),     // Forward data from MEM Stage
        /********** CSRs Interface **********/
        .csr_rd_data    (csr_rd_data),      // Read from CSRs
        .csr_op         (csr_op),           // CSRs operation
        .csr_addr       (csr_addr),         // Access CSRs address
        .csr_wr_data    (csr_wr_data),      // Write to CSRs
        /*********  Pipeline Control Signal *********/
        .stall          (id_stall),         // Stall
        .flush          (id_flush),         // Flush
        /********** Forward Signal **********/
        .rs1_fwd_ctrl   (rs1_fwd_ctrl),
        .rs2_fwd_ctrl   (rs2_fwd_ctrl),
        /********** IF/ID Pipeline  Register **********/
        .pc             (pc),               // Current Program count
        .if_npc         (if_npc),           // Next Program count
        .if_insn        (if_insn),          // Instruction
        .if_en          (if_en),            // Pipeline data enable
        .if_hart_id     (if_hart_id),       // IF stage hart state
        /********** ID/EX Pipeline  Register **********/
        .id_is_jalr     (id_is_jalr),       // is JALR instruction
        .id_exp_code    (id_exp_code),      // Exception code
        .id_pc          (id_pc),
        .id_en          (id_en),            // Pipeline data enable
        .id_alu_op      (id_alu_op),        // ALU operation
        .id_alu_in_0    (id_alu_in_0),      // ALU input 0
        .id_alu_in_1    (id_alu_in_1),      // ALU input 1
        .id_cmp_op      (id_cmp_op),        // CMP Operation
        .id_cmp_in_0    (id_cmp_in_0),      // CMP input 0
        .id_cmp_in_1    (id_cmp_in_1),      // CMP input 1
        .id_jump_taken  (id_jump_taken),
        .id_mem_op      (id_mem_op),        // Memory operation
        .id_mem_wr_data (id_mem_wr_data),   // Memory Write data
        .id_rd_addr     (id_rd_addr),       // GPRWrite  address
        .id_gpr_we_     (id_gpr_we_),       // GPRWrite enable
        .id_ex_out_sel  (id_ex_out_sel),
        .id_gpr_wr_data (id_gpr_wr_data),
        .id_hart_id     (id_hart_id),       // ID stage hart state
        /********** output to Control Unit **********/
        .is_eret        (is_eret),          // is ERET instruction
        .op             (op),
        .id_rs1_addr    (id_rs1_addr),
        .id_rs2_addr    (id_rs2_addr),
        .rs1_addr       (rs1_addr),
        .rs2_addr       (rs2_addr),
        .src_reg_used   (src_reg_used),
        /********** Hart Control Interface **********/
        // input from Hart Control
        .get_hart_idle    (get_hart_idle),
        .get_hart_val     (get_hart_val),
        .hart_acti_hstate (hart_acti_hstate),
        .hart_idle_hstate (hart_idle_hstate),
        // output to Hart Control
        .is_branch      (is_branch),
        .is_load        (is_load),
        .spec_hid       (spec_hid),
        .id_hkill       (id_hkill),
        .id_set_hid     (id_set_hid),
        // output to IF stage
        .id_hstart      (id_hstart),
        .id_hidle       (id_hidle),
        .id_hs_id       (id_hs_id),         // Hart start id
        .id_hs_pc       (id_hs_pc)          // Hart start pc
    );

    /********** EX Stage **********/
    ex_stage ex_stage (
        .clk            (clk),
        .reset          (reset),
        // Pipeline Control Signal
        .stall          (ex_stall),
        .flush          (ex_flush),
        // ID/EX Pipleline Register
        .id_is_jalr     (id_is_jalr),
        .id_exp_code    (id_exp_code),
        .id_pc          (id_pc),
        .id_en          (id_en),
        .id_alu_op      (id_alu_op),
        .id_alu_in_0    (id_alu_in_0),
        .id_alu_in_1    (id_alu_in_1),
        .id_cmp_op      (id_cmp_op),
        .id_cmp_in_0    (id_cmp_in_0),
        .id_cmp_in_1    (id_cmp_in_1),
        .id_jump_taken  (id_jump_taken),
        .id_mem_op      (id_mem_op),
        .id_mem_wr_data (id_mem_wr_data),
        .id_rd_addr     (id_rd_addr),
        .id_gpr_we_     (id_gpr_we_),
        .id_hart_id     (id_hart_id),
        .id_ex_out_sel  (id_ex_out_sel),
        .id_gpr_wr_data (id_gpr_wr_data),
        // Forward Data From MEM Stage
        .ex_rs1_fwd_en  (ex_rs1_fwd_en),
        .ex_rs2_fwd_en  (ex_rs2_fwd_en),
        .mem_fwd_data   (mem_fwd_data),
        // output to ID Stage
        .fwd_data       (ex_fwd_data),
        // Output to Next Stage
        .ex_exp_code    (ex_exp_code),
        .ex_pc          (ex_pc),
        .ex_en          (ex_en),
        .ex_mem_op      (ex_mem_op),
        .ex_mem_wr_data (ex_mem_wr_data),
        .ex_rd_addr     (ex_rd_addr),
        .ex_gpr_we_     (ex_gpr_we_),
        .ex_out         (ex_out),
        .ex_hart_id     (ex_hart_id),
        // output to IF Stage
        .br_addr        (br_addr),
        .br_taken       (br_taken),
        // To d cache
        .access_mem     (access_mem),
        .alu_out        (alu_out)
    );

    /********** MEM Stage **********/
    mem_stage mem_stage (
        .clk            (clk),
        .reset          (reset),
        /**** Pipeline Control Signal *****/
        .stall          (mem_stall),
        .flush          (mem_flush),
        /************ Forward *************/
        .fwd_data       (mem_fwd_data),
        /********** EX/MEM Pipeline Register **********/
        .ex_exp_code    (ex_exp_code),
        .ex_pc          (ex_pc),
        .ex_en          (ex_en),
        .ex_mem_op      (ex_mem_op),
        .ex_mem_wr_data (ex_mem_wr_data),
        .ex_offset      (ex_out[1:0]),
        .ex_rd_addr     (ex_rd_addr),
        .ex_gpr_we_     (ex_gpr_we_),
        .ex_out         (ex_out),
        .ex_hart_id     (ex_hart_id),
        /********** D Cache **********/
        .rd_data        (rd_data),        // Read data
        .rw             (rw),             // Read/Write
        .wr_data        (wr_data),        // Write data
        .rd_to_write_m  (rd_to_write_m),
        .out_rdy        (out_rdy),
        /********** MEM/WB Pipeline Register **********/
        .mem_exp_code   (mem_exp_code),
        .mem_pc         (mem_pc),
        .mem_en         (mem_en),
        .mem_rd_addr    (mem_rd_addr),
        .mem_gpr_we_    (mem_gpr_we_),
        .mem_out        (mem_out),
        .mem_hart_id    (mem_hart_id)
    );

    /********** hart control unit **********/
    hart_ctrl hart_ctrl (
        .clk                   (clk),                 // √
        .rst                   (reset),               // √

        /* ID stage part ***********************/
        .id_hstart             (id_hstart),           // √
        .id_hkill              (id_hkill),            // √
        .id_set_hid            (id_set_hid),          // √
        .id_hidle              (id_hidle),
        .spec_hid              (spec_hid),            // √
        .get_hart_val          (get_hart_val),        // √
        .get_hart_idle         (get_hart_idle),       // √

        .is_branch             (is_branch),           // √
        .is_load               (is_load),             // √
        .if_hart_id            (if_hart_id),          // √

        .hart_ic_stall         (hart_ic_stall),       // √
        .hart_dc_stall         (hart_dc_stall),       // √
        .hart_ic_flush         (hart_ic_flush),       // √
        .hart_dc_flush         (hart_dc_flush),       // √
        .hart_acti_hstate      (hart_acti_hstate),    // √
        .hart_idle_hstate      (hart_idle_hstate),    // √

        /* IF stage part **************************/
        .i_cache_miss          (i_cache_miss),
        .i_cache_fin           (i_cache_fin),
        .i_cache_fin_hid       (i_cache_fin_hid),

        .hart_issue_hid        (hart_issue_hid),      // √
        .hart_issue_hstate     (hart_issue_hstate),   // √

        /* MEM stage part ************************/
        .d_cache_miss          (d_cache_miss),
        .ex_hart_id            (ex_hart_id),          // √
        .d_cache_fin           (d_cache_fin),
        .d_cache_fin_hid       (d_cache_fin_hid)
    );

    /********** control unit **********/
    ctrl ctrl (
        .br_taken       (br_taken),
        .src_reg_used   (src_reg_used),
        .is_eret        (is_eret),
        .id_en          (id_en),
        .id_rd_addr     (id_rd_addr),
        .id_gpr_we_     (id_gpr_we_),
        .id_mem_op      (id_mem_op),
        .op             (op),
        .rs1_addr       (rs1_addr),
        .rs2_addr       (rs2_addr),
        .id_rs1_addr    (id_rs1_addr),
        .id_rs2_addr    (id_rs2_addr),
        .ex_en          (ex_en),
        .ex_rd_addr     (ex_rd_addr),
        .ex_gpr_we_     (ex_gpr_we_),
        .ex_mem_op      (ex_mem_op),
        .mem_pc         (mem_pc),
        .mem_en         (mem_en),
        .mem_exp_code   (mem_exp_code),
        .mepc_i         (csr_mepc),
        .mepc_o         (ctrl_mepc),
        .exp_code       (exp_code),
        .save_exp       (save_exp),
        .restore_exp    (restore_exp),
        .if_stall       (if_stall),
        .id_stall       (id_stall),
        .ex_stall       (ex_stall),
        .mem_stall      (mem_stall),
        .if_flush       (if_flush),
        .id_flush       (id_flush),
        .ex_flush       (ex_flush),
        .mem_flush      (mem_flush),
        .new_pc         (new_pc),
        .rs1_fwd_ctrl   (rs1_fwd_ctrl),
        .rs2_fwd_ctrl   (rs2_fwd_ctrl),
        .ex_rs1_fwd_en  (ex_rs1_fwd_en),
        .ex_rs2_fwd_en  (ex_rs2_fwd_en),
        /********** Storage **********/
        .ic_busy        (ic_busy),
        .dc_busy        (dc_busy),
        /********** Hart Control Unit **********/
        // hart ID
        .issue_id       (hart_issue_hid), // IF  stage used
        .if_hart_id     (if_hart_id),     // ID  stage used
        .id_hart_id     (id_hart_id),     // EX  stage used
        .ex_hart_id     (ex_hart_id),     // MEM stage used
        // stall
        .hart_ic_stall  (hart_ic_stall),
        .hart_dc_stall  (hart_dc_stall),
        .hart_ic_flush  (hart_ic_flush),
        .hart_dc_flush  (hart_dc_flush),
        // to IF stage
        .if_pc          (if_pc),
        .ex_pc          (ex_pc),
        .cache_miss     (cache_miss),     // Cache miss occur
        .cm_hart_id     (cm_hart_id),     // Cache miss hart id
        .cm_addr        (cm_addr)         // Cache miss address
    );

    /********** Control & State Registers **********/
    cs_registers cs_registers (
        .clk            (clk),
        .reset          (reset),
        .csr_addr       (csr_addr),
        .csr_rd_data    (csr_rd_data),
        .csr_wr_data_i  (csr_wr_data),
        .csr_op         (csr_op),
        .mepc_i         (ctrl_mepc),
        .mepc_o         (csr_mepc),
        .exp_code_i     (exp_code),
        // .save_exp_code  (save_exp_code),
        .save_exp       (save_exp),
        .restore_exp    (restore_exp)
    );

    /********** General purpose Register **********/
    gpr gpr (
        /********** Clock & Reset **********/
        .clk            (clk),              // Clock
        .reset          (reset),            // Asynchronous Reset
        /********** Hart ID **********/
        .if_hart_id     (if_hart_id),
        .mem_hart_id    (mem_hart_id),
        /********** Read Port  0 **********/
        .rs1_addr       (gpr_rs1_addr),     // Read address
        .rs1_data       (gpr_rs1_data),     // Read data
        /********** Read Port  1 **********/
        .rs2_addr       (gpr_rs2_addr),     // Read address
        .rs2_data       (gpr_rs2_data),     // Read data
        /********** Write Port  **********/
        .we_            (mem_gpr_we_),      // Write enable
        .wr_addr        (mem_rd_addr),      // Write address
        .wr_data        (mem_out)           // Write data
    );

    storage storage (
        .clk            (clk),                // clock
        .rst            (reset),                // reset
        // input from if stage
        // .thread         (hart_id),
        .thread         (hart_issue_hid),
        .if_stall       (if_stall),
        // .if_addr        (if_pc[31:2]),
        .if_addr        (if_pc[31:2]),
        // .offset         (if_pc[3:2]),
        // output to if stage
        .insn           (insn),
        .data_rdy       (data_rdy),
        // output to ctrl
        .if_busy        (ic_busy),
        .dc_busy        (dc_busy),
        .dc_miss        (d_cache_miss),
        .dc_thread_rdy  (d_cache_fin),
        .dc_rdy_thread  (d_cache_fin_hid),
        .ic_miss        (i_cache_miss),
        .ic_thread_rdy  (i_cache_fin),
        .ic_rdy_thread  (i_cache_fin_hid),
        // input from ex stage
        .br_addr_ic     (br_addr[31:2]),
        .br_taken       (br_taken),
        .next_addr      (alu_out[31:2]),
        .access_mem     (access_mem),
        // input from mem stage
        .memwrite_m     (rw),
        .wr_data        (wr_data),
        .out_rdy        (out_rdy),
        .offset_m       (ex_out[3:2]),
        // output to mem stage
        .rd_to_write_m  (rd_to_write_m),
        .read_data_m    (rd_data) 
    );
 
endmodule