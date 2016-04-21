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
    input               clk,            // clock
    input               block0_we,      // write signal of block0
    input               block1_we,      // write signal of block1
    input               block0_re,      // read signal of block0
    input               block1_re,      // read signal of block1
    input       [7:0]   index,          // address of cache
    input       [20:0]  tag_wd,         // write data of tag
    output      [20:0]  tag0_rd,        // read data of tag0
    output      [20:0]  tag1_rd,        // read data of tag1
    output              lru,            // read data of lru_field
    output  reg         complete        // complete write from L2 to L1
    );
    reg                 lru_we;         // read / write signal of lru_field
    reg                 lru_wd;         // write data of lru_field
    reg                 lru_re;
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
    end
    always @(posedge clk) begin
        if (block0_we == `ENABLE) begin
            complete <= `ENABLE;      
        end else if (block1_we == `ENABLE) begin
            complete <= `ENABLE;   
        end else begin
            complete <= `DISABLE;
        end
    end

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