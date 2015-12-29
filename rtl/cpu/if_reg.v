/* 
 -- ============================================================================
 -- FILE NAME : if_reg.v
 -- DESCRIPTION : IF/ID 流水线寄存器的实现
 -- ----------------------------------------------------------------------------
 -- Date : 2015/12/8                       Coding_by : kippy
 -- ============================================================================
*/

/********** General header file **********/
`include "stddef.h"

/********** module header file **********/
`include "isa.h"

module if_reg(input  clk,                         // Clk
              input  reset,                       // Reset
              input  stall,                       // Stall
              input  flush,                       // Flush
              input  br_taken,                    // Branch taken
              input  [`WORD_DATA_BUS] new_pc,     // New value of program counter
              input  [`WORD_DATA_BUS] br_addr,    // Branch target
              input  [`WORD_DATA_BUS] insn,       // Reading instruction
              output reg[`WORD_DATA_BUS] if_pc,   // Program counter
              output [`WORD_DATA_BUS] if_pc_plus4,// Next PC 
              output reg[`WORD_DATA_BUS] if_insn, // Instruction
              output reg if_en                    // Effective mark of pipeline
              ); 

assign if_pc_plus4 = if_pc + `WORD_DATA_W'd4;

always @(posedge clk)
    begin
          if (reset == `ENABLE)
              begin
    /******************** Reset ********************/
                  if_pc <= #1 `WORD_DATA_W'b0;          
                  if_insn <= #1 `ISA_NOP;               
                  if_en <= #1 `DISABLE;                
              end
          else
            begin
    /************* Update pipeline ***************/
                if (stall == `DISABLE)
                    begin
                      if (flush == `ENABLE)                
                          /* Flush */
                          begin
                              if_pc <= #1 new_pc;       
                              if_insn <= #1 `ISA_NOP;   
                              if_en <= #1 `DISABLE;    
                          end 
                      else if (br_taken == `ENABLE)
                          /* Branch taken */
                          begin 
                              if_pc <= #1 br_addr;      
                              if_insn <= #1 insn;      
                              if_en <= #1 `ENABLE;     
                         end
                      else                                     
                          /* Next PC */
                          begin
                              if_pc <= #1 if_pc_plus4;  
                              if_insn <= #1 insn;       
                              if_en <= #1 `ENABLE;      
                          end
                    end
        end
    end
endmodule
