////////////////////////////////////////////////////////////////////
// Engineer:       Kippy Chen - 799182081@qq.com                  //
//                                                                //
// Additional contributions by:                                   //
//                 Beyond Sky - fan-dave@163.com                  //
//                 Junhao Chang                                   //
//                 Leway Colin - colin4124@gmail.com              //
//                                                                //
// Design Name:    if_stage                                       //
// Project Name:   FMRT Mini Core                                 //
// Language:       Verilog                                        //
//                                                                //
// Description:    IF STAGE.                                      //
//                                                                //
////////////////////////////////////////////////////////////////////
 
`timescale 1ns/1ps

/* General header file */
`include "stddef.h"

module if_stage(
    /********** Clock & Reset *********/
    input                   clk,           // Clk
    input                   reset,         // Reset
    /* CPU part */ 
    input                   mem_busy,
    output                  ic_busy,
    output                  miss_stall,    // the signal of stall caused by cache miss
    output                  ic_choose_way,
    /****** Thread choose part *****/
    input      [1:0]        l2_thread,
    input      [1:0]        mem_thread,
    input      [1:0]        thread,
    output     [1:0]        ic_thread,
    /************* I_Cache ************/
    input                   lru,           // mark of replacing
    input      [1:0]        thread0,          // read data of tag0
    input      [1:0]        thread1,          // read data of tag1
    input      [20:0]       tag0_rd,       // read data of tag0
    input      [20:0]       tag1_rd,       // read data of tag1
    input      [127:0]      data0_rd,      // read data of data0
    input      [127:0]      data1_rd,      // read data of data1
    input      [127:0]      data_wd_l2,
    input      [127:0]      data_wd_l2_mem,       // wr_data from L2 
    // input                   w_complete,    // complete op writing to L1
    // input                   r_complete,    // complete op reading from L1
    output                  block0_re,     // read signal of block0
    output                  block1_re,     // read signal of block1
    output      [7:0]       index,         // address of L1_cache
    /************* L2_Cache ************/
    input                   ic_en,         // busy signal of L2_cache
    input                   l2_rdy,        // ready signal of L2_cache
    input                   mem_wr_ic_en,
    output                  irq,           // icache request
    /******** Pipeline control ********/
    input                   stall,          // Stall
    input                   flush,          // Flush
    input  [`WORD_DATA_BUS] new_pc,         // New value of program counter
    input                   br_taken,       // Branch taken
    input  [`WORD_DATA_BUS] br_addr,        // Branch target
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
        .rst            (reset),         // reset
        /* CPU part */
        .choose_way     (ic_choose_way),
        .mem_busy       (mem_busy),
        .if_addr        (if_pc[31:2]),   // address of fetching instruction
        .rw             (`READ),         // read / write signal of CPU
        .cpu_data       (insn),          // read data of CPU
        .miss_stall     (miss_stall),    // the signal of stall caused by cache miss
        .ic_busy        (ic_busy),
        /*thread part*/
        .l2_thread      (l2_thread),
        .mem_thread     (mem_thread),
        .thread         (thread),
        .ic_thread      (ic_thread),       
        /* L1_cache part */
        .lru            (lru),           // mark of replacing
        .tag0_rd        (tag0_rd),       // read data of tag0
        .tag1_rd        (tag1_rd),       // read data of tag1
        .thread0        (thread0),
        .thread1        (thread1),
        .data0_rd       (data0_rd),      // read data of data0
        .data1_rd       (data1_rd),      // read data of data1
        .data_wd_l2     (data_wd_l2), 
        .data_wd_l2_mem (data_wd_l2_mem), 
        .block0_re      (block0_re),     // read signal of block0
        .block1_re      (block1_re),     // read signal of block1
        .index          (index),         // address of L1_cache
        /* l2_cache part */
        .ic_en          (ic_en),         // busy signal of l2_cache
        .l2_rdy         (l2_rdy),        // ready signal of l2_cache
        .mem_wr_ic_en   (mem_wr_ic_en), 
        .irq            (irq),
        .data_rdy       (data_rdy)        
        );

    if_reg if_reg(
        /******** Clock & Rest ********/
        .clk          (clk),                  // Clk
        .reset        (reset),                // Reset
        /******** Read Instruction ********/
        .insn         (insn),                 // Reading instruction
        .stall        (stall),                // Stall
        .data_rdy     (data_rdy),             // tag hit mark
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
