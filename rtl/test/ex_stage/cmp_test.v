/**
 * filename  : cmp_test.v
 * testmodule: cmp
 * author    : besky
 * time      : 2015-12-15 21:34:41
 */
`timescale 1ns/1ps

`include "stddef.h"
`include "isa.h"
`include "vunit.v"
`include "cmp.h"

module cmp_test;
	/* CMP Instance ==================================================*/
	reg  [31:0] arg0;
	reg  [31:0] arg1;
	reg  [ 2:0] op;
	wire        true;

	cmp #(32) cmp_t (
		.arg0 (arg0),
		.arg1 (arg1),
		.op   (op),
		.true (true)
	);

	/* VUNIT Instance ================================================*/
	reg                check;
	reg                exp_val;
	reg  [`VUNIT_OP_B] vunit_op;
	wire               is_right;

	vunit #(1) vunit_t (
		.check    (check),
		.real_val (true),                  // cmp output => vunit input
		.exp_val  (exp_val),
		.op       (vunit_op),
		.is_right (is_right)
	);

	/* Parameter Define ==============================================*/
	parameter TRUE         = `CMP_TRUE;
	parameter FALSE        = `CMP_FALSE;

	/* Test Vector ===================================================*/
	initial begin
		# 0 begin 
			clk   <= 1;
			check <= 1;
		end

		// 1. test cmp eq                  || ((arg0 == arg1)? == TRUE)?
		//# (STEP * 3 / 4) 
		vector(32'h0001_0000, `CMP_OP_EQ, 32'h0001_0000, `VUNIT_OP_EQ, TRUE);
		vector(32'h0000_1056, `CMP_OP_EQ, 32'h1056_1056, `VUNIT_OP_EQ, FALSE);
		vector(32'h0000_1056, `CMP_OP_EQ, 32'h0000_1056, `VUNIT_OP_EQ, TRUE);

		// 2. test not eq
		vector(32'h0000_1056, `CMP_OP_NE, 32'h1056_1056, `VUNIT_OP_EQ, TRUE);
		vector(32'h0000_1056, `CMP_OP_NE, 32'h0000_1056, `VUNIT_OP_EQ, FALSE);
		vector(32'h0000_0000, `CMP_OP_NE, 32'hffff_ffff, `VUNIT_OP_NEQ,FALSE);
		vector(32'hffff_0000, `CMP_OP_NE, 32'hffff_0000, `VUNIT_OP_NEQ,TRUE);
		vector(32'b0        , `CMP_OP_NE, 32'hffff_0000, `VUNIT_OP_EQ, TRUE);
		vector(32'h1000_0000, `CMP_OP_NE, 32'h0000_0000, `VUNIT_OP_EQ, TRUE);

		// 3. test lower than (signed-compare)
		vector(32'h0000_0000, `CMP_OP_LT, 32'h0000_0001, `VUNIT_OP_EQ, TRUE );
		vector(32'h8000_0000, `CMP_OP_LT, 32'h0000_0001, `VUNIT_OP_EQ, TRUE );
		vector(32'h8000_0000, `CMP_OP_LT, 32'h8000_0001, `VUNIT_OP_EQ, TRUE );
		vector(32'h8000_0000, `CMP_OP_LT, 32'h7000_0000, `VUNIT_OP_EQ, TRUE );
		vector(32'hffff_ffff, `CMP_OP_LT, 32'h0000_0000, `VUNIT_OP_EQ, TRUE );

		// 4. test lower than (unsigned-compare)
		vector(32'h0000_0000, `CMP_OP_LTU, 32'h0000_0001, `VUNIT_OP_EQ, TRUE ); 
		vector(32'h8000_0000, `CMP_OP_LTU, 32'h0000_0001, `VUNIT_OP_EQ, FALSE); 
		vector(32'h8000_0000, `CMP_OP_LTU, 32'h8000_0001, `VUNIT_OP_EQ, TRUE ); 
		vector(32'h8000_0000, `CMP_OP_LTU, 32'h0000_0005, `VUNIT_OP_EQ, FALSE); 
		vector(32'hffff_ffff, `CMP_OP_LTU, 32'h0000_0000, `VUNIT_OP_EQ, FALSE); 

		// 5. test greater equal (signed-compare)
		vector(32'h0000_0000, `CMP_OP_GE, 32'h0000_0000, `VUNIT_OP_EQ, TRUE ); 
		vector(32'h0000_0000, `CMP_OP_GE, 32'h0000_0001, `VUNIT_OP_EQ, FALSE); 
		vector(32'h8000_0000, `CMP_OP_GE, 32'h0000_0001, `VUNIT_OP_EQ, FALSE); 
		vector(32'h8000_0000, `CMP_OP_GE, 32'h8000_0001, `VUNIT_OP_EQ, FALSE); 
		vector(32'h8000_0000, `CMP_OP_GE, 32'h0000_0005, `VUNIT_OP_EQ, FALSE); 
		vector(32'hffff_ffff, `CMP_OP_GE, 32'h0000_0000, `VUNIT_OP_EQ, FALSE); 
		
		// 6. test greater equal (unsigned-compare)
		vector(32'h0000_0000, `CMP_OP_GEU, 32'h0000_0000, `VUNIT_OP_EQ, TRUE ); 
		vector(32'h0000_0000, `CMP_OP_GEU, 32'h0000_0001, `VUNIT_OP_EQ, FALSE); 
		vector(32'h8000_0000, `CMP_OP_GEU, 32'h0000_0001, `VUNIT_OP_EQ, TRUE ); 
		vector(32'h8000_0000, `CMP_OP_GEU, 32'h8000_0001, `VUNIT_OP_EQ, FALSE); 
		vector(32'h8000_0000, `CMP_OP_GEU, 32'h0000_0005, `VUNIT_OP_EQ, TRUE ); 
		vector(32'hffff_ffff, `CMP_OP_GEU, 32'h0000_0000, `VUNIT_OP_EQ, TRUE ); 
		
		# STEP $finish;
	end

	/* Interface Connection ==========================================*/
	integer times = 1;
	task vector;
		input [31:0] arg0_t;
		input [ 2:0] op_t;
		input [31:0] arg1_t;

		input [`VUNIT_OP_B] vunit_op_t;
		input               exp_val_t;

		begin
			arg0 = arg0_t;            // cmp module input
			arg1 = arg1_t;
			op   = op_t;
			# STEP begin
				$write("%m.%2d: (%h, %h, %o) || ", times, arg0, arg1, op);
				times    = times + 1;
				exp_val  = exp_val_t;     // vunit module input
				vunit_op = vunit_op_t;
				check    = ~check;
			end
		end
	endtask

	/* Clock Generation ==============================================*/
	parameter STEP  = `VUNIT_STEP;        // 10M
	reg                clk;
	always #(STEP / 2) clk <= ~clk;

	/* Wave Generation ===============================================*/
	initial begin
		$dumpfile("cmp_test.vcd");
		$dumpvars(0, cmp_t);
	end
endmodule
