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
    input               data_wd_dc_en,
    input               l2_wr_dc_en,
    input      [7:0]    index,             // address of cache
    input               block0_we,         // write signal of block0
    input               block1_we,         // write signal of block1
    input               block0_re,         // write signal of block0
    input               block1_re,         // read signal of block1
    input       [1:0]   thread_wd,
    input       [20:0]  tag_wd,            // write data of tag
    output      [20:0]  tag0_rd,           // read data of tag0
    output      [20:0]  tag1_rd,           // read data of tag1
    output      [1:0]   thread0,
    output      [1:0]   thread1,
    output              dirty0,
    output              dirty1,
    output reg          w_complete,
    output              lru                // read data of lru_field
    );
    reg                 lru_we;            // read / write signal of lru_field
    reg                 lru_wd;            // write data of lru_field
    reg                 lru_re;
    reg                 dirty_wd;
    always @(*) begin 
        if(l2_wr_dc_en == `ENABLE) begin 
            dirty_wd  =  1'b0;
        end else if (data_wd_dc_en == `ENABLE) begin
            dirty_wd  =  1'b1;
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
    always @(posedge clk) begin
        if (block0_we == `ENABLE) begin
            w_complete <= `ENABLE;      
        end else if (block1_we == `ENABLE) begin
            w_complete <= `ENABLE;   
        end else begin
            w_complete <= `DISABLE;
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
