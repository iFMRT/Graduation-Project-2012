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
`include "common_defines.v"

module data_ram(
    input  wire            clk,              // clock
    input  wire    [7:0]   index,            // address of cache
    input  wire            block0_we,        // write signal of block0
    input  wire            block1_we,        // write signal of block1
    input  wire            block0_re,        // read signal of block0
    input  wire            block1_re,        // read signal of block1
    input  wire            l2_wr_dc_en,
    input  wire            data_wd_dc_en,    
    input  wire    [31:0]  dc_wd,       
    input  wire    [1:0]   dc_offset,  
    input  wire    [127:0] dc_data_wd,      
    output wire    [127:0] data0_rd,         // read data of cache_data0
    output wire    [127:0] data1_rd          // read data of cache_data1
    );
    reg        [127:0] data_wd;
    reg                wr0_en0;
    reg                wr0_en1;
    reg                wr0_en2;
    reg                wr0_en3;
    reg                wr1_en0;
    reg                wr1_en1;
    reg                wr1_en2;
    reg                wr1_en3;
    always @(*) begin
        // write signal
        wr0_en0       = `DISABLE;
        wr0_en1       = `DISABLE;
        wr0_en2       = `DISABLE;
        wr0_en3       = `DISABLE;
        wr1_en0       = `DISABLE;
        wr1_en1       = `DISABLE;
        wr1_en2       = `DISABLE;
        wr1_en3       = `DISABLE; 
        if(l2_wr_dc_en == `ENABLE) begin 
            data_wd   = dc_data_wd;
            if (block0_we == `ENABLE) begin
                wr0_en0 = `ENABLE;
                wr0_en1 = `ENABLE;
                wr0_en2 = `ENABLE;
                wr0_en3 = `ENABLE;
            end 
            if (block1_we == `ENABLE) begin
                wr1_en0 = `ENABLE;
                wr1_en1 = `ENABLE;
                wr1_en2 = `ENABLE;
                wr1_en3 = `ENABLE;
            end  
        end else if(data_wd_dc_en == `ENABLE) begin
            case(dc_offset)
                `WORD0:begin
                    data_wd[31:0]   = dc_wd;
                    if (block0_we == `ENABLE) begin
                        wr0_en0 = `ENABLE;
                    end else if (block1_we == `ENABLE) begin
                        wr1_en0 = `ENABLE;
                    end 
                end
                `WORD1:begin
                    data_wd[63:32]  = dc_wd;
                    if (block0_we == `ENABLE) begin
                        wr0_en1 = `ENABLE;
                    end else if (block1_we == `ENABLE) begin
                        wr1_en1 = `ENABLE;
                    end 
                end
                `WORD2:begin
                    data_wd[95:64]  = dc_wd;
                    if (block0_we == `ENABLE) begin
                        wr0_en2 = `ENABLE;
                    end else if (block1_we == `ENABLE) begin
                        wr1_en2 = `ENABLE;
                    end 
                end
                `WORD3:begin
                    data_wd[127:96] = dc_wd;
                    if (block0_we == `ENABLE) begin
                        wr0_en3 = `ENABLE;
                    end else if (block1_we == `ENABLE) begin
                        wr1_en3 = `ENABLE;
                    end 
                end
            endcase
        end
    end

    // sram_256x32
    ram256x32 data_way00(
        .clock    (clk),
        .address  (index),
        .wren     (wr0_en0),
        .rden     (block0_re),
        .q        (data0_rd[31:0]),
        .data     (data_wd[31:0])
        );
    ram256x32 data_way01(
        .clock    (clk),
        .address  (index),
        .wren     (wr0_en1),
        .rden     (block0_re),
        .q        (data0_rd[63:32]),
        .data     (data_wd[63:32])
        );
    ram256x32 data_way02(
        .clock    (clk),
        .address  (index),
        .wren     (wr0_en2),
        .rden     (block0_re),
        .q        (data0_rd[95:64]),
        .data     (data_wd[95:64])
        );
    ram256x32 data_way03(
        .clock    (clk),
        .address  (index),
        .wren     (wr0_en3),
        .rden     (block0_re),
        .q        (data0_rd[127:96]),
        .data     (data_wd[127:96])
        );
    // sram_256x32
    ram256x32 data_way10(
        .clock    (clk),
        .address  (index),
        .wren     (wr1_en0),
        .rden     (block1_re),
        .q        (data1_rd[31:0]),
        .data     (data_wd[31:0])
        );
    ram256x32 data_way11(
        .clock    (clk),
        .address  (index),
        .wren     (wr1_en1),
        .rden     (block1_re),
        .q        (data1_rd[63:32]),
        .data     (data_wd[63:32])
        );
    ram256x32 data_way12(
        .clock    (clk),
        .address  (index),
        .wren     (wr1_en2),
        .rden     (block1_re),
        .q        (data1_rd[95:64]),
        .data     (data_wd[95:64])
        );
    ram256x32 data_way13(
        .clock    (clk),
        .address  (index),
        .wren     (wr1_en3),
        .rden     (block1_re),
        .q        (data1_rd[127:96]),
        .data     (data_wd[127:96])
        );

endmodule