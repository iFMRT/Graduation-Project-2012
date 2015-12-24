/**
 * filename  : ex_reg_test.v
 * testmodule: ex_reg
 * author    : besky
 * time      : 2015-12-23 19:33:22
 */
`timescale 1ns/1ps

`include "stddef.h"
`include "isa.h"
`include "vunit.v"

module ex_reg_test;
	/* Parameter Define ==============================================*/
	parameter WIDTH        = 32 + 5 + 1 + 2 + 32; // 72

	/* ex_reg Instance ==============================*/
	reg         rst;
	reg  [31:0] ex_out_in;
	wire [31:0] ex_out;

	reg  [ 4:0] id_dst_address;          // bypass input
	reg         id_gpr_we_;
	reg  [ 1:0] id_mem_op;
	reg  [31:0] id_mem_wr_data;

	wire [ 4:0] ex_dst_address;          // bypass output
	wire        ex_gpr_we_;
	wire [ 1:0] ex_mem_op;
	wire [31:0] ex_mem_wr_data;

	ex_reg ex_reg_t (
		.clk            (clk           ),
		.rst            (rst           ),
		.ex_out_in      (ex_out_in     ),
		.ex_out         (ex_out        ),
		.id_dst_address (id_dst_address),
		.id_gpr_we_     (id_gpr_we_    ),
		.id_mem_op      (id_mem_op     ),
		.id_mem_wr_data (id_mem_wr_data),
		.ex_dst_address (ex_dst_address),
		.ex_gpr_we_     (ex_gpr_we_    ),
		.ex_mem_op      (ex_mem_op     ),
		.ex_mem_wr_data (ex_mem_wr_data)
	);

	/* VUNIT Instance ================================================*/
	reg                check;            // DON'T MODIFY THIS SECTION!!!
	reg  [WIDTH-1:0]   real_val;
	reg  [WIDTH-1:0]   exp_val;          // Change the bus.
	reg  [`VUNIT_OP_B] vunit_op;
	wire               is_right;

	always @(*) begin
		real_val = {
			ex_out, 
			ex_dst_address, ex_gpr_we_, 
			ex_mem_op, ex_mem_wr_data
		};
	end

	vunit #(WIDTH) vunit_t (             // Change the WIDTH
		.check    (check   ),
		.real_val (real_val),              // tested output => vunit input
		.exp_val  (exp_val ),
		.op       (vunit_op),
		.is_right (is_right)
	);

	/* Interface Connection ==========================================*/
	integer times = 1;
	task vector;
		input        rst_t;
		input [31:0] ex_out_in_t;
	
		input [ 4:0] id_dst_address_t;
		input        id_gpr_we__t;
		input [ 1:0] id_mem_op_t;
		input [31:0] id_mem_wr_data_t;

		input [`VUNIT_OP_B] vunit_op_t;
		input [WIDTH-1:0]   exp_val_t;     // Change the bus.

		begin
			rst            = rst_t;          // ex_reg module input
			ex_out_in      = ex_out_in_t;

			id_dst_address = id_dst_address_t;
      id_gpr_we_     = id_gpr_we__t;
      id_mem_op      = id_mem_op_t;
      id_mem_wr_data = id_mem_wr_data_t;

			# STEP begin
				$write("%m.%2d: (%h, %h, %b, %b, %h) || ",
					times, ex_out_in,            // show test vectors
					id_dst_address, id_gpr_we_, id_mem_op, id_mem_wr_data);  
				times    = times + 1;          // DON'T CHANGE BELOW↓
				exp_val  = exp_val_t;          // vunit module input
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

		# (STEP * 3 / 4)  // uncomment this line for sequential circuit
		vector(`ENABLE , 32'hFFFF_FFFF, 5'b1111, 1'b1, 2'b11, 32'hFFFF_FFFF, 
			`VUNIT_OP_EQ, {32'h0000_0000, 5'b0000, 1'b0, 2'b00, 32'h0000_0000});
		vector(`DISABLE, 32'hFFFF_FFFF, 5'b1111, 1'b1, 2'b11, 32'hFFFF_FFFF, 
			`VUNIT_OP_EQ, {32'hFFFF_FFFF, 5'b1111, 1'b1, 2'b11, 32'hFFFF_FFFF});
		vector(`DISABLE, 32'h0012_34FF, 5'b1001, 1'b0, 2'b01, 32'h010F_0ab0, 
			`VUNIT_OP_EQ, {32'h0012_34FF, 5'b1001, 1'b0, 2'b01, 32'h010F_0ab0});
		vector(`ENABLE , 32'hFFFF_FFFF, 5'b1111, 1'b1, 2'b11, 32'hFFFF_FFFF, 
			`VUNIT_OP_EQ, {32'h0000_0000, 5'b0000, 1'b0, 2'b00, 32'h0000_0000});
		vector(`DISABLE, 32'hFFFF_FFFF, 5'b1111, 1'b1, 2'b11, 32'hFFFF_FFFF, 
			`VUNIT_OP_EQ, {32'hFFFF_FFFF, 5'b1111, 1'b1, 2'b11, 32'hFFFF_FFFF});

		# STEP $finish;
	end

	/* Clock Generation ==============================================*/
	parameter STEP  = `VUNIT_STEP;        // 10M
	reg                clk;
	always #(STEP / 2) clk <= ~clk;

	/* Wave Generation ===============================================*/
	initial begin
		$dumpfile("ex_reg_test.vcd");
		$dumpvars(0, ex_reg_t);
	end
endmodule
