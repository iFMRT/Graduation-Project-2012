/**
 * filename: ex_stage.v
 * author  : besky
 * time    : 2015-12-21 23:04:59
 */

`include "isa.h"
`include "alu.h"
`include "cmp.h"
`include "ctrl.h"
`include "stddef.h"
`include "cpu.h"
`include "mem.h"
`include "ex_stage.h"

module ex_stage (
    input                   clk,
    input                   reset,
    // Pipeline Control Signal
    input                   stall,
    input                   flush,

    input  wire             id_en,
    input [`ALU_OP_BUS]     id_alu_op,
    input [`WORD_DATA_BUS]  id_alu_in_0,
    input [`WORD_DATA_BUS]  id_alu_in_1,

    // input [`WORD_DATA_BUS]  id_cmp_in0,
    // input [`WORD_DATA_BUS]  id_cmp_in1,
    // input [`CMP_OP_B]       id_cmp_op,

    input [`MEM_OP_BUS]     id_mem_op,
    input [`WORD_DATA_BUS]  id_mem_wr_data,
    input [`REG_ADDR_BUS]   id_dst_addr, // bypass input
    input                   id_gpr_we_,

    input [`EX_OUT_SEL_BUS] ex_out_sel,

    input [`WORD_DATA_BUS] id_gpr_wr_data,

    // Forward Data From MEM Stage 
    input                   ex_ra_fwd_en,
    input                   ex_rb_fwd_en,
    input [`WORD_DATA_BUS]  mem_fwd_data,    // MEM Stage
    
    output [`WORD_DATA_BUS] fwd_data,   

    output                  ex_en, 
    output [`MEM_OP_BUS]    ex_mem_op,
    output [`WORD_DATA_BUS] ex_mem_wr_data,
    output [`REG_ADDR_BUS]  ex_dst_addr, // bypass output
    output                  ex_gpr_we_,

    output [`WORD_DATA_BUS] ex_out,

    // input [`WORD_DATA_BUS]  pc_next, // pc_next = current pc + 1
    input                   id_jump_taken, // true - jump to target pc

    output [`WORD_DATA_BUS] br_addr, // target pc value of branch or jump
    output                  br_taken       // ture - take branch or jump
);

    /* internal signles ==============================================*/
    wire [`WORD_DATA_BUS] alu_out;
    wire [`WORD_DATA_BUS] alu_in_0;
    wire [`WORD_DATA_BUS] mem_wr_data;
    // wire        cmp_out;
    reg  [`WORD_DATA_BUS] ex_out_inner;

    assign fwd_data    = alu_out;
    // Forward Data From MEM Stage 
    // When Load instruction in MEM Stage, Store instruction in EX Stage.
    assign alu_in_0    = (ex_ra_fwd_en == `ENABLE) ? mem_fwd_data : id_alu_in_0;
    assign mem_wr_data = (ex_rb_fwd_en == `ENABLE) ? mem_fwd_data : id_mem_wr_data;

    // assign alu_in_1 = (ex_rb_fwd_en == `ENABLE) ? mem_fwd_data : id_alu_in_1; 
    // It's wrong! When the instruction is Store, alu_in_1 is imm, not register data!

    /* input logic ===================================================*/


    /* computation ===================================================*/
    alu alu_i (
        .arg0 (alu_in_0),
        .arg1 (id_alu_in_1),
        .op   (id_alu_op),
        .val  (alu_out)
    );

    // cmp #(32) cmp_i (
    //  .arg0 (id_cmp_in0),
    //  .arg1 (id_cmp_in1),
    //  .op   (id_cmp_op),
    //  .true (id_cmp_out)
    // );

    /* output logic ==================================================*/
    always @(*) begin
        case(ex_out_sel)
            `EX_OUT_ALU : begin
                ex_out_inner = alu_out;
            end
            // `EX_OUT_CMP : ex_out_inner = {31'b0, cmp_out};
            `EX_OUT_PCN : begin
                ex_out_inner = id_gpr_wr_data;  // When EX_OUT_PCN, it is PC + 4
            end
            default: begin
                ex_out_inner = `WORD_DATA_W'h0;
            end
        endcase
    end

    assign br_addr  = alu_out;
    assign br_taken = id_jump_taken;
    // assign br_taken = cmp_out | id_jump_taken;

    /* ex_stage reg ==================================================*/
    ex_reg ex_reg_i (
        .clk            (clk),
        .reset          (reset),
        // Inner Output
        .ex_out_inner   (ex_out_inner),    // ex_stage out
        // Pipeline Control Signal
        .stall          (stall),
        .flush          (flush),
        // ID/EX Pipeline Register
        .id_en          (id_en),
        .id_mem_op      (id_mem_op),
        .id_mem_wr_data (mem_wr_data),
        .id_dst_addr    (id_dst_addr),     // bypass out
        .id_gpr_we_     (id_gpr_we_),
        // EX/MEM Pipeline Register
        .ex_en          (ex_en),
        .ex_dst_addr    (ex_dst_addr),
        .ex_gpr_we_     (ex_gpr_we_),
        .ex_mem_op      (ex_mem_op),
        .ex_mem_wr_data (ex_mem_wr_data),
        .ex_out         (ex_out)
    );

endmodule
