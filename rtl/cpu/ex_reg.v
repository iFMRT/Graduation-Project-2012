/**
 * filename: ex_reg.v
 * author  : besky
 * time    : 2015-12-23 19:33:22
 */
`include "stddef.h"
`include "isa.h"
`include "ctrl.h"

module ex_reg (
	input  wire        clk,
	input  wire        reset,
	input  wire [`WORD_DATA_BUS] ex_out_in,
	output reg  [`WORD_DATA_BUS] ex_out,

	input  wire [`REG_ADDR_BUS] id_dst_addr,          // bypass input
	input  wire        id_gpr_we_,
	input  wire         id_gpr_mux_mem,
	input  wire [`MEM_OP_BUS] id_mem_op,
	input  wire [`WORD_DATA_BUS] id_mem_wr_data,

	output reg  [`REG_ADDR_BUS] ex_dst_addr,          // bypass output
	output reg         ex_gpr_we_,
	output reg  [`MEM_OP_BUS] ex_mem_op,
	output reg  [`WORD_DATA_BUS] ex_mem_wr_data
	);

	always @(posedge clk or posedge reset) begin
		if(reset == `ENABLE) begin
			ex_out         <= 32'b0;
			ex_dst_addr <= 32'b0;
			ex_gpr_we_     <= 32'b0;
			ex_mem_op      <= 32'b0;
			ex_mem_wr_data <= 32'b0;
		end	else begin
			ex_out <= ex_out_in;
			ex_dst_addr <= id_dst_addr;
			ex_gpr_we_     <= id_gpr_we_    ;
			ex_mem_op      <= id_mem_op     ;
			ex_mem_wr_data <= id_mem_wr_data;
		end
	end

endmodule
