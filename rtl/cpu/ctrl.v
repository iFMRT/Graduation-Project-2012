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
    // state of pipeline
//  input  wire                   if_busy,      // IF busy mark
    input  wire                   ld_hazard,    // load hazard mark
//  input  wire                   mem_busy,     // MEM busy mark
    // 延迟信号
    output wire                   if_stall,     // IF stage stall 
//  output wire                   id_stall,     // ID stage stall 
//  output wire                   ex_stall,     // EX stage stall 
//  output wire                   mem_stall,    // MEM stage stall 
    // 刷新信号
    output wire                   if_flush,     // IF stage flush
    output wire                   id_flush,     // ID stage flush
    output wire                   ex_flush,     // EX stage flush
    output wire                   mem_flush,    // MEM stage flush
    output reg  [`WordAddrBus]    new_pc        // New program counter
);

    /********** pipeline control **********/
    // stall
    assign if_stall  = ld_hazard;
//  wire   stall  = if_busy | mem_busy;
//  assign if_stall   = stall | ld_hazard;
//  assign id_stall   = stall;
//  assign ex_stall   = stall;
//  assign mem_stall = stall;

    // flush
    reg    flush;
    assign if_flush  = flush;
    assign id_flush  = flush | ld_hazard;
    assign ex_flush  = flush;
    assign mem_flush = flush;

    always @(*) begin
        /* default */
        new_pc = `WORD_ADDR_W'h0;
        flush  = `DISABLE;
    end
endmodule
