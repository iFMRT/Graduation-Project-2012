/* 
 -- ============================================================================
 -- FILE NAME : if_stage.v
 -- DESCRIPTION : IF 阶段的实现
 -- ----------------------------------------------------------------------------
 -- Date : 2015/12/25                       
 -- ============================================================================
*/

/* General header file */
`include "stddef.h"

module if_stage(/********** clock & reset *********/ 
                input  clk,                             // Clk
                input  reset,                           // Reset
                input  br_taken,                        // Branch taken
                input  [`WORD_DATA_BUS] new_pc,         // New value of program counter
                input  [`WORD_DATA_BUS] br_addr,        // Branch target
                output [`WORD_DATA_BUS] if_pc,          // Program counter
                output [`WORD_DATA_BUS] if_pc_plus4,    // Next PC
                output [`WORD_DATA_BUS] if_insn,        // Instruction
                output  if_en,                          // Effective mark of pipeline
                /******** Pipeline control ********/ 
                input  stall,                           // Stall 
                input  flush,                           // Flush  
                /********* SPM Interface *********/
                input  [`WORD_DATA_BUS] spm_rd_data,    // Address of reading SPM
                output [`WORD_ADDR_BUS] spm_addr,       // Address of SPM
                output spm_as_,                         // SPM strobe
                output spm_rw,                          // Read/Write SPM
                output [`WORD_DATA_BUS] spm_wr_data     // Write data of SPM
                );

    /********** Inner Signal **********/ 
    wire [`WORD_DATA_BUS]insn;

    bus_if bus_if(/****** Pipeline control ********/ 
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

    if_reg if_reg(.clk          (clk),                  // Clk
                  .reset        (reset),                // Reset
                  .stall        (stall),                // Stall
                  .flush        (flush),                // Flush
                  .br_taken     (br_taken),             // Branch taken
                  .new_pc       (new_pc),               // New value of program counter
                  .br_addr      (br_addr),              // Branch target
                  .insn         (insn),                 // Reading instruction
                  .if_pc        (if_pc),                // Program counter
                  .if_pc_plus4  (if_pc_plus4),          // Next PC
                  .if_insn      (if_insn),              // Instruction
                  .if_en        (if_en)                 // Effective mark of pipeline
                  ); 
endmodule