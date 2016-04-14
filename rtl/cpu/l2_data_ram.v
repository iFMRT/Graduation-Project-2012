/*
 -- ============================================================================
 -- FILE NAME   : l2_data_ram.v
 -- DESCRIPTION : data ram of l2_cache
 -- ----------------------------------------------------------------------------
 -- Date:2016/4/12         Coding_by:kippy   
 -- ============================================================================
*/
`timescale 1ns/1ps
/********** General header file **********/
`include "ram_512x256.v"

module l2_data_ram(
    input           clk,                    // clock
    input           l2_data0_rw,            // the mark of cache_data0 write signal 
    input           l2_data1_rw,            // the mark of cache_data1 write signal 
    input           l2_data2_rw,            // the mark of cache_data2 write signal 
    input           l2_data3_rw,            // the mark of cache_data3 write signal 
    input   [8:0]   l2_index,               // address of cache  
    input   [511:0] l2_data_wd,             // write data of l2_cache
    output  [511:0] l2_data0_rd,            // read data of cache_data0
    output  [511:0] l2_data1_rd,            // read data of cache_data1
    output  [511:0] l2_data2_rd,            // read data of cache_data2
    output  [511:0] l2_data3_rd             // read data of cache_data3
    );
    // sram_512x256 
    ram_512x256 data_way0_0(
        .clock    (clk),
        .address  (l2_index),
        .wren     (l2_data0_rw),
        .q        (l2_data0_rd[255:0]),
        .data     (l2_data_wd[255:0])
        );
    // sram_512x256 
    ram_512x256 data_way0_1(
        .clock    (clk),
        .address  (l2_index),
        .wren     (l2_data0_rw),
        .q        (l2_data0_rd[511:256]),
        .data     (l2_data_wd[511:256])
        );
    // sram_512x256 
    ram_512x256 data_way1_0(
        .clock    (clk),
        .address  (l2_index),
        .wren     (l2_data1_rw),
        .q        (l2_data1_rd[255:0]),
        .data     (l2_data_wd[255:0])
        );
    // sram_512x256 
    ram_512x256 data_way1_1(
        .clock    (clk),
        .address  (l2_index),
        .wren     (l2_data1_rw),
        .q        (l2_data1_rd[511:256]),
        .data     (l2_data_wd[511:256])
        );
    // sram_512x256 
    ram_512x256 data_way2_0(
        .clock    (clk),
        .address  (l2_index),
        .wren     (l2_data2_rw),
        .q        (l2_data2_rd[255:0]),
        .data     (l2_data_wd[255:0])
        );
    // sram_512x256 
    ram_512x256 data_way2_1(
        .clock    (clk),
        .address  (l2_index),
        .wren     (l2_data2_rw),
        .q        (l2_data2_rd[511:256]),
        .data     (l2_data_wd[511:256])
        );
    // sram_512x256 
    ram_512x256 data_way3_0(
        .clock    (clk),
        .address  (l2_index),
        .wren     (l2_data3_rw),
        .q        (l2_data3_rd[255:0]),
        .data     (l2_data_wd[255:0])
        );
    // sram_512x256 
    ram_512x256 data_way3_1(
        .clock    (clk),
        .address  (l2_index),
        .wren     (l2_data3_rw),
        .q        (l2_data3_rd[511:256]),
        .data     (l2_data_wd[511:256])
        );

endmodule