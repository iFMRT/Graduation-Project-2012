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
    input               l2_block0_we,      // write signal of block0
    input               l2_block1_we,      // write signal of block1
    input               l2_block2_we,      // write signal of block2
    input               l2_block3_we,      // write signal of block3
    input               l2_block0_re,      // read signal of block0
    input               l2_block1_re,      // read signal of block1
    input               l2_block2_re,      // read signal of block2
    input               l2_block3_re,      // read signal of block3
    input       [8:0]   l2_index,
    input       [17:0]  l2_tag_wd,         // write data of tag
    input               l2_dirty_wd,
    output      [17:0]  l2_tag0_rd,        // read data of tag0
    output      [17:0]  l2_tag1_rd,        // read data of tag1
    output      [17:0]  l2_tag2_rd,        // read data of tag2
    output      [17:0]  l2_tag3_rd,        // read data of tag3
    output      [2:0]   plru,              // read data of plru_field
    output reg          l2_complete,       // complete write from L2 to L1
    output              l2_dirty0,         // dirty signal of L2 
    output              l2_dirty1,         // dirty signal of L2 
    output              l2_dirty2,         // dirty signal of L2 
    output              l2_dirty3          // dirty signal of L2 
    );
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
    end

    always @(posedge clk) begin
        if (rst == `ENABLE) begin
            i <= 1'b0;
            l2_complete <= `DISABLE;
        end else begin
            i <= next_i;
            if (next_i == 1'b1) begin
                if (l2_block0_we == `ENABLE || l2_block1_we == `ENABLE 
                    || l2_block2_we == `ENABLE || l2_block3_we == `ENABLE) begin
                    l2_complete <= `ENABLE;
                end
            end else begin
                l2_complete <= `DISABLE;
            end 
        end                
    end
    // sram_256x1
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