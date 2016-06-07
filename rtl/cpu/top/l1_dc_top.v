/*
 -- ============================================================================
 -- FILE NAME   : l1_dc_top.v
 -- DESCRIPTION : top of dcache
 -- ----------------------------------------------------------------------------
 -- Date:2016/4/13         Coding_by:kippy   
 -- ============================================================================
*/
`timescale 1ns/1ps
/********** General header file **********/
`include "common_defines.v"
`include "l1_cache.h"
`include "l2_cache.h"

module l1_dc_top(
    /********* Clk & Reset ********/
    input  wire                     clk,           // clock
    input  wire                     rst,           // reset
    /******** Memory part *********/
    input  wire                     memory_en,
    input  wire                     l2_en,
    input  wire    [`L2_ADDR_BUS]   dc_addr_mem,
    input  wire    [`L2_ADDR_BUS]   dc_addr_l2,
    input  wire    [`L1_TAG_BUS]    dc_tag_wd_mem,
    input  wire    [`L1_INDEX_BUS]  dc_index_mem,
    input  wire    [`L1_DATA_BUS]   data_wd_l2_mem,
    input  wire    [`OFFSET_BUS]    offset_mem,
    input  wire                     dc_block0_we_mem,
    input  wire                     dc_block1_we_mem,
    input  wire                     dc_rw_mem,
    /********** CPU part **********/
    input  wire    [`WORD_ADDR_BUS] next_addr,          // address of accessing memory
    input  wire                     memwrite_m,    // read / write signal of CPU
    input  wire                     access_mem,    // access MEM mark
    input  wire    [`WORD_DATA_BUS] wr_data,       // write data from CPU
    input  wire    [`OFFSET_BUS]    offset_m,
    input  wire                     out_rdy,
    output wire    [`WORD_DATA_BUS] read_data_m,   // read data of CPU
    output wire                     dc_miss,       // the signal of stall caused by cache miss
    output wire                     access_l2_clean,
    output wire                     access_l2_dirty,
    output wire                     choose_way,
    output wire    [`L2_ADDR_BUS]   dc_addr,
    output wire                     thread_rdy,
    output wire    [`THREAD_BUS]    thread_rdy_thread,
    input  wire    [`WORD_DATA_BUS] wr_data_l2,
    input  wire    [`WORD_DATA_BUS] wr_data_mem,
    output wire    [`WORD_DATA_BUS] wr_data_dc,
    /****** Thread choose part *****/
    input  wire    [`THREAD_BUS]    l2_thread,
    input  wire    [`THREAD_BUS]    mem_thread,
    input  wire    [`THREAD_BUS]    thread,
    output wire    [`THREAD_BUS]    dc_thread,
    output wire                     dc_busy,
    /******** D_Cache part ********/         
    output wire                     drq,               // dcache request
    input  wire                     data_wd_l2_en_dc,    
    output wire    [`OFFSET_BUS]    dc_offset, 
    // d_data 
    output wire                     dc_rw,   
    output wire    [`L1_DATA_BUS]   dirty_data,
    output wire    [`L1_TAG_BUS]    dirty_tag,         // write data of dtag
    output wire    [`WORD_DATA_BUS] rd_to_write_m,
    /******* L2_Cache part *******/
    input  wire    [`L1_TAG_BUS]    dc_tag_wd_l2,
    input  wire    [`L1_INDEX_BUS]  dc_index_l2,
    input  wire                     dc_block0_we_l2,
    input  wire                     dc_block1_we_l2,
    input  wire                     dc_rw_l2,
    input  wire    [`OFFSET_BUS]    offset_l2, 
    input  wire                     l2_busy,
    input  wire                     dc_en,         // busy signal of L2_cache
    input  wire                     l2_rdy,        // ready signal of L2_cache
    input  wire                     mem_wr_dc_en,
    input  wire    [`L1_DATA_BUS]   data_wd_l2       
    );    
    // wire       [`OFFSET_BUS]    dc_offset;  
    wire                        l2_wr_dc_en;
    wire                        data_wd_dc_en; 
    /*dtag*/
    wire       [`L1_INDEX_BUS]  index;         // address of cache
    wire                        block0_we;
    wire                        block1_we;
    wire                        block0_re;
    wire                        block1_re;
    wire       [`L1_DATA_BUS]   data0_rd;      // read data of cache_data0
    wire       [`L1_DATA_BUS]   data1_rd;      // read data of cache_data1
    wire       [`L1_TAG_BUS]    tag_wd;        // write data of tag
    wire       [`L1_TAG_BUS]    tag0_rd;       // read data of tag0
    wire       [`L1_TAG_BUS]    tag1_rd;       // read data of tag1
    wire       [`THREAD_BUS]    thread0;       // read data of tag0
    wire       [`THREAD_BUS]    thread1;       // read data of tag1 
    wire       [`THREAD_BUS]    dc_thread_wd;  // write data of dtag
    wire                        dirty0;
    wire                        dirty1;
    wire                        lru;           // read data of lru_field
    /*ddata*/
    wire       [`L1_DATA_BUS]   data_wd;    
    wire       [`WORD_DATA_BUS] dc_wd;
    
    dtag_ram dtag_ram(
        .clk               (clk),           // clock
        .data_wd_dc_en     (data_wd_dc_en), // write data of l2_cache
        .l2_wr_dc_en       (l2_wr_dc_en),
        .index             (index),      // address of cache
        .block0_we         (block0_we),      // write signal of block0
        .block1_we         (block1_we),      // write signal of block1
        .block0_re         (block0_re),
        .block1_re         (block1_re), 
        // .w_complete        (w_complete),
        .thread_wd         (dc_thread_wd),
        .tag_wd            (tag_wd),     // write data of tag
        .tag0_rd           (tag0_rd),    // read data of tag0
        .tag1_rd           (tag1_rd),    // read data of tag1
        .thread0           (thread0),
        .thread1           (thread1),
        .dirty0            (dirty0),
        .dirty1            (dirty1),
        .lru               (lru)         // read data of tag
        );
    data_ram ddata_ram(
        .clk               (clk),               // clock   
        .index             (index),          // address of cache
        .block0_we         (block0_we),      // write signal of block0
        .block1_we         (block1_we),      // write signal of block1
        .block0_re         (block0_re),         // read signal of block0
        .block1_re         (block1_re),         // read signal of block1
        .l2_wr_dc_en       (l2_wr_dc_en),
        .data_wd_dc_en     (data_wd_dc_en),     // write data of l2_cache
        .dc_wd             (dc_wd),
        .dc_offset         (dc_offset),
        .dc_data_wd        (data_wd),           // write data of l2_cache
        .data0_rd          (data0_rd),       // read data of cache_data0
        .data1_rd          (data1_rd)        // read data of cache_data1
    );
    /********** Dcache Interface **********/
    dcache_ctrl dcache_ctrl(
        .clk               (clk),           // clock
        .rst               (rst),           // reset
        .dc_index_mem      (dc_index_mem),
        .dc_tag_wd_mem     (dc_tag_wd_mem),
        .dc_block0_we_mem  (dc_block0_we_mem),
        .dc_block1_we_mem  (dc_block1_we_mem),
        .dc_rw_mem         (dc_rw_mem),  
        .offset_mem        (offset_mem),
        .l2_wr_dc_en       (l2_wr_dc_en),
        .data_wd_l2_en_dc  (data_wd_l2_en_dc),
        .dc_thread_wd      (dc_thread_wd),
        .thread_rdy_thread (thread_rdy_thread),
        .data_wd           (data_wd),
        /* CPU part */
        .memory_en         (memory_en),
        .l2_en             (l2_en),
        .dc_addr_mem       (dc_addr_mem),
        .dc_addr_l2        (dc_addr_l2),
        .access_l2_clean   (access_l2_clean),
        .access_l2_dirty   (access_l2_dirty),
        .next_addr         (next_addr),     // address of fetching instruction
        .memwrite_m        (memwrite_m),    // Read/Write 
        .wr_data           (wr_data),       // read / write signal of CPU
        .offset_m          (offset_m),
        .dc_wd             (dc_wd),
        .access_mem        (access_mem), 
        .out_rdy           (out_rdy),
        .read_data_m       (read_data_m),   // read data of CPU
        .miss_stall        (dc_miss),    // the signal of stall caused by cache miss
        .choose_way        (choose_way),
        .dc_addr           (dc_addr),
        .dc_rw             (dc_rw),
        .dirty_data        (dirty_data),
        .dirty_tag         (dirty_tag),
        .rd_to_write_m     (rd_to_write_m),
        .wr_data_l2        (wr_data_l2),
        .wr_data_mem       (wr_data_mem),
        .wr_data_dc        (wr_data_dc),
        /*thread part*/
        .l2_thread         (l2_thread),
        .mem_thread        (mem_thread),
        .thread            (thread),
        .dc_thread         (dc_thread),  
        .dc_busy           (dc_busy),
        /* L1_cache part */
        .block0_we         (block0_we),     // write signal of block0
        .block1_we         (block1_we),     // write signal of block1
        .block0_re         (block0_re),     // read signal of block0
        .block1_re         (block1_re),     // read signal of block1      
        .offset            (dc_offset),      
        .index             (index),         // address of L1_cache
        .drq               (drq), 
        .lru               (lru),           // mark of replacing
        .tag0_rd           (tag0_rd),       // read data of tag0
        .tag1_rd           (tag1_rd),       // read data of tag1
        .thread0           (thread0),
        .thread1           (thread1),
        .data0_rd          (data0_rd),      // read data of data0
        .data1_rd          (data1_rd),      // read data of data1
        .dirty0            (dirty0),         
        .dirty1            (dirty1),          
        .tag_wd            (tag_wd),        // write data of L1_tag
        .data_wd_dc_en     (data_wd_dc_en),
        /* l2_cache part */
        .dc_index_l2       (dc_index_l2),
        .dc_tag_wd_l2      (dc_tag_wd_l2),
        .dc_block0_we_l2   (dc_block0_we_l2),
        .dc_block1_we_l2   (dc_block1_we_l2),
        .dc_rw_l2          (dc_rw_l2),  
        .offset_l2         (offset_l2), 
        .thread_rdy        (thread_rdy),
        .l2_busy           (l2_busy), 
        .dc_en             (dc_en),         // busy signal of l2_cache
        .l2_rdy            (l2_rdy),        // ready signal of l2_cache
        .mem_wr_dc_en      (mem_wr_dc_en), 
        .data_wd_l2_mem    (data_wd_l2_mem), 
        .data_wd_l2        (data_wd_l2)                  
        );
endmodule