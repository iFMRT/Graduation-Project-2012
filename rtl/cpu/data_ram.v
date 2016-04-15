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

module data_ram(
    input              clk,             // clock
    input              wr0_en0,
    input              wr0_en1,
    input              wr0_en2,
    input              wr0_en3,
    input              wr1_en0,
    input              wr1_en1,
    input              wr1_en2,
    input              wr1_en3,
    input      [7:0]   index,           // address of cache
    input      [127:0] data_wd_l2,      // read data of l2_cache
    // input   [127:0] data_wd_dc,
    input              data_wd_l2_en,
    input              data_wd_dc_en,    
    input      [31:0]  wr_data_m,       // ++++++++++
    input      [1:0]   offset,          // +++++++++++
    output     [127:0] data0_rd,        // read data of cache_data0
    output     [127:0] data1_rd         // read data of cache_data1
    );
    reg [127:0]  data_wd;

    always @(*) begin
        if(data_wd_l2_en == `ENABLE) begin 
            data_wd = data_wd_l2;
        end
        if (data_wd_dc_en == `ENABLE) begin
            case(offset)
                `WORD0:begin
                    data_wd[31:0]  = wr_data_m;
                end
                `WORD1:begin
                    data_wd[63:32]  = wr_data_m;
                end
                `WORD2:begin
                    data_wd[95:64]  = wr_data_m;
                end
                `WORD3:begin
                    data_wd[127:96] = wr_data_m;
                end
            endcase
        end
    end

     // sram_256x32
    ram_256x32 data_way00(
        .clock    (clk),
        .address  (index),
        .wren     (wr0_en0),
        .q        (data0_rd[31:0]),
        .data     (data_wd[31:0])
        );
    ram_256x32 data_way01(
        .clock    (clk),
        .address  (index),
        .wren     (wr0_en1),
        .q        (data0_rd[63:32]),
        .data     (data_wd[63:32])
        );
    ram_256x32 data_way02(
        .clock    (clk),
        .address  (index),
        .wren     (wr0_en2),
        .q        (data0_rd[95:64]),
        .data     (data_wd[95:64])
        );
    ram_256x32 data_way03(
        .clock    (clk),
        .address  (index),
        .wren     (wr0_en3),
        .q        (data0_rd[127:96]),
        .data     (data_wd[127:96])
        );
    // sram_256x32
    ram_256x32 data_way10(
        .clock    (clk),
        .address  (index),
        .wren     (wr1_en0),
        .q        (data1_rd[31:0]),
        .data     (data_wd[31:0])
        );
    ram_256x32 data_way11(
        .clock    (clk),
        .address  (index),
        .wren     (wr1_en1),
        .q        (data1_rd[63:32]),
        .data     (data_wd[63:32])
        );
    ram_256x32 data_way12(
        .clock    (clk),
        .address  (index),
        .wren     (wr1_en2),
        .q        (data1_rd[95:64]),
        .data     (data_wd[95:64])
        );
    ram_256x32 data_way13(
        .clock    (clk),
        .address  (index),
        .wren     (wr1_en3),
        .q        (data1_rd[127:96]),
        .data     (data_wd[127:96])
        );

endmodule