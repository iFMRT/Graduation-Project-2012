`include "stddef.h"
`include "cpu.h"

/********** MEM Stage Register Module**********/
module mem_reg (
	  /********** Clock & Reset **********/
	  input wire                  clk,            // Clock
	  input wire                  reset,          // Asynchronous reset
	  /********** Memory Access Result **********/
	  input wire [`WORD_DATA_BUS] out,            // Memory access result
	  input wire                  miss_align,     // miss align
	  /********** EX/MEM Pipeline Register **********/
	  input wire [`REG_ADDR_BUS]  ex_dst_addr,    // General purpose register write address
	  input wire                  ex_gpr_we_,     // General purpose register write enable
	  /********** MEM/WB Pipeline Register **********/
	  output reg [`REG_ADDR_BUS]  mem_dst_addr,   // General purpose register write address
	  output reg                  mem_gpr_we_,    // General purpose register write enable
	  output reg [`WORD_DATA_BUS] mem_out		  // MEM stage operating result
);

	 /********** Pipeline Register **********/
	  always @(posedge clk or negedge reset) begin
	     if (reset == `ENABLE) begin
			     /* Asynchronous Reset */
			     mem_dst_addr <= #1 `REG_ADDR_W'h0;
			     mem_gpr_we_  <= #1 `DISABLE_;
			     mem_out	    <= #1 `WORD_DATA_W'h0;
		   end else begin
		       /* Update Pipeline Register */
				   if (miss_align == `ENABLE) begin    // Miss align
					     mem_dst_addr <= #1 `REG_ADDR_W'h0;
					     mem_gpr_we_  <= #1 `DISABLE_;
					     mem_out	    <= #1 `WORD_DATA_W'h0;
				   end else begin							         // Next data
					     mem_dst_addr <= #1 ex_dst_addr;
					     mem_gpr_we_  <= #1 ex_gpr_we_;
					     mem_out	    <= #1 out;
				   end
		   end
	 end

endmodule
