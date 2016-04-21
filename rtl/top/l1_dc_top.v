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
`include "stddef.h"
`include "dcache.h"

module l1_dc_top(
    input              clk,           // clock
    input              rst,           // reset
    /* CPU part */
    input      [29:0]  addr,          // address of accessing memory
    input      [31:0]  wr_data_m,
    input              memwrite_m,    // read / write signal of CPU
    input              access_mem,
    input              access_mem_ex,
    output     [31:0]  read_data_m,   // read data of CPU
    output             mem_busy,      // the signal of stall caused by cache miss
    /* dcache part */
    output             hitway,        // path hit mark            
    output     [127:0] rd_to_l2,      // read data of L1_cache's data
    /* L2_cache part */
    input      [127:0] data_wd_l2,    // write data of l2_cache
    input              data_wd_l2_en,
    input              l2_complete,
    input              dc_en,         // busy signal of L2_cache
    input              l2_rdy,        // ready signal of L2_cache
    input              mem_wr_dc_en,   
    output             complete_dc,   // complete write from L2 to L1
    output             drq,           // dcache request
    output             dc_rw_en,      // enable signal of writing dcache 
    output     [27:0]  l2_addr_dc,
    output             l2_cache_rw_dc // l2_cache read/write signal
    );    
    /*dtag*/
    wire    [7:0]   index_dc;         // address of cache
    wire    [1:0]   offset; 
    wire            block0_rw;
    wire            block1_rw;
    wire            dirty_wd;
    wire    [20:0]  tag_wd_dc;        // write data of tag
    wire    [20:0]  tag0_rd_dc;       // read data of tag0
    wire    [20:0]  tag1_rd_dc;       // read data of tag1
    wire            dirty0;
    wire            dirty1;
    wire            lru_dc;           // read data of lru_field
    /*ddata*/
    wire    [127:0] data_wd_dc;
    wire            data_wd_dc_en;
    wire    [127:0] data0_rd_dc;      // read data of cache_data0
    wire    [127:0] data1_rd_dc;      // read data of cache_data1
    wire            tagcomp_hit;

    l1_dram_top l1_dram_top(
        .clk            (clk),              // clock
        .index_dc       (index_dc),         // address of cache
        .block0_we      (block0_we),        // write signal of block0
        .block1_we      (block1_we),        // write signal of block1
        .block0_re      (block0_re),        // read signal of block0
        .block1_re      (block1_re),        // read signal of block1  
        .dirty_wd       (dirty_wd), 
        .tag_wd_dc      (tag_wd_dc),        // write data of tag
        .tag0_rd_dc     (tag0_rd_dc),       // read data of tag0
        .tag1_rd_dc     (tag1_rd_dc),       // read data of tag1
        .dirty0         (dirty0),
        .dirty1         (dirty1),
        .lru_dc         (lru_dc),           // read data of tag
        .complete_dc    (complete_dc),      // complete write from L2 to L1
        .wr_data_m      (wr_data_m),
        .offset         (offset),
        .tagcomp_hit    (tagcomp_hit),    
        .data_wd_l2     (data_wd_l2),       // write data of l2_cache
        .data_wd_l2_en  (data_wd_l2_en),    // write data of l2_cache
        .data_wd_dc_en  (data_wd_dc_en),    // write data of l2_cache
        .data0_rd_dc    (data0_rd_dc),      // read data of cache_data0
        .data1_rd_dc    (data1_rd_dc)       // read data of cache_data1
        );
        /********** Dcache Interface **********/
    dcache_ctrl dcache_ctrl(
        .clk            (clk),              // clock
        .rst            (rst),              // reset
        /* CPU part */
        .addr           (addr),             // address of fetching instruction
        .memwrite_m     (memwrite_m),       // read / write signal of CPU
        .access_mem     (access_mem), 
        .access_mem_ex  (access_mem_ex), 
        .read_data_m    (read_data_m),      // read data of CPU
        .miss_stall     (mem_busy),         // the signal of stall caused by cache miss
        /* L1_cache part */
        .lru            (lru_dc),           // mark of replacing
        .tag0_rd        (tag0_rd_dc),       // read data of tag0
        .tag1_rd        (tag1_rd_dc),       // read data of tag1
        .data0_rd       (data0_rd_dc),      // read data of data0
        .data1_rd       (data1_rd_dc),      // read data of data1
        .data_wd_l2     (data_wd_l2),
        .dirty0         (dirty0),         
        .dirty1         (dirty1),          
        .dirty_wd       (dirty_wd),             
        .block0_we      (block0_we),        // write signal of block0
        .block1_we      (block1_we),        // write signal of block1
        .block0_re      (block0_re),        // read signal of block0
        .block1_re      (block1_re),        // read signal of block1
        .offset         (offset),
        .tagcomp_hit    (tagcomp_hit),       
        .tag_wd         (tag_wd_dc),        // write data of L1_tag
        .data_wd_dc_en  (data_wd_dc_en),
        .hitway         (hitway),
        .index          (index_dc),         // address of L1_cache
        .rd_to_l2       (rd_to_l2), 
        /* l2_cache part */
        .l2_complete    (l2_complete),
        .dc_en          (dc_en),            // busy signal of l2_cache
        .l2_rdy         (l2_rdy),           // ready signal of l2_cache
        .mem_wr_dc_en   (mem_wr_dc_en),  
        .complete       (complete_dc),      // complete op writing to L1
        .drq            (drq),  
        .dc_rw_en       (dc_rw_en),     
        .l2_addr        (l2_addr_dc),    
        .l2_cache_rw    (l2_cache_rw_dc)        
        );
endmodule