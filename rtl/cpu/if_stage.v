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
    input  wire                  br_taken,       // Branch taken
    input  wire [`WORD_DATA_BUS] br_addr,        // Branch target
    input  wire                  hstart,         // Hart start
    input  wire                  hidle,          // Hart idle state 1: idle, 0: active/pend
    input  wire [`HART_ID_B]     hs_id,          // Hart start id
    input  wire [`WORD_DATA_BUS] hs_pc,          // Hart start pc

    /* Hart select ***************************/
    input  wire [`HART_ID_B]     hart_id,        // Hart ID to issue ins
    input  wire [`HART_STATE_B]  hart_st,        // Hart state

    /* IF/ID Pipeline Register ***************/
    output wire [`WORD_DATA_BUS] pc,             // Current Program counter
    output wire [`WORD_DATA_BUS] if_pc,          // Next PC
    output wire [`WORD_DATA_BUS] if_insn,        // Instruction
    output wire                  if_en,          // Effective mark of pipeline
    output wire [`HART_STATE_B]  if_hart_st      // Hart state
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

        .br_taken     (br_taken),             // Branch taken
        .br_addr      (br_addr),              // Branch target

        .hstart       (hstart),               // Hart start
        .hidle        (hidle),                // Hart idle
        .hs_id        (hs_id),                // Hart start id
        .hs_pc        (hs_pc),                // Hart start pc

        .hart_id      (hart_id),              // Hart ID to issue ins
        .hart_st      (hart_st),              // Hart state

        /******** Output ********/
        .pc           (pc),                   // Current Program counter
        .if_pc        (if_pc),                // Next PC
        .if_insn      (if_insn),              // Instruction
        .if_en        (if_en),                // Effective mark of pipeline
        .if_hart_st   (if_hart_st)            // Hart state to de_stage
    );

endmodule
