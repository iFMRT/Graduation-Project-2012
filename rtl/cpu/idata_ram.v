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
    input           clk,             // clock
    input           data0_rw,        // the mark of cache_data0 write signal 
    input           data1_rw,        // the mark of cache_data1 write signal 
    input   [7:0]   index,           // address of cache
    input   [127:0] data_wd_l2,         // write data of l2_cache
    input           data_wd_l2_en,
    output  [127:0] data0_rd,        // read data of cache_data0
    output  [127:0] data1_rd         // read data of cache_data1
    );
    
    reg [127:0] data_wd;

    always @(*) begin
        if(data_wd_l2_en == `ENABLE) begin 
            data_wd = data_wd_l2;
        end
    end

    // sram_256x128 
    ram_256x128 data_way0(
        .clock    (clk),
        .address  (index),
        .wren     (data0_rw),
        .q        (data0_rd),
        .data     (data_wd)
        );
    // sram_256x128 
    ram_256x128 data_way1(
        .clock    (clk),
        .address  (index),
        .wren     (data1_rw),
        .q        (data1_rd),
        .data     (data_wd)
        );

endmodule