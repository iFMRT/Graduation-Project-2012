/*
 -- ============================================================================
 -- FILE NAME   : l2_top.v
 -- DESCRIPTION : top of l2_cache
 -- ----------------------------------------------------------------------------
 -- Date:2016/4/13         Coding_by:kippy   
 -- ============================================================================
*/
`timescale 1ns/1ps

`include "stddef.h"
`include "l2_cache.h"

module l2_top(
    input            clk,           // Clock
    input            rst,           // Asynchronous Reset
    /*l2_cache part*/
    input    [27:0]  l2_addr_ic,  
    input    [27:0]  l2_addr_dc,
    input            l2_cache_rw_ic,
    input            l2_cache_rw_dc, 
    output           ic_en,         // busy mark of L2C        
    output           dc_en,         
    output           l2_rdy,
    output           l2_complete_w, // complete write from MEM to L2
    /*dcache part*/
    input            drq, 
    input            dc_rw_en, 
    input            w_complete_dc, // complete write to L1D 
    /*icache part*/
    input            irq,
    input            ic_rw_en,      // write enable signal
    input            w_complete_ic, // complete write to L1P 
    
    /*l1_cache part*/
    input    [127:0] rd_to_l2, 
    output   [127:0] data_wd_l2,    // write data to L1    
    output           data_wd_l2_en,   
    output           mem_wr_dc_en,       
    output           mem_wr_ic_en,
    /*memory part*/
    input            mem_complete_r,
    input            mem_complete_w,
    input    [511:0] mem_rd,
    output   [511:0] mem_wd,
    output   [25:0]  mem_addr,      // address of memory
    output           mem_we,        // read / write signal of memory
    output           mem_re         // read / write signal of memory
    ); 
    /*cache part*/
    wire     [17:0]  l2_tag_wd;     // write data of tag
    wire     [8:0]   l2_index;
    wire     [1:0]   l2_offset;
    // complete write from L2 to L1 
    // l2_tag_ram part
    wire     [17:0]  l2_tag0_rd;    // read data of tag0
    wire     [17:0]  l2_tag1_rd;    // read data of tag1
    wire     [17:0]  l2_tag2_rd;    // read data of tag2
    wire     [17:0]  l2_tag3_rd;    // read data of tag3
    wire     [2:0]   plru;          // read data of tag
    wire             l2_complete_r;
    // l2_data_ram
    wire             wd_from_l1_en;
    wire             wd_from_mem_en;
    wire     [511:0] l2_data_wd;     // write data of l2_cache
    wire     [511:0] l2_data0_rd;    // read data of cache_data0
    wire     [511:0] l2_data1_rd;    // read data of cache_data1
    wire     [511:0] l2_data2_rd;    // read data of cache_data2
    wire     [511:0] l2_data3_rd;    // read data of cache_data3 
    // l2_dirty
    wire             l2_dirty_wd;
    wire             l2_block0_we;
    wire             l2_block1_we;
    wire             l2_block2_we;
    wire             l2_block3_we;
    wire             l2_block0_re;
    wire             l2_block1_re;
    wire             l2_block2_re;
    wire             l2_block3_re;
    wire             l2_dirty0;
    wire             l2_dirty1;
    wire             l2_dirty2;
    wire             l2_dirty3;
    // l2_cache
    wire             l2_tagcomp_hit;
l2_cache_ctrl l2_cache_ctrl(
        .clk            (clk),           // clock of L2C
        .rst            (rst),           // reset
        /* CPU part */
        .l2_addr_ic     (l2_addr_ic),    // address of fetching instruction
        .l2_cache_rw_ic (l2_cache_rw_ic),// read / write signal of CPU
        .l2_addr_dc     (l2_addr_dc),    // address of fetching instruction
        .l2_cache_rw_dc (l2_cache_rw_dc),// read / write signal of CPU
        .l2_index       (l2_index),
        .offset         (l2_offset), 
        .tagcomp_hit    (l2_tagcomp_hit),     
        /*cache part*/
        .irq            (irq),           // icache request
        .drq            (drq),
        .ic_rw_en       (ic_rw_en),      // write enable signal of icache
        .dc_rw_en       (dc_rw_en),
        .w_complete_ic  (w_complete_ic), // complete write to L1P
        .w_complete_dc  (w_complete_dc), // complete write to L1D     
        .data_wd_l2     (data_wd_l2),    // write data to L1C       
        .data_wd_l2_en  (data_wd_l2_en), 
        .wd_from_mem_en (wd_from_mem_en),
        .wd_from_l1_en  (wd_from_l1_en),
        .mem_wr_dc_en   (mem_wr_dc_en), 
        .mem_wr_ic_en   (mem_wr_ic_en),
        /*l2_cache part*/
        .l2_complete_w  (l2_complete_w), // complete write from MEM to L2
        .l2_complete_r  (l2_complete_r), // complete mark of reading from l2_cache
        .l2_rdy         (l2_rdy),
        .ic_en          (ic_en),
        .dc_en          (dc_en),
        // l2_tag part
        .plru           (plru),          // replace mark
        .l2_tag0_rd     (l2_tag0_rd),    // read data of tag0
        .l2_tag1_rd     (l2_tag1_rd),    // read data of tag1
        .l2_tag2_rd     (l2_tag2_rd),    // read data of tag2
        .l2_tag3_rd     (l2_tag3_rd),    // read data of tag3
        .l2_tag_wd      (l2_tag_wd),     // write data of tag0                
        // l2_data part
        .l2_data0_rd    (l2_data0_rd),   // read data of cache_data0
        .l2_data1_rd    (l2_data1_rd),   // read data of cache_data1
        .l2_data2_rd    (l2_data2_rd),   // read data of cache_data2
        .l2_data3_rd    (l2_data3_rd),   // read data of cache_data3     
        // l2_dirty part
        .l2_dirty_wd    (l2_dirty_wd),
        .l2_block0_we   (l2_block0_we),  // write signal of block0
        .l2_block1_we   (l2_block1_we),  // write signal of block1
        .l2_block2_we   (l2_block2_we),  // write signal of block2
        .l2_block3_we   (l2_block3_we),  // write signal of block3
        .l2_block0_re   (l2_block0_re),  // read signal of block0
        .l2_block1_re   (l2_block1_re),  // read signal of block1
        .l2_block2_re   (l2_block2_re),  // read signal of block2
        .l2_block3_re   (l2_block3_re),  // read signal of block3
        .l2_dirty0      (l2_dirty0),
        .l2_dirty1      (l2_dirty1),
        .l2_dirty2      (l2_dirty2), 
        .l2_dirty3      (l2_dirty3),         
        /*memory part*/
        .mem_complete_w (mem_complete_w),
        .mem_complete_r (mem_complete_r),
        .mem_rd         (mem_rd),
        .mem_wd         (mem_wd), 
        .mem_addr       (mem_addr),     // address of memory
        .mem_we         (mem_we),       // mark of writing to memory
        .mem_re         (mem_re)        // mark of reading from memory
    );
    l2_data_ram l2_data_ram(
        .clk            (clk),        // clock of L2C
        .l2_index       (l2_index),     // address of cache
        .mem_rd         (mem_rd),
        .offset         (l2_offset),
        .rd_to_l2       (rd_to_l2),
        .wd_from_mem_en (wd_from_mem_en),
        .wd_from_l1_en  (wd_from_l1_en),
        .tagcomp_hit    (l2_tagcomp_hit),   
        .l2_block0_we   (l2_block0_we),  // write signal of block0
        .l2_block1_we   (l2_block1_we),  // write signal of block1
        .l2_block2_we   (l2_block2_we),  // write signal of block2
        .l2_block3_we   (l2_block3_we),  // write signal of block3
        .l2_block0_re   (l2_block0_re),  // read signal of block0
        .l2_block1_re   (l2_block1_re),  // read signal of block1
        .l2_block2_re   (l2_block2_re),  // read signal of block2
        .l2_block3_re   (l2_block3_re),  // read signal of block3
        .l2_data0_rd    (l2_data0_rd),   // read data of cache_data0
        .l2_data1_rd    (l2_data1_rd),   // read data of cache_data1
        .l2_data2_rd    (l2_data2_rd),   // read data of cache_data2
        .l2_data3_rd    (l2_data3_rd)    // read data of cache_data3
    );
    l2_tag_ram l2_tag_ram(    
        .clk            (clk),         // clock of L2C
        .rst            (rst),   
        .l2_index       (l2_index),      // address of cache
        .l2_tag_wd      (l2_tag_wd),     // write data of tag
        .l2_block0_we   (l2_block0_we),  // write signal of block0
        .l2_block1_we   (l2_block1_we),  // write signal of block1
        .l2_block2_we   (l2_block2_we),  // write signal of block2
        .l2_block3_we   (l2_block3_we),  // write signal of block3
        .l2_block0_re   (l2_block0_re),  // read signal of block0
        .l2_block1_re   (l2_block1_re),  // read signal of block1
        .l2_block2_re   (l2_block2_re),  // read signal of block2
        .l2_block3_re   (l2_block3_re),  // read signal of block3
        .l2_dirty_wd    (l2_dirty_wd),
        .l2_tag0_rd     (l2_tag0_rd),    // read data of tag0
        .l2_tag1_rd     (l2_tag1_rd),    // read data of tag1
        .l2_tag2_rd     (l2_tag2_rd),    // read data of tag2
        .l2_tag3_rd     (l2_tag3_rd),    // read data of tag3
        .plru           (plru),          // read data of plru_field
        .l2_complete_w  (l2_complete_w), // complete write to L2
        .l2_complete_r  (l2_complete_r), // complete read from L2
        .l2_dirty0      (l2_dirty0),
        .l2_dirty1      (l2_dirty1),
        .l2_dirty2      (l2_dirty2),
        .l2_dirty3      (l2_dirty3)
    );
endmodule