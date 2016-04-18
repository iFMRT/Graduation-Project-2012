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
    input              clk,             // clock
    input      [8:0]   l2_index,        // address of cache     
    input      [511:0] mem_rd,          // +++++
    input      [1:0]   offset,          // +++++++++++
    input      [127:0] rd_to_l2,        // ++++++++++
    input              wd_from_mem_en,
    input              wd_from_l1_en,
    input              tagcomp_hit,
    input              l2_block0_rw,    // read / write signal of block0
    input              l2_block1_rw,    // read / write signal of block1
    input              l2_block2_rw,    // read / write signal of block2
    input              l2_block3_rw,    // read / write signal of block3
    // input              wr0_en0,
    // input              wr0_en1,
    // input              wr0_en2,
    // input              wr0_en3,
    // input              wr1_en0,
    // input              wr1_en1,
    // input              wr1_en2,
    // input              wr1_en3,
    // input              wr2_en0,
    // input              wr2_en1,
    // input              wr2_en2,
    // input              wr2_en3,
    // input              wr3_en0,
    // input              wr3_en1,
    // input              wr3_en2,
    // input              wr3_en3,
    output     [511:0] l2_data0_rd,            // read data of cache_data0
    output     [511:0] l2_data1_rd,            // read data of cache_data1
    output     [511:0] l2_data2_rd,            // read data of cache_data2
    output     [511:0] l2_data3_rd             // read data of cache_data3
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
        wr0_en0       = `READ;
        wr0_en1       = `READ;
        wr0_en2       = `READ;
        wr0_en3       = `READ;
        wr1_en0       = `READ;
        wr1_en1       = `READ;
        wr1_en2       = `READ;
        wr1_en3       = `READ;
        wr2_en0       = `READ;
        wr2_en1       = `READ;
        wr2_en2       = `READ;
        wr2_en3       = `READ;
        wr3_en0       = `READ;
        wr3_en1       = `READ;
        wr3_en2       = `READ;
        wr3_en3       = `READ; 
        if(tagcomp_hit == `ENABLE)begin
            if (l2_block0_rw == `WRITE) begin
                case(offset)
                    `WORD0:begin
                        wr0_en0 = `WRITE;
                    end
                    `WORD1:begin
                        wr0_en1 = `WRITE;
                    end
                    `WORD2:begin
                        wr0_en2 = `WRITE;
                    end
                    `WORD3:begin
                        wr0_en3 = `WRITE;
                    end
                endcase
            end
            if (l2_block1_rw == `WRITE) begin
                case(offset)
                    `WORD0:begin
                        wr1_en0 = `WRITE;
                    end
                    `WORD1:begin
                        wr1_en1 = `WRITE;
                    end
                    `WORD2:begin
                        wr1_en2 = `WRITE;
                    end
                    `WORD3:begin
                        wr1_en3 = `WRITE;
                    end
                endcase
            end
            if (l2_block2_rw == `WRITE) begin
                case(offset)
                    `WORD0:begin
                        wr2_en0 = `WRITE;
                    end
                    `WORD1:begin
                        wr2_en1 = `WRITE;
                    end
                    `WORD2:begin
                        wr2_en2 = `WRITE;
                    end
                    `WORD3:begin
                        wr2_en3 = `WRITE;
                    end
                endcase
            end
            if (l2_block3_rw == `WRITE) begin
                case(offset)
                    `WORD0:begin
                        wr3_en0 = `WRITE;
                    end
                    `WORD1:begin
                        wr3_en1 = `WRITE;
                    end
                    `WORD2:begin
                        wr3_en2 = `WRITE;
                    end
                    `WORD3:begin
                        wr3_en3 = `WRITE;
                    end
                endcase
            end
        end else begin
            if (l2_block0_rw == `WRITE) begin
                wr0_en0 = `WRITE;
                wr0_en1 = `WRITE;
                wr0_en2 = `WRITE;
                wr0_en3 = `WRITE;
            end 
            if (l2_block1_rw == `WRITE) begin
                wr1_en0 = `WRITE;
                wr1_en1 = `WRITE;
                wr1_en2 = `WRITE;
                wr1_en3 = `WRITE;
            end
            if (l2_block2_rw == `WRITE) begin
                wr2_en0 = `WRITE;
                wr2_en1 = `WRITE;
                wr2_en2 = `WRITE;
                wr2_en3 = `WRITE;
            end
            if (l2_block3_rw == `WRITE) begin
                wr3_en0 = `WRITE;
                wr3_en1 = `WRITE;
                wr3_en2 = `WRITE;
                wr3_en3 = `WRITE;    
            end                    
        end
        if (wd_from_mem_en == `ENABLE) begin
            l2_data_wd   = mem_rd;
        end
        if (wd_from_l1_en == `ENABLE) begin
            case(offset)
                `WORD0:begin
                    l2_data_wd[127:0]  = rd_to_l2;
                end
                `WORD1:begin
                    l2_data_wd[255:128] = rd_to_l2;
                end
                `WORD2:begin
                    l2_data_wd[383:256] = rd_to_l2;
                end
                `WORD3:begin
                    l2_data_wd[511:384] = rd_to_l2;
                end
            endcase // case(offset)  
        end
    end

    // sram_512x128
    // data_way0   
    ram_512x128 data0_way0(
        .clock    (clk),
        .address  (l2_index),
        .wren     (wr0_en0),
        .q        (l2_data0_rd[127:0]),
        .data     (l2_data_wd[127:0])
        );
    ram_512x128 data0_way1(
        .clock    (clk),
        .address  (l2_index),
        .wren     (wr0_en1),
        .q        (l2_data0_rd[255:128]),
        .data     (l2_data_wd[255:128])
        );
    ram_512x128 data0_way2(
        .clock    (clk),
        .address  (l2_index),
        .wren     (wr0_en2),
        .q        (l2_data0_rd[383:256]),
        .data     (l2_data_wd[383:256])
        );
    ram_512x128 data0_way3(
        .clock    (clk),
        .address  (l2_index),
        .wren     (wr0_en3),
        .q        (l2_data0_rd[511:384]),
        .data     (l2_data_wd[511:384])
        );
    // data_way1  
    ram_512x128 data1_way0(
        .clock    (clk),
        .address  (l2_index),
        .wren     (wr1_en0),
        .q        (l2_data1_rd[127:0]),
        .data     (l2_data_wd[127:0])
        );
    ram_512x128 data1_way1(
        .clock    (clk),
        .address  (l2_index),
        .wren     (wr1_en1),
        .q        (l2_data1_rd[255:128]),
        .data     (l2_data_wd[255:128])
        );
    ram_512x128 data1_way2(
        .clock    (clk),
        .address  (l2_index),
        .wren     (wr1_en2),
        .q        (l2_data1_rd[383:256]),
        .data     (l2_data_wd[383:256])
        );
    ram_512x128 data1_way3(
        .clock    (clk),
        .address  (l2_index),
        .wren     (wr1_en3),
        .q        (l2_data1_rd[511:384]),
        .data     (l2_data_wd[511:384])
        );
    // // data_way2  
    ram_512x128 data2_way0(
        .clock    (clk),
        .address  (l2_index),
        .wren     (wr2_en0),
        .q        (l2_data2_rd[127:0]),
        .data     (l2_data_wd[127:0])
        );
    ram_512x128 data2_way1(
        .clock    (clk),
        .address  (l2_index),
        .wren     (wr2_en1),
        .q        (l2_data2_rd[255:128]),
        .data     (l2_data_wd[255:128])
        );
    ram_512x128 data2_way2(
        .clock    (clk),
        .address  (l2_index),
        .wren     (wr2_en2),
        .q        (l2_data2_rd[383:256]),
        .data     (l2_data_wd[383:256])
        );
    ram_512x128 data2_way3(
        .clock    (clk),
        .address  (l2_index),
        .wren     (wr2_en3),
        .q        (l2_data2_rd[511:384]),
        .data     (l2_data_wd[511:384])
        );
    // // data_way3  
    ram_512x128 data3_way0(
        .clock    (clk),
        .address  (l2_index),
        .wren     (wr3_en0),
        .q        (l2_data3_rd[127:0]),
        .data     (l2_data_wd[127:0])
        );
    ram_512x128 data3_way1(
        .clock    (clk),
        .address  (l2_index),
        .wren      (wr3_en1),
        .q        (l2_data3_rd[255:128]),
        .data     (l2_data_wd[255:128])
        );
    ram_512x128 data3_way2(
        .clock    (clk),
        .address  (l2_index),
        .wren     (wr3_en2),
        .q        (l2_data3_rd[383:256]),
        .data     (l2_data_wd[383:256])
        );
    ram_512x128 data3_way3(
        .clock    (clk),
        .address  (l2_index),
        .wren     (wr3_en3),
        .q        (l2_data3_rd[511:384]),
        .data     (l2_data_wd[511:384])
        );

endmodule