/* 
 -- ============================================================================
 -- FILE NAME : if_reg.v
 -- DESCRIPTION : IF/ID pipeline reg
 -- ----------------------------------------------------------------------------
 -- Date : 2015/12/8                       Coding_by : kippy
 -- ============================================================================
*/
`timescale 1ns/1ps

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
    input                   data_rdy, // tag hit mark
    input                   flush,       // Flush
    input  [`WORD_DATA_BUS] new_pc,      // New value of program counter
    input                   br_taken,                    // Branch taken
    input  [`WORD_DATA_BUS] br_addr,     // Branch target

    output reg [`WORD_DATA_BUS] pc,      // Current Program counter
    output reg [`WORD_DATA_BUS] if_pc,   // Next Program counter
    output reg [`WORD_DATA_BUS] if_insn, // Instruction
    output reg                  if_en    // Effective mark of pipeline
);

    always @(posedge clk) begin    
        if (reset == `ENABLE) begin
            /******** Reset ********/
            pc      <=  `WORD_DATA_W'h0;
            if_pc   <=  32'b1110_0001_0000_0000;
            if_insn <=  `ISA_NOP;
            if_en   <=  `DISABLE;
        end else begin
            /******** Update pipeline ********/
            if(data_rdy == `ENABLE) begin
                if (stall == `DISABLE) begin
                    if (flush == `ENABLE) begin
                        /* Flush */
                        if_pc   <=  new_pc;
                        if_insn <=  `ISA_NOP;
                        if_en   <=  `DISABLE;
                    end else if (br_taken == `ENABLE) begin
                        /* Branch taken */
                        if_pc   <=  br_addr;
                        if_insn <=  `ISA_NOP;
                        if_en   <=  `DISABLE;
                    end else begin
                        /* Next PC */
                        pc      <=  if_pc;
                        if_pc   <= #1 if_pc + `WORD_DATA_W'd4;
                        if_insn <=  insn; 
                        if_en   <=  `ENABLE;
                    end // else: !if(br_taken == `ENABLE)
                end 
            end else begin 
                if_en <= `DISABLE;
            end
        end // else: !if(reset == `ENABLE)
    end // always @ (posedge clk)

endmodule
