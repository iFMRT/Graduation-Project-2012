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
    output wire [`WORD_DATA_BUS]      if_pc,     // PC
    input  wire                       data_rdy,  // tag hit mark

    input  wire                       stall,     // Stall
    input  wire                       flush,     // Flush
    input  wire [`WORD_DATA_BUS]      new_pc,    // New value of program counter
    input  wire                       cache_miss,// Cache miss occur
    input  wire [`HART_ID_B]          cm_hart_id,// Cache miss hart id
    input  wire [`WORD_DATA_BUS]      cm_addr,        // Cache miss address
    input  wire [`HART_ID_B]          br_hart_id,// Branch Hart ID (equal to id_hart_id)
    input  wire                       br_taken,  // Branch taken
    input  wire [`WORD_DATA_BUS]      br_addr,   // Branch target

    input  wire [`HART_ID_B]          hart_id,   // Hart ID to issue ins
    input  wire                       id_hstart, // Hart start
    input  wire                       id_hidle,  // Hart idle state 1: idle, 0: active/pend
    input  wire [`HART_ID_B]          id_hs_id,  // Hart start id
    input  wire [`WORD_DATA_BUS]      id_hs_pc,  // Hart start pc

    output reg  [`WORD_DATA_BUS]      pc,        // PC in if_reg
    output reg  [`WORD_DATA_BUS]      if_npc,    // Next PC in if_reg
    output reg  [`WORD_DATA_BUS]      if_insn,   // Instruction
    output reg                        if_en,     // Effective mark of pipeline
    output reg  [`HART_ID_B]          if_hart_id // Hart id
);

    reg  [`WORD_DATA_BUS] if_pcs [`HART_NUM_B];    // four if_pcs
    assign if_pc = if_pcs[hart_id];

    wire [`WORD_DATA_BUS] npc;
    assign npc = if_pcs[hart_id] + `WORD_DATA_W'd4;

    always @(posedge clk) begin
        if (reset == `ENABLE) begin
            /******** Reset ********/
            pc              <= `WORD_DATA_W'h0;
            if_npc          <= `WORD_DATA_W'h0;
            if_pcs[hart_id] <= `WORD_DATA_W'h0;
            if_insn         <= `OP_NOP;
            if_en           <= `DISABLE;
            if_hart_id      <= `HART_ID_W'h0;
        end else begin
            /******** Update pipeline ********/
            if (stall == `DISABLE) begin
                if (id_hstart & id_hidle & hart_id != id_hs_id) begin
                    if_pcs[id_hs_id] <= id_hs_pc;    // can't start other non-idle hart
                end
                if (flush == `ENABLE) begin
                    /* Flush */
                    pc                 <= `WORD_DATA_W'h0;
                    if_npc             <= `WORD_DATA_W'h0;
                    if_pcs[hart_id]    <= new_pc;
                    if_insn            <= `OP_NOP;
                    if_en              <= `DISABLE;
                    if_hart_id         <= hart_id;
                end else if (br_taken == `ENABLE) begin
                    /* Branch taken */
                    if (hart_id == br_hart_id) begin
                        pc             <= `WORD_DATA_W'h0;
                        if_npc         <= `WORD_DATA_W'h0;
                        if_pcs[hart_id] <= br_addr;
                        if_insn        <= `OP_NOP;
                        if_en          <= `DISABLE;
                        if_hart_id     <= `HART_ID_W'h0;
                    end else begin
                        pc             <= if_pcs[hart_id];
                        if_npc         <= npc;
                        if_pcs[hart_id] <= npc;
                        if_pcs[br_hart_id] <= br_addr;
                        if_insn        <= insn;
                        if_en          <= `ENABLE;
                        if_hart_id     <= hart_id;
                    end
                end else if (cache_miss) begin
                    if_hart_id         <= hart_id;
                    if (cm_hart_id == hart_id) begin
                        pc              <= if_pcs[hart_id];
                        if_npc          <= npc;
                        if_pcs[hart_id] <= cm_addr;
                        if_insn        <= `OP_NOP;
                        if_en          <= `DISABLE;
                    end else begin
                        pc             <= if_pcs[hart_id];
                        if_npc         <= npc;
                        if_pcs[hart_id] <= npc;
                        if_pcs[cm_hart_id] <= cm_addr;
                        if_insn        <= insn;
                        if_en          <= `ENABLE;
                    end
                end else begin
                    if (data_rdy == `ENABLE) begin
                        /* Next PC */
                        pc                 <= if_pcs[hart_id];
                        if_npc             <= npc;
                        if_pcs[hart_id]    <= npc;
                        if_insn            <= insn;
                        if_en              <= `ENABLE;
                        if_hart_id         <= hart_id;
                    end else begin
                        if_en              <= `DISABLE;
                    end
                        
                end
            end
        end
    end

endmodule
