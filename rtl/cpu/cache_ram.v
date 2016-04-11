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
    output [WIDTH-1:0] rd,
    input  [WIDTH-1:0] wd);

    reg    [WIDTH-1:0] ram[255:0]; 

    // initial begin
    //     for (int i = 0; i < 256; i++) begin
    //         ram[i] = 0;
    //     end
    // end

    assign rd = ram[a];

    always @(posedge clk) begin
        if (wr == `WRITE) begin
            ram[a] <= wd;
        end
    end
endmodule
// // sram_256 * n
// module ic_sram_256 #(parameter WIDTH = 128)
//    (input              clk,
//     input  [7:0]       a,
//     input              wr,
//     output [WIDTH-1:0] rd
//     );

//     reg    [WIDTH-1:0] ram[255:0]; 

//     // initial begin
//     //     for (int i = 0; i < 256; i++) begin
//     //         ram[i] = 0;
//     //     end
//     // end

//     assign rd = ram[a];

//     // always @(posedge clk) begin
//     //     if (wr == `WRITE) begin
//     //         ram[a] <= wd;
//     //     end
//     // end
// endmodule

// sram_512 * n
module sram_512 #(parameter WIDTH = 32)
   (input              clk,
    input  [8:0]       a,
    input              wr,
    output [WIDTH-1:0] rd,
    input  [WIDTH-1:0] wd);
    reg    [WIDTH-1:0] ram[511:0]; 
    // integer            i = 0;
    // initial begin
    //     for (int i = 0; i < 512; i++) begin
    //         ram[i] = 0;
    //         i      = i + 1;
    //     end
    // end

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
    input           clk,             // clock
    input           data0_rw,        // the mark of cache_data0 write signal 
    input           data1_rw,        // the mark of cache_data1 write signal 
    input   [7:0]   index,           // address of cache
    input   [127:0] data_wd_l2,         // write data of l2_cache
    input   [127:0] data_wd_dc,
    input           data_wd_l2_en,
    input           data_wd_dc_en,
    output  [127:0] data0_rd,        // read data of cache_data0
    output  [127:0] data1_rd         // read data of cache_data1
    );
    
    reg [127:0] data_wd;

    always @(*) begin
        if(data_wd_dc_en == `ENABLE) begin
            data_wd = data_wd_dc;
        end
        if(data_wd_l2_en == `ENABLE) begin 
            data_wd = data_wd_l2;
        end
    end

    // sram_256x128 
    sram_256 #(128) data_way0(
        .clk    (clk),
        .a      (index),
        .wr     (data0_rw),
        .rd     (data0_rd),
        .wd     (data_wd)
        );
    // sram_256x128 
    sram_256 #(128) data_way1(
        .clk    (clk),
        .a      (index),
        .wr     (data1_rw),
        .rd     (data1_rd),
        .wd     (data_wd)
        );

endmodule

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
    sram_256 #(128) data_way0(
        .clk    (clk),
        .a      (index),
        .wr     (data0_rw),
        .rd     (data0_rd),
        .wd     (data_wd)
        );
    // sram_256x128 
    sram_256 #(128) data_way1(
        .clk    (clk),
        .a      (index),
        .wr     (data1_rw),
        .rd     (data1_rd),
        .wd     (data_wd)
        );

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
    // input               irq,
    // input               drq,
    // input       [8:0]   l2_index_ic,       // address of cache
    // input       [8:0]   l2_index_dc,       // address of cache
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
        // if(irq == `ENABLE) begin
        //     l2_index = l2_index_ic;
        // end else if(drq == `ENABLE)begin 
        //     l2_index = l2_index_dc;
        // end
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
    input           clk,                    // clock
    input           l2_data0_rw,            // the mark of cache_data0 write signal 
    input           l2_data1_rw,            // the mark of cache_data1 write signal 
    input           l2_data2_rw,            // the mark of cache_data2 write signal 
    input           l2_data3_rw,            // the mark of cache_data3 write signal 
    input   [8:0]   l2_index,               // address of cache  
    // input           irq,
    // input           drq,
    // input   [8:0]   l2_index_ic,       // address of cache
    // input   [8:0]   l2_index_dc,       // address of cache    
    input   [511:0] l2_data_wd,             // write data of l2_cache
    output  [511:0] l2_data0_rd,            // read data of cache_data0
    output  [511:0] l2_data1_rd,            // read data of cache_data1
    output  [511:0] l2_data2_rd,            // read data of cache_data2
    output  [511:0] l2_data3_rd             // read data of cache_data3
    );
    // reg     [8:0]   l2_index;               // address of cache
    // always @(*) begin
    //     if(irq == `ENABLE) begin
    //         l2_index = l2_index_ic;
    //     end else if(drq == `ENABLE)begin 
    //         l2_index = l2_index_dc;
    //     end
    // end
    // sram_512x512 
    sram_512 #(512) data_way0(
        .clk    (clk),
        .a      (l2_index),
        .wr     (l2_data0_rw),
        .rd     (l2_data0_rd),
        .wd     (l2_data_wd)
        );
    // sram_512x512 
    sram_512 #(512) data_way1(
        .clk    (clk),
        .a      (l2_index),
        .wr     (l2_data1_rw),
        .rd     (l2_data1_rd),
        .wd     (l2_data_wd)
        );
    // sram_512x512 
    sram_512 #(512) data_way2(
        .clk    (clk),
        .a      (l2_index),
        .wr     (l2_data2_rw),
        .rd     (l2_data2_rd),
        .wd     (l2_data_wd)
        );
    // sram_512x512 
    sram_512 #(512) data_way3(
        .clk    (clk),
        .a      (l2_index),
        .wr     (l2_data3_rw),
        .rd     (l2_data3_rd),
        .wd     (l2_data_wd)
        );

endmodule