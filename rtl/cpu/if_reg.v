//////////////////////////////////////////////////////////////////////
// Engineer:       Kippy Chen - 799182081@qq.com                    //
//                                                                  //
// Additional contributions by:                                     //
//                 Beyond Sky - fan-dave@163.com                    //
//                 Leway Colin - colin4124@gmail.com                //
//                 Junhao Chen                                      //
//                                                                  //
// Design Name:    IF/ID Pipeline Register                          //
// Project Name:   FMRT Mini Core                                   //
// Language:       Verilog                                          //
//                                                                  //
// Description:    IF/ID Pipeline Register.                         //
//                                                                  //
//////////////////////////////////////////////////////////////////////

`include "common_defines.v"
`include "base_core_defines.v"
`include "hart_ctrl.h"

`timescale 1ns/1ps

module if_reg (
    /******** Clock & Rest ********/
    input wire                        clk,       // Clk
    input wire                        reset,     // Reset
    /******** Read Instruction ********/
    input  wire [`WORD_DATA_BUS]      insn,      // Reading instruction

    input  wire                       stall,     // Stall
    input  wire                       flush,     // Flush
    input  wire [`WORD_DATA_BUS]      new_pc,    // New value of program counter
    input  wire                       br_taken,  // Branch taken
    input  wire [`WORD_DATA_BUS]      br_addr,   // Branch target

    input  wire                       hstart,    // Hart start
    input  wire                       hidle,     // Hart idle state 1: idle, 0: active/pend
    input  wire [`HART_ID_B]          hs_id,     // Hart start id
    input  wire [`WORD_DATA_BUS]      hs_pc,     // Hart start pc

    input  wire [`HART_ID_B]          hart_id,   // Hart ID to issue ins
    input  wire [`HART_STATE_B]       hart_st,   // Hart state

    output reg  [`WORD_DATA_BUS]      pc,        // Current Program counter
    output wire [`WORD_DATA_BUS]      if_pc,     // Next Program counter
    output reg  [`WORD_DATA_BUS]      if_insn,   // Instruction
    output reg                        if_en,     // Effective mark of pipeline
    output reg  [`HART_STATE_B]       if_hart_st // Hart state
);

    reg  [`WORD_DATA_BUS] if_pcs [`HART_NUM_B];    // four if_pcs
    assign if_pc = if_pcs[hart_id];

    always @(posedge clk) begin
        if (reset == `ENABLE) begin
            /******** Reset ********/
            pc              <= `WORD_DATA_W'h0;
            if_pcs[hart_id] <= `WORD_DATA_W'h0;
            if_insn         <= `OP_NOP;
            if_en           <= `DISABLE;
            if_hart_st      <= `HART_STATE_B'h0;
        end else begin
            /******** Update pipeline ********/
            if (hstart & hidle & hart_id != hs_id) begin
                if_pcs[hs_id] <= hs_pc;    // can't start other non-idle hart
            end
            if (stall == `DISABLE) begin
                if (flush == `ENABLE) begin
                    /* Flush */
                    if_pcs[hart_id] <= new_pc;
                    if_insn         <= `OP_NOP;
                    if_en           <= `DISABLE;
                    if_hart_st      <= hart_st;
                end else if (br_taken == `ENABLE) begin
                    /* Branch taken */
                    if_pcs[hart_id] <= br_addr;
                    if_insn         <= `OP_NOP;
                    if_en           <= `DISABLE;
                    if_hart_st      <= hart_st;
                end else if (hstart & hart_id == hs_id) begin
                    if_pcs[hart_id] <= hs_pc;
                    if_insn         <= `OP_NOP;
                    if_en           <= `DISABLE;
                    if_hart_st      <= hart_st;
                end else begin
                    /* Next PC */
                    pc              <= if_pcs[hart_id];
                    if_pcs[hart_id] <= #1 if_pcs[hart_id] + `WORD_DATA_W'd4;
                    if_insn         <= insn;
                    if_en           <= `ENABLE;
                    if_hart_st      <= hart_st;
                end
            end
        end
    end

endmodule
