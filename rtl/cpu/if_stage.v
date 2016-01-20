/* 
 -- ============================================================================
 -- FILE NAME : if_stage.v
 -- DESCRIPTION : IF Stage Implementation
 -- ----------------------------------------------------------------------------
 -- Date : 2015/12/25
 -- ============================================================================
*/

/* General header file */
`include "stddef.h"

module if_stage(
    /********** clock & reset *********/
    input                   clk,            // Clk
    input                   reset,          // Reset
    /********* SPM Interface *********/
    input  [`WORD_DATA_BUS] spm_rd_data,    // Address of reading SPM
    output [`WORD_ADDR_BUS] spm_addr,       // Address of SPM
    output                  spm_as_,        // SPM strobe
    output                  spm_rw,         // Read/Write SPM
    output [`WORD_DATA_BUS] spm_wr_data,    // Write data of SPM
    /******** Pipeline control ********/
    input                   stall,          // Stall
    input                   flush,          // Flush
    input  [`WORD_DATA_BUS] new_pc,         // New value of program counter
    input                   br_taken,       // Branch taken
    input  [`WORD_DATA_BUS] br_addr,        // Branch target
    // output                  busy,           // Busy Signal
    /******** IF/ID Pipeline Register ********/
    output [`WORD_DATA_BUS] pc,             // Current Program counter
    output [`WORD_DATA_BUS] if_pc,          // Next PC
    output [`WORD_DATA_BUS] if_insn,        // Instruction
    output                  if_en           // Effective mark of pipeline
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
        
        /* Output */
        .pc           (pc),                   // Current Program counter
        .if_pc        (if_pc),                // Next PC
        .if_insn      (if_insn),              // Instruction
        .if_en        (if_en)                 // Effective mark of pipeline
    );
    
endmodule
