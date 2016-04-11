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
    // input  [`WORD_DATA_BUS] spm_rd_data,    // Address of reading SPM
    // output [`WORD_ADDR_BUS] spm_addr,       // Address of SPM
    // output                  spm_as_,        // SPM strobe
    // output                  spm_rw,         // Read/Write SPM
    // output [`WORD_DATA_BUS] spm_wr_data,    // Write data of SPM
    /************* Icache ************/
    /* CPU part */ 
    output             miss_stall,    // the signal of stall caused by cache miss
    /* L1_cache part */
    input              lru,           // mark of replacing
    input      [20:0]  tag0_rd,       // read data of tag0
    input      [20:0]  tag1_rd,       // read data of tag1
    input      [127:0] data0_rd,      // read data of data0
    input      [127:0] data1_rd,      // read data of data1
    output             tag0_rw,       // read / write signal of L1_tag0
    output             tag1_rw,       // read / write signal of L1_tag1
    output     [20:0]  tag_wd,        // write data of L1_tag
    output             data0_rw,      // read / write signal of data0
    output             data1_rw,      // read / write signal of data1
    output     [7:0]   index,         // address of L1_cache
    /* L2_cache part */
    input              l2_busy,       // busy signal of L2_cache
    input              l2_rdy,        // ready signal of L2_cache
    input              complete,      // complete op writing to L1
    output             irq,           // icache request
    output             ic_rw_en,
    // output     [8:0]   l2_index,
    output     [31:0]  l2_addr,
    output             l2_cache_rw,
    /******** Pipeline control ********/
    input                   stall,          // Stall
    input                   flush,          // Flush
    input  [`WORD_DATA_BUS] new_pc,         // New value of program counter
    input                   br_taken,       // Branch taken
    input  [`WORD_DATA_BUS] br_addr,        // Branch target
    // output                  busy,           // Busy Signal
    /******** IF/ID Pipeline Register ********/
    output [`WORD_DATA_BUS] pc,             // Current Program counter
    output [`WORD_DATA_BUS] if_pc,          // Current Program counter
    output [`WORD_DATA_BUS] if_insn,        // Instruction
    output                  if_en           // Effective mark of pipeline
);

    /********** Inner Signal **********/
    wire [`WORD_DATA_BUS]    insn;
    // wire [`WORD_DATA_BUS]    if_pc;          // Next PC
    wire                     data_rdy;
    // bus_if bus_if(
    //     /****** Pipeline control ********/
    //     .stall        (stall),                // Stall
    //     .flush        (flush),                // Flush
    //     /******** CPU Interface ********/
    //     .addr         (if_pc[`WORD_MSB:2]),   // Address
    //     .as_          (`ENABLE_),             // Address strobe
    //     .rw           (`READ),                // Read/Write
    //     .wr_data      (`WORD_DATA_W'h0),      // Write data
    //     .rd_data      (insn),                 // Read data
    //     /****** SPM Interface ********/
    //     .spm_rd_data  (spm_rd_data),          // Address of reading SPM
    //     .spm_addr     (spm_addr),             // Address of SPM
    //     .spm_as_      (spm_as_),              // SPM strobe
    //     .spm_rw       (spm_rw),               // Read/Write SPM
    //     .spm_wr_data  (spm_wr_data)           // Write data of SPM
    // );

    icache_ctrl icache_ctrl(
        .clk            (clk),           // clock
        .rst            (reset),           // reset
        /* CPU part */
        .if_addr        (if_pc),          // address of fetching instruction
        .rw             (`READ),         // read / write signal of CPU
        .cpu_data       (insn),       // read data from cache to CPU
        .miss_stall     (miss_stall),    // the signal of stall caused by cache miss
        /* L1_cache part */
        .lru            (lru),           // mark of replacing
        .tag0_rd        (tag0_rd),       // read data of tag0
        .tag1_rd        (tag1_rd),       // read data of tag1
        .data0_rd       (data0_rd),      // read data of data0
        .data1_rd       (data1_rd),      // read data of data1
        .tag0_rw        (tag0_rw),       // read / write signal of L1_tag0
        .tag1_rw        (tag1_rw),       // read / write signal of L1_tag1
        .tag_wd         (tag_wd),        // write data of L1_tag
        .data0_rw       (data0_rw),      // read / write signal of data0
        .data1_rw       (data1_rw),      // read / write signal of data1
        .index          (index),         // address of L1_cache
        /* l2_cache part */
        .l2_busy        (l2_busy),       // busy signal of l2_cache
        .l2_rdy         (l2_rdy),        // ready signal of l2_cache
        .complete       (complete),      // complete op writing to L1
        .irq            (irq),
        .ic_rw_en       (ic_rw_en), 
        // .l2_index       (l2_index),        
        .l2_addr        (l2_addr),        
        .l2_cache_rw    (l2_cache_rw),
        /* if_reg part */
        .data_rdy       (data_rdy)        
        );

    if_reg if_reg(
        /******** Clock & Rest ********/
        .clk          (clk),                  // Clk
        .reset        (reset),                // Reset
        /******** Read Instruction ********/
        .insn         (insn),                 // Reading instruction
        .stall        (stall),                // Stall
        .data_rdy     (data_rdy),          // tag hit mark
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
