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
    input               l2_block0_rw,      // read / write signal of block0
    input               l2_block1_rw,      // read / write signal of block1
    input               l2_block2_rw,      // read / write signal of block2
    input               l2_block3_rw,      // read / write signal of block3
    // input               l2_tag0_rw,        // read / write signal of tag0
    // input               l2_tag1_rw,        // read / write signal of tag1
    // input               l2_tag2_rw,        // read / write signal of tag2
    // input               l2_tag3_rw,        // read / write signal of tag3
    input       [8:0]   l2_index,
    // input               irq,
    // input               drq,
    // input       [8:0]   l2_index_ic,       // address of cache
    // input       [8:0]   l2_index_dc,       // address of cache
    input       [17:0]  l2_tag_wd,         // write data of tag
    // input               l2_dirty0_rw,
    // input               l2_dirty1_rw,
    // input               l2_dirty2_rw,
    // input               l2_dirty3_rw,
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
    reg                 plru_we;           // read / write signal of plru_field
    reg         [2:0]   plru_wd;           // write data of plru_field
    // reg         [8:0]   l2_index;
    always @(*) begin
        // if(irq == `ENABLE) begin
        //     l2_index = l2_index_ic;
        // end else if(drq == `ENABLE)begin 
        //     l2_index = l2_index_dc;
        // end
        if (l2_block0_rw == `WRITE) begin
            plru_wd   <= {plru[2],2'b11};
            plru_we   <= `WRITE;    
        end else if (l2_block1_rw == `WRITE) begin 
            plru_wd   <= {plru[2],2'b01};
            plru_we   <= `WRITE;    
        end else if (l2_block2_rw == `WRITE) begin  
            plru_wd   <= {1'b1,plru[1],1'b0};
            plru_we   <= `WRITE;    
        end else if (l2_block3_rw == `WRITE) begin
            plru_wd   <= {1'b0,plru[1],1'b0}; 
            plru_we   <= `WRITE;    
        end else begin
            plru_we   <= `READ;
        end
    end
    // always @(posedge clk) begin
    //     if (l2_tag0_rw == `WRITE) begin
    //         l2_complete <= `ENABLE;     
    //     end else if (l2_tag1_rw == `WRITE) begin
    //         l2_complete <= `ENABLE;   
    //     end else if (l2_tag2_rw == `WRITE) begin
    //         l2_complete <= `ENABLE;   
    //     end else if (l2_tag3_rw == `WRITE) begin
    //         l2_complete <= `ENABLE;   
    //     end else begin
    //         l2_complete <= `DISABLE;
    //     end
    // end
    always @(posedge clk) begin
        if (l2_block0_rw == `WRITE || l2_block1_rw == `WRITE || l2_block2_rw == `WRITE || l2_block3_rw == `WRITE) begin
            l2_complete <= `ENABLE;     
        end else begin
            l2_complete <= `DISABLE;
        end
    end
    // sram_256x1
    ram_512x1 dirty0_field(        
        .clock    (clk),
        .address  (l2_index),
        .wren     (l2_block0_rw),
        .q        (l2_dirty0),
        .data     (l2_dirty_wd)
        );
    // sram_512x1
    ram_512x1 dirty1_field(        
        .clock    (clk),
        .address  (l2_index),
        .wren     (l2_block1_rw),
        .q        (l2_dirty1),
        .data     (l2_dirty_wd)
        );
        // sram_512x1
    ram_512x1 dirty2_field(        
        .clock    (clk),
        .address  (l2_index),
        .wren     (l2_block2_rw),
        .q        (l2_dirty2),
        .data     (l2_dirty_wd)
        );
    // sram_512x1
    ram_512x1 dirty3_field(        
        .clock    (clk),
        .address  (l2_index),
        .wren     (l2_block3_rw),
        .q        (l2_dirty3),
        .data     (l2_dirty_wd)
        );
    // sram_512x1
    ram_512x1 plru0_field(        
        .clock    (clk),
        .address  (l2_index),
        .wren     (plru_we),
        .q        (plru[0]),
        .data     (plru_wd[0])
        );
    ram_512x1 plru1_field(        
        .clock    (clk),
        .address  (l2_index),
        .wren     (plru_we),
        .q        (plru[1]),
        .data     (plru_wd[1])
        );
    ram_512x1 plru2_field(        
        .clock    (clk),
        .address  (l2_index),
        .wren     (plru_we),
        .q        (plru[2]),
        .data     (plru_wd[2])
        );
    // sram_512x18
    ram_512x18 tag_way0(
        .clock    (clk),
        .address  (l2_index),
        .wren     (l2_block0_rw),
        .q        (l2_tag0_rd),
        .data     (l2_tag_wd)
        );
    // sram_512x18
    ram_512x18 tag_way1(
        .clock    (clk),
        .address  (l2_index),
        .wren     (l2_block1_rw),
        .q        (l2_tag1_rd),
        .data     (l2_tag_wd)
        );
    // sram_512x18
    ram_512x18 tag_way2(
        .clock    (clk),
        .address  (l2_index),
        .wren     (l2_block2_rw),
        .q        (l2_tag2_rd),
        .data     (l2_tag_wd)
        );
    // sram_512x18
    ram_512x18 tag_way3(
        .clock    (clk),
        .address  (l2_index),
        .wren     (l2_block3_rw),
        .q        (l2_tag3_rd),
        .data     (l2_tag_wd)
        );

endmodule