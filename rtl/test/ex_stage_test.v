/**
 * filename  : ex_stage_test.v
 * testmodule: ex_stage
 * author    : besky
 * time      : 2015-12-21 23:04:59
 */
`timescale 1ns/1ps

`include "stddef.h"
`include "isa.h"
`include "vunit.v"
`include "ex_stage.h"
`include "alu.h"
`include "cmp.h"

module ex_stage_test;
	/* Parameter Define ==============================================*/
	parameter VUNIT_IN_EX_OUT = 2'b00;
	parameter VUNIT_IN_BRANCH = 2'b01;

	parameter TRUE  = `CMP_TRUE;
	parameter FALSE = `CMP_FALSE;

	parameter RST   = `ENABLE;
	parameter NRST  = `DISABLE;

	/* ex_stage Instance =============================================*/
	reg                   rst;

	reg  [39:0]           bypass_in;
	wire [ 4:0]           id_dst_address;   // bypass input
	wire                  id_gpr_we_;
	wire [ 1:0]           id_mem_op;
	wire [31:0]           id_mem_wr_data;

	wire [39:0]           bypass_out;
	wire [ 4:0]           ex_dst_address;          // bypass output
	wire                  ex_gpr_we_;
	wire [ 1:0]           ex_mem_op;
	wire [31:0]           ex_mem_wr_data;

	reg  [31:0]           alu_in0;
	reg  [31:0]           alu_in1;
	reg  [`ALU_OP_B]      alu_op;
	reg  [31:0]           cmp_in0;
	reg  [31:0]           cmp_in1;
	reg  [`CMP_OP_B]      cmp_op;
	reg  [`EX_OUT_SEL_B]  ex_out_sel;
	wire [31:0]           ex_out;
	reg  [31:0]           pc_next;
	reg                   jump_en;
	reg                   branch_en;
	wire [31:0]           pc_target;
  wire                  branch;

	ex_stage ex_stage_t (
		.clk            (clk),
		.rst            (rst),

		.id_dst_address (id_dst_address),
		.id_gpr_we_     (id_gpr_we_    ),
		.id_mem_op      (id_mem_op     ),
		.id_mem_wr_data (id_mem_wr_data),

		.ex_dst_address (ex_dst_address),
		.ex_gpr_we_     (ex_gpr_we_    ),
		.ex_mem_op      (ex_mem_op     ),
		.ex_mem_wr_data (ex_mem_wr_data),

		.alu_in0    (alu_in0  ),
		.alu_in1    (alu_in1  ),
		.alu_op     (alu_op   ),
		.cmp_in0    (cmp_in0  ),
		.cmp_in1    (cmp_in1  ),
		.cmp_op     (cmp_op   ),
		.ex_out_sel (ex_out_sel),
		.ex_out     (ex_out   ),
		.pc_next    (pc_next  ),
    .jump_en    (jump_en  ),
    .branch_en  (branch_en),
    .pc_target  (pc_target),
    .branch     (branch   )
	);

	assign {id_dst_address, id_gpr_we_, id_mem_op, id_mem_wr_data} 
				= bypass_in;

	assign  bypass_out = 
				 {ex_dst_address, ex_gpr_we_, ex_mem_op, ex_mem_wr_data};

	reg  [39:0] exp_bypass;
	reg         check_reg;
	vunit #(40) vunit_reg (              // Change the WIDTH
		.check     (check_reg),
		.real_val  (bypass_out),            // tested output => vunit input
		.exp_val   (exp_bypass),
		.op        (`VUNIT_OP_EQ),          // only test eq
		.is_right  ()                       // hang in the air
	);

	task regvct;
		input [39:0] bypass_in_t;
		input [39:0] exp_bypass_t;
		begin
			bypass_in  = bypass_in_t;
			# STEP begin
				$write("%m.%2d: (%b, %h, %b, %b, %h) || ",	
					times, rst, 
					id_dst_address, id_gpr_we_, id_mem_op, id_mem_wr_data);
				exp_bypass = exp_bypass_t;
				check_reg  = ~check_reg;
			end
		end
	endtask

	/* VUNIT Instance ================================================*/
	reg                check;            // DON'T MODIFY THIS SECTION!!!(except commented)
	reg  [1:0]         vunit_in_sel;
	reg  [31:0]        real_val;
	reg  [31:0]        exp_val;          // Change the bus.
	reg  [`VUNIT_OP_B] vunit_op;
	wire               is_right;

	vunit #(32) vunit_ex(                // Change the WIDTH
		.check    (check),
		.real_val (real_val),              // tested output => vunit input
		.exp_val  (exp_val),
		.op       (vunit_op),
		.is_right (is_right)
	);

	always @(*) begin
		case(vunit_in_sel)
			VUNIT_IN_EX_OUT: real_val = ex_out;
			VUNIT_IN_BRANCH: real_val = branch;
		endcase
	end

	/* Interface Connection ==========================================*/
	task vector;
		input [31:0]           alu_in0_t, alu_in1_t;
		input [`ALU_OP_B]      alu_op_t;
		input [31:0]           cmp_in0_t, cmp_in1_t;
		input [`CMP_OP_B]      cmp_op_t;
		input [`EX_OUT_SEL_B]  ex_out_sel_t;
		input [31:0]           pc_next_t;
		input                  jump_en_t;
		input                  branch_en_t;

		input [1:0]            vunit_in_sel_t;
		input [`VUNIT_OP_B]    vunit_op_t;
		input [31:0]           exp_val_t;  // Change the bus.

		begin
			alu_in0    = alu_in0_t;          // ex_stage module input
			alu_in1    = alu_in1_t;
			alu_op     = alu_op_t;
			cmp_in0    = cmp_in0_t;
			cmp_in1    = cmp_in1_t;
			cmp_op     = cmp_op_t;
			ex_out_sel = ex_out_sel_t;
			pc_next    = pc_next_t;
      jump_en    = jump_en_t;
      branch_en  = branch_en_t;
			# STEP begin
				exp_val      = exp_val_t;      // vunit module input
				vunit_in_sel = vunit_in_sel_t;
				vunit_op     = vunit_op_t;
				check        = ~check;
			end
		end
	endtask

	integer times = 1;
	task aluvct;                         // alu test vector
		input [31:0]        alu_in0_t, alu_in1_t;
		input [`ALU_OP_B]   alu_op_t;
		input [`VUNIT_OP_B] vunit_op_t;
		input [31:0]        exp_val_t;     // Change the bus.
		begin
			vector(alu_in0_t, alu_in1_t, alu_op_t, 
				     32'b0, 32'b0, `CMP_OP_NOP, 
						 `EX_OUT_ALU, 
			       32'b0, FALSE, FALSE,
						 VUNIT_IN_EX_OUT, vunit_op_t, exp_val_t); 
			$write("%m.%2d: (%h, %h, %0h) || ",	
				times, alu_in0_t, alu_in1_t, alu_op_t);  // show test vectors
				times = times + 1;
		end
	endtask

	task cmpvct;                        // cmp test vector
		input [31:0]        cmp_in0_t, cmp_in1_t;
		input [`CMP_OP_B]   cmp_op_t;
		input [`VUNIT_OP_B] vunit_op_t;
		input               exp_val_t;    // Change the bus.
		begin
			vector(32'b0, 32'b0, `ALU_OP_NOP,
				     cmp_in0_t, cmp_in1_t, cmp_op_t, 
						 `EX_OUT_CMP, 
			       32'b0, FALSE, FALSE,
						 VUNIT_IN_EX_OUT, vunit_op_t, {31'b0, exp_val_t}); 
			$write("%m.%2d: (%h, %h, %0h) || ",	
				times, cmp_in0_t, cmp_in1_t, cmp_op_t);  // show test vectors
				times = times + 1;
		end
	endtask

	task pcnvct;                        // cmp test vector
		input [31:0]        pc_next_t;
		input [`VUNIT_OP_B] vunit_op_t;
		input [31:0]        exp_val_t;    // Change the bus.
		begin
			vector(32'b0, 32'b0, `ALU_OP_NOP,
						 32'b0, 32'b0, `CMP_OP_NOP,
						 `EX_OUT_PCN, 
			       pc_next_t, FALSE, FALSE,
						 VUNIT_IN_EX_OUT, vunit_op_t, exp_val_t); 
			$write("%m.%2d: (%h) || ",	
				times, pc_next_t);            // show test vectors
				times = times + 1;
		end
	endtask

	task bcheqvct;                      // branch test vector(real == exp)
		input [31:0]        cmp_in0_t, cmp_in1_t;
		input [`CMP_OP_B]   cmp_op_t;
		input               jump_en_t, branch_en_t;
		input               exp_val_t;    // Change the bus.
		begin
			vector(32'b0, 32'b0, `ALU_OP_NOP,
				     cmp_in0_t, cmp_in1_t, cmp_op_t, 
						 `EX_OUT_CMP, 
			       32'b0, jump_en_t, branch_en_t,
						 VUNIT_IN_BRANCH, `VUNIT_OP_EQ, {31'b0, exp_val_t}); 
			$write("%m.%2d: (%h, %h, %0h, %b, %b) || ",	
				times, cmp_in0_t, cmp_in1_t, cmp_op_t, jump_en_t, branch_en_t);  // show test vectors
				times = times + 1;
		end
	endtask

	/* Test Vector ===================================================*/
	initial begin
		# 0 begin       // DON'T CHANGE HERE
			clk   <= 1;   // just add initial signals if needed
			check <= 1;
			check_reg <= 1;
			rst   <= RST;
		end

		# STEP rst <= NRST;

		# (STEP / 4)  // uncomment this line for sequential circuit
		// ALU test
		//vector(32'h0000_0000, 32'h0000_0000, ALU_OP_ADD, 32'b0, 32'b0, CMP_OP_NOP, EX_OUT_ALU, VUNIT_OP_EQ, 32'b0); 
		aluvct(32'h0000_0000, 32'h0000_0000, `ALU_OP_AND, `VUNIT_OP_EQ, 32'b0); 
		aluvct(32'h0000_0000, 32'h0000_0FF0, `ALU_OP_AND, `VUNIT_OP_EQ, 32'b0); 
		aluvct(32'h00F0_0000, 32'h0F00_0000, `ALU_OP_ADD, `VUNIT_OP_EQ, 32'h0FF0_0000); 
		aluvct(32'h0000_0000, 32'h0000_0ff0, `ALU_OP_ADD, `VUNIT_OP_EQ, 32'h0000_0ff0); 

		// CMP test
		cmpvct(32'h0000_0000, 32'h0000_0FF0, `CMP_OP_EQ , `VUNIT_OP_EQ, FALSE); 
		cmpvct(32'h0000_0000, 32'h0000_0FF0, `CMP_OP_NE , `VUNIT_OP_EQ, TRUE ); 
		cmpvct(32'h0000_0000, 32'h0000_0FF0, `CMP_OP_GE , `VUNIT_OP_EQ, FALSE); 
		cmpvct(32'h0000_0000, 32'h8000_0FF0, `CMP_OP_GE , `VUNIT_OP_EQ, TRUE ); 

		// PC NEXT test
		pcnvct(32'h0000_0000, `VUNIT_OP_EQ, 32'b0);
		pcnvct(32'h8000_0000, `VUNIT_OP_EQ, 32'h8000_0000);
		pcnvct(32'h55aa_aa55, `VUNIT_OP_EQ, 32'h55aa_aa55);
		pcnvct(32'ha0f0_00a0, `VUNIT_OP_EQ, 32'ha0f0_00a0);

		// branch test
		// no branch or jump
		bcheqvct(32'h0000_0000, 32'h0000_0000, `CMP_OP_EQ, FALSE, FALSE, FALSE);
		bcheqvct(32'h0000_1000, 32'h0000_1000, `CMP_OP_EQ, FALSE, FALSE, FALSE);
		bcheqvct(32'h1000_1000, 32'h1000_1000, `CMP_OP_NE, FALSE, FALSE, FALSE);

		// branch
		bcheqvct(32'h0000_0000, 32'h0000_0000, `CMP_OP_EQ, FALSE, TRUE , TRUE);
		bcheqvct(32'h0000_0000, 32'h0000_0000, `CMP_OP_NE, FALSE, TRUE , FALSE);
		bcheqvct(32'h0000_0000, 32'h0000_0000, `CMP_OP_GE, FALSE, TRUE , TRUE );
		bcheqvct(32'h8000_0000, 32'h0000_0000, `CMP_OP_GE, FALSE, TRUE , FALSE);
		// jump
		bcheqvct(32'h0000_0000, 32'h0000_0000, `CMP_OP_EQ, TRUE , FALSE, TRUE);
		bcheqvct(32'hfdcc_0000, 32'h0000_0123, `CMP_OP_EQ, TRUE , FALSE, TRUE);
		bcheqvct(32'h0000_0000, 32'h0000_0000, `CMP_OP_EQ, FALSE, FALSE, FALSE);
		bcheqvct(32'h0000_0000, 32'h0000_0000, `CMP_OP_NE, FALSE, FALSE, FALSE);

		//# (STEP * 3 / 4)
		rst <= RST;
		regvct({32'hFFFF_FFFF, 1'b1, 2'b11, 32'hFFFF_FFFF}, 
					 {32'h0000_0000, 1'b0, 2'b00, 32'h0000_0000});
		rst <= NRST;
		regvct({32'hFFFF_FFFF, 1'b1, 2'b11, 32'hFFFF_FFFF}, 
					 {32'hFFFF_FFFF, 1'b1, 2'b11, 32'hFFFF_FFFF});
		regvct({32'hF0F1_234F, 1'b0, 2'b01, 32'h12dF_0010}, 
					 {32'hF0F1_234F, 1'b0, 2'b01, 32'h12dF_0010});

		# STEP $finish;
	end

	/* Clock Generation ==============================================*/
	parameter STEP  = `VUNIT_STEP;        // 10M
	reg                clk;
	always #(STEP / 2) clk <= ~clk;

	/* Wave Generation ===============================================*/
	initial begin
		$dumpfile("ex_stage_test.vcd");
		$dumpvars(0, ex_stage_t);
	end
endmodule
