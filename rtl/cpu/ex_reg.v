/**
 * filename: ex_reg.v
 * author  : besky
 * time    : 2015-12-23 19:33:22
 */
`include "stddef.h"
`include "isa.h"

module ex_reg (
	input  wire        clk,
	input  wire        rst,
	input  wire [31:0] ex_out_in,
	output reg  [31:0] ex_out,

	input  wire [ 4:0] id_dst_address,          // bypass input
	input  wire        id_gpr_we_,
	input  wire [ 1:0] id_mem_op,
	input  wire [31:0] id_mem_wr_data,

	output reg  [ 4:0] ex_dst_address,          // bypass output
	output reg         ex_gpr_we_,
	output reg  [ 1:0] ex_mem_op,
	output reg  [31:0] ex_mem_wr_data
	);

	always @(posedge clk or posedge rst) begin
		if(rst == `ENABLE) begin
			ex_out         <= 32'b0;
			ex_dst_address <= 32'b0;
			ex_gpr_we_     <= 32'b0;
			ex_mem_op      <= 32'b0;
			ex_mem_wr_data <= 32'b0;
		end	else begin
			ex_out <= ex_out_in;
			ex_dst_address <= id_dst_address;
			ex_gpr_we_     <= id_gpr_we_    ;
			ex_mem_op      <= id_mem_op     ;
			ex_mem_wr_data <= id_mem_wr_data;
		end
	end

endmodule
