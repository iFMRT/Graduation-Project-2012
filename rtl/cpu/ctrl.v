/*
 -- ============================================================================
 -- FILE NAME   : ctrl.v
 -- DESCRIPTION : 控制模块
 -- ----------------------------------------------------------------------------
 -- Date：2015/12/29
 -- ============================================================================
*/

/********** General header file **********/
`include "stddef.h"

/********** module **********/
module ctrl (
    /********* pipeline control signals ********/
    //  State of Pipeline
//  input  wire                   if_busy,      // IF busy mark
    input  wire                   ld_hazard,    // load hazard mark
//  input  wire                   br_hazard,    // branch hazard mark
//  input  wire                   br_flag,      // branch instruction flag
//  input  wire                   mem_busy,     // MEM busy mark
    // 延迟信号
    output wire                   if_stall,     // IF stage stall
    output wire                   id_stall,     // ID stage stall
    output wire                   ex_stall,     // EX stage stall
    output wire                   mem_stall,    // MEM stage stall
    // 刷新信号
    output wire                   if_flush,     // IF stage flush
    output wire                   id_flush,     // ID stage flush
    output wire                   ex_flush,     // EX stage flush
    output wire                   mem_flush,    // MEM stage flush
    output wire  [`WORD_DATA_W]   new_pc        // New program counter
);

    /********** pipeline control **********/
    // stall
    assign if_stall  = ld_hazard;
    assign id_stall  = `DISABLE;
    assign ex_stall  = `DISABLE;
    assign mem_stall = `DISABLE;
//  wire   stall     = if_busy | mem_busy;
//  assign if_stall  = stall   | ld_hazard;
//  assign id_stall  = stall;
//  assign ex_stall  = stall;
//  assign mem_stall = stall;

    // flush
//  assign if_flush  = br_hazard;
    assign if_flush  = `DISABLE;
    assign id_flush  = ld_hazard;
//  assign id_flush  = ld_hazard | br_hazard;
    assign ex_flush  = `DISABLE;
    assign mem_flush = `DISABLE;
//  reg    flush;
//  assign if_flush  = flush | br_hazard;
//  assign id_flush  = flush | ld_hazard | br_hazard;
//  assign ex_flush  = flush;
//  assign mem_flush = flush;

    assign new_pc = `WORD_DATA_W'h0;
//  always @(*) begin
//     /* default */
//     new_pc = `WORD_DATA_W'h0;

//     flush  = `DISABLE;
//  end
endmodule
