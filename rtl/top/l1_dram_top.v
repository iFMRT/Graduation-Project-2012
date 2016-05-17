/*
 -- ============================================================================
 -- FILE NAME   : l1_dram_top.v
 -- DESCRIPTION : top of dcache_ram
 -- ----------------------------------------------------------------------------
 -- Date:2016/4/12         Coding_by:kippy   
 -- ============================================================================
*/
`timescale 1ns/1ps
/********** General header file **********/
`include "stddef.h"
`include "dcache.h"

module l1_dram_top(
    input           clk,               // clock
    /*dtag*/
    input   [7:0]   index_dc,          // address of cache
    input           tagcomp_hit, 
    input           block0_we,         // the mark of cache_block0 write signal 
    input           block1_we,         // the mark of cache_block1 write signal 
    input           block0_re,         // the mark of cache_block0 read signal 
    input           block1_re,         // the mark of cache_block1 read signal 
    input           dirty_wd,
    input   [20:0]  tag_wd_dc,         // write data of tag
    output  [20:0]  tag0_rd_dc,        // read data of tag0
    output  [20:0]  tag1_rd_dc,        // read data of tag1
    output          dirty0,
    output          dirty1,
    output          lru_dc,            // read data of lru_field
    output          w_complete_dc,     // complete write to L1
    output          r_complete_dc,     // complete read from L1
    /*ddata*/
    input   [31:0]  dc_wd,    
    input   [1:0]   offset, 
    input   [127:0] data_wd_l2,        // write data of l2_cache
    input           data_wd_l2_en,
    input           data_wd_dc_en,
    output  [127:0] data0_rd_dc,       // read data of cache_data0
    output  [127:0] data1_rd_dc        // read data of cache_data1
    );
    dtag_ram dtag_ram(
        .clk            (clk),           // clock
        .block0_we      (block0_we),     // write signal of block0
        .block1_we      (block1_we),     // write signal of block1
        .block0_re      (block0_re),     // read signal of block0
        .block1_re      (block1_re),     // read signal of block1
        .index          (index_dc),      // address of cache
        .dirty_wd       (dirty_wd),   
        .tag_wd         (tag_wd_dc),     // write data of tag
        .tag0_rd        (tag0_rd_dc),    // read data of tag0
        .tag1_rd        (tag1_rd_dc),    // read data of tag1
        .dirty0         (dirty0),
        .dirty1         (dirty1),
        .lru            (lru_dc),        // read data of tag
        .w_complete     (w_complete_dc), // complete write to L1
        .r_complete     (r_complete_dc)  // complete write from L1
        );
    data_ram ddata_ram(
        .clk            (clk),           // clock
        .index          (index_dc),      // address of cache
        .tagcomp_hit    (tagcomp_hit),   // +++++++++
        .block0_we      (block0_we),     // write signal of block0
        .block1_we      (block1_we),     // write signal of block1
        .block0_re      (block0_re),     // read signal of block0
        .block1_re      (block1_re),     // read signal of block1
        .data_wd_l2     (data_wd_l2),    // write data of l2_cache
        // .data_wd_dc     (data_wd_dc),    // write data of l2_cache
        .data_wd_l2_en  (data_wd_l2_en), // write data of l2_cache
        .data_wd_dc_en  (data_wd_dc_en), // write data of l2_cache
        .dc_wd          (dc_wd),
        .offset         (offset), 
        .data0_rd       (data0_rd_dc),   // read data of cache_data0
        .data1_rd       (data1_rd_dc)    // read data of cache_data1
    );
endmodule