/**
 * filename: ex_reg.v
 * author  : besky
 * time    : 2015-12-23 19:33:22
 */
 `timescale 1ns/1ps
 
`include "isa.h"
`include "alu.h"
`include "cmp.h"
`include "ctrl.h"
`include "stddef.h"
`include "cpu.h"
`include "mem.h"
`include "ex_stage.h"

module ex_reg (
	input wire                  clk,
	input wire                  reset,
	// Inner Output
	input wire [`WORD_DATA_BUS] ex_out_inner,
	// Pipeline Control Signal
	input  wire				    stall,		   
	input  wire				    flush,		   
	// ID/EX Pipeline Register 
	input  wire				    id_en,
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
	output reg                  access_mem,    // access MEM mark
	output reg [`WORD_DATA_BUS] ex_out
);
	always @(*) begin
        if (id_mem_op[3:2] == 2'b00) begin
            access_mem = `DISABLE;
        end else begin
            access_mem = `ENABLE;
        end
    end
  	always @(posedge clk or posedge reset) begin
		    if(reset == `ENABLE) begin
				  ex_en		     <=  `DISABLE;
			      ex_mem_op      <=  `MEM_OP_NOP;
			      ex_mem_wr_data <=  `WORD_DATA_W'h0;
			      ex_dst_addr    <=  `REG_ADDR_W'd0;
			      ex_gpr_we_     <=  `DISABLE_;
			      ex_out         <=  `WORD_DATA_W'b0;
		    end	else begin
		    	if (stall == `DISABLE) begin
		    		if (flush == `ENABLE) begin
						ex_en		   <=  `DISABLE;
		    		    ex_mem_op      <=  `MEM_OP_NOP;
			      		ex_mem_wr_data <=  `WORD_DATA_W'h0;
			      		ex_dst_addr    <=  `REG_ADDR_W'd0;
			      		ex_gpr_we_     <=  `DISABLE_;
			      		ex_out         <=  `WORD_DATA_W'b0;
		    		end else begin
						ex_en		   <=  id_en;
		    			ex_out         <=  ex_out_inner;
					    ex_dst_addr    <=  id_dst_addr;
					    ex_gpr_we_     <=  id_gpr_we_;
					    ex_mem_op      <=  id_mem_op;
					    ex_mem_wr_data <=  id_mem_wr_data;
		    		end
		    	end 

		    end
	  end

endmodule
