////////////////////////////////////////////////////////////////////
// Engineer:       Kippy Chen - 799182081@qq.com                  //
//                                                                //
// Additional contributions by:                                   //
//                 Beyond Sky - fan-dave@163.com                  //
//                 Junhao Chang                                   //
//                 Leway Colin - colin4124@gmail.com              //
//                                                                //
// Design Name:    l1_ic_top                                      //
// Project Name:   FMRT Mini Core                                 //
// Language:       Verilog                                        //
//                                                                //
// Description:    I-Cache.                                       //
//                                                                //
////////////////////////////////////////////////////////////////////

`timescale 1ns/1ps
/********** General header file **********/
`include "common_defines.v"
`include "l1_cache.h"
`include "l2_cache.h"

module l1_ic_top(
    /********* Clk & Reset ********/
    input  wire                     clk,              // clock
    input  wire                     rst,              // reset
    /********** CPU part **********/
    input  wire    [`WORD_ADDR_BUS] br_addr_ic,        // Branch target
    input  wire                     br_taken,
    input  wire    [`L2_ADDR_BUS]   ic_addr_mem,
    input  wire    [`L2_ADDR_BUS]   ic_addr_l2,
    input  wire                     memory_en,
    input  wire                     l2_en,
    // input  wire    [`OFFSET_BUS]    offset,
    input  wire                     if_stall,
    input  wire    [`WORD_ADDR_BUS] if_addr,          // address of fetching instruction
    output wire    [`WORD_ADDR_BUS] ic_addr,
    output wire    [`WORD_DATA_BUS] insn,         // read data of CPU
    output wire                     ic_miss,       // the signal of stall caused by cache miss
    output wire                     choose_way,
    output wire                     thread_rdy,
    output wire    [`THREAD_BUS]    ic_thread_wd,
    /****** Thread choose part *****/
    input  wire    [`THREAD_BUS]    l2_thread,
    input  wire    [`THREAD_BUS]    mem_thread,
    input  wire    [`THREAD_BUS]    thread,
    output wire    [`THREAD_BUS]    ic_thread,
    output wire                     if_busy,
    /******** I_Cache part ********/
    input  wire    [`L1_DATA_BUS]   data_wd_l2,       // wr_data from L2 
    input  wire    [`L1_DATA_BUS]   data_wd_l2_mem,   // wr_data from L2 
    /******* Memory part *******/
    input  wire    [`L1_TAG_BUS]    ic_tag_wd_mem,
    input  wire    [`L1_INDEX_BUS]  ic_index_mem,
    input  wire                     ic_block0_we_mem,
    input  wire                     ic_block1_we_mem,
    /******* L2_Cache part *******/
    input  wire                     l2_busy,
    input  wire    [`L1_TAG_BUS]    ic_tag_wd,
    input  wire    [`L1_INDEX_BUS]  ic_index_l2,
    input  wire                     ic_block0_we_l2,
    input  wire                     ic_block1_we_l2,
    input  wire                     ic_en,            // I_Cache enable signal of accessing L2_cache
    input  wire                     l2_rdy,           // ready signal of L2_cache
    input  wire                     mem_wr_ic_en,     // enable signal that MEM write I_Cache  
    output wire                     irq,              // I_Cache request
    /****** IF reg module ********/
    output wire                     data_rdy          // data to CPU ready mark
    );
    /************ itag ***********/
    wire                        block0_we;      // write signal of block0
    wire                        block1_we;      // write signal of block1
    wire                        block0_re;      // read signal of block0
    wire                        block1_re;      // read signal of block1
    wire    [`THREAD_BUS]       thread0;        // read data of tag0
    wire    [`THREAD_BUS]       thread1;        // read data of tag1
    wire    [`L1_INDEX_BUS]     index;          // address of cache
    wire    [`L1_TAG_BUS]       tag_wd;         // write data of tag
    wire    [`L1_TAG_BUS]       tag0_rd;        // read data of tag0
    wire    [`L1_TAG_BUS]       tag1_rd;        // read data of tag1
    wire                        lru;            // read data of lru_field
    /************ data ***********/  
    wire    [`L1_DATA_BUS]      data_wd;          // wr_data from L2    
    wire    [`L1_DATA_BUS]      data0_rd;       // read data of cache_data0
    wire    [`L1_DATA_BUS]      data1_rd;       // read data of cache_data1

    //////////////////////////////
    //   ___ _____  _    ____   //
    //  |_ _|_   _|/ \  / ___|  //
    //   | |  | | / _ \| |  _   //
    //   | |  | |/ ___ \ |_| |  //
    //  |___| |_/_/   \_\____|  //
    //                          //
    //////////////////////////////

    itag_ram itag_ram(
        .clk            (clk),              // clock
        .block0_we      (block0_we),        // write signal of block0
        .block1_we      (block1_we),        // write signal of block1
        .block0_re      (block0_re),        // read signal of block0
        .block1_re      (block1_re),        // read signal of block1
        .thread_wd      (ic_thread_wd),
        .thread0        (thread0),
        .thread1        (thread1),
        .index          (index),            // address of cache
        .tag_wd         (tag_wd),           // write data of tag
        .tag0_rd        (tag0_rd),          // read data of tag0
        .tag1_rd        (tag1_rd),          // read data of tag1
        .lru            (lru)               // read data of tag
        );

    //////////////////////////////////
    //  ___ ____    _  _____  _     //
    // |_ _|  _ \  / \|_   _|/ \    //
    //  | || | | |/ _ \ | | / _ \   //
    //  | || |_| / ___ \| |/ ___ \  //
    // |___|____/_/   \_\_/_/   \_\ //
    //                              //
    //////////////////////////////////

    idata_ram idata_ram(
        .clk            (clk),             // clock
        .block0_we      (block0_we),       // write signal of block0
        .block1_we      (block1_we),       // write signal of block1
        .block0_re      (block0_re),       // read signal of block0
        .block1_re      (block1_re),       // read signal of block1
        .index          (index),           // address of cache 
        .data_wd        (data_wd),         // write data of l2_cache
        .data0_rd       (data0_rd),        // read data of cache_data0
        .data1_rd       (data1_rd)         // read data of cache_data1
    );

    /////////////////////////////// 
    //   ____ _____ ____  _      //
    //  / ___|_   _|  _ \| |     //
    // | |     | | | |_) | |     //
    // | |___  | | |  _ <| |___  //
    //  \____| |_| |_| \_\_____| //
    //                           //
    ///////////////////////////////  

    icache_ctrl icache_ctrl(
        .clk                (clk),           // clock
        .rst                (rst),         // reset
        /* CPU part */
        .br_taken           (br_taken),
        .br_addr_ic         (br_addr_ic), 
        .ic_addr_mem        (ic_addr_mem),
        .ic_addr_l2         (ic_addr_l2),
        .memory_en          (memory_en),
        .l2_en              (l2_en),
        .choose_way         (choose_way),
        // .offset             (offset),
        .if_stall           (if_stall),
        .if_addr            (if_addr),       // address of fetching instruction
        .rw                 (`READ),         // read / write signal of CPU
        .cpu_data           (insn),          // read data of CPU
        .miss_stall         (ic_miss),    // the signal of stall caused by cache miss
        .ic_busy            (if_busy),
        .thread_rdy         (thread_rdy),
        /*thread part*/
        .l2_thread          (l2_thread),
        .mem_thread         (mem_thread),
        .thread             (thread),
        .ic_thread          (ic_thread),       
        /* L1_cache part */
        .lru                (lru),           // mark of replacing
        .tag0_rd            (tag0_rd),       // read data of tag0
        .tag1_rd            (tag1_rd),       // read data of tag1
        .thread0            (thread0),
        .thread1            (thread1),
        .data0_rd           (data0_rd),      // read data of data0
        .data1_rd           (data1_rd),      // read data of data1
        .data_wd_l2         (data_wd_l2), 
        .data_wd_l2_mem     (data_wd_l2_mem), 
        .block0_re          (block0_re),     // read signal of block0
        .block1_re          (block1_re),     // read signal of block1
        .index              (index),         // address of L1_cache
        .data_wd            (data_wd),
        .ic_thread_wd       (ic_thread_wd),
        .block0_we          (block0_we),
        .block1_we          (block1_we),
        .tag_wd             (tag_wd),
        .ic_index_l2        (ic_index_l2),
        .ic_tag_wd_l2       (ic_tag_wd),
        .ic_block0_we_l2    (ic_block0_we_l2),
        .ic_block1_we_l2    (ic_block1_we_l2),
        .ic_index_mem       (ic_index_mem),
        .ic_tag_wd_mem      (ic_tag_wd_mem), 
        .ic_block0_we_mem   (ic_block0_we_mem),
        .ic_block1_we_mem   (ic_block1_we_mem),
        .ic_addr            (ic_addr),
        /* l2_cache part */
        .l2_busy            (l2_busy),
        .ic_en              (ic_en),         // busy signal of l2_cache
        .l2_rdy             (l2_rdy),        // ready signal of l2_cache
        .mem_wr_ic_en       (mem_wr_ic_en), 
        .irq                (irq),
        .data_rdy           (data_rdy)        
        );
endmodule