/**
 * filename  : alu_test.v
 * testmodule: alu
 * author    : besky
 * time      : 2015-12-19 10:24:48
 */
`timescale 1ns/1ps

`include "stddef.h"
`include "isa.h"
`include "alu.h"
`include "vunit.v"

module alu_test;
	/* alu Instance ==============================*/
	reg  [31:0] arg0;
	reg  [31:0] arg1;
	reg  [ 3:0] alu_op;
	wire [31:0] value;

	alu alu_t (
		.arg0 (arg0),
		.arg1 (arg1),
		.op   (alu_op),
		.val  (value)
	);

	/* VUNIT Instance ================================================*/
	reg                check;            // DON'T MODIFY THIS SECTION!!!
	reg  [31:0]        exp_val;          // Except the bus of exp_val
	reg  [`VUNIT_OP_B] vunit_op;
	wire               is_right;

	vunit #(32) vunit_t (                // Change the width of module
		.check    (check),
		.real_val (value),                 // tested output => vunit input
		.exp_val  (exp_val),
		.op       (vunit_op),
		.is_right (is_right)
	);

	/* Interface Connection ==========================================*/
	integer times = 1;
	task vector;
		input [31:0] arg0_t;
		input [ 3:0] alu_op_t;
		input [31:0] arg1_t;

		input [`VUNIT_OP_B] vunit_op_t;
		input [31:0] exp_val_t;

		begin
			arg0   = arg0_t;            // alu module input
			alu_op = alu_op_t;
			arg1   = arg1_t;
			# STEP begin                // DON'T CHANGE BELOW↓(Except $write)
				$write("%m.%2d: (%h, %h, %0h) || ", times, arg0, arg1, alu_op);  // show test vectors
				times    = times + 1;
				exp_val  = exp_val_t;     // vunit module input
				vunit_op = vunit_op_t;
				check    = ~check;
			end
		end
	endtask

	/* Test Vector ===================================================*/
	initial begin
		# 0 begin       // DON'T CHANGE HERE
			clk   <= 1;   // just add initial signals if needed
			check <= 1;
		end

		//# (STEP * 3 / 4)  // uncomment this line for sequential circuit
		// NOP
		vector(32'b0, `ALU_OP_NOP, 32'b1, `VUNIT_OP_EQ, 32'b0);
		vector(32'b1, `ALU_OP_NOP, 32'b1, `VUNIT_OP_EQ, 32'b0);
		// AND
		vector(32'b0,         `ALU_OP_AND, 32'hffff_ffff, `VUNIT_OP_EQ, 32'b0);
		vector(32'hffff_ffff, `ALU_OP_AND, 32'hffff_ffff, `VUNIT_OP_EQ, 32'hffff_ffff);
		vector(32'hf0ff_ffff, `ALU_OP_AND, 32'hffff_ff01, `VUNIT_OP_EQ, 32'hf0ff_ff01);
		vector(32'hf0ff_ff1f, `ALU_OP_AND, 32'hffff_ff01, `VUNIT_OP_EQ, 32'hf0ff_ff01);

		// OR
		vector(32'h0,         `ALU_OP_OR,  32'hffff_ffff, `VUNIT_OP_EQ, 32'hffff_ffff);
		vector(32'h0,         `ALU_OP_OR,  32'h0000_0000, `VUNIT_OP_EQ, 32'h0000_0000);
		vector(32'hf0ff_ffff, `ALU_OP_OR,  32'hffff_ff01, `VUNIT_OP_EQ, 32'hffff_ffff);
		vector(32'hf0ff_ff1f, `ALU_OP_OR,  32'hffff_ff01, `VUNIT_OP_EQ, 32'hffff_ff1f);

		// NOT (arg0 XOR 32'hffff_ffff)
		vector(32'h0,         `ALU_OP_XOR, 32'hffff_ffff, `VUNIT_OP_EQ, 32'hffff_ffff);
		vector(32'h0,         `ALU_OP_XOR, 32'hffff_ffff, `VUNIT_OP_EQ, 32'hffff_ffff);
		vector(32'hffff_ffff, `ALU_OP_XOR, 32'hffff_ffff, `VUNIT_OP_EQ, 32'h0000_0000);
		vector(32'h1010_0101, `ALU_OP_XOR, 32'hffff_ffff, `VUNIT_OP_EQ, 32'hefef_fefe);

		// Shift Left Logic
		vector(32'h0,         `ALU_OP_SLL, 32'hffff_ffff, `VUNIT_OP_EQ, 32'h0000_0000);
		vector(32'hffff_ffff, `ALU_OP_SLL, 32'h0000_0004, `VUNIT_OP_EQ, 32'hffff_fff0); 
		vector(32'h1010_0101, `ALU_OP_SLL, 32'h0000_0003, `VUNIT_OP_EQ, 32'h8080_0808);

		// Shift Right Logic
		vector(32'h0,         `ALU_OP_SRL, 32'hffff_ffff, `VUNIT_OP_EQ, 32'h0000_0000);
		vector(32'hffff_ffff, `ALU_OP_SRL, 32'h0000_0004, `VUNIT_OP_EQ, 32'h0fff_ffff); 
		vector(32'h1010_0101, `ALU_OP_SRL, 32'h0000_0003, `VUNIT_OP_EQ, 32'h0202_0020);

		// Shift Right Arithmetic
		vector(32'h0,         `ALU_OP_SRA, 32'h0000_0005, `VUNIT_OP_EQ, 32'h0000_0000);
		vector(32'hffff_ffff, `ALU_OP_SRA, 32'h0000_0004, `VUNIT_OP_EQ, 32'hffff_ffff); 
		vector(32'h8010_0f01, `ALU_OP_SRA, 32'h0000_0003, `VUNIT_OP_EQ, 32'hf002_01e0);
 
		// XOR
		vector(32'h0123_abcd, `ALU_OP_XOR, 32'h0000_0000, `VUNIT_OP_EQ, 32'h0123_abcd);
		vector(32'h0000_0000, `ALU_OP_XOR, 32'hffff_ffff, `VUNIT_OP_EQ, 32'hffff_ffff);
		vector(32'h1010_8030, `ALU_OP_XOR, 32'h1000_2010, `VUNIT_OP_EQ, 32'h0010_a020);
		vector(32'h1010_0101, `ALU_OP_XOR, 32'h1010_0101, `VUNIT_OP_EQ, 32'h0000_0000);
		vector(32'h1010_0101, `ALU_OP_XOR, 32'hefef_fefe, `VUNIT_OP_EQ, 32'hffff_ffff);
                                      
		// ADD                            
		vector(32'h0123_abcd, `ALU_OP_ADD, 32'h0000_0000, `VUNIT_OP_EQ, 32'h0123_abcd);
		vector(32'h0000_0000, `ALU_OP_ADD, 32'hffff_ffff, `VUNIT_OP_EQ, 32'hffff_ffff);
		vector(32'h1010_8030, `ALU_OP_ADD, 32'h1000_2010, `VUNIT_OP_EQ, 32'h2010_a040);
		vector(32'h1010_0101, `ALU_OP_ADD, 32'h1010_0101, `VUNIT_OP_EQ, 32'h2020_0202);
		vector(32'h1010_0101, `ALU_OP_ADD, 32'hefef_fefe, `VUNIT_OP_EQ, 32'hffff_ffff);
                                      
		// SUB                            
		vector(32'h0123_abcd, `ALU_OP_SUB, 32'h0000_0000, `VUNIT_OP_EQ, 32'h0123_abcd);
		vector(32'h0000_0000, `ALU_OP_SUB, 32'hffff_ffff, `VUNIT_OP_EQ, 32'h0000_0001);
		vector(32'h1010_8030, `ALU_OP_SUB, 32'h1000_2010, `VUNIT_OP_EQ, 32'h0010_6020);
		vector(32'h1010_0101, `ALU_OP_SUB, 32'h1010_0101, `VUNIT_OP_EQ, 32'h0000_0000);
		vector(32'h1010_0101, `ALU_OP_SUB, 32'hefef_fefe, `VUNIT_OP_EQ, 32'h2020_0203);

		# STEP $finish;
	end

	/* Clock Generation ==============================================*/
	parameter STEP  = `VUNIT_STEP;        // 10M
	reg                clk;
	always #(STEP / 2) clk <= ~clk;

	/* Wave Generation ===============================================*/
	initial begin
		$dumpfile("alu_test.vcd");
		$dumpvars(0, alu_t);
	end
endmodule
