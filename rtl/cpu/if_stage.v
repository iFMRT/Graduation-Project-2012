////////////////////////////////////////////////////////////////////////
// Engineer:       Kippy Chen - 799182081@qq.com                      //
//                                                                    //
// Additional contributions by:                                       //
//                 Beyond Sky - fan-dave@163.com                      //
//                 Leway Colin - colin4124@gmail.com                  //
//                 Junhao Chen                                        //
//                                                                    //
// Design Name:    Instruction Fetch Stage                            //
// Project Name:   FMRT Mini Core                                     //
// Language:       Verilog                                            //
//                                                                    //
// Description:    Instruction fetch unit: Selection of the next PC.  //
//                                                                    //
////////////////////////////////////////////////////////////////////////

`include "common_defines.v"
`include "base_core_defines.v"
`include "hart_ctrl.h"

`timescale 1ns/1ps

module if_stage(
    /* clock & reset *************************/
    input  wire                  clk,            // Clk
    input  wire                  reset,          // Reset

    /* Pipeline control **********************/
    input  wire                  stall,          // Stall
    input  wire                  flush,          // Flush
    input  wire [`WORD_DATA_BUS] new_pc,         // New value of program counter
    input  wire                  cache_miss,     // Cache miss occur
    input  wire [`HART_ID_B]     cm_hart_id,     // Cache miss hart id
    input  wire [`WORD_DATA_BUS] cm_addr,        // Cache miss address
    input  wire [`HART_ID_B]     br_hart_id,     // Branch Hart ID (equal to id_hart_id)
    input  wire                  br_taken,       // Branch taken
    input  wire [`WORD_DATA_BUS] br_addr,        // Branch target

    /* I Cache ***************************/
    input  wire [`WORD_DATA_BUS] insn,           // Reading instruction
    output wire [`WORD_DATA_BUS] if_pc,          // PC
    input  wire                  data_rdy,
    /* Hart Control ***************************/
    input  wire [`HART_ID_B]     hart_id,        // Hart ID to issue ins
    input  wire                  id_hstart,      // Hart start
    input  wire                  id_hidle,       // Hart idle state 1: idle, 0: active/pend
    input  wire [`HART_ID_B]     id_hs_id,       // Hart start id
    input  wire [`WORD_DATA_BUS] id_hs_pc,       // Hart start pc

    /* IF/ID Pipeline Register ***************/
    output wire [`WORD_DATA_BUS] pc,             // PC in if_reg
    output wire [`WORD_DATA_BUS] if_npc,         // Next PC in if_reg
    output wire [`WORD_DATA_BUS] if_insn,        // Instruction
    output wire                  if_en,          // Effective mark of pipeline
    output wire [`HART_ID_B]     if_hart_id      // Hart id
);

    if_reg if_reg(
        /******** Clock & Rest ********/
        .clk          (clk),                  // Clk
        .reset        (reset),                // Reset
        /******** Read Instruction ********/
        .insn         (insn),                 // Reading instruction
        .if_pc        (if_pc),                // PC
        .data_rdy       (data_rdy),
        
        .stall        (stall),                // Stall
        .flush        (flush),                // Flush
        .new_pc       (new_pc),               // New value of program counter

        .cache_miss   (cache_miss),           // Cache miss occur
        .cm_hart_id   (cm_hart_id),           // Cache miss hart ID
        .cm_addr      (cm_addr),              // Cache miss address

        .br_hart_id   (br_hart_id),           // Branch Hart ID
        .br_taken     (br_taken),             // Branch taken
        .br_addr      (br_addr),              // Branch target

        .hart_id      (hart_id),              // Hart ID to issue ins
        .id_hstart    (id_hstart),            // Hart start
        .id_hidle     (id_hidle),             // Hart idle
        .id_hs_id     (id_hs_id),             // Hart start id
        .id_hs_pc     (id_hs_pc),             // Hart start pc

        /******** Output ********/
        .pc           (pc),                   // PC in if_reg
        .if_npc       (if_npc),               // Next PC in if_reg
        .if_insn      (if_insn),              // Instruction
        .if_en        (if_en),                // Effective mark of pipeline
        .if_hart_id   (if_hart_id)            // Hart state to de_stage
    );

endmodule
