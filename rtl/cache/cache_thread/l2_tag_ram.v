/*
 -- ============================================================================
 -- FILE NAME   : l2_tag_ram.v
 -- DESCRIPTION : tag_ram of l2cache
 -- ----------------------------------------------------------------------------
 -- Date:2016/4/12         Coding_by:kippy   
 -- ============================================================================
*/
`timescale 1ns/1ps
/********** General header file **********/
`include "stddef.h"

module l2_tag_ram(    
    input               clk,               // clock
    input               rst,               // clock
    input               wd_from_l1_en,
    input               wd_from_l1_en_mem,
    input               wd_from_mem_en,
    input               l2_block0_we_mem,    // write signal of block0
    input               l2_block1_we_mem,    // write signal of block1
    input               l2_block2_we_mem,    // write signal of block2
    input               l2_block3_we_mem,    // write signal of block3
    input               l2_block0_we_l2,    // write signal of block0
    input               l2_block1_we_l2,    // write signal of block1
    input               l2_block2_we_l2,    // write signal of block2
    input               l2_block3_we_l2,    // write signal of block3
    input               l2_block0_re,      // read signal of block0
    input               l2_block1_re,      // read signal of block1
    input               l2_block2_re,      // read signal of block2
    input               l2_block3_re,      // read signal of block3
    input       [8:0]   l2_index_mem,
    input       [8:0]   l2_index_l2,       // address of cache     
    input       [17:0]  l2_tag_wd_l2,      // write data of tag
    input       [17:0]  l2_tag_wd_mem,     // write data of tag
    input       [1:0]   l2_thread,
    input       [1:0]   mem_thread,
    output      [17:0]  l2_tag0_rd,        // read data of tag0
    output      [17:0]  l2_tag1_rd,        // read data of tag1
    output      [17:0]  l2_tag2_rd,        // read data of tag2
    output      [17:0]  l2_tag3_rd,        // read data of tag3
    output      [2:0]   plru,              // read data of plru_field
    output reg          l2_complete_w,     // complete write to L2
    output reg          l2_complete_r,     // complete read from L2
    output      [1:0]   l2_thread0,        // thread signal of L2 
    output      [1:0]   l2_thread1,        // thread signal of L2 
    output      [1:0]   l2_thread2,        // thread signal of L2 
    output      [1:0]   l2_thread3,        // thread signal of L2 
    output              l2_dirty0,         // dirty signal of L2 
    output              l2_dirty1,         // dirty signal of L2 
    output              l2_dirty2,         // dirty signal of L2 
    output              l2_dirty3          // dirty signal of L2 
    );
    reg         [17:0]  l2_tag_wd;
    reg         [8:0]   l2_index;
    reg         [1:0]   l2_thread_wd;
    reg                 l2_block0_we;
    reg                 l2_block1_we;
    reg                 l2_block2_we;
    reg                 l2_block3_we;
    reg                 l2_dirty_wd;
    reg                 plru_re; 
    reg                 plru_we;           // read / write signal of plru_field
    reg         [2:0]   plru_wd;           // write data of plru_field
    reg                 i,next_i;
    always @(*) begin
        if (l2_block0_we == `ENABLE) begin
            plru_wd[1:0] = 2'b11;
            plru_we      = `ENABLE;    
        end else if (l2_block1_we == `ENABLE) begin 
            plru_wd[1:0] = 2'b01;
            plru_we      = `ENABLE;    
        end else if (l2_block2_we == `ENABLE) begin  
            plru_wd[2]   = 1'b1;
            plru_wd[0]   = 1'b0;
            plru_we      = `ENABLE;    
        end else if (l2_block3_we == `ENABLE) begin
            plru_wd[2]   = 1'b0;
            plru_wd[0]   = 1'b0; 
            plru_we      = `ENABLE;    
        end else begin
            plru_we      = `DISABLE;
        end
        if (l2_block0_re == `ENABLE || l2_block1_re == `ENABLE 
            || l2_block2_re == `ENABLE || l2_block3_re == `ENABLE) begin
            plru_re      = `ENABLE;
        end else begin
            plru_re      = `DISABLE;
        end
        if (i == 1'b1) begin
            next_i = 1'b0;
        end else begin
            next_i = 1'b1;
        end

        l2_block0_we = `DISABLE;
        l2_block1_we = `DISABLE;
        l2_block2_we = `DISABLE;
        l2_block3_we = `DISABLE;
        if (wd_from_l1_en == `ENABLE) begin
            l2_block0_we = l2_block0_we_l2;
            l2_block1_we = l2_block1_we_l2;
            l2_block2_we = l2_block2_we_l2;
            l2_block3_we = l2_block3_we_l2;
            l2_index     = l2_index_l2;
            l2_thread_wd = l2_thread;
            l2_tag_wd    = l2_tag_wd_l2;
            l2_dirty_wd  = 1'b1;
        end else if (wd_from_mem_en == `ENABLE || wd_from_l1_en_mem == `ENABLE) begin
            l2_dirty_wd  =  1'b0;
            l2_block0_we = l2_block0_we_mem;
            l2_block1_we = l2_block1_we_mem;
            l2_block2_we = l2_block2_we_mem;
            l2_block3_we = l2_block3_we_mem;
            l2_tag_wd    = l2_tag_wd_mem;
            l2_index     = l2_index_mem;
            l2_thread_wd = mem_thread;
        end else begin
            l2_index     = l2_index_l2;
        end
    end

    always @(posedge clk) begin
        if (rst == `ENABLE) begin
            i <= 1'b0;
            l2_complete_w <= `DISABLE;
            l2_complete_r <= `DISABLE;
        end else begin
            i <= next_i;
            l2_complete_w <= `DISABLE;
            l2_complete_r <= `DISABLE;
            if (l2_block0_re == `ENABLE || l2_block1_re == `ENABLE 
                || l2_block2_re == `ENABLE || l2_block3_re == `ENABLE) begin
                if (next_i == 1'b1) begin
                    l2_complete_r <= `ENABLE;
                end 
            end 
            if (l2_block0_we == `ENABLE || l2_block1_we == `ENABLE 
                || l2_block2_we == `ENABLE || l2_block3_we == `ENABLE) begin
                if (next_i == 1'b1) begin
                    l2_complete_w <= `ENABLE;
                end 
            end 
        end                
    end
    // sram_512x2
    ram512x2 thread0_field(        
        .clock    (clk),
        .address  (l2_index),
        .wren     (l2_block0_we),
        .rden     (l2_block0_re),
        .q        (l2_thread0),
        .data     (l2_thread_wd)
        );
    // sram_512x2
    ram512x2 thread1_field(        
        .clock    (clk),
        .address  (l2_index),
        .wren     (l2_block1_we),
        .rden     (l2_block1_re),
        .q        (l2_thread1),
        .data     (l2_thread_wd)
        );
        // sram_512x2
    ram512x2 thread2_field(        
        .clock    (clk),
        .address  (l2_index),
        .wren     (l2_block2_we),
        .rden     (l2_block2_re),
        .q        (l2_thread2),
        .data     (l2_thread_wd)
        );
    // sram_512x2
    ram512x2 thread3_field(        
        .clock    (clk),
        .address  (l2_index),
        .wren     (l2_block3_we),
        .rden     (l2_block3_re),
        .q        (l2_thread3),
        .data     (l2_thread_wd)
        );
    // sram_512x1
    ram512x1 dirty0_field(        
        .clock    (clk),
        .address  (l2_index),
        .wren     (l2_block0_we),
        .rden     (l2_block0_re),
        .q        (l2_dirty0),
        .data     (l2_dirty_wd)
        );
    // sram_512x1
    ram512x1 dirty1_field(        
        .clock    (clk),
        .address  (l2_index),
        .wren     (l2_block1_we),
        .rden     (l2_block1_re),
        .q        (l2_dirty1),
        .data     (l2_dirty_wd)
        );
        // sram_512x1
    ram512x1 dirty2_field(        
        .clock    (clk),
        .address  (l2_index),
        .wren     (l2_block2_we),
        .rden     (l2_block2_re),
        .q        (l2_dirty2),
        .data     (l2_dirty_wd)
        );
    // sram_512x1
    ram512x1 dirty3_field(        
        .clock    (clk),
        .address  (l2_index),
        .wren     (l2_block3_we),
        .rden     (l2_block3_re),
        .q        (l2_dirty3),
        .data     (l2_dirty_wd)
        );
    // sram_512x1
    ram512x1 plru0_field(        
        .clock    (clk),
        .address  (l2_index),
        .wren     (plru_we),
        .rden     (plru_re),
        .q        (plru[0]),
        .data     (plru_wd[0])
        );
    ram512x1 plru1_field(        
        .clock    (clk),
        .address  (l2_index),
        .wren     (plru_we),
        .rden     (plru_re),
        .q        (plru[1]),
        .data     (plru_wd[1])
        );
    ram512x1 plru2_field(        
        .clock    (clk),
        .address  (l2_index),
        .wren     (plru_we),
        .rden     (plru_re),
        .q        (plru[2]),
        .data     (plru_wd[2])
        );
    // sram_512x18
    ram512x18 tag_way0(
        .clock    (clk),
        .address  (l2_index),
        .wren     (l2_block0_we),
        .rden     (l2_block0_re),
        .q        (l2_tag0_rd),
        .data     (l2_tag_wd)
        );
    // sram_512x18
    ram512x18 tag_way1(
        .clock    (clk),
        .address  (l2_index),
        .wren     (l2_block1_we),
        .rden     (l2_block1_re),
        .q        (l2_tag1_rd),
        .data     (l2_tag_wd)
        );
    // sram_512x18
    ram512x18 tag_way2(
        .clock    (clk),
        .address  (l2_index),
        .wren     (l2_block2_we),
        .rden     (l2_block2_re),
        .q        (l2_tag2_rd),
        .data     (l2_tag_wd)
        );
    // sram_512x18
    ram512x18 tag_way3(
        .clock    (clk),
        .address  (l2_index),
        .wren     (l2_block3_we),
        .rden     (l2_block3_re),
        .q        (l2_tag3_rd),
        .data     (l2_tag_wd)
        );

endmodule