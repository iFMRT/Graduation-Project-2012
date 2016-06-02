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

module idata_ram(
    input              clk,             // clock
    input              block0_we,       // the mark of cache_block0 write signal 
    input              block1_we,       // the mark of cache_block1 write signal 
    input              block0_re,       // the mark of cache_block0 read signal 
    input              block1_re,       // the mark of cache_block1 read signal 
    input      [7:0]   index,
    input      [127:0] data_wd,
    output     [127:0] data0_rd,        // read data of cache_data0
    output     [127:0] data1_rd         // read data of cache_data1
    );
    
    // sram_256x32
    ram256x32 data_way00(
        .clock    (clk),
        .address  (index),
        .wren     (block0_we),
        .rden     (block0_re),
        .q        (data0_rd[31:0]),
        .data     (data_wd[31:0])
        );
    ram256x32 data_way01(
        .clock    (clk),
        .address  (index),
        .wren     (block0_we),
        .rden     (block0_re),
        .q        (data0_rd[63:32]),
        .data     (data_wd[63:32])
        );
    ram256x32 data_way02(
        .clock    (clk),
        .address  (index),
        .wren     (block0_we),
        .rden     (block0_re),
        .q        (data0_rd[95:64]),
        .data     (data_wd[95:64])
        );
    ram256x32 data_way03(
        .clock    (clk),
        .address  (index),
        .wren     (block0_we),
        .rden     (block0_re),
        .q        (data0_rd[127:96]),
        .data     (data_wd[127:96])
        );
    // sram_256x32
    ram256x32 data_way10(
        .clock    (clk),
        .address  (index),
        .wren     (block1_we),
        .rden     (block1_re),
        .q        (data1_rd[31:0]),
        .data     (data_wd[31:0])
        );
    ram256x32 data_way11(
        .clock    (clk),
        .address  (index),
        .wren     (block1_we),
        .rden     (block1_re),
        .q        (data1_rd[63:32]),
        .data     (data_wd[63:32])
        );
    ram256x32 data_way12(
        .clock    (clk),
        .address  (index),
        .wren     (block1_we),
        .rden     (block1_re),
        .q        (data1_rd[95:64]),
        .data     (data_wd[95:64])
        );
    ram256x32 data_way13(
        .clock    (clk),
        .address  (index),
        .wren     (block1_we),
        .rden     (block1_re),
        .q        (data1_rd[127:96]),
        .data     (data_wd[127:96])
        );

endmodule