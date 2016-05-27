/*
 -- ============================================================================
 -- FILE NAME   : dtag_ram.v
 -- DESCRIPTION : tag ram of dcache
 -- ----------------------------------------------------------------------------
 -- Date:2016/4/12         Coding_by:kippy   
 -- ============================================================================
*/
`timescale 1ns/1ps
/********** General header file **********/
`include "stddef.h"

module dtag_ram(
    input               clk,               // clock
    input               dc_en,
    input               dc_en_mem,
    input               data_wd_l2_en,
    input               data_wd_l2_en_mem,
    input               data_wd_dc_en,
    input      [7:0]    dc_index,          // address of cache
    input      [7:0]    dc_index_l2,       // address of cache
    input      [7:0]    dc_index_mem,      // address of cache
    input               dc_block0_we,      // write signal of block0
    input               dc_block1_we,      // write signal of block1
    input               dc_block0_we_l2,   // write signal of block0
    input               dc_block1_we_l2,   // write signal of block1
    input               dc_block0_we_mem,  // write signal of block0
    input               dc_block1_we_mem,  // write signal of block1
    input               block0_re,         // write signal of block0
    input               block1_re,         // read signal of block1
    input       [1:0]   dc_thread,
    input       [1:0]   l2_thread,
    input       [1:0]   mem_thread,
    input       [20:0]  dc_tag_wd,         // write data of tag
    input       [20:0]  dc_tag_wd_l2,      // write data of tag
    input       [20:0]  dc_tag_wd_mem,     // write data of tag
    output      [20:0]  tag0_rd,           // read data of tag0
    output      [20:0]  tag1_rd,           // read data of tag1
    output      [1:0]   thread0,
    output      [1:0]   thread1,
    output              dirty0,
    output              dirty1,
    output              lru                // read data of lru_field
    );
    reg                 lru_we;            // read / write signal of lru_field
    reg                 lru_wd;            // write data of lru_field
    reg                 lru_re;
    reg                 dirty_wd;
    reg         [7:0]   index;
    reg                 block0_we;         // write signal of block0
    reg                 block1_we;         // write signal of block1
    reg         [20:0]  tag_wd;
    reg         [1:0]   thread_wd;
    always @(*) begin
        block0_we  = `DISABLE;
        block1_we  = `DISABLE;
        if(data_wd_l2_en == `ENABLE && dc_en == `ENABLE) begin 
            thread_wd = l2_thread;
            tag_wd    = dc_tag_wd_l2;
            index     = dc_index_l2;
            block0_we = dc_block0_we_l2;
            block1_we = dc_block1_we_l2;
            dirty_wd  =  1'b0;
        end else if(data_wd_l2_en_mem == `ENABLE && dc_en_mem == `ENABLE) begin 
            thread_wd = mem_thread;
            tag_wd    = dc_tag_wd_mem;
            index     = dc_index_mem;
            block0_we = dc_block0_we_mem;
            block1_we = dc_block1_we_mem;
            dirty_wd  =  1'b0;
        end else if (data_wd_dc_en == `ENABLE) begin
            dirty_wd  =  1'b1;
            thread_wd = dc_thread;
            tag_wd    = dc_tag_wd;
            index     = dc_index;
            block0_we = dc_block0_we;
            block1_we = dc_block1_we;
        end else begin
            index     = dc_index;
        end

        if (block0_we == `ENABLE) begin 
            lru_wd = 1'b1;
            lru_we = `ENABLE;    
        end else if (block1_we == `ENABLE) begin
            lru_wd = 1'b0; 
            lru_we = `ENABLE;    
        end else begin
            lru_we = `READ;
        end
        if (block0_re == `ENABLE || block1_re == `ENABLE) begin
            lru_re = `ENABLE;
        end else begin
            lru_re = `DISABLE;
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
    ram256x1 dirty0_field(        
        .clock  (clk),
        .address(index),
        .wren   (block0_we),
        .rden   (block0_re),
        .q      (dirty0),
        .data   (dirty_wd)
        );
    ram256x1 dirty1_field(        
        .clock  (clk),
        .address(index),
        .wren   (block1_we),
        .rden   (block1_re),
        .q      (dirty1),
        .data   (dirty_wd)
        );
    // sram256x1
    ram256x1 lru_field(        
        .clock  (clk),
        .address(index),
        .wren   (lru_we),
        .rden   (lru_re),
        .q      (lru),
        .data   (lru_wd)
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
