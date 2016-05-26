////////////////////////////////////////////////////////////////////
// Engineer:       Beyond Sky - fan-dave@163.com                  //
//                                                                //
// Additional contributions by:                                   //
//                 Leway Colin - colin4124@gmail.com              //
//                 Junhao Chen                                    //
//                 Kippy Chen - 799182081@qq.com                  //
//                                                                //
// Design Name:    EX Pipeline Stage                              //
// Project Name:   FMRT Mini Core                                 //
// Language:       Verilog                                        //
//                                                                //
// Description:    EX Pipeline Stage.                             //
//                                                                //
////////////////////////////////////////////////////////////////////

`include "common_defines.v"
`include "base_core_defines.v"
`include "hart_ctrl.h"

module ex_stage (
    input  wire                   clk,
    input  wire                   reset,
    // Pipeline Control Signal
    input  wire                   stall,
    input  wire                   flush,
    // ID/EX Pipleline Register
    input  wire                   id_is_jalr,  // is JALR instruction
    input  wire [`EXP_CODE_BUS]   id_exp_code, // Exception code
    input  wire [`WORD_DATA_BUS]  id_pc,
    input  wire                   id_en,       // Pipeline data enable
    input  wire [`ALU_OP_BUS]     id_alu_op,
    input  wire [`WORD_DATA_BUS]  id_alu_in_0,
    input  wire [`WORD_DATA_BUS]  id_alu_in_1,
    input  wire [`CMP_OP_BUS]     id_cmp_op,
    input  wire [`WORD_DATA_BUS]  id_cmp_in_0,
    input  wire [`WORD_DATA_BUS]  id_cmp_in_1,
    input  wire                   id_jump_taken, // true - jump to target pc
    input  wire [`MEM_OP_BUS]     id_mem_op,
    input  wire [`WORD_DATA_BUS]  id_mem_wr_data,
    input  wire [`REG_ADDR_BUS]   id_rd_addr,    // bypass input wire
    input  wire                   id_gpr_we_,
    input  wire [`HART_STATE_B]   id_hart_st,      // ID stage hart state
    input  wire [`EX_OUT_SEL_BUS] id_ex_out_sel,
    input  wire [`WORD_DATA_BUS]  id_gpr_wr_data,
    // Forward Data From MEM Stage
    input  wire                   ex_rs1_fwd_en,
    input  wire                   ex_rs2_fwd_en,
    input  wire [`WORD_DATA_BUS]  mem_fwd_data,   // MEM Stage
    // output to ID Stage
    output wire [`WORD_DATA_BUS]  fwd_data,
    // Output to Next Stage
    output wire [`EXP_CODE_BUS]   ex_exp_code,    // Exception code
    output wire [`WORD_DATA_BUS]  ex_pc,
    output wire                   ex_en,
    output wire [`MEM_OP_BUS]     ex_mem_op,
    output wire [`WORD_DATA_BUS]  ex_mem_wr_data,
    output wire [`REG_ADDR_BUS]   ex_rd_addr,     // bypass output wire
    output wire                   ex_gpr_we_,
    output wire [`WORD_DATA_BUS]  ex_out,
    output wire [`HART_STATE_B]   ex_hart_st,
    // output to IF Stage
    output wire [`WORD_DATA_BUS]  br_addr,        // target pc value of branch or jump
    output wire                   br_taken        // ture - take branch or jump
);

    /******** internal signles ********/
    wire [`WORD_DATA_BUS] alu_out;
    wire [`WORD_DATA_BUS] alu_in_0;
    wire [`WORD_DATA_BUS] mem_wr_data;
    wire                  cmp_out;
    reg  [`WORD_DATA_BUS] ex_out_inner;

    assign fwd_data    = ex_out_inner;
    // Forward Data From MEM Stage
    // When Load instruction in MEM Stage, Store instruction in EX Stage.
    assign alu_in_0    = (ex_rs1_fwd_en == `ENABLE) ? mem_fwd_data : id_alu_in_0;
    assign mem_wr_data = (ex_rs2_fwd_en == `ENABLE) ? mem_fwd_data : id_mem_wr_data;

    // assign alu_in_1 = (ex_rs2_fwd_en == `ENABLE) ? mem_fwd_data : id_alu_in_1;
    // It's wrong! When the instruction is Store, alu_in_1 is imm, not register data!

    /******** input logic ********/
    alu alu_i (
        .arg0 (alu_in_0),
        .arg1 (id_alu_in_1),
        .op   (id_alu_op),
        .val  (alu_out)
    );

    cmp #(32) cmp_i (
        .arg0 (id_cmp_in_0),
        .arg1 (id_cmp_in_1),
        .op   (id_cmp_op),
        .true (cmp_out)
    );

    /******** output logic ********/
    always @(*) begin
        case(id_ex_out_sel)
            `EX_OUT_ALU : ex_out_inner = alu_out;
            `EX_OUT_CMP : ex_out_inner = {31'b0, cmp_out};
            // When EX_OUT_PCN, it is PC + 4
            `EX_OUT_PCN : ex_out_inner = id_gpr_wr_data;
            default     : ex_out_inner = `WORD_DATA_W'h0;
        endcase
    end

    assign br_addr  = id_is_jalr ? {alu_out[31:1], 1'b0} : alu_out;
    // Branch gpr_we_ is disable_ (Logic 1)ut;
    assign br_taken = ( cmp_out && id_gpr_we_ ) | id_jump_taken;

    /******** EX/MEM Pipeline Register ********/
    ex_reg ex_reg_i (
        .clk            (clk),
        .reset          (reset),
        // Inner Output
        .ex_out_inner   (ex_out_inner),    // ex_stage out
        // Pipeline Control Signal
        .stall          (stall),
        .flush          (flush),
        // ID/EX Pipeline Register
        .id_exp_code    (id_exp_code),
        .id_pc          (id_pc),
        .id_en          (id_en),
        .id_mem_op      (id_mem_op),
        .id_mem_wr_data (mem_wr_data),
        .id_rd_addr     (id_rd_addr),     // bypass out
        .id_gpr_we_     (id_gpr_we_),
        .id_hart_st     (id_hart_st),     // ID stage hart state
        // EX/MEM Pipeline Register
        .ex_exp_code    (ex_exp_code),
        .ex_pc          (ex_pc),
        .ex_en          (ex_en),
        .ex_rd_addr     (ex_rd_addr),
        .ex_gpr_we_     (ex_gpr_we_),
        .ex_mem_op      (ex_mem_op),
        .ex_mem_wr_data (ex_mem_wr_data),
        .ex_out         (ex_out),
        .ex_hart_st     (ex_hart_st)
    );

endmodule