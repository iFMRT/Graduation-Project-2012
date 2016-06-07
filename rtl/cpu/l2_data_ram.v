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
`include "common_defines.v"

module l2_data_ram(
    input  wire            clk,             // clock
    input  wire    [8:0]   l2_index,    
    input  wire    [511:0] l2_data_wd_mem,          
    input  wire    [1:0]   offset,
    input  wire    [127:0] rd_to_l2,       
    input  wire            mem_wr_l2_en,
    input  wire            wd_from_l1_en,
    input  wire            l2_block0_we,    // write signal of block0
    input  wire            l2_block1_we,    // write signal of block1
    input  wire            l2_block2_we,    // write signal of block2
    input  wire            l2_block3_we,    // write signal of block3k3
    input  wire            l2_block0_re,    // read signal of block0
    input  wire            l2_block1_re,    // read signal of block1
    input  wire            l2_block2_re,    // read signal of block2
    input  wire            l2_block3_re,    // read signal of block3
    output wire    [511:0] l2_data0_rd,     // read data of cache_data0
    output wire    [511:0] l2_data1_rd,     // read data of cache_data1
    output wire    [511:0] l2_data2_rd,     // read data of cache_data2
    output wire    [511:0] l2_data3_rd      // read data of cache_data3
    );
    reg   [511:0] l2_data_wd;
    reg           wr0_en0;
    reg           wr0_en1;
    reg           wr0_en2;
    reg           wr0_en3;
    reg           wr1_en0;
    reg           wr1_en1;
    reg           wr1_en2;
    reg           wr1_en3;
    reg           wr2_en0;
    reg           wr2_en1;
    reg           wr2_en2;
    reg           wr2_en3;
    reg           wr3_en0;
    reg           wr3_en1;
    reg           wr3_en2;
    reg           wr3_en3;
    always @(*) begin
        wr0_en0       = `DISABLE;
        wr0_en1       = `DISABLE;
        wr0_en2       = `DISABLE;
        wr0_en3       = `DISABLE;
        wr1_en0       = `DISABLE;
        wr1_en1       = `DISABLE;
        wr1_en2       = `DISABLE;
        wr1_en3       = `DISABLE;
        wr2_en0       = `DISABLE;
        wr2_en1       = `DISABLE;
        wr2_en2       = `DISABLE;
        wr2_en3       = `DISABLE;
        wr3_en0       = `DISABLE;
        wr3_en1       = `DISABLE;
        wr3_en2       = `DISABLE;
        wr3_en3       = `DISABLE; 
        if (mem_wr_l2_en == `ENABLE) begin
            l2_data_wd   = l2_data_wd_mem;
            if (l2_block0_we == `ENABLE) begin
                wr0_en0 = `ENABLE;
                wr0_en1 = `ENABLE;
                wr0_en2 = `ENABLE;
                wr0_en3 = `ENABLE;
            end 
            if (l2_block1_we == `ENABLE) begin
                wr1_en0 = `ENABLE;
                wr1_en1 = `ENABLE;
                wr1_en2 = `ENABLE;
                wr1_en3 = `ENABLE;
            end
            if (l2_block2_we == `ENABLE) begin
                wr2_en0 = `ENABLE;
                wr2_en1 = `ENABLE;
                wr2_en2 = `ENABLE;
                wr2_en3 = `ENABLE;
            end
            if (l2_block3_we == `ENABLE) begin
                wr3_en0 = `ENABLE;
                wr3_en1 = `ENABLE;
                wr3_en2 = `ENABLE;
                wr3_en3 = `ENABLE;    
            end
        end else if (wd_from_l1_en == `ENABLE) begin
            case(offset)
                `WORD0:begin
                    l2_data_wd[127:0]  = rd_to_l2;
                    if (l2_block0_we == `ENABLE) begin
                        wr0_en0 = `ENABLE;
                    end else if (l2_block1_we == `ENABLE) begin
                        wr1_en0 = `ENABLE;
                    end else if (l2_block2_we == `ENABLE) begin
                        wr2_en0 = `ENABLE;
                    end else if (l2_block3_we == `ENABLE) begin
                        wr3_en0 = `ENABLE;
                    end
                end
                `WORD1:begin
                    l2_data_wd[255:128] = rd_to_l2;
                    if (l2_block0_we == `ENABLE) begin
                        wr0_en1 = `ENABLE;
                    end else if (l2_block1_we == `ENABLE) begin
                        wr1_en1 = `ENABLE;
                    end else if (l2_block2_we == `ENABLE) begin
                        wr2_en1 = `ENABLE;
                    end else if (l2_block3_we == `ENABLE) begin
                        wr3_en1 = `ENABLE;
                    end
                end
                `WORD2:begin
                    l2_data_wd[383:256] = rd_to_l2;
                    if (l2_block0_we == `ENABLE) begin
                        wr0_en2 = `ENABLE;
                    end else if (l2_block1_we == `ENABLE) begin
                        wr1_en2 = `ENABLE;
                    end else if (l2_block2_we == `ENABLE) begin
                        wr2_en2 = `ENABLE;
                    end else if (l2_block3_we == `ENABLE) begin
                        wr3_en2 = `ENABLE;
                    end
                end
                `WORD3:begin
                    l2_data_wd[511:384] = rd_to_l2;
                    if (l2_block0_we == `ENABLE) begin
                        wr0_en3 = `ENABLE;
                    end else if (l2_block1_we == `ENABLE) begin
                        wr1_en3 = `ENABLE;
                    end else if (l2_block2_we == `ENABLE) begin
                        wr2_en3 = `ENABLE;
                    end else if (l2_block3_we == `ENABLE) begin
                        wr3_en3 = `ENABLE;
                    end
                end
            endcase // case(offset)  
        end
    end

    // sram_512x128
    // data_way0   
    ram512x128 data0_way0(
        .clock    (clk),
        .address  (l2_index),
        .wren     (wr0_en0),
        .rden     (l2_block0_re),
        .q        (l2_data0_rd[127:0]),
        .data     (l2_data_wd[127:0])
        );
    ram512x128 data0_way1(
        .clock    (clk),
        .address  (l2_index),
        .wren     (wr0_en1),
        .rden     (l2_block0_re),
        .q        (l2_data0_rd[255:128]),
        .data     (l2_data_wd[255:128])
        );
    ram512x128 data0_way2(
        .clock    (clk),
        .address  (l2_index),
        .wren     (wr0_en2),
        .rden     (l2_block0_re),
        .q        (l2_data0_rd[383:256]),
        .data     (l2_data_wd[383:256])
        );
    ram512x128 data0_way3(
        .clock    (clk),
        .address  (l2_index),
        .wren     (wr0_en3),
        .rden     (l2_block0_re),
        .q        (l2_data0_rd[511:384]),
        .data     (l2_data_wd[511:384])
        );
    // data_way1  
    ram512x128 data1_way0(
        .clock    (clk),
        .address  (l2_index),
        .wren     (wr1_en0),
        .rden     (l2_block1_re),
        .q        (l2_data1_rd[127:0]),
        .data     (l2_data_wd[127:0])
        );
    ram512x128 data1_way1(
        .clock    (clk),
        .address  (l2_index),
        .wren     (wr1_en1),
        .rden     (l2_block1_re),
        .q        (l2_data1_rd[255:128]),
        .data     (l2_data_wd[255:128])
        );
    ram512x128 data1_way2(
        .clock    (clk),
        .address  (l2_index),
        .wren     (wr1_en2),
        .rden     (l2_block1_re),
        .q        (l2_data1_rd[383:256]),
        .data     (l2_data_wd[383:256])
        );
    ram512x128 data1_way3(
        .clock    (clk),
        .address  (l2_index),
        .wren     (wr1_en3),
        .rden     (l2_block1_re),
        .q        (l2_data1_rd[511:384]),
        .data     (l2_data_wd[511:384])
        );
    // // data_way2  
    ram512x128 data2_way0(
        .clock    (clk),
        .address  (l2_index),
        .wren     (wr2_en0),
        .rden     (l2_block2_re),
        .q        (l2_data2_rd[127:0]),
        .data     (l2_data_wd[127:0])
        );
    ram512x128 data2_way1(
        .clock    (clk),
        .address  (l2_index),
        .wren     (wr2_en1),
        .rden     (l2_block2_re),
        .q        (l2_data2_rd[255:128]),
        .data     (l2_data_wd[255:128])
        );
    ram512x128 data2_way2(
        .clock    (clk),
        .address  (l2_index),
        .wren     (wr2_en2),
        .rden     (l2_block2_re),
        .q        (l2_data2_rd[383:256]),
        .data     (l2_data_wd[383:256])
        );
    ram512x128 data2_way3(
        .clock    (clk),
        .address  (l2_index),
        .wren     (wr2_en3),
        .rden     (l2_block2_re),
        .q        (l2_data2_rd[511:384]),
        .data     (l2_data_wd[511:384])
        );
    // data_way3  
    ram512x128 data3_way0(
        .clock    (clk),
        .address  (l2_index),
        .wren     (wr3_en0),
        .rden     (l2_block3_re),
        .q        (l2_data3_rd[127:0]),
        .data     (l2_data_wd[127:0])
        );
    ram512x128 data3_way1(
        .clock    (clk),
        .address  (l2_index),
        .wren      (wr3_en1),
        .rden     (l2_block3_re),
        .q        (l2_data3_rd[255:128]),
        .data     (l2_data_wd[255:128])
        );
    ram512x128 data3_way2(
        .clock    (clk),
        .address  (l2_index),
        .wren     (wr3_en2),
        .rden     (l2_block3_re),
        .q        (l2_data3_rd[383:256]),
        .data     (l2_data_wd[383:256])
        );
    ram512x128 data3_way3(
        .clock    (clk),
        .address  (l2_index),
        .wren     (wr3_en3),
        .rden     (l2_block3_re),
        .q        (l2_data3_rd[511:384]),
        .data     (l2_data_wd[511:384])
        );
endmodule