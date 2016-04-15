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
    /************* Icache ************/
    /* CPU part */ 
    output             miss_stall,    // the signal of stall caused by cache miss
    /* L1_cache part */
    input              lru,           // mark of replacing
    input      [20:0]  tag0_rd,       // read data of tag0
    input      [20:0]  tag1_rd,       // read data of tag1
    input      [127:0] data0_rd,      // read data of data0
    input      [127:0] data1_rd,      // read data of data1
    input      [127:0] data_wd_l2,
    input              complete,      // complete op writing to L1
    output             tag0_rw,       // read / write signal of L1_tag0
    output             tag1_rw,       // read / write signal of L1_tag1
    output     [20:0]  tag_wd,        // write data of L1_tag
    output             data0_rw,      // read / write signal of data0
    output             data1_rw,      // read / write signal of data1
    output     [7:0]   index,         // address of L1_cache
    /* L2_cache part */
    input              l2_busy,       // busy signal of L2_cache
    input              l2_rdy,        // ready signal of L2_cache
    input              mem_wr_ic_en,
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
    wire                     data_rdy;

icache_ctrl icache_ctrl(
        .clk            (clk),           // clock
        .rst            (reset),           // reset
        /* CPU part */
        .if_addr        (if_pc),         // address of fetching instruction
        .rw             (`READ),            // read / write signal of CPU
        .cpu_data       (insn),      // read data of CPU
        .miss_stall     (miss_stall),    // the signal of stall caused by cache miss
        /* L1_cache part */
        .lru            (lru),           // mark of replacing
        .tag0_rd        (tag0_rd),       // read data of tag0
        .tag1_rd        (tag1_rd),       // read data of tag1
        .data0_rd       (data0_rd),      // read data of data0
        .data1_rd       (data1_rd),      // read data of data1
        .data_wd_l2     (data_wd_l2), 
        .complete       (complete),      // complete op writing to L1
        .tag0_rw        (tag0_rw),       // read / write signal of L1_tag0
        .tag1_rw        (tag1_rw),       // read / write signal of L1_tag1
        .tag_wd         (tag_wd),        // write data of L1_tag
        .data0_rw       (data0_rw),      // read / write signal of data0
        .data1_rw       (data1_rw),      // read / write signal of data1
        .index          (index),         // address of L1_cache
        /* l2_cache part */
        .l2_busy        (l2_busy),       // busy signal of l2_cache
        .l2_rdy         (l2_rdy),        // ready signal of l2_cache
        .mem_wr_ic_en   (mem_wr_ic_en), 
        .irq            (irq),
        .ic_rw_en       (ic_rw_en),      
        .l2_addr        (l2_addr),        
        .l2_cache_rw    (l2_cache_rw), 
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
