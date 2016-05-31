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

    /* SPM Interface *************************/
    input  wire [`WORD_DATA_BUS] spm_rd_data,    // Address of reading SPM
    output wire [`WORD_ADDR_BUS] spm_addr,       // Address of SPM
    output wire                  spm_as_,        // SPM strobe
    output wire                  spm_rw,         // Read/Write SPM
    output wire [`WORD_DATA_BUS] spm_wr_data,    // Write data of SPM

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

    /* Hart Control ***************************/
    input  wire [`HART_ID_B]     hart_id,        // Hart ID to issue ins
    input  wire                  id_hstart,      // Hart start
    input  wire                  id_hidle,       // Hart idle state 1: idle, 0: active/pend
    input  wire [`HART_ID_B]     id_hs_id,       // Hart start id
    input  wire [`WORD_DATA_BUS] id_hs_pc,       // Hart start pc

    /* IF/ID Pipeline Register ***************/
    output wire [`WORD_DATA_BUS] pc,             // Current Program counter
    output wire [`WORD_DATA_BUS] if_pc,          // Next PC
    output wire [`WORD_DATA_BUS] if_insn,        // Instruction
    output wire                  if_en,          // Effective mark of pipeline
    output wire [`HART_STATE_B]  if_hart_id      // Hart id
);

    /********** Inner Signal **********/
    wire [`WORD_DATA_BUS]    insn;

    bus_if bus_if(
        /****** Pipeline control ********/
        .stall        (stall),                // Stall
        .flush        (flush),                // Flush
        /******** CPU Interface ********/
        .addr         (if_pc[`WORD_MSB:2]),   // Address
        .as_          (`ENABLE_),             // Address strobe
        .rw           (`READ),                // Read/Write
        .wr_data      (`WORD_DATA_W'h0),      // Write data
        .rd_data      (insn),                 // Read data
        /****** SPM Interface ********/
        .spm_rd_data  (spm_rd_data),          // Address of reading SPM
        .spm_addr     (spm_addr),             // Address of SPM
        .spm_as_      (spm_as_),              // SPM strobe
        .spm_rw       (spm_rw),               // Read/Write SPM
        .spm_wr_data  (spm_wr_data)           // Write data of SPM
    );

    if_reg if_reg(
        /******** Clock & Rest ********/
        .clk          (clk),                  // Clk
        .reset        (reset),                // Reset
        /******** Read Instruction ********/
        .insn         (insn),                 // Reading instruction

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
        .pc           (pc),                   // Current Program counter
        .if_pc        (if_pc),                // Next PC
        .if_insn      (if_insn),              // Instruction
        .if_en        (if_en),                // Effective mark of pipeline
        .if_hart_id   (if_hart_id)            // Hart state to de_stage
    );

endmodule
