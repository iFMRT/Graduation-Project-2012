/**
 * filename: vunit.v
 * author  : besky
 * time    : 2015-12-16 08:38:46
 */
`ifndef __VUNIT_V__
	`define __VUNIT_V__			         // Include Guard

`include "vunit.h"

module vunit #(parameter WIDTH = 32) (
	input  wire               check,
	input  wire [WIDTH-1:0]   real_val,
	input  wire [WIDTH-1:0]   exp_val,
	input  wire [`VUNIT_OP_B] op,
	output reg                is_right
	);

	always @(check) begin
		case(op) 
			`VUNIT_OP_EQ  : assert( equal(real_val, exp_val), real_val);
			`VUNIT_OP_NEQ : assert(nequal(real_val, exp_val), real_val);
		endcase
	end

	function equal;
		input [WIDTH-1:0] src, dst;
		equal  = (src == dst) ? `TRUE : `FALSE;
	endfunction

	function nequal;
		input [WIDTH-1:0] src, dst;
		nequal = (src != dst) ? `TRUE : `FALSE;
	endfunction

	task assert;
		input true;
		input [WIDTH-1:0] value;
		begin
			is_right <= true;
			if (true) $display("%m: Successful! (%h)", value, $time);
			else      $display("%m: Failed!     (%h)", value, $time);
		end
	endtask
	
endmodule

`endif
