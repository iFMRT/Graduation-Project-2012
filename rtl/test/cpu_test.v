////////////////////////////////////////////////////////////////////////
// Engineer:       Leway Colin - colin4124@gmail.com                  //
//                                                                    //
// Additional contributions by:                                       //
//                 Beyond Sky - fan-dave@163.com                      //
//                 Kippy Chen - 799182081@qq.com                      //
//                 Junhao Chen                                        //
//                                                                    //
// Design Name:    Test Case for CPU                                  //
// Project Name:   FMRT Mini Core                                     //
// Language:       Verilog                                            //
//                                                                    //
// Description:    Test all the CPU components together.              //
//                                                                    //
////////////////////////////////////////////////////////////////////////

`include "common_defines.v"
`include "base_core_defines.v"

`timescale 1ns/1ps

module cpu_test;
    /********** Clock & Reset **********/
    reg                    clk;            // Clock
    wire                   clk_;           // Reverse Clock
    reg                    reset;          // Asynchronous Reset
    /**********  Pipeline  Register **********/
    // IF/ID
    wire [`WORD_DATA_BUS]  if_pc;          // Next Program count
    wire [`WORD_DATA_BUS]  pc;             // Current Program count
    wire [`WORD_DATA_BUS]  if_insn;        // Instruction
    wire                   if_en;          //  Pipeline data enable
    // ID/EX Pipeline  Register
    wire                   id_is_jalr;     // is JALR instruction
    wire [`EXP_CODE_BUS]   id_exp_code;    // Exception code
    wire [`WORD_DATA_BUS]  id_pc;          // Program count
    wire                   id_en;          //  Pipeline data enable
    wire [`ALU_OP_BUS]     id_alu_op;      // ALU operation
    wire [`WORD_DATA_BUS]  id_alu_in_0;    // ALU input 0
    wire [`WORD_DATA_BUS]  id_alu_in_1;    // ALU input 1
    wire [`CMP_OP_BUS]     id_cmp_op;      // CMP Operation
    wire [`WORD_DATA_BUS]  id_cmp_in_0;    // CMP input 0
    wire [`WORD_DATA_BUS]  id_cmp_in_1;    // CMP input 1
    wire                   id_jump_taken;
    wire [`MEM_OP_BUS]     id_mem_op;      // Memory operation
    wire [`WORD_DATA_BUS]  id_mem_wr_data; // Memory Write data
    wire [`REG_ADDR_BUS]   id_rd_addr;     // GPRWrite  address
    wire                   id_gpr_we_;     // GPRWrite enable
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
    wire [`WORD_DATA_BUS]  ex_out;         // Operating result
    // MEM/WB Pipeline  Register
    wire [`EXP_CODE_BUS]   mem_exp_code;   // Exception code
    wire [`WORD_DATA_BUS]  mem_pc;
    wire                   mem_en;         // If Pipeline data enables
    wire [`REG_ADDR_BUS]   mem_rd_addr;    // General purpose register write  address
    wire                   mem_gpr_we_;    // General purpose register write enable
    wire [`WORD_DATA_BUS]  mem_out;        // Operating result
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
    wire [`WORD_DATA_BUS]  br_addr;        // Branch  address
    wire                   br_taken;       // Branch taken
    wire                   ld_hazard;      // Hazard
    /********** Forward Control **********/
    wire [`FWD_CTRL_BUS]   rs1_fwd_ctrl;
    wire [`FWD_CTRL_BUS]   rs2_fwd_ctrl;
    wire                   ex_rs1_fwd_en;
    wire                   ex_rs2_fwd_en;
    /********** Forward  Data **********/
    wire [`WORD_DATA_BUS]  ex_fwd_data;     // EX Stage
    wire [`WORD_DATA_BUS]  mem_fwd_data;    // MEM Stage
    /********** General Purpose Register Signal **********/
    wire [`WORD_DATA_BUS]  gpr_rs1_data;    // Read data 0
    wire [`WORD_DATA_BUS]  gpr_rs2_data;    // Read data 1
    wire [`REG_ADDR_BUS]   gpr_rs1_addr;    // Read  address 0
    wire [`REG_ADDR_BUS]   gpr_rs2_addr;    // Read  address 1
    /********** Scratch Pad Memory Signal **********/
    // IF Stage
    wire [`WORD_DATA_BUS]  if_spm_rd_data;  // Read data
    wire [`WORD_ADDR_BUS]  if_spm_addr;     // address
    wire                   if_spm_as_;      // address strobe
    wire                   if_spm_rw;       // Read/Write
    wire [`WORD_DATA_BUS]  if_spm_wr_data;  // Write data
    // MEM Stage
    wire [`WORD_DATA_BUS]  mem_spm_rd_data; // Read data
    wire [`WORD_ADDR_BUS]  mem_spm_addr;    // address
    wire                   mem_spm_as_;     // address strobe
    wire                   mem_spm_rw;      // Read/Write
    wire [`WORD_DATA_BUS]  mem_spm_wr_data; // Write data
    /********** CSRs Interface **********/
    wire [`CSR_OP_BUS]     csr_op;          // CSRs operation
    wire [`CSR_ADDR_BUS]   csr_addr;        // Access CSRs address
    wire [`WORD_DATA_BUS]  csr_rd_data;     // Read from CSRs
    wire [`WORD_DATA_BUS]  csr_wr_data;     // Write to CSRs
    wire [`EXP_CODE_BUS]   exp_code;
    wire                   save_exp_code;
    wire                   save_exp;
    wire                   restore_exp;

    wire [`WORD_DATA_BUS]  ctrl_mepc;       // Output from control unit
    wire [`WORD_DATA_BUS]  csr_mepc;        // Output from CSRs uni
    /******** Define Simulation Loop********/
    parameter             STEP = 10;

    /******** Generate Clock ********/
    always #(STEP / 2) begin
        clk <= ~clk;
    end

    assign clk_ = ~clk;

    /********** IF Stage **********/
    if_stage if_stage (
        /********** Clock & Reset **********/
        .clk            (clk),              // Clock
        .reset          (reset),            // Asynchronous Reset
        /********** SPM Interface **********/
        .spm_rd_data    (if_spm_rd_data),   // Read data
        .spm_addr       (if_spm_addr),      // Address
        .spm_as_        (if_spm_as_),       // Address strobe
        .spm_rw         (if_spm_rw),        // Read/Write
        .spm_wr_data    (if_spm_wr_data),   // Write data
        /**********  Pipeline Control Signal **********/
        .stall          (if_stall),         // Stall
        .flush          (if_flush),         // Flush
        .new_pc         (new_pc),           // New PC
        .br_taken       (br_taken),         // Branch taken
        .br_addr        (br_addr),          // Branch address
        /********** IF/ID Pipeline Register **********/
        .pc             (pc),               // Current Program count
        .if_pc          (if_pc),            // Next Program count
        .if_insn        (if_insn),          // Instruction
        .if_en          (if_en)             // Pipeline data enable
    );

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
        .if_pc          (if_pc),            // Next Program count
        .if_insn        (if_insn),          // Instruction
        .if_en          (if_en),            // Pipeline data enable
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
        // output to Control Unit
        .is_eret        (is_eret),          // is ERET instruction
        .op             (op),
        .id_rs1_addr    (id_rs1_addr),
        .id_rs2_addr    (id_rs2_addr),
        .rs1_addr       (rs1_addr),
        .rs2_addr       (rs2_addr),
        .src_reg_used   (src_reg_used)
    );

    ex_stage ex_stage (
        .clk            (clk),
        .reset          (reset),
        .stall          (ex_stall),
        .flush          (ex_flush),
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
        .id_ex_out_sel  (id_ex_out_sel),
        .id_gpr_wr_data (id_gpr_wr_data),
        .ex_rs1_fwd_en  (ex_rs1_fwd_en),
        .ex_rs2_fwd_en  (ex_rs2_fwd_en),
        .mem_fwd_data   (mem_fwd_data),
        .fwd_data       (ex_fwd_data),
        .ex_exp_code    (ex_exp_code),
        .ex_pc          (ex_pc),
        .ex_en          (ex_en),
        .ex_mem_op      (ex_mem_op),
        .ex_mem_wr_data (ex_mem_wr_data),
        .ex_rd_addr     (ex_rd_addr),
        .ex_gpr_we_     (ex_gpr_we_),
        .ex_out         (ex_out),
        .br_addr        (br_addr),
        .br_taken       (br_taken)
    );

    mem_stage mem_stage (
        .clk            (clk),
        .reset          (reset),
        .stall          (mem_stall),
        .flush          (mem_flush),
        .fwd_data       (mem_fwd_data),
        .spm_rd_data    (mem_spm_rd_data),
        .spm_addr       (mem_spm_addr),
        .spm_as_        (mem_spm_as_),
        .spm_rw         (mem_spm_rw),
        .spm_wr_data    (mem_spm_wr_data),
        .ex_exp_code    (ex_exp_code),
        .ex_pc          (ex_pc),
        .ex_en          (ex_en),
        .ex_mem_op      (ex_mem_op),
        .ex_mem_wr_data (ex_mem_wr_data),
        .ex_rd_addr     (ex_rd_addr),
        .ex_gpr_we_     (ex_gpr_we_),
        .ex_out         (ex_out),
        .mem_exp_code   (mem_exp_code),
        .mem_pc         (mem_pc),
        .mem_en         (mem_en),
        .mem_rd_addr    (mem_rd_addr),
        .mem_gpr_we_    (mem_gpr_we_),
        .mem_out        (mem_out)
    );

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
        .ex_rs2_fwd_en  (ex_rs2_fwd_en)
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
        .save_exp_code  (save_exp_code),
        .save_exp       (save_exp),
        .restore_exp    (restore_exp)
    );

    /********** General purpose Register **********/
    gpr gpr (
        /********** Clock & Reset **********/
        .clk            (clk),              // Clock
        .reset          (reset),            // Asynchronous Reset
        /********** Read Port  0 **********/
        .rd_addr_0      (gpr_rs1_addr),     // Read  address
        .rd_data_0      (gpr_rs1_data),    // Read data
        /********** Read Port  1 **********/
        .rd_addr_1      (gpr_rs2_addr),     // Read  address
        .rd_data_1      (gpr_rs2_data),     // Read data
        /********** Write Port  **********/
        .we_            (mem_gpr_we_),      // Write enable
        .wr_addr        (mem_rd_addr),      // Write  address
        .wr_data        (mem_out)           //  Write data
    );
    /********** Scratch Pad Memory **********/
    spm spm (
        /********** Clock **********/
        .clk             (clk_),            // Clock
        /********** Port A: IF Stage **********/
        .if_spm_addr     (if_spm_addr[`SPM_ADDR_LOC]),  // address
        .if_spm_as_      (if_spm_as_),      // address strobe
        .if_spm_rw       (if_spm_rw),       // Read/Write
        .if_spm_wr_data  (if_spm_wr_data),  // Write data
        .if_spm_rd_data  (if_spm_rd_data)   // Read data
    );

    task if_stage_tb;
        input [`WORD_DATA_BUS] _pc;
        input [`WORD_DATA_BUS] _if_pc;
        input [`WORD_DATA_BUS] _if_insn;
        input                  _if_en;

        begin
            if( (pc      === _pc)       &&
                (if_pc   === _if_pc)    &&
                (if_insn === _if_insn)  &&
                (if_en   === _if_en)
              ) begin
                $display("IF Stage Test Succeeded !");
            end else begin
                $display("IF Stage Test Failed !");
            end
        end
    endtask

    task id_stage_tb;
        input [`REG_ADDR_BUS]   _gpr_rs1_addr;
        input [`REG_ADDR_BUS]   _gpr_rs2_addr;
        input [`CSR_OP_BUS]     _csr_op;
        input [`CSR_ADDR_BUS]   _csr_addr;
        input [`WORD_DATA_BUS]  _csr_wr_data;
        input                   _id_is_jalr;
        input [`EXP_CODE_BUS]   _id_exp_code;
        input [`WORD_DATA_BUS]  _id_pc;
        input                   _id_en;
        input [`ALU_OP_BUS]     _id_alu_op;
        input [`WORD_DATA_BUS]  _id_alu_in_0;
        input [`WORD_DATA_BUS]  _id_alu_in_1;
        input [`CMP_OP_BUS]     _id_cmp_op;
        input [`WORD_DATA_BUS]  _id_cmp_in_0;
        input [`WORD_DATA_BUS]  _id_cmp_in_1;
        input                   _id_jump_taken;
        input [`MEM_OP_BUS]     _id_mem_op;
        input [`WORD_DATA_BUS]  _id_mem_wr_data;
        input [`REG_ADDR_BUS]   _id_rd_addr;
        input                   _id_gpr_we_;
        input [`EX_OUT_SEL_BUS] _id_ex_out_sel;
        input [`WORD_DATA_BUS]  _id_gpr_wr_data;
        input                   _is_eret;
        input [`INSN_OP_BUS]    _op;
        input [`REG_ADDR_BUS]   _id_rs1_addr;
        input [`REG_ADDR_BUS]   _id_rs2_addr;
        input [`REG_ADDR_BUS]   _rs1_addr;
        input [`REG_ADDR_BUS]   _rs2_addr;
        input [1:0]             _src_reg_used;

        begin
            if((gpr_rs1_addr  === _gpr_rs1_addr)  &&
               (gpr_rs2_addr  === _gpr_rs2_addr)  &&
               (csr_op        === _csr_op)  &&
               (csr_addr      === _csr_addr)  &&
               (csr_wr_data   === _csr_wr_data)  &&
               (id_is_jalr    === _id_is_jalr)  &&
               (id_exp_code   === _id_exp_code)  &&
               (id_pc         === _id_pc)  &&
               (id_en         === _id_en)  &&
               (id_alu_op     === _id_alu_op)  &&
               (id_alu_in_0   === _id_alu_in_0)  &&
               (id_alu_in_1   === _id_alu_in_1)  &&
               (id_cmp_op     === _id_cmp_op)  &&
               (id_cmp_in_0    === _id_cmp_in_0)  &&
               (id_cmp_in_1    === _id_cmp_in_1)  &&
               (id_jump_taken  === _id_jump_taken)  &&
               (id_mem_op      === _id_mem_op)  &&
               (id_mem_wr_data === _id_mem_wr_data)  &&
               (id_rd_addr     === _id_rd_addr)  &&
               (id_gpr_we_     === _id_gpr_we_)  &&
               (id_ex_out_sel  === _id_ex_out_sel)  &&
               (id_gpr_wr_data === _id_gpr_wr_data)  &&
               (is_eret        === _is_eret)  &&
               (op             === _op)  &&
               (id_rs1_addr  === _id_rs1_addr)  &&
               (id_rs2_addr  === _id_rs2_addr)  &&
               (rs1_addr  === _rs1_addr)  &&
               (rs2_addr  === _rs2_addr)  &&
               (src_reg_used  === _src_reg_used)
              ) begin
                $display("Test Succeeded !");
            end else begin
                $display("Test Failed !");
            end
        end

    endtask

    /******** Test Case ********/
    initial begin
        # 0 begin
            clk      <= 1'h1;
            reset    <= `ENABLE;
        end
        # (STEP * 3/4)
        # STEP begin
            /******** Initialize Test Output ********/
            $display("\n===== Initialization =====");
            if_stage_tb(
                `WORD_DATA_W'h0,                 // pc
                `WORD_DATA_W'h0,                 // if_pc
                `OP_NOP,                         // if_insn
                `DISABLE                         // if_en
            );

            reset <= `DISABLE;
        end
        # STEP begin
            $display("\n========= Clock 1 ========");
            if_stage_tb(
                `WORD_DATA_W'h0,                 // pc
                `WORD_DATA_W'h4,                 // if_pc
                `WORD_DATA_W'h00400493,          // if_insn
                `ENABLE                          // if_en
            );
        end
        # STEP begin
            $display("\n========= Clock 2 ========");
            if_stage_tb(
                `WORD_DATA_W'h4,                 // pc
                `WORD_DATA_W'h8,                 // if_pc
                `WORD_DATA_W'hFFE02913,          // if_insn
                `ENABLE                          // if_en
            );
            $display("%h", gpr_rs2_addr);
            $display("%h", id_alu_in_0);
            $display("%h", rs1_addr);
            $display("%h", rs2_addr);
            id_stage_tb(
                `REG_ADDR_W'h0,                  // gpr_rs1_addr
                `REG_ADDR_W'h4,                  // gpr_rs2_addr
                `CSR_OP_NOP,                     // csr_op
                `CSR_ADDR_W'h0,                  // csr_addr
                `WORD_DATA_W'h0,                 // csr_wr_data
                `DISABLE,                        // id_is_jalr
                `EXP_CODE_W'h0,                   // id_exp_code
                `WORD_DATA_W'h0,                 // id_pc
                `ENABLE,                         // id_en
                `ALU_OP_ADD,                     // id_alu_op
                `WORD_DATA_W'h0,                 // id_alu_in_0
                `WORD_DATA_W'h4,                 // id_alu_in_1
                `CMP_OP_NOP,                     // id_cmp_op
                `WORD_DATA_W'h0,                 // id_cmp_in_0
                `WORD_DATA_W'h4,                 // id_cmp_in_1
                `DISABLE,                        // id_jump_taken
                `MEM_OP_NOP,                     // id_mem_op
                `WORD_DATA_W'h4,                 // id_mem_wr_data
                `WORD_ADDR_W'h3,                 // id_rd_addr
                `ENABLE_,                        // id_gpr_we_
                `EX_OUT_ALU,                     // id_ex_out_sel
                `WORD_DATA_W'h0,                 // id_gpr_wr_data
                `DISABLE,                        // is_eret
                `OP_ALSI,                        // op
                `REG_ADDR_W'h0,                  // id_rs1_addr
                `REG_ADDR_W'h0,                  // id_rs2_addr
                `REG_ADDR_W'h0,                  // rs1_addr
                `REG_ADDR_W'h0,                  // rs2_addr
                2'b0                             // src_reg_used
            );
        end
        # STEP begin
            $display("\n========= Clock 3 ========");
            if_stage_tb(
                `WORD_DATA_W'h8,                 // pc
                `WORD_DATA_W'hc,                 // if_pc
                `WORD_DATA_W'hFFE03993,          // if_insn
                `ENABLE                          // if_en
            );
        end
        # STEP begin
            $display("\n========= Clock 4 ========");
            if_stage_tb(
                `WORD_DATA_W'hc,                 // pc
                `WORD_DATA_W'h10,                // if_pc
                `WORD_DATA_W'h0054CA13,          // if_insn
                `ENABLE                          // if_en
            );
        end
        # STEP begin
            $finish;
        end
    end

    /******** Output Waveform ********/
    initial begin
        $dumpfile("cpu.vcd");
        $dumpvars(0,if_stage);
    end

endmodule