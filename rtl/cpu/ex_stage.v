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
	input  wire                 clk,
	input  wire                 rst,

	input  wire [ 4:0]          id_dst_address,     // bypass input
	input  wire                 id_gpr_we_,
	input  wire [ 1:0]          id_mem_op,
	input  wire [31:0]          id_mem_wr_data,

	output wire [ 4:0]          ex_dst_address,     // bypass output
	output wire                 ex_gpr_we_,
	output wire [ 1:0]          ex_mem_op,
	output wire [31:0]          ex_mem_wr_data,

	input  wire [31:0]          alu_in0,
	input  wire [31:0]          alu_in1,
	input  wire [`ALU_OP_B]     alu_op,
	input  wire [31:0]          cmp_in0,
	input  wire [31:0]          cmp_in1,
	input  wire [`CMP_OP_B]     cmp_op,
	input  wire [`EX_OUT_SEL_B] ex_out_sel,
	output wire [31:0]          ex_out,

	input  wire [31:0]          pc_next,     // pc_next = current pc + 1
	input  wire                 jump_en,     // true - jump to target pc
	input  wire                 branch_en,   // true - branch instruction
	output wire [31:0]          pc_target,   // target pc value of branch or jump
	output wire                 branch       // ture - take branch or jump
);

	/* internal signles ==============================================*/
	wire [31:0] alu_out;
	wire        cmp_out;
	reg  [31:0] ex_out_in;

	/* input logic ===================================================*/

	
	/* computation ===================================================*/
	alu alu_i (
		.arg0 (alu_in0),
		.arg1 (alu_in1),
		.op   (alu_op),
		.val  (alu_out)
	);

	cmp #(32) cmp_i (
		.arg0 (cmp_in0),
		.arg1 (cmp_in1),
		.op   (cmp_op),
		.true (cmp_out)
	);

	/* output logic ==================================================*/
	always @(*) begin
		case(ex_out_sel)
			`EX_OUT_ALU : ex_out_in = alu_out;
			`EX_OUT_CMP : ex_out_in = {31'b0, cmp_out};
			`EX_OUT_PCN : ex_out_in = pc_next;
		endcase
	end

	assign pc_target = alu_out;
	assign branch    = cmp_out & branch_en | jump_en;

	/* ex_stage reg ==================================================*/
	ex_reg ex_reg_i (
		.clk            (clk           ),
		.rst            (rst           ),
		.ex_out_in      (ex_out_in     ),  // ex_stage out
		.ex_out         (ex_out        ),
		.id_dst_address (id_dst_address),  // bypass out
		.id_gpr_we_     (id_gpr_we_    ),
		.id_mem_op      (id_mem_op     ),
		.id_mem_wr_data (id_mem_wr_data),
		.ex_dst_address (ex_dst_address),
		.ex_gpr_we_     (ex_gpr_we_    ),
		.ex_mem_op      (ex_mem_op     ),
		.ex_mem_wr_data (ex_mem_wr_data)
	);

endmodule
