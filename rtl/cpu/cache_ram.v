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
   (input              clk,
    input  [7:0]       a,
    input              wr,
    // input              read_en,  // +++++++++
    output [WIDTH-1:0] rd,
    input  [WIDTH-1:0] wd
    );
    reg    [WIDTH-1:0] ram[255:0]; 

    // if (read_en == `ENABLE) begin
    //     assign rd = ram[a];
    // end
    
    assign rd = ram[a];

    always @(posedge clk) begin
        if (wr == `WRITE) begin
            ram[a] <= wd;
        end
    end
endmodule

// sram_512 * n
module sram_512 #(parameter WIDTH = 32)
   (input              clk,
    input  [8:0]       a,
    input              wr,
    output [WIDTH-1:0] rd,
    input  [WIDTH-1:0] wd);
    reg    [WIDTH-1:0] ram[511:0]; 

    assign  rd = ram[a];

    always @(posedge clk) begin
        if (wr == `WRITE) begin
            ram[a] <= wd;
        end
    end
endmodule

module itag_ram(
    input               clk,            // clock
    input               tag0_rw,        // read / write signal of tag0
    input               tag1_rw,        // read / write signal of tag1
    input       [7:0]   index,          // address of cache
    // input       [19:0]  tag_wd,         // write data of tag
    input       [20:0]  tag_wd,         // write data of tag
    output      [20:0]  tag0_rd,        // read data of tag0
    output      [20:0]  tag1_rd,        // read data of tag1
    output              lru,            // read data of lru_field
    output  reg         complete        // complete write from L2 to L1
    );
    reg                 lru_we;         // read / write signal of lru_field
    reg                 lru_wd;         // write data of lru_field

    always @(*) begin
        if (tag0_rw == `WRITE) begin 
            lru_wd   <= 1'b1;
            lru_we   <= `WRITE;    
        end else if (tag1_rw == `WRITE) begin
            lru_wd   <= 1'b0; 
            lru_we   <= `WRITE;    
        end else begin
            lru_we   <= `READ;
        end
    end
    always @(posedge clk) begin
        if (tag0_rw == `WRITE) begin
            complete <= `ENABLE;      
        end else if (tag1_rw == `WRITE) begin
            complete <= `ENABLE;   
        end else begin
            complete <= `DISABLE;
        end
    end

    // sram_256x1
    sram_256 #(1) lru_field(        
        .clk    (clk),
        .a      (index),
        .wr     (lru_we),
        .rd     (lru),
        .wd     (lru_wd)
        );
    // sram_256x21
    sram_256 #(21) tag_way0(
        .clk    (clk),
        .a      (index),
        .wr     (tag0_rw),
        .rd     (tag0_rd),
        .wd     (tag_wd)
        );
    // sram_256x21
    sram_256 #(21) tag_way1(
        .clk    (clk),
        .a      (index),
        .wr     (tag1_rw),
        .rd     (tag1_rd),
        .wd     (tag_wd)
        );
endmodule

module dtag_ram(
    input               clk,            // clock
    input               tag0_rw,        // read / write signal of tag0
    input               tag1_rw,        // read / write signal of tag1
    input       [7:0]   index,          // address of cache
    input               dirty0_rw,
    input               dirty1_rw,
    input               dirty_wd,
    input       [20:0]  tag_wd,         // write data of tag
    output      [20:0]  tag0_rd,        // read data of tag0
    output      [20:0]  tag1_rd,        // read data of tag1
    output              dirty0,
    output              dirty1,
    output              lru,            // read data of lru_field
    output  reg         complete        // complete write from L2 to L1
    );
    reg                 lru_we;         // read / write signal of lru_field
    reg                 lru_wd;         // write data of lru_field

    always @(*) begin
        if (tag0_rw == `WRITE) begin 
            lru_wd   <= 1'b1;
            lru_we   <= `WRITE;    
        end else if (tag1_rw == `WRITE) begin
            lru_wd   <= 1'b0; 
            lru_we   <= `WRITE;    
        end else begin
            lru_we   <= `READ;
        end
    end
    always @(posedge clk) begin
        if (tag0_rw == `WRITE) begin
            complete <= `ENABLE;      
        end else if (tag1_rw == `WRITE) begin
            complete <= `ENABLE;   
        end else begin
            complete <= `DISABLE;
        end
    end
    
    // sram_256x1
    sram_256 #(1) dirty0_field(        
        .clk    (clk),
        .a      (index),
        .wr     (dirty0_rw),
        .rd     (dirty0),
        .wd     (dirty_wd)
        );
    // sram_256x1
    sram_256 #(1) dirty1_field(        
        .clk    (clk),
        .a      (index),
        .wr     (dirty1_rw),
        .rd     (dirty1),
        .wd     (dirty_wd)
        );
    // sram_256x1
    sram_256 #(1) lru_field(        
        .clk    (clk),
        .a      (index),
        .wr     (lru_we),
        .rd     (lru),
        .wd     (lru_wd)
        );
    // sram_256x21
    sram_256 #(21) tag_way0(
        .clk    (clk),
        .a      (index),
        .wr     (tag0_rw),
        .rd     (tag0_rd),
        .wd     (tag_wd)
        );
    // sram_256x21
    sram_256 #(21) tag_way1(
        .clk    (clk),
        .a      (index),
        .wr     (tag1_rw),
        .rd     (tag1_rd),
        .wd     (tag_wd)
        );

endmodule

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
    output  [127:0] data0_rd,        // read data of cache_data0
    output  [127:0] data1_rd         // read data of cache_data1
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
    sram_256 #(32) data_way00(
        .clk    (clk),
        .a      (index),
        .wr     (wr0_en0),
        .rd     (data0_rd[31:0]),
        .wd     (data_wd[31:0])
        );
    sram_256 #(32) data_way01(
        .clk    (clk),
        .a      (index),
        .wr     (wr0_en1),
        .rd     (data0_rd[63:32]),
        .wd     (data_wd[63:32])
        );
    sram_256 #(32) data_way02(
        .clk    (clk),
        .a      (index),
        .wr     (wr0_en2),
        .rd     (data0_rd[95:64]),
        .wd     (data_wd[95:64])
        );
    sram_256 #(32) data_way03(
        .clk    (clk),
        .a      (index),
        .wr     (wr0_en3),
        .rd     (data0_rd[127:96]),
        .wd     (data_wd[127:96])
        );
    // sram_256x32
    sram_256 #(32) data_way10(
        .clk    (clk),
        .a      (index),
        .wr     (wr1_en0),
        .rd     (data1_rd[31:0]),
        .wd     (data_wd[31:0])
        );
    sram_256 #(32) data_way11(
        .clk    (clk),
        .a      (index),
        .wr     (wr1_en1),
        .rd     (data1_rd[63:32]),
        .wd     (data_wd[63:32])
        );
    sram_256 #(32) data_way12(
        .clk    (clk),
        .a      (index),
        .wr     (wr1_en2),
        .rd     (data1_rd[95:64]),
        .wd     (data_wd[95:64])
        );
    sram_256 #(32) data_way13(
        .clk    (clk),
        .a      (index),
        .wr     (wr1_en3),
        .rd     (data1_rd[127:96]),
        .wd     (data_wd[127:96])
        );

endmodule

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
    
    reg  [127:0] data_wd;

    always @(*) begin
        if(data_wd_l2_en == `ENABLE) begin 
            data_wd = data_wd_l2;
        end
    end
    // sram_256x32
    sram_256 #(32) data_way00(
        .clk    (clk),
        .a      (index),
        .wr     (data0_rw),
        .rd     (data0_rd[31:0]),
        .wd     (data_wd[31:0])
        );
    sram_256 #(32) data_way01(
        .clk    (clk),
        .a      (index),
        .wr     (data0_rw),
        .rd     (data0_rd[63:32]),
        .wd     (data_wd[63:32])
        );
    sram_256 #(32) data_way02(
        .clk    (clk),
        .a      (index),
        .wr     (data0_rw),
        .rd     (data0_rd[95:64]),
        .wd     (data_wd[95:64])
        );
    sram_256 #(32) data_way03(
        .clk    (clk),
        .a      (index),
        .wr     (data0_rw),
        .rd     (data0_rd[127:96]),
        .wd     (data_wd[127:96])
        );
    // sram_256x32
    sram_256 #(32) data_way10(
        .clk    (clk),
        .a      (index),
        .wr     (data1_rw),
        .rd     (data1_rd[31:0]),
        .wd     (data_wd[31:0])
        );
    sram_256 #(32) data_way11(
        .clk    (clk),
        .a      (index),
        .wr     (data1_rw),
        .rd     (data1_rd[63:32]),
        .wd     (data_wd[63:32])
        );
    sram_256 #(32) data_way12(
        .clk    (clk),
        .a      (index),
        .wr     (data1_rw),
        .rd     (data1_rd[95:64]),
        .wd     (data_wd[95:64])
        );
    sram_256 #(32) data_way13(
        .clk    (clk),
        .a      (index),
        .wr     (data1_rw),
        .rd     (data1_rd[127:96]),
        .wd     (data_wd[127:96])
        );

    // // sram_256x128 
    // sram_256 #(128) data_way0(
    //     .clk    (clk),
    //     .a      (index),
    //     .wr     (data0_rw),
    //     .rd     (data0_rd),
    //     .wd     (data_wd)
    //     );
    // // sram_256x128 
    // sram_256 #(128) data_way1(
    //     .clk    (clk),
    //     .a      (index),
    //     .wr     (data1_rw),
    //     .rd     (data1_rd),
    //     .wd     (data_wd)
    //     );

endmodule

/********** General header file **********/
`include "stddef.h"

module l2_tag_ram(    
    input               clk,               // clock
    input               l2_tag0_rw,        // read / write signal of tag0
    input               l2_tag1_rw,        // read / write signal of tag1
    input               l2_tag2_rw,        // read / write signal of tag2
    input               l2_tag3_rw,        // read / write signal of tag3
    input       [8:0]   l2_index,
    input       [17:0]  l2_tag_wd,         // write data of tag
    input               l2_dirty0_rw,
    input               l2_dirty1_rw,
    input               l2_dirty2_rw,
    input               l2_dirty3_rw,
    input               l2_dirty_wd,
    output      [17:0]  l2_tag0_rd,        // read data of tag0
    output      [17:0]  l2_tag1_rd,        // read data of tag1
    output      [17:0]  l2_tag2_rd,        // read data of tag2
    output      [17:0]  l2_tag3_rd,        // read data of tag3
    output      [2:0]   plru,              // read data of plru_field
    output reg          l2_complete,       // complete write from L2 to L1
    output              l2_dirty0,         // dirty signal of L2 
    output              l2_dirty1,         // dirty signal of L2 
    output              l2_dirty2,         // dirty signal of L2 
    output              l2_dirty3          // dirty signal of L2 
    );
    reg                 plru_we;           // read / write signal of plru_field
    reg         [2:0]   plru_wd;           // write data of plru_field
    // reg         [8:0]   l2_index;
    always @(*) begin
        if (l2_tag0_rw == `WRITE) begin
            plru_wd   <= {plru[2],2'b11};
            plru_we   <= `WRITE;    
        end else if (l2_tag1_rw == `WRITE) begin 
            plru_wd   <= {plru[2],2'b01};
            plru_we   <= `WRITE;    
        end else if (l2_tag2_rw == `WRITE) begin  
            plru_wd   <= {1'b1,plru[1],1'b0};
            plru_we   <= `WRITE;    
        end else if (l2_tag3_rw == `WRITE) begin
            plru_wd   <= {1'b0,plru[1],1'b0}; 
            plru_we   <= `WRITE;    
        end else begin
            plru_we   <= `READ;
        end
    end
    always @(posedge clk) begin
        if (l2_tag0_rw == `WRITE) begin
            l2_complete <= `ENABLE;     
        end else if (l2_tag1_rw == `WRITE) begin
            l2_complete <= `ENABLE;   
        end else if (l2_tag2_rw == `WRITE) begin
            l2_complete <= `ENABLE;   
        end else if (l2_tag3_rw == `WRITE) begin
            l2_complete <= `ENABLE;   
        end else begin
            l2_complete <= `DISABLE;
        end
    end
    // sram_256x1
    sram_512 #(1) dirty0_field(        
        .clk    (clk),
        .a      (l2_index),
        .wr     (l2_dirty0_rw),
        .rd     (l2_dirty0),
        .wd     (l2_dirty_wd)
        );
    // sram_512x1
    sram_512 #(1) dirty1_field(        
        .clk    (clk),
        .a      (l2_index),
        .wr     (l2_dirty1_rw),
        .rd     (l2_dirty1),
        .wd     (l2_dirty_wd)
        );
        // sram_512x1
    sram_512 #(1) dirty2_field(        
        .clk    (clk),
        .a      (l2_index),
        .wr     (l2_dirty2_rw),
        .rd     (l2_dirty2),
        .wd     (l2_dirty_wd)
        );
    // sram_512x1
    sram_512 #(1) dirty3_field(        
        .clk    (clk),
        .a      (l2_index),
        .wr     (l2_dirty3_rw),
        .rd     (l2_dirty3),
        .wd     (l2_dirty_wd)
        );
    // sram_512x1
    sram_512 #(3) plru_field(        
        .clk    (clk),
        .a      (l2_index),
        .wr     (plru_we),
        .rd     (plru),
        .wd     (plru_wd)
        );
    // sram_512x18
    sram_512 #(18) tag_way0(
        .clk    (clk),
        .a      (l2_index),
        .wr     (l2_tag0_rw),
        .rd     (l2_tag0_rd),
        .wd     (l2_tag_wd)
        );
    // sram_512x18
    sram_512 #(18) tag_way1(
        .clk    (clk),
        .a      (l2_index),
        .wr     (l2_tag1_rw),
        .rd     (l2_tag1_rd),
        .wd     (l2_tag_wd)
        );
    // sram_512x18
    sram_512 #(18) tag_way2(
        .clk    (clk),
        .a      (l2_index),
        .wr     (l2_tag2_rw),
        .rd     (l2_tag2_rd),
        .wd     (l2_tag_wd)
        );
    // sram_512x18
    sram_512 #(18) tag_way3(
        .clk    (clk),
        .a      (l2_index),
        .wr     (l2_tag3_rw),
        .rd     (l2_tag3_rd),
        .wd     (l2_tag_wd)
        );

endmodule

/********** General header file **********/
`include "stddef.h"

module l2_data_ram(
    input              clk,             // clock
    input      [8:0]   l2_index,        // address of cache     
    input      [511:0] mem_rd,          // +++++
    input      [1:0]   offset,          // +++++++++++
    input      [127:0] rd_to_l2,        // ++++++++++
    input              wd_from_mem_en,
    input              wd_from_l1_en,
    input              wr0_en0,
    input              wr0_en1,
    input              wr0_en2,
    input              wr0_en3,
    input              wr1_en0,
    input              wr1_en1,
    input              wr1_en2,
    input              wr1_en3,
    input              wr2_en0,
    input              wr2_en1,
    input              wr2_en2,
    input              wr2_en3,
    input              wr3_en0,
    input              wr3_en1,
    input              wr3_en2,
    input              wr3_en3,
    output     [511:0] l2_data0_rd,            // read data of cache_data0
    output     [511:0] l2_data1_rd,            // read data of cache_data1
    output     [511:0] l2_data2_rd,            // read data of cache_data2
    output     [511:0] l2_data3_rd             // read data of cache_data3
    );
    reg   [511:0] l2_data_wd;

    always @(*) begin
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
        .rd     (l2_data0_rd[127:0]),
        .wd     (l2_data_wd[127:0])
        );
    sram_512 #(128) data0_way1(
        .clk    (clk),
        .a      (l2_index),
        .wr     (wr0_en1),
        .rd     (l2_data0_rd[255:128]),
        .wd     (l2_data_wd[255:128])
        );
    sram_512 #(128) data0_way2(
        .clk    (clk),
        .a      (l2_index),
        .wr     (wr0_en2),
        .rd     (l2_data0_rd[383:256]),
        .wd     (l2_data_wd[383:256])
        );
    sram_512 #(128) data0_way3(
        .clk    (clk),
        .a      (l2_index),
        .wr     (wr0_en3),
        .rd     (l2_data0_rd[511:384]),
        .wd     (l2_data_wd[511:384])
        );
    // data_way1  
    sram_512 #(128) data1_way0(
        .clk    (clk),
        .a      (l2_index),
        .wr     (wr1_en0),
        .rd     (l2_data1_rd[127:0]),
        .wd     (l2_data_wd[127:0])
        );
    sram_512 #(128) data1_way1(
        .clk    (clk),
        .a      (l2_index),
        .wr  (wr1_en1),
        .rd     (l2_data1_rd[255:128]),
        .wd     (l2_data_wd[255:128])
        );
    sram_512 #(128) data1_way2(
        .clk    (clk),
        .a      (l2_index),
        .wr     (wr1_en2),
        .rd     (l2_data1_rd[383:256]),
        .wd     (l2_data_wd[383:256])
        );
    sram_512 #(128) data1_way3(
        .clk    (clk),
        .a      (l2_index),
        .wr     (wr1_en3),
        .rd     (l2_data1_rd[511:384]),
        .wd     (l2_data_wd[511:384])
        );
    // // data_way2  
    sram_512 #(128) data2_way0(
        .clk    (clk),
        .a      (l2_index),
        .wr     (wr2_en0),
        .rd     (l2_data2_rd[127:0]),
        .wd     (l2_data_wd[127:0])
        );
    sram_512 #(128) data2_way1(
        .clk    (clk),
        .a      (l2_index),
        .wr     (wr2_en1),
        .rd     (l2_data2_rd[255:128]),
        .wd     (l2_data_wd[255:128])
        );
    sram_512 #(128) data2_way2(
        .clk    (clk),
        .a      (l2_index),
        .wr     (wr2_en2),
        .rd     (l2_data2_rd[383:256]),
        .wd     (l2_data_wd[383:256])
        );
    sram_512 #(128) data2_way3(
        .clk    (clk),
        .a      (l2_index),
        .wr     (wr2_en3),
        .rd     (l2_data2_rd[511:384]),
        .wd     (l2_data_wd[511:384])
        );
    // // data_way3  
    sram_512 #(128) data3_way0(
        .clk    (clk),
        .a      (l2_index),
        .wr     (wr3_en0),
        .rd     (l2_data3_rd[127:0]),
        .wd     (l2_data_wd[127:0])
        );
    sram_512 #(128) data3_way1(
        .clk    (clk),
        .a      (l2_index),
        .wr     (wr3_en1),
        .rd     (l2_data3_rd[255:128]),
        .wd     (l2_data_wd[255:128])
        );
    sram_512 #(128) data3_way2(
        .clk    (clk),
        .a      (l2_index),
        .wr     (wr3_en2),
        .rd     (l2_data3_rd[383:256]),
        .wd     (l2_data_wd[383:256])
        );
    sram_512 #(128) data3_way3(
        .clk    (clk),
        .a      (l2_index),
        .wr     (wr3_en3),
        .rd     (l2_data3_rd[511:384]),
        .wd     (l2_data_wd[511:384])
        );

    // sram_512 #(512) data_way0(
    //     .clk    (clk),
    //     .a      (l2_index),
    //     .wr     (l2_data0_rw),
    //     .rd     (l2_data0_rd),
    //     .wd     (l2_data_wd)
    //     );
    // // sram_512x512 
    // sram_512 #(512) data_way1(
    //     .clk    (clk),
    //     .a      (l2_index),
    //     .wr     (l2_data1_rw),
    //     .rd     (l2_data1_rd),
    //     .wd     (l2_data_wd)
    //     );
    // // sram_512x512 
    // sram_512 #(512) data_way2(
    //     .clk    (clk),
    //     .a      (l2_index),
    //     .wr     (l2_data2_rw),
    //     .rd     (l2_data2_rd),
    //     .wd     (l2_data_wd)
    //     );
    // // sram_512x512 
    // sram_512 #(512) data_way3(
    //     .clk    (clk),
    //     .a      (l2_index),
    //     .wr     (l2_data3_rw),
    //     .rd     (l2_data3_rd),
    //     .wd     (l2_data_wd)
    //     );

endmodule