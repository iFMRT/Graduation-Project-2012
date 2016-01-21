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

module if_reg(
    /******** Clock & Rest ********/
    input                   clk,         // Clk
    input                   reset,       // Reset
    /******** Read Instruction ********/
    input  [`WORD_DATA_BUS] insn,        // Reading instruction

    input                   stall,       // Stall
    input                   flush,       // Flush
    input  [`WORD_DATA_BUS] new_pc,      // New value of program counter
    input                   br_taken,                    // Branch taken
    input  [`WORD_DATA_BUS] br_addr,     // Branch target

    output     [`WORD_DATA_BUS] pc,      // Current Program counter
    output reg [`WORD_DATA_BUS] if_pc,   // Next Program counter
    output reg [`WORD_DATA_BUS] if_insn, // Instruction
    output reg                  if_en    // Effective mark of pipeline
);

    assign pc = (if_pc != 0 ) ? if_pc - `WORD_DATA_W'd4 : if_pc;

    always @(posedge clk) begin    
        if (reset == `ENABLE) begin
            /******** Reset ********/
            if_pc   <= #1 `WORD_DATA_W'h0;
            if_insn <= #1 `ISA_NOP;
            if_en   <= #1 `DISABLE;
        end else begin
            /******** Update pipeline ********/
            if (stall == `DISABLE) begin
                if (flush == `ENABLE) begin
                    /* Flush */
                    if_pc   <= #1 new_pc;
                    if_insn <= #1 `ISA_NOP;
                    if_en   <= #1 `DISABLE;
                end else if (br_taken == `ENABLE) begin
                    /* Branch taken */
                    if_pc   <= #1 br_addr;
                    if_insn <= #1 `ISA_NOP;
                    if_en   <= #1 `DISABLE;
                end else begin
                    /* Next PC */
                    if_pc   <= #1 if_pc + `WORD_DATA_W'd4;
                    if_insn <= #1 insn;
                    if_en   <= #1 `ENABLE;
                end // else: !if(br_taken == `ENABLE)
            end // if (stall == `DISABLE)
        end // else: !if(reset == `ENABLE)
    end // always @ (posedge clk)

endmodule
