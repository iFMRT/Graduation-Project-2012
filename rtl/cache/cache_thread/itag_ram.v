/*
 -- ============================================================================
 -- FILE NAME   : itag_ram.v
 -- DESCRIPTION : tag ram of icache
 -- ----------------------------------------------------------------------------
 -- Date:2016/4/12         Coding_by:kippy   
 -- ============================================================================
*/
`timescale 1ns/1ps
/********** General header file **********/
`include "stddef.h"

module itag_ram(
    input               clk,                // clock
    input               ic_en,
    input               ic_en_mem,
    input               data_wd_l2_en,
    input               data_wd_l2_en_mem,
    input               ic_block0_we,       // the mark of cache_block0 write signal 
    input               ic_block1_we,       // the mark of cache_block1 write signal 
    input               ic_block0_we_mem,   // the mark of cache_block0 write signal 
    input               ic_block1_we_mem,   // the mark of cache_block1 write signal 
    input               block0_re,          // read signal of block0
    input               block1_re,          // read signal of block1
    input       [1:0]   l2_thread,
    input       [1:0]   mem_thread,
    input       [7:0]   ic_index_mem,       // address of cache
    input       [7:0]   ic_index_l2,        // address of cache
    input       [7:0]   ic_index,           // address of cache
    input       [20:0]  ic_tag_wd,          // write data of tag
    input       [20:0]  ic_tag_wd_mem,      // write data of tag
    output      [20:0]  tag0_rd,            // read data of tag0
    output      [20:0]  tag1_rd,            // read data of tag1
    output      [1:0]   thread0,
    output      [1:0]   thread1,
    output              lru                 // read data of lru_field
    );
    reg                 lru_we;             // read / write signal of lru_field
    reg                 lru_wd;             // write data of lru_field
    reg                 lru_re;
    reg          [20:0] tag_wd;
    reg          [7:0]  index;
    reg                 block0_we;
    reg                 block1_we;
    reg          [1:0]  thread_wd;
    always @(*) begin
        if (block0_we == `ENABLE) begin 
            lru_wd   <= 1'b1;
            lru_we   <= `ENABLE;    
        end else if (block1_we == `ENABLE) begin
            lru_wd   <= 1'b0; 
            lru_we   <= `ENABLE;    
        end else begin
            lru_we   <= `READ;
        end
        if (block0_re == `ENABLE || block1_re == `ENABLE) begin
            lru_re = `ENABLE;
        end else begin
            lru_re = `DISABLE;
        end
        block0_we = `DISABLE;    
        block1_we = `DISABLE; 
        if (data_wd_l2_en == `ENABLE && ic_en == `ENABLE) begin
            thread_wd = l2_thread;
            index     = ic_index_l2;
            tag_wd    = ic_tag_wd;   
            block0_we = ic_block0_we;    
            block1_we = ic_block1_we; 
        end else if (data_wd_l2_en_mem == `ENABLE  && ic_en_mem == `ENABLE) begin
            thread_wd = mem_thread;
            index     = ic_index_mem;
            tag_wd    = ic_tag_wd_mem;
            block0_we = ic_block0_we_mem;    
            block1_we = ic_block1_we_mem; 
        end else begin
            index     = ic_index;
        end
    end

    // sram256x1
    ram256x2 thread0_field(        
        .clock  (clk),
        .address(index),
        .wren   (block0_we),
        .rden   (block0_re),
        .q      (thread0),
        .data   (thread_wd)
        );
    ram256x2 thread1_field(        
        .clock  (clk),
        .address(index),
        .wren   (block1_we),
        .rden   (block1_re),
        .q      (thread1),
        .data   (thread_wd)
        );
    // sram_256x1
    ram256x1 lru_field(        
        .address(index),
        .clock  (clk),
        .data   (lru_wd),
        .rden   (lru_re),
        .wren   (lru_we),
        .q      (lru)   
        );
    // sram_256x21
    ram256x21 tag_way0(
        .clock  (clk),
        .address(index),
        .wren   (block0_we),
        .rden   (block0_re),
        .q      (tag0_rd),
        .data   (tag_wd)
        );
    // sram_256x21
    ram256x21 tag_way1(
        .clock  (clk),
        .address(index),
        .wren   (block1_we),
        .rden   (block1_re),
        .q      (tag1_rd),
        .data   (tag_wd)
        );
endmodule