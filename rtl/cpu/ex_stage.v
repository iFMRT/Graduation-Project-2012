/**
 * filename: ex_stage.v
 * author  : besky
 * time    : 2015-12-21 23:04:59
 */
`include "stddef.h"
`include "isa.h"
`include "ex_stage.h"
`include "alu.h"
`include "cmp.h"

module ex_stage (
    input                   clk,
    input                   reset,

    input [`ALU_OP_BUS]     alu_op,
    input [`WORD_DATA_BUS]  alu_in0,
    input [`WORD_DATA_BUS]  alu_in1,

    // input [`WORD_DATA_BUS]  cmp_in0,
    // input [`WORD_DATA_BUS]  cmp_in1,
    // input [`CMP_OP_B]       cmp_op,

    input [`MEM_OP_BUS]     id_mem_op,
    input [`WORD_DATA_BUS]  id_mem_wr_data,
    input [`REG_ADDR_BUS]   id_dst_addr, // bypass input
    input                   id_gpr_we_,

    input                   id_gpr_mux_mem,
    input [`EX_OUT_SEL_BUS] ex_out_sel,

    output [`MEM_OP_BUS]    ex_mem_op,
    output [`WORD_DATA_BUS] ex_mem_wr_data,
    output [`REG_ADDR_BUS]  ex_dst_addr, // bypass output
    output                  ex_gpr_we_,

    output [`WORD_DATA_BUS] ex_out

    // input [`WORD_DATA_BUS]  pc_next, // pc_next = current pc + 1
    // input                   jump_en, // true - jump to target pc
    // input                   branch_en, // true - branch instruction
    // output [`WORD_DATA_BUS] pc_target, // target pc value of branch or jump
    // output                  branch       // ture - take branch or jump
);

    /* internal signles ==============================================*/
    wire [`WORD_DATA_BUS] alu_out;
    wire        cmp_out;
    reg  [`WORD_DATA_BUS] ex_out_in;

    /* input logic ===================================================*/


    /* computation ===================================================*/
    alu alu_i (
        .arg0 (alu_in0),
        .arg1 (alu_in1),
        .op   (alu_op),
        .val  (alu_out)
    );

    // cmp #(32) cmp_i (
    //  .arg0 (cmp_in0),
    //  .arg1 (cmp_in1),
    //  .op   (cmp_op),
    //  .true (cmp_out)
    // );

    /* output logic ==================================================*/
    always @(*) begin
        case(ex_out_sel)
            `EX_OUT_ALU : ex_out_in = alu_out;
            // `EX_OUT_CMP : ex_out_in = {31'b0, cmp_out};
            // `EX_OUT_PCN : ex_out_in = pc_next;
        endcase
    end

    // assign pc_target = alu_out;
    // assign branch    = cmp_out & branch_en | jump_en;

    /* ex_stage reg ==================================================*/
    ex_reg ex_reg_i (
        .clk            (clk           ),
        .reset            (reset           ),
        .ex_out_in      (ex_out_in     ),  // ex_stage out
        .ex_out         (ex_out        ),
        .id_dst_addr    (id_dst_addr),  // bypass out
        .id_gpr_we_     (id_gpr_we_    ),
        .id_gpr_mux_mem (id_gpr_mux_mem),
        .id_mem_op      (id_mem_op     ),
        .id_mem_wr_data (id_mem_wr_data),
        .ex_dst_addr    (ex_dst_addr),
        .ex_gpr_we_     (ex_gpr_we_    ),
        .ex_mem_op      (ex_mem_op     ),
        .ex_mem_wr_data (ex_mem_wr_data)
    );

endmodule
