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
    input              data0_rw,        // the mark of cache_data0 write signal 
    input              data1_rw,        // the mark of cache_data1 write signal 
    input      [7:0]   index,           // address of cache
    input      [127:0] data_wd_l2,         // write data of l2_cache
    input              data_wd_l2_en,
    output     [127:0] data0_rd,        // read data of cache_data0
    output     [127:0] data1_rd         // read data of cache_data1
    );
    
    reg [127:0] data_wd;

    always @(*) begin
        if(data_wd_l2_en == `ENABLE) begin 
            data_wd = data_wd_l2;
        end
    end

    // sram_256x32
    ram_256x32 data_way00(
        .clock    (clk),
        .address  (index),
        .wren     (data0_rw),
        .q        (data0_rd[31:0]),
        .data     (data_wd[31:0])
        );
    ram_256x32 data_way01(
        .clock    (clk),
        .address  (index),
        .wren     (data0_rw),
        .q        (data0_rd[63:32]),
        .data     (data_wd[63:32])
        );
    ram_256x32 data_way02(
        .clock    (clk),
        .address  (index),
        .wren     (data0_rw),
        .q        (data0_rd[95:64]),
        .data     (data_wd[95:64])
        );
    ram_256x32 data_way03(
        .clock    (clk),
        .address  (index),
        .wren     (data0_rw),
        .q        (data0_rd[127:96]),
        .data     (data_wd[127:96])
        );
    // sram_256x32
    ram_256x32 data_way10(
        .clock    (clk),
        .address  (index),
        .wren     (data1_rw),
        .q        (data1_rd[31:0]),
        .data     (data_wd[31:0])
        );
    ram_256x32 data_way11(
        .clock    (clk),
        .address  (index),
        .wren     (data1_rw),
        .q        (data1_rd[63:32]),
        .data     (data_wd[63:32])
        );
    ram_256x32 data_way12(
        .clock    (clk),
        .address  (index),
        .wren     (data1_rw),
        .q        (data1_rd[95:64]),
        .data     (data_wd[95:64])
        );
    ram_256x32 data_way13(
        .clock    (clk),
        .address  (index),
        .wren     (data1_rw),
        .q        (data1_rd[127:96]),
        .data     (data_wd[127:96])
        );

endmodule