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
    input               clk,            // clock
    // input               tag0_rw,        // read / write signal of tag0
    // input               tag1_rw,        // read / write signal of tag1
    input       [7:0]   index,          // address of cache
    input               block0_rw,      // read / write signal of block0
    input               block1_rw,      // read / write signal of block1
    // input               dirty0_rw,
    // input               dirty1_rw,
    input               dirty_wd,
    input       [20:0]  tag_wd,         // write data of tag
    output      [20:0]  tag0_rd,        // read data of tag0
    output      [20:0]  tag1_rd,        // read data of tag1
    output              dirty0,
    output              dirty1,
    output              lru,            // read data of lru_field
    output  reg         complete        // complete write from L2 to L1
    );
    reg                 lru_we;         // read / write signal of lru_field
    reg                 lru_wd;         // write data of lru_field

    always @(*) begin
        if (block0_rw == `WRITE) begin 
            lru_wd   <= 1'b1;
            lru_we   <= `WRITE;    
        end else if (block1_rw == `WRITE) begin
            lru_wd   <= 1'b0; 
            lru_we   <= `WRITE;    
        end else begin
            lru_we   <= `READ;
        end
    end
    always @(posedge clk) begin
        if (block0_rw == `WRITE) begin
            complete <= `ENABLE;      
        end else if (block1_rw == `WRITE) begin
            complete <= `ENABLE;   
        end else begin
            complete <= `DISABLE;
        end
    end
    // sram_256x1
    ram_256x1 dirty0_field(        
        .clock  (clk),
        .address(index),
        .wren   (block0_rw),
        .q      (dirty0),
        .data   (dirty_wd)
        );
    // sram_256x1
    ram_256x1 dirty1_field(        
        .clock  (clk),
        .address(index),
        .wren   (block1_rw),
        .q      (dirty1),
        .data   (dirty_wd)
        );
    // sram_256x1
    ram_256x1 lru_field(        
        .clock  (clk),
        .address(index),
        .wren   (lru_we),
        .q      (lru),
        .data   (lru_wd)
        );
    // sram_256x21
    ram_256x21 tag_way0(
        .clock  (clk),
        .address(index),
        .wren   (block0_rw),
        .q      (tag0_rd),
        .data   (tag_wd)
        );
    // sram_256x21
    ram_256x21 tag_way1(
        .clock  (clk),
        .address(index),
        .wren   (block1_rw),
        .q      (tag1_rd),
        .data   (tag_wd)
        );

endmodule
