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
    input              ic_en,
    input              ic_en_mem,
    input              ic_block0_we,       // the mark of cache_block0 write signal 
    input              ic_block1_we,       // the mark of cache_block1 write signal 
    input              ic_block0_we_mem,       // the mark of cache_block0 write signal 
    input              ic_block1_we_mem,       // the mark of cache_block1 write signal 
    input              block0_re,       // the mark of cache_block0 read signal 
    input              block1_re,       // the mark of cache_block1 read signal 
    input      [7:0]   ic_index_mem,    // address of cache
    input      [7:0]   ic_index_l2,     // address of cache
    input      [7:0]   ic_index,        // address of cache
    input              data_wd_l2_en,
    input              data_wd_l2_en_mem,
    input      [127:0] data_wd_l2,      // write data of l2_cache
    input      [127:0] data_wd_l2_mem,  // write data of l2_cache
    output     [127:0] data0_rd,        // read data of cache_data0
    output     [127:0] data1_rd         // read data of cache_data1
    );
    reg        [7:0]   index;
    reg        [127:0] data_wd;
    reg                block0_we,block1_we;

    always @(*) begin
        block0_we = `DISABLE;    
        block1_we = `DISABLE; 
        if (data_wd_l2_en == `ENABLE && ic_en == `ENABLE) begin
            index     = ic_index_l2;
            data_wd   = data_wd_l2;   
            block0_we = ic_block0_we;    
            block1_we = ic_block1_we; 
        end else if (data_wd_l2_en_mem == `ENABLE  && ic_en_mem == `ENABLE) begin
            index     = ic_index_mem;
            data_wd   = data_wd_l2_mem;
            block0_we = ic_block0_we_mem;    
            block1_we = ic_block1_we_mem; 
        end else begin
            index     = ic_index;
        end
    end
    
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