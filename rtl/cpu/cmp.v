/**
 * filename: cmp.v
 * author  : besky
 * time    : 2015-12-15 21:34:41
 */
`include "stddef.h"
`include "isa.h"
`include "cmp.h"

module cmp #(parameter WIDTH = 32) (
	input  wire signed [WIDTH-1:0]   arg0,
	input  wire signed [WIDTH-1:0]   arg1,
	input  wire        [`CMP_OP_BUS] op,
	output reg                       true
);

	wire [WIDTH-1:0] arg0_u;
	wire [WIDTH-1:0] arg1_u;
	wire eq,ne,lt,ltu,ge,geu;
	assign arg0_u = arg0;
	assign arg1_u = arg1;


	always @(*) begin
		case(op)
			`CMP_OP_NOP : true = `CMP_FALSE;
			`CMP_OP_EQ  : true = eq;
			`CMP_OP_NE  : true = ne;
			`CMP_OP_LT  : true = lt;
			`CMP_OP_LTU : true = ltu;
			`CMP_OP_GE  : true = ge;
			`CMP_OP_GEU : true = geu;
			default     : true = `CMP_FALSE;
		endcase
	end

	assign eq  = (arg0 == arg1) ? `CMP_TRUE : `CMP_FALSE;
	assign ne  = ~eq;
	assign lt  = (arg0 <  arg1) ? `CMP_TRUE : `CMP_FALSE;
	assign ltu = (arg0_u <  arg1_u) ? `CMP_TRUE : `CMP_FALSE;
	assign ge  = ~lt;
	assign geu = ~ltu;

endmodule
