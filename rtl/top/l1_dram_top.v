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
    input           tag0_rw_dc,        // read / write signal of tag0
    input           tag1_rw_dc,        // read / write signal of tag1
    input   [7:0]   index_dc,          // address of cache
    input           dirty0_rw,
    input           dirty1_rw,
    input           dirty_wd,
    input   [20:0]  tag_wd_dc,         // write data of tag
    output  [20:0]  tag0_rd_dc,        // read data of tag0
    output  [20:0]  tag1_rd_dc,        // read data of tag1
    output          dirty0,
    output          dirty1,
    output          lru_dc,            // read data of lru_field
    output          complete_dc,       // complete write from L2 to L1
    /*ddata*/
    input              wr0_en0,
    input              wr0_en1,
    input              wr0_en2,
    input              wr0_en3,
    input              wr1_en0,
    input              wr1_en1,
    input              wr1_en2,
    input              wr1_en3,
    input      [31:0]  wr_data_m,       // ++++++++++
    input      [1:0]   offset, 
    // input           data0_rw_dc,       // the mark of cache_data0 write signal 
    // input           data1_rw_dc,       // the mark of cache_data1 write signal 
    input   [127:0] data_wd_l2,        // write data of l2_cache
    // input   [127:0] data_wd_dc,
    input           data_wd_l2_en,
    input           data_wd_dc_en,
    output  [127:0] data0_rd_dc,       // read data of cache_data0
    output  [127:0] data1_rd_dc        // read data of cache_data1
    );
    dtag_ram dtag_ram(
        .clk            (clk),              // clock
        .tag0_rw        (tag0_rw_dc),       // read / write signal of tag0
        .tag1_rw        (tag1_rw_dc),       // read / write signal of tag1
        .index          (index_dc),         // address of cache
        .dirty0_rw      (dirty0_rw),        
        .dirty1_rw      (dirty1_rw),   
        .dirty_wd       (dirty_wd), 
        .tag_wd         (tag_wd_dc),        // write data of tag
        .tag0_rd        (tag0_rd_dc),       // read data of tag0
        .tag1_rd        (tag1_rd_dc),       // read data of tag1
        .dirty0         (dirty0),
        .dirty1         (dirty1),
        .lru            (lru_dc),           // read data of tag
        .complete       (complete_dc)       // complete write from L2 to L1
        );
    data_ram ddata_ram(
        .clk            (clk),           // clock
        // .data0_rw       (data0_rw_dc),      // the mark of cache_data0 write signal 
        // .data1_rw       (data1_rw_dc),      // the mark of cache_data1 write signal 
        .wr0_en0        (wr0_en0),   // the mark of cache_data0 write signal 
        .wr0_en1        (wr0_en1),   // the mark of cache_data1 write signal 
        .wr0_en2        (wr0_en2),   // the mark of cache_data2 write signal 
        .wr0_en3        (wr0_en3),   // the mark of cache_data3 write signal         
        .wr1_en0        (wr1_en0),
        .wr1_en1        (wr1_en1),
        .wr1_en2        (wr1_en2),
        .wr1_en3        (wr1_en3),
        .index          (index_dc),         // address of cache__
        .data_wd_l2     (data_wd_l2),    // write data of l2_cache
        // .data_wd_dc     (data_wd_dc),    // write data of l2_cache
        .data_wd_l2_en  (data_wd_l2_en), // write data of l2_cache
        .data_wd_dc_en  (data_wd_dc_en), // write data of l2_cache
        .wr_data_m      (wr_data_m),
        .offset         (offset), 
        .data0_rd       (data0_rd_dc),      // read data of cache_data0
        .data1_rd       (data1_rd_dc)       // read data of cache_data1
    );
endmodule