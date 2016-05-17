/*
 -- ============================================================================
 -- FILE NAME   : cache_ram.v
 -- DESCRIPTION : ram of cache
 -- ----------------------------------------------------------------------------
 -- Date:2016/1/18         Coding_by:kippy   
 -- ============================================================================
*/
`timescale 1ns/1ps
/********** General header file **********/
`include "stddef.h"
// sram_256 * n
module sram_256 #(parameter WIDTH = 128)
   (input                   clk,
    input       [7:0]       a,
    input                   wr,
    input                   re,   
    output  reg [WIDTH-1:0] rd,
    input       [WIDTH-1:0] wd
    );
    reg         [WIDTH-1:0] ram[255:0];   

    always @(*) begin
        if (re == `ENABLE) begin
            rd = ram[a];
        end
    end
      
    always @(posedge clk) begin
        if (wr == `ENABLE) begin
            ram[a] <= wd;
        end
    end
endmodule

// sram_512 * n
module sram_512 #(parameter WIDTH = 32)
   (input                  clk,
    input      [8:0]       a,
    input                  wr,
    input                  re,  
    output reg [WIDTH-1:0] rd,
    input      [WIDTH-1:0] wd
    );
    reg        [WIDTH-1:0] ram[511:0]; 
    
    always @(*) begin
        if (re == `ENABLE) begin
            rd = ram[a];
        end
    end

    always @(posedge clk) begin
        if (wr == `ENABLE) begin
            ram[a] <= wd;
        end
    end
endmodule

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
    output  reg         w_complete,     // complete write to L1
    output  reg         r_complete      // complete read from L1
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
            w_complete <= `ENABLE;      
        end else if (block1_we == `ENABLE) begin
            w_complete <= `ENABLE;   
        end else begin
            w_complete <= `DISABLE;
        end
        if (block0_re == `ENABLE) begin
            r_complete <= `ENABLE;      
        end else if (block1_re == `ENABLE) begin
            r_complete <= `ENABLE;   
        end else begin
            r_complete <= `DISABLE;
        end
    end

    // sram_256x1
    sram_256 #(1) lru_field(        
        .clk    (clk),
        .a      (index),
        .wr     (lru_we),
        .re     (lru_re),
        .rd     (lru),
        .wd     (lru_wd)
        );
    // sram_256x21
    sram_256 #(21) tag_way0(
        .clk    (clk),
        .a      (index),
        .wr     (block0_we),
        .re     (block0_re),
        .rd     (tag0_rd),
        .wd     (tag_wd)
        );
    // sram_256x21
    sram_256 #(21) tag_way1(
        .clk    (clk),
        .a      (index),
        .wr     (block1_we),
        .re     (block1_re),
        .rd     (tag1_rd),
        .wd     (tag_wd)
        );
endmodule

module dtag_ram(
    input               clk,            // clock
    input       [7:0]   index,          // address of cache
    input               block0_we,      // read / write signal of block0
    input               block1_we,      // read / write signal of block1
    input               block0_re,      // write signal of block0
    input               block1_re,      // read signal of block1
    input               dirty_wd,
    input       [20:0]  tag_wd,         // write data of tag
    output      [20:0]  tag0_rd,        // read data of tag0
    output      [20:0]  tag1_rd,        // read data of tag1
    output              dirty0,
    output              dirty1,
    output              lru,            // read data of lru_field
    output  reg         w_complete,     // complete write to L1
    output  reg         r_complete      // complete read from L1
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
            w_complete <= `ENABLE;      
        end else if (block1_we == `ENABLE) begin
            w_complete <= `ENABLE;   
        end else begin
            w_complete <= `DISABLE;
        end
        if (block0_re == `ENABLE) begin
            r_complete <= `ENABLE;      
        end else if (block1_re == `ENABLE) begin
            r_complete <= `ENABLE;   
        end else begin
            r_complete <= `DISABLE;
        end
    end
    
    // sram_256x1
    sram_256 #(1) dirty0_field(        
        .clk    (clk),
        .a      (index),
        .wr     (block0_we),
        .re     (block0_re),
        .rd     (dirty0),
        .wd     (dirty_wd)
        );
    // sram_256x1
    sram_256 #(1) dirty1_field(        
        .clk    (clk),
        .a      (index),
        .wr     (block1_we),
        .re     (block1_re),
        .rd     (dirty1),
        .wd     (dirty_wd)
        );
    // sram_256x1
    sram_256 #(1) lru_field(        
        .clk    (clk),
        .a      (index),
        .wr     (lru_we),
        .re     (lru_re),
        .rd     (lru),
        .wd     (lru_wd)
        );
    // sram_256x21
    sram_256 #(21) tag_way0(
        .clk    (clk),
        .a      (index),
        .wr     (block0_we),
        .re     (block0_re),
        .rd     (tag0_rd),
        .wd     (tag_wd)
        );
    // sram_256x21
    sram_256 #(21) tag_way1(
        .clk    (clk),
        .a      (index),
        .re     (block1_re),
        .wr     (block1_we),
        .rd     (tag1_rd),
        .wd     (tag_wd)
        );

endmodule

/********** General header file **********/
`include "stddef.h"

module data_ram(
    input              clk,             // clock
    input      [7:0]   index,           // address of cache
    input              tagcomp_hit,
    input              block0_we,       // write signal of block0
    input              block1_we,       // write signal of block1
    input              block0_re,       // read signal of block0
    input              block1_re,       // read signal of block1
    input      [127:0] data_wd_l2,      // read data of l2_cache
    input              data_wd_l2_en,
    input              data_wd_dc_en,    
    input      [31:0]  dc_wd,       
    input      [1:0]   offset,          
    output     [127:0] data0_rd,        // read data of cache_data0
    output     [127:0] data1_rd         // read data of cache_data1
    );
    reg [127:0]  data_wd;
    reg          wr0_en0;
    reg          wr0_en1;
    reg          wr0_en2;
    reg          wr0_en3;
    reg          wr1_en0;
    reg          wr1_en1;
    reg          wr1_en2;
    reg          wr1_en3;

    always @(*) begin
        wr0_en0       = `DISABLE;
        wr0_en1       = `DISABLE;
        wr0_en2       = `DISABLE;
        wr0_en3       = `DISABLE;
        wr1_en0       = `DISABLE;
        wr1_en1       = `DISABLE;
        wr1_en2       = `DISABLE;
        wr1_en3       = `DISABLE; 
        if(tagcomp_hit == `ENABLE)begin
            if (block0_we == `ENABLE) begin
                case(offset)
                    `WORD0:begin
                        wr0_en0 = `ENABLE;
                    end
                    `WORD1:begin
                        wr0_en1 = `ENABLE;
                    end
                    `WORD2:begin
                        wr0_en2 = `ENABLE;
                    end
                    `WORD3:begin
                        wr0_en3 = `ENABLE;
                    end
                endcase
            end
            if (block1_we == `ENABLE) begin
                case(offset)
                    `WORD0:begin
                        wr1_en0 = `ENABLE;
                    end
                    `WORD1:begin
                        wr1_en1 = `ENABLE;
                    end
                    `WORD2:begin
                        wr1_en2 = `ENABLE;
                    end
                    `WORD3:begin
                        wr1_en3 = `ENABLE;
                    end
                endcase
            end
        end else begin
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
        end

        if(data_wd_l2_en == `ENABLE) begin 
            data_wd = data_wd_l2;
        end
        if (data_wd_dc_en == `ENABLE) begin
            case(offset)
                `WORD0:begin
                    data_wd[31:0]   = dc_wd;
                end
                `WORD1:begin
                    data_wd[63:32]  = dc_wd;
                end
                `WORD2:begin
                    data_wd[95:64]  = dc_wd;
                end
                `WORD3:begin
                    data_wd[127:96] = dc_wd;
                end
            endcase
        end
    end

    // sram_256x32
    sram_256 #(32) data_way00(
        .clk    (clk),
        .a      (index),
        .wr     (wr0_en0),
        .re     (block0_re),
        .rd     (data0_rd[31:0]),
        .wd     (data_wd[31:0])
        );
    sram_256 #(32) data_way01(
        .clk    (clk),
        .a      (index),
        .wr     (wr0_en1),
        .re     (block0_re),
        .rd     (data0_rd[63:32]),
        .wd     (data_wd[63:32])
        );
    sram_256 #(32) data_way02(
        .clk    (clk),
        .a      (index),
        .wr     (wr0_en2),
        .re     (block0_re),
        .rd     (data0_rd[95:64]),
        .wd     (data_wd[95:64])
        );
    sram_256 #(32) data_way03(
        .clk    (clk),
        .a      (index),
        .wr     (wr0_en3),
        .re     (block0_re),
        .rd     (data0_rd[127:96]),
        .wd     (data_wd[127:96])
        );
    // sram_256x32
    sram_256 #(32) data_way10(
        .clk    (clk),
        .a      (index),
        .wr     (wr1_en0),
        .re     (block1_re),
        .rd     (data1_rd[31:0]),
        .wd     (data_wd[31:0])
        );
    sram_256 #(32) data_way11(
        .clk    (clk),
        .a      (index),
        .wr     (wr1_en1),
        .re     (block1_re),
        .rd     (data1_rd[63:32]),
        .wd     (data_wd[63:32])
        );
    sram_256 #(32) data_way12(
        .clk    (clk),
        .a      (index),
        .wr     (wr1_en2),
        .re     (block1_re),
        .rd     (data1_rd[95:64]),
        .wd     (data_wd[95:64])
        );
    sram_256 #(32) data_way13(
        .clk    (clk),
        .a      (index),
        .wr     (wr1_en3),
        .re     (block1_re),
        .rd     (data1_rd[127:96]),
        .wd     (data_wd[127:96])
        );

endmodule

module idata_ram(
    input              clk,             // clock
    input              block0_we,       // the mark of cache_block0 write signal 
    input              block1_we,       // the mark of cache_block1 write signal 
    input              block0_re,       // the mark of cache_block0 read signal 
    input              block1_re,       // the mark of cache_block1 read signal 
    input      [7:0]   index,           // address of cache
    input      [127:0] data_wd_l2,      // write data of l2_cache
    output     [127:0] data0_rd,        // read data of cache_data0
    output     [127:0] data1_rd         // read data of cache_data1
    );
    // sram_256x32
    sram_256 #(32) data_way00(
        .clk    (clk),
        .a      (index),
        .wr     (block0_we),
        .re     (block0_re),
        .rd     (data0_rd[31:0]),
        .wd     (data_wd_l2[31:0])
        );
    sram_256 #(32) data_way01(
        .clk    (clk),
        .a      (index),
        .wr     (block0_we),
        .re     (block0_re),
        .rd     (data0_rd[63:32]),
        .wd     (data_wd_l2[63:32])
        );
    sram_256 #(32) data_way02(
        .clk    (clk),
        .a      (index),
        .wr     (block0_we),
        .re     (block0_re),
        .rd     (data0_rd[95:64]),
        .wd     (data_wd_l2[95:64])
        );
    sram_256 #(32) data_way03(
        .clk    (clk),
        .a      (index),
        .wr     (block0_we),
        .re     (block0_re),
        .rd     (data0_rd[127:96]),
        .wd     (data_wd_l2[127:96])
        );
    // sram_256x32
    sram_256 #(32) data_way10(
        .clk    (clk),
        .a      (index),
        .wr     (block1_we),
        .re     (block1_re),
        .rd     (data1_rd[31:0]),
        .wd     (data_wd_l2[31:0])
        );
    sram_256 #(32) data_way11(
        .clk    (clk),
        .a      (index),
        .wr     (block1_we),
        .re     (block1_re),
        .rd     (data1_rd[63:32]),
        .wd     (data_wd_l2[63:32])
        );
    sram_256 #(32) data_way12(
        .clk    (clk),
        .a      (index),
        .wr     (block1_we),
        .re     (block1_re),
        .rd     (data1_rd[95:64]),
        .wd     (data_wd_l2[95:64])
        );
    sram_256 #(32) data_way13(
        .clk    (clk),
        .a      (index),
        .wr     (block1_we),
        .re     (block1_re),
        .rd     (data1_rd[127:96]),
        .wd     (data_wd_l2[127:96])
        );
endmodule

/********** General header file **********/
`include "stddef.h"

module l2_tag_ram(    
    input               clk,               // clock
    input               rst,               // clock
    input               l2_block0_we,      // write signal of block0
    input               l2_block1_we,      // write signal of block1
    input               l2_block2_we,      // write signal of block2
    input               l2_block3_we,      // write signal of block3
    input               l2_block0_re,      // read signal of block0
    input               l2_block1_re,      // read signal of block1
    input               l2_block2_re,      // read signal of block2
    input               l2_block3_re,      // read signal of block3
    input       [8:0]   l2_index,
    input       [17:0]  l2_tag_wd,         // write data of tag
    input               l2_dirty_wd,
    output      [17:0]  l2_tag0_rd,        // read data of tag0
    output      [17:0]  l2_tag1_rd,        // read data of tag1
    output      [17:0]  l2_tag2_rd,        // read data of tag2
    output      [17:0]  l2_tag3_rd,        // read data of tag3
    output      [2:0]   plru,              // read data of plru_field
    output reg          l2_complete_w,     // complete write to L2
    output reg          l2_complete_r,     // complete read from L2
    output              l2_dirty0,         // dirty signal of L2 
    output              l2_dirty1,         // dirty signal of L2 
    output              l2_dirty2,         // dirty signal of L2 
    output              l2_dirty3          // dirty signal of L2 
    );
    reg                 plru_re; 
    reg                 plru_we;           // read / write signal of plru_field
    reg         [2:0]   plru_wd;           // write data of plru_field
    reg                 i,next_i;
    always @(*) begin
        if (l2_block0_we == `ENABLE) begin
            plru_wd[1:0] = 2'b11;
            plru_we      = `ENABLE;    
        end else if (l2_block1_we == `ENABLE) begin 
            plru_wd[1:0] = 2'b01;
            plru_we      = `ENABLE;    
        end else if (l2_block2_we == `ENABLE) begin  
            plru_wd[2]   = 1'b1;
            plru_wd[0]   = 1'b0;
            plru_we      = `ENABLE;    
        end else if (l2_block3_we == `ENABLE) begin
            plru_wd[2]   = 1'b0;
            plru_wd[0]   = 1'b0; 
            plru_we      = `ENABLE;    
        end else begin
            plru_we      = `DISABLE;
        end
        if (l2_block0_re == `ENABLE || l2_block1_re == `ENABLE 
            || l2_block2_re == `ENABLE || l2_block3_re == `ENABLE) begin
            plru_re      = `ENABLE;
        end else begin
            plru_re      = `DISABLE;
        end
        if (i == 1'b1) begin
            next_i = 1'b0;
        end else begin
            next_i = 1'b1;
        end
    end

    always @(posedge clk) begin
        if (rst == `ENABLE) begin
            i <= 1'b0;
            l2_complete_w <= `DISABLE;
            l2_complete_r <= `DISABLE;
        end else begin
            i <= next_i;
            l2_complete_w <= `DISABLE;
            l2_complete_r <= `DISABLE;
            if (l2_block0_re == `ENABLE || l2_block1_re == `ENABLE 
                || l2_block2_re == `ENABLE || l2_block3_re == `ENABLE) begin
                if (next_i == 1'b1) begin
                    l2_complete_r <= `ENABLE;
                end 
            end 
            if (l2_block0_we == `ENABLE || l2_block1_we == `ENABLE 
                || l2_block2_we == `ENABLE || l2_block3_we == `ENABLE) begin
                if (next_i == 1'b1) begin
                    l2_complete_w <= `ENABLE;
                end 
            end 
        end                
    end
    // sram_256x1
    sram_512 #(1) dirty0_field(        
        .clk    (clk),
        .a      (l2_index),
        .wr     (l2_block0_we),
        .re     (l2_block0_re),
        .rd     (l2_dirty0),
        .wd     (l2_dirty_wd)
        );
    // sram_512x1
    sram_512 #(1) dirty1_field(        
        .clk    (clk),
        .a      (l2_index),
        .wr     (l2_block1_we),
        .re     (l2_block1_re),
        .rd     (l2_dirty1),
        .wd     (l2_dirty_wd)
        );
        // sram_512x1
    sram_512 #(1) dirty2_field(        
        .clk    (clk),
        .a      (l2_index),
        .wr     (l2_block2_we),
        .re     (l2_block2_re),
        .rd     (l2_dirty2),
        .wd     (l2_dirty_wd)
        );
    // sram_512x1
    sram_512 #(1) dirty3_field(        
        .clk    (clk),
        .a      (l2_index),
        .wr     (l2_block3_we),
        .re     (l2_block3_re),
        .rd     (l2_dirty3),
        .wd     (l2_dirty_wd)
        );
    // sram_512x1
    sram_512 #(1) plru0_field(        
        .clk    (clk),
        .a      (l2_index),
        .wr     (plru_we),
        .re     (plru_re),
        .rd     (plru[0]),
        .wd     (plru_wd[0])
        );
    sram_512 #(1) plru1_field(        
        .clk    (clk),
        .a      (l2_index),
        .wr     (plru_we),
        .re     (plru_re),
        .rd     (plru[1]),
        .wd     (plru_wd[1])
        );
    sram_512 #(1) plru2_field(        
        .clk    (clk),
        .a      (l2_index),
        .wr     (plru_we),
        .re     (plru_re),
        .rd     (plru[2]),
        .wd     (plru_wd[2])
        );
    // sram_512x18
    sram_512 #(18) tag_way0(
        .clk    (clk),
        .a      (l2_index),
        .wr     (l2_block0_we),
        .re     (l2_block0_re),
        .rd     (l2_tag0_rd),
        .wd     (l2_tag_wd)
        );
    // sram_512x18
    sram_512 #(18) tag_way1(
        .clk    (clk),
        .a      (l2_index),
        .wr     (l2_block1_we),
        .re     (l2_block1_re),
        .rd     (l2_tag1_rd),
        .wd     (l2_tag_wd)
        );
    // sram_512x18
    sram_512 #(18) tag_way2(
        .clk    (clk),
        .a      (l2_index),
        .wr     (l2_block2_we),
        .re     (l2_block2_re),
        .rd     (l2_tag2_rd),
        .wd     (l2_tag_wd)
        );
    // sram_512x18
    sram_512 #(18) tag_way3(
        .clk    (clk),
        .a      (l2_index),
        .wr     (l2_block3_we),
        .re     (l2_block3_re),
        .rd     (l2_tag3_rd),
        .wd     (l2_tag_wd)
        );

endmodule

/********** General header file **********/
`include "stddef.h"

module l2_data_ram(
    input              clk,             // clock
    input      [8:0]   l2_index,        // address of cache     
    input      [511:0] mem_rd,          
    input      [1:0]   offset,          
    input      [127:0] rd_to_l2,        
    input              wd_from_mem_en,
    input              wd_from_l1_en,
    input              tagcomp_hit,
    input              l2_block0_we,    // write signal of block0
    input              l2_block1_we,    // write signal of block1
    input              l2_block2_we,    // write signal of block2
    input              l2_block3_we,    // write signal of block3
    input              l2_block0_re,    // read signal of block0
    input              l2_block1_re,    // read signal of block1
    input              l2_block2_re,    // read signal of block2
    input              l2_block3_re,    // read signal of block3
    output     [511:0] l2_data0_rd,     // read data of cache_data0
    output     [511:0] l2_data1_rd,     // read data of cache_data1
    output     [511:0] l2_data2_rd,     // read data of cache_data2
    output     [511:0] l2_data3_rd      // read data of cache_data3
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
        if(tagcomp_hit == `ENABLE)begin
            if (l2_block0_we == `ENABLE) begin
                case(offset)
                    `WORD0:begin
                        wr0_en0 = `ENABLE;
                    end
                    `WORD1:begin
                        wr0_en1 = `ENABLE;
                    end
                    `WORD2:begin
                        wr0_en2 = `ENABLE;
                    end
                    `WORD3:begin
                        wr0_en3 = `ENABLE;
                    end
                endcase
            end
            if (l2_block1_we == `ENABLE) begin
                case(offset)
                    `WORD0:begin
                        wr1_en0 = `ENABLE;
                    end
                    `WORD1:begin
                        wr1_en1 = `ENABLE;
                    end
                    `WORD2:begin
                        wr1_en2 = `ENABLE;
                    end
                    `WORD3:begin
                        wr1_en3 = `ENABLE;
                    end
                endcase
            end
            if (l2_block2_we == `ENABLE) begin
                case(offset)
                    `WORD0:begin
                        wr2_en0 = `ENABLE;
                    end
                    `WORD1:begin
                        wr2_en1 = `ENABLE;
                    end
                    `WORD2:begin
                        wr2_en2 = `ENABLE;
                    end
                    `WORD3:begin
                        wr2_en3 = `ENABLE;
                    end
                endcase
            end
            if (l2_block3_we == `ENABLE) begin
                case(offset)
                    `WORD0:begin
                        wr3_en0 = `ENABLE;
                    end
                    `WORD1:begin
                        wr3_en1 = `ENABLE;
                    end
                    `WORD2:begin
                        wr3_en2 = `ENABLE;
                    end
                    `WORD3:begin
                        wr3_en3 = `ENABLE;
                    end
                endcase
            end
        end else begin
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
    sram_512 #(128) data0_way0(
        .clk    (clk),
        .a      (l2_index),
        .wr     (wr0_en0),
        .re     (l2_block0_re),
        .rd     (l2_data0_rd[127:0]),
        .wd     (l2_data_wd[127:0])
        );
    sram_512 #(128) data0_way1(
        .clk    (clk),
        .a      (l2_index),
        .wr     (wr0_en1),
        .re     (l2_block0_re),
        .rd     (l2_data0_rd[255:128]),
        .wd     (l2_data_wd[255:128])
        );
    sram_512 #(128) data0_way2(
        .clk    (clk),
        .a      (l2_index),
        .wr     (wr0_en2),
        .re     (l2_block0_re),
        .rd     (l2_data0_rd[383:256]),
        .wd     (l2_data_wd[383:256])
        );
    sram_512 #(128) data0_way3(
        .clk    (clk),
        .a      (l2_index),
        .wr     (wr0_en3),
        .re     (l2_block0_re),
        .rd     (l2_data0_rd[511:384]),
        .wd     (l2_data_wd[511:384])
        );
    // data_way1  
    sram_512 #(128) data1_way0(
        .clk    (clk),
        .a      (l2_index),
        .wr     (wr1_en0),
        .re     (l2_block1_re),
        .rd     (l2_data1_rd[127:0]),
        .wd     (l2_data_wd[127:0])
        );
    sram_512 #(128) data1_way1(
        .clk    (clk),
        .a      (l2_index),
        .wr     (wr1_en1),
        .re     (l2_block1_re),
        .rd     (l2_data1_rd[255:128]),
        .wd     (l2_data_wd[255:128])
        );
    sram_512 #(128) data1_way2(
        .clk    (clk),
        .a      (l2_index),
        .wr     (wr1_en2),
        .re     (l2_block1_re),
        .rd     (l2_data1_rd[383:256]),
        .wd     (l2_data_wd[383:256])
        );
    sram_512 #(128) data1_way3(
        .clk    (clk),
        .a      (l2_index),
        .wr     (wr1_en3),
        .re     (l2_block1_re),
        .rd     (l2_data1_rd[511:384]),
        .wd     (l2_data_wd[511:384])
        );
    // // data_way2  
    sram_512 #(128) data2_way0(
        .clk    (clk),
        .a      (l2_index),
        .wr     (wr2_en0),
        .re     (l2_block2_re),
        .rd     (l2_data2_rd[127:0]),
        .wd     (l2_data_wd[127:0])
        );
    sram_512 #(128) data2_way1(
        .clk    (clk),
        .a      (l2_index),
        .wr     (wr2_en1),
        .re     (l2_block2_re),
        .rd     (l2_data2_rd[255:128]),
        .wd     (l2_data_wd[255:128])
        );
    sram_512 #(128) data2_way2(
        .clk    (clk),
        .a      (l2_index),
        .wr     (wr2_en2),
        .re     (l2_block2_re),
        .rd     (l2_data2_rd[383:256]),
        .wd     (l2_data_wd[383:256])
        );
    sram_512 #(128) data2_way3(
        .clk    (clk),
        .a      (l2_index),
        .wr     (wr2_en3),
        .re     (l2_block2_re),
        .rd     (l2_data2_rd[511:384]),
        .wd     (l2_data_wd[511:384])
        );
    // // data_way3  
    sram_512 #(128) data3_way0(
        .clk    (clk),
        .a      (l2_index),
        .wr     (wr3_en0),
        .re     (l2_block3_re),
        .rd     (l2_data3_rd[127:0]),
        .wd     (l2_data_wd[127:0])
        );
    sram_512 #(128) data3_way1(
        .clk    (clk),
        .a      (l2_index),
        .wr     (wr3_en1),
        .re     (l2_block3_re),
        .rd     (l2_data3_rd[255:128]),
        .wd     (l2_data_wd[255:128])
        );
    sram_512 #(128) data3_way2(
        .clk    (clk),
        .a      (l2_index),
        .wr     (wr3_en2),
        .re     (l2_block3_re),
        .rd     (l2_data3_rd[383:256]),
        .wd     (l2_data_wd[383:256])
        );
    sram_512 #(128) data3_way3(
        .clk    (clk),
        .a      (l2_index),
        .wr     (wr3_en3),
        .re     (l2_block3_re),
        .rd     (l2_data3_rd[511:384]),
        .wd     (l2_data_wd[511:384])
        );
endmodule