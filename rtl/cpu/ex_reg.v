/**
 * filename: ex_reg.v
 * author  : besky
 * time    : 2015-12-23 19:33:22
 */
`include "stddef.h"
`include "isa.h"
`include "ctrl.h"

module ex_reg (
	input wire                  clk,
	input wire                  reset,
	// Inner Output
	input wire [`WORD_DATA_BUS] ex_out_inner,
	// Pipeline Control Signal
	input  wire				   stall,		   
	input  wire				   flush,		   
	// ID/EX Pipeline Register 
	input  wire				   id_en,
	input wire [`MEM_OP_BUS]    id_mem_op,
	input wire [`WORD_DATA_BUS] id_mem_wr_data,
	input wire [`REG_ADDR_BUS]  id_dst_addr, // bypass input
	input wire                  id_gpr_we_,
	// EX/MEM Pipeline Register 
	output reg				    ex_en,		
	output reg [`MEM_OP_BUS]    ex_mem_op,
	output reg [`WORD_DATA_BUS] ex_mem_wr_data,
	output reg [`REG_ADDR_BUS]  ex_dst_addr, // bypass output
	output reg                  ex_gpr_we_,
	output reg [`WORD_DATA_BUS] ex_out
);

  	always @(posedge clk or posedge reset) begin
		    if(reset == `ENABLE) begin
				  ex_en		   <= #1 `DISABLE;
			      ex_mem_op      <= #1 `MEM_OP_NOP;
			      ex_mem_wr_data <= #1 `WORD_DATA_W'h0;
			      ex_dst_addr    <= #1 `REG_ADDR_W'd0;
			      ex_gpr_we_     <= #1 `DISABLE_;
			      ex_out         <= #1 `WORD_DATA_W'b0;
		    end	else begin
		    	if (stall == `DISABLE) begin
		    		if (flush == `ENABLE) begin
						ex_en		   <= #1 `DISABLE;
		    		    ex_mem_op      <= #1 `MEM_OP_NOP;
			      		ex_mem_wr_data <= #1 `WORD_DATA_W'h0;
			      		ex_dst_addr    <= #1 `REG_ADDR_W'd0;
			      		ex_gpr_we_     <= #1 `DISABLE_;
			      		ex_out         <= #1 `WORD_DATA_W'b0;
		    		end else begin
						ex_en		   <= #1 id_en;
		    			ex_out         <= #1 ex_out_inner;
					    ex_dst_addr    <= #1 id_dst_addr;
					    ex_gpr_we_     <= #1 id_gpr_we_;
					    ex_mem_op      <= #1 id_mem_op;
					    ex_mem_wr_data <= #1 id_mem_wr_data;
		    		end
		    	end

		    end
	  end

endmodule
