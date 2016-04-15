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
    input               clk,                     // Clock
    input               clk_2,                   // clock of L2C
    input               rst,                     // Asynchronous Reset
    /*l2_cache part*/
    input       [31:0]  l2_addr_ic,  
    input       [31:0]  l2_addr_dc,
    input               l2_cache_rw_ic,
    input               l2_cache_rw_dc, 
    output              l2_busy,                 // busy mark of L2C        
    output              l2_miss_stall,
    output              l2_rdy,
    output              l2_complete,             // complete write from MEM to L2
    /*dcache part*/
    input               drq, 
    input               dc_rw_en, 
    input               complete_dc, 
    /*icache part*/
    input               irq,
    input               ic_rw_en,                // write enable signal
    input               complete_ic,             // complete write from L2 to L1 
    /*l1_cache part*/
    input       [127:0] rd_to_l2, 
    output      [127:0] data_wd_l2,              // write data to L1    
    output              data_wd_l2_en,   
    output reg          mem_wr_dc_en,       
    output reg          mem_wr_ic_en,
    /*memory part*/
    input               mem_complete,
    input       [511:0] mem_rd,
    output      [511:0] mem_wd,
    output      [25:0]  mem_addr,                // address of memory
    output              mem_rw                   // read / write signal of memory
    ); 
    /*cache part*/
    wire             l2_tag0_rw;    // read / write signal of tag0
    wire             l2_tag1_rw;    // read / write signal of tag1
    wire             l2_tag2_rw;    // read / write signal of tag0
    wire             l2_tag3_rw;    // read / write signal of tag1
    wire     [17:0]  l2_tag_wd;     // write data of tag
    // wire             l2_data0_rw;   // the mark of cache_data0 write signal 
    // wire             l2_data1_rw;   // the mark of cache_data1 write signal 
    // wire             l2_data2_rw;   // the mark of cache_data2 write signal 
    // wire             l2_data3_rw;   // the mark of cache_data3 write signal 
    wire     [8:0]   l2_index;
    wire     [1:0]   l2_offset;
    // complete write from L2 to L1 
    // l2_tag_ram part
    wire     [17:0]  l2_tag0_rd;    // read data of tag0
    wire     [17:0]  l2_tag1_rd;    // read data of tag1
    wire     [17:0]  l2_tag2_rd;    // read data of tag2
    wire     [17:0]  l2_tag3_rd;    // read data of tag3
    wire     [2:0]   plru;          // read data of tag
    // l2_data_ram
    wire             wd_from_l1_en;
    wire             wd_from_mem_en;
    wire             wr0_en0;
    wire             wr0_en1;
    wire             wr0_en2;
    wire             wr0_en3;
    wire             wr1_en0;
    wire             wr1_en1;
    wire             wr1_en2;
    wire             wr1_en3;
    wire             wr2_en0;
    wire             wr2_en1;
    wire             wr2_en2;
    wire             wr2_en3;
    wire             wr3_en0;
    wire             wr3_en1;
    wire             wr3_en2;
    wire             wr3_en3;
    wire     [511:0] l2_data_wd;     // write data of l2_cache
    wire     [511:0] l2_data0_rd;    // read data of cache_data0
    wire     [511:0] l2_data1_rd;    // read data of cache_data1
    wire     [511:0] l2_data2_rd;    // read data of cache_data2
    wire     [511:0] l2_data3_rd;    // read data of cache_data3 
    // l2_dirty
    wire             l2_dirty_wd;
    wire             l2_dirty0_rw;
    wire             l2_dirty1_rw;
    wire             l2_dirty2_rw;
    wire             l2_dirty3_rw;
    wire             l2_dirty0;
    wire             l2_dirty1;
    wire             l2_dirty2;
    wire             l2_dirty3;
    // l2_cache
l2_cache_ctrl l2_cache_ctrl(
        .clk            (clk),           // clock of L2C
        .rst            (rst),           // reset
        /* CPU part */
        .l2_addr_ic     (l2_addr_ic),    // address of fetching instruction
        .l2_cache_rw_ic (l2_cache_rw_ic),// read / write signal of CPU
        .l2_addr_dc     (l2_addr_dc),    // address of fetching instruction
        .l2_cache_rw_dc (l2_cache_rw_dc),// read / write signal of CPU
        .l2_miss_stall  (l2_miss_stall), // stall caused by l2_miss
        .l2_index       (l2_index),
        .offset         (l2_offset), 
        /*cache part*/
        .irq            (irq),           // icache request
        .drq            (drq),
        .ic_rw_en       (ic_rw_en),      // write enable signal of icache
        .dc_rw_en       (dc_rw_en),
        .complete_ic    (complete_ic),   // complete write from L2 to L1
        .complete_dc    (complete_dc),
        // .data_rd        (data_rd),       // read data from L1C       
        .data_wd_l2     (data_wd_l2),    // write data to L1C       
        .data_wd_l2_en  (data_wd_l2_en), 
        .wd_from_mem_en (wd_from_mem_en),
        .wd_from_l1_en  (wd_from_l1_en),
        .mem_wr_dc_en   (mem_wr_dc_en), 
        .mem_wr_ic_en   (mem_wr_ic_en),
        /*l2_cache part*/
        .l2_complete    (l2_complete),   // complete write from MEM to L2
        .l2_rdy         (l2_rdy),
        .l2_busy        (l2_busy),
        // l2_tag part
        .plru           (plru),          // replace mark
        .l2_tag0_rd     (l2_tag0_rd),    // read data of tag0
        .l2_tag1_rd     (l2_tag1_rd),    // read data of tag1
        .l2_tag2_rd     (l2_tag2_rd),    // read data of tag2
        .l2_tag3_rd     (l2_tag3_rd),    // read data of tag3
        .l2_tag0_rw     (l2_tag0_rw),    // read / write signal of tag0
        .l2_tag1_rw     (l2_tag1_rw),    // read / write signal of tag1
        .l2_tag2_rw     (l2_tag2_rw),    // read / write signal of tag0
        .l2_tag3_rw     (l2_tag3_rw),    // read / write signal of tag1
        .l2_tag_wd      (l2_tag_wd),     // write data of tag0                
        // l2_data part
        .l2_data0_rd    (l2_data0_rd),   // read data of cache_data0
        .l2_data1_rd    (l2_data1_rd),   // read data of cache_data1
        .l2_data2_rd    (l2_data2_rd),   // read data of cache_data2
        .l2_data3_rd    (l2_data3_rd),   // read data of cache_data3
        // .l2_data_wd     (l2_data_wd),           
        // .l2_data0_rw    (l2_data0_rw),   // the mark of cache_data0 write signal 
        // .l2_data1_rw    (l2_data1_rw),   // the mark of cache_data1 write signal 
        // .l2_data2_rw    (l2_data2_rw),   // the mark of cache_data2 write signal 
        // .l2_data3_rw    (l2_data3_rw),   // the mark of cache_data3 write signal         
        .wr0_en0        (wr0_en0),   // the mark of cache_data0 write signal 
        .wr0_en1        (wr0_en1),   // the mark of cache_data1 write signal 
        .wr0_en2        (wr0_en2),   // the mark of cache_data2 write signal 
        .wr0_en3        (wr0_en3),   // the mark of cache_data3 write signal         
        .wr1_en0        (wr1_en0),
        .wr1_en1        (wr1_en1),
        .wr1_en2        (wr1_en2),
        .wr1_en3        (wr1_en3),
        .wr2_en0        (wr2_en0),
        .wr2_en1        (wr2_en1),
        .wr2_en2        (wr2_en2),
        .wr2_en3        (wr2_en3), 
        .wr3_en0        (wr3_en0),
        .wr3_en1        (wr3_en1),
        .wr3_en2        (wr3_en2), 
        .wr3_en3        (wr3_en3),
        // l2_dirty part
        .l2_dirty_wd    (l2_dirty_wd),
        .l2_dirty0_rw   (l2_dirty0_rw),
        .l2_dirty1_rw   (l2_dirty1_rw),
        .l2_dirty2_rw   (l2_dirty2_rw),
        .l2_dirty3_rw   (l2_dirty3_rw),
        .l2_dirty0      (l2_dirty0),
        .l2_dirty1      (l2_dirty1),
        .l2_dirty2      (l2_dirty2), 
        .l2_dirty3      (l2_dirty3),         
        /*memory part*/
        .mem_complete   (mem_complete),
        // .mem_rd         (mem_rd),
        .mem_wd         (mem_wd), 
        .mem_addr       (mem_addr),     // address of memory
        .mem_rw         (mem_rw)        // read / write signal of memory
    );
    l2_data_ram l2_data_ram(
        .clk            (clk_2),       // clock of L2C
        // .l2_data0_rw    (l2_data0_rw),   // the mark of cache_data0 write signal 
        // .l2_data1_rw    (l2_data1_rw),   // the mark of cache_data1 write signal 
        // .l2_data2_rw    (l2_data2_rw),   // the mark of cache_data2 write signal 
        // .l2_data3_rw    (l2_data3_rw),   // the mark of cache_data3 write signal 
        .l2_index       (l2_index),      // address of cache
        .mem_rd         (mem_rd),
        .offset         (l2_offset),
        .rd_to_l2       (rd_to_l2),
        .wd_from_mem_en (wd_from_mem_en),
        .wd_from_l1_en  (wd_from_l1_en),
        .wr0_en0        (wr0_en0),   // the mark of cache_data0 write signal 
        .wr0_en1        (wr0_en1),   // the mark of cache_data1 write signal 
        .wr0_en2        (wr0_en2),   // the mark of cache_data2 write signal 
        .wr0_en3        (wr0_en3),   // the mark of cache_data3 write signal         
        .wr1_en0        (wr1_en0),
        .wr1_en1        (wr1_en1),
        .wr1_en2        (wr1_en2),
        .wr1_en3        (wr1_en3),
        .wr2_en0        (wr2_en0),
        .wr2_en1        (wr2_en1),
        .wr2_en2        (wr2_en2),
        .wr2_en3        (wr2_en3), 
        .wr3_en0        (wr3_en0),
        .wr3_en1        (wr3_en1),
        .wr3_en2        (wr3_en2), 
        .wr3_en3        (wr3_en3),
        // .l2_data_wd     (l2_data_wd),    // write data of l2_cache
        .l2_data0_rd    (l2_data0_rd),   // read data of cache_data0
        .l2_data1_rd    (l2_data1_rd),   // read data of cache_data1
        .l2_data2_rd    (l2_data2_rd),   // read data of cache_data2
        .l2_data3_rd    (l2_data3_rd)    // read data of cache_data3
    );
    l2_tag_ram l2_tag_ram(    
        .clk            (clk_2),       // clock of L2C
        .l2_tag0_rw     (l2_tag0_rw),    // read / write signal of tag0
        .l2_tag1_rw     (l2_tag1_rw),    // read / write signal of tag1
        .l2_tag2_rw     (l2_tag2_rw),    // read / write signal of tag2
        .l2_tag3_rw     (l2_tag3_rw),    // read / write signal of tag3
        .l2_index       (l2_index),      // address of cache
        .l2_tag_wd      (l2_tag_wd),     // write data of tag
        .l2_dirty0_rw   (l2_dirty0_rw),
        .l2_dirty1_rw   (l2_dirty1_rw),
        .l2_dirty2_rw   (l2_dirty2_rw),
        .l2_dirty3_rw   (l2_dirty3_rw),
        .l2_dirty_wd    (l2_dirty_wd),
        .l2_tag0_rd     (l2_tag0_rd),    // read data of tag0
        .l2_tag1_rd     (l2_tag1_rd),    // read data of tag1
        .l2_tag2_rd     (l2_tag2_rd),    // read data of tag2
        .l2_tag3_rd     (l2_tag3_rd),    // read data of tag3
        .plru           (plru),          // read data of plru_field
        .l2_complete    (l2_complete),   // complete write from L2 to L1
        .l2_dirty0      (l2_dirty0),
        .l2_dirty1      (l2_dirty1),
        .l2_dirty2      (l2_dirty2),
        .l2_dirty3      (l2_dirty3)
    );
endmodule