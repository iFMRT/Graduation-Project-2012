/*
 -- ============================================================================
 -- FILE NAME   : icache_ram.v
 -- DESCRIPTION : ram of cache
 -- ----------------------------------------------------------------------------
 -- Date:2016/1/18         Coding_by:kippy   
 -- ============================================================================
*/
`timescale 1ns/1ps
/********** General header file **********/
`include "stddef.h"

module tag_ram(
    input               clk,            // clock
    input               tag0_rw,        // read / write signal of tag0
    input               tag1_rw,        // read / write signal of tag1
    input       [7:0]   index,          // address of cache
    input       [19:0]  tag_wd,         // write data of tag
    output      [20:0]  tag0_rd,        // read data of tag0
    output      [20:0]  tag1_rd,        // read data of tag1
    output              LUR,            // read data of tag
    output  reg         complete        // complete write from L2 to L1
    );
    reg         [42:0]  ram_tag[255:0]; // ram of tag
    wire        [42:0]  rd;             // read data of tag
    wire        [42:0]  read;           // read data of tag
    reg         [42:0]  wd0,wd1,wd;     // write data of tag

    integer  i=0;
    initial begin
        while (i < 256) begin
            ram_tag[i]  <= 43'b0;
            i = i + 1;
        end
    end
   
    assign LUR     = rd[42];
    assign tag0_rd = {rd[40],rd[19:0]};
    assign tag1_rd = {rd[41],rd[39:20]};
    assign read    = ram_tag[index];
    assign rd      = ((tag0_rw == `WRITE) || (tag1_rw == `WRITE)) ? wd : ram_tag[index];
   always @(*) begin
       wd0              <= {1'b1,read[41],1'b1,read[39:20],tag_wd};
       wd1              <= {1'b0,1'b1,read[40],tag_wd,read[19:0]};
   end
    always @(posedge clk) begin
        complete     <= `DISABLE;
        if (tag0_rw == `WRITE) begin
            wd <= wd0;
            ram_tag[index]  <= wd0;
            complete     <= `ENABLE;            
        end else if (tag1_rw == `WRITE) begin
            wd <= wd1;
            ram_tag[index]  <= wd1;
            complete     <= `ENABLE;
        end
    end
endmodule

/********** General header file **********/
`include "stddef.h"

module data_ram(
    input           clk,             // clock
    input           data0_rw,        // the mark of cache_data0 write signal 
    input           data1_rw,        // the mark of cache_data1 write signal 
    input   [7:0]   index,           // address of cache
    input   [127:0] data_wd,         // write data of L2_cache
    output  [127:0] data0_rd,        // read data of cache_data0
    output  [127:0] data1_rd         // read data of cache_data1
    );
    reg     [255:0] ram_data[255:0]; // ram of data
    wire    [255:0]  rd;             // read data of data
    wire    [255:0]  read;           // read data of data
    reg     [255:0]  wd,wd0,wd1;             // write data of data
    integer  i=0;
    initial begin
        while (i <=8'd255) begin
            ram_data[i]  <= 256'b0;
            i = i + 1;
        end
    end

    assign data0_rd = rd[127:0];
    assign data1_rd = rd[255:128];
    assign read     = ram_data[index];
    assign rd       = ((data0_rw == `WRITE) || (data1_rw == `WRITE)) ? wd : ram_data[index];
    always @(*) begin
       wd0              <= {read[255:128],data_wd};
       wd1              <= {data_wd,read[127:0]};
    end
    always @(posedge clk) begin
        if (data0_rw == `WRITE) begin
            wd <= wd0;
            ram_data[index] <= wd0;
        end else if (data1_rw == `WRITE) begin
            wd <= wd1;
            ram_data[index] <= wd1;
        end
    end       
endmodule

/********** General header file **********/
`include "stddef.h"

module L2_tag_ram(    
    input               clk,               // clock
    input               L2_tag0_rw,        // read / write signal of tag0
    input               L2_tag1_rw,        // read / write signal of tag1
    input               L2_tag2_rw,        // read / write signal of tag2
    input               L2_tag3_rw,        // read / write signal of tag3
    input       [8:0]   L2_index,          // address of cache
    input       [16:0]  L2_tag_wd,         // write data of tag
    output      [18:0]  L2_tag0_rd,        // read data of tag0
    output      [18:0]  L2_tag1_rd,        // read data of tag1
    output      [18:0]  L2_tag2_rd,        // read data of tag2
    output      [18:0]  L2_tag3_rd,        // read data of tag3
    output      [2:0]   PLUR,              // read data of tag
    output reg          L2_complete        // complete write from L2 to L1
    );
    reg         [77:0]  ram_tag[511:0];    // ram of tag
    wire        [77:0]  rd;                // read data of tag
    wire        [77:0]  read;              // read data of tag
    reg         [77:0]  wd,wd0,wd1,wd2,wd3;// write data of tag
    integer  i=0;
    initial begin
        while(i <=511) begin
            ram_tag[i] <= 76'b0;
            i = i + 1;
        end
    end

    assign PLUR       = rd[77:75];
    assign L2_tag0_rd = {rd[71],rd[67],rd[16:0]};
    assign L2_tag1_rd = {rd[72],rd[68],rd[33:17]};
    assign L2_tag2_rd = {rd[73],rd[69],rd[50:34]};
    assign L2_tag3_rd = {rd[74],rd[70],rd[67:51]};  
    assign read = ram_tag[L2_index];
    assign rd =  ((L2_tag0_rw == `WRITE) || (L2_tag1_rw == `WRITE) 
                   || (L2_tag2_rw == `WRITE) || (L2_tag3_rw == `WRITE)) 
                   ? wd : ram_tag[L2_index];
    always @(*) begin
        wd0 = {read[77],2'b11,read[74:72],1'b1,read[70:17],L2_tag_wd};
        wd1 = {read[77],2'b01,read[74:73],1'b1,read[71:34],L2_tag_wd,read[16:0]};
        wd2 = {1'b1,read[76],1'b0,read[74],1'b1,read[72:51],L2_tag_wd,read[33:0]};
        wd3 = {1'b0,read[76],1'b0,1'b1,read[73:67],L2_tag_wd,read[50:0]};
    end
    always @(posedge clk) begin
         L2_complete       <= `DISABLE;
        if (L2_tag0_rw == `WRITE) begin // 只指令cache，先不考虑dirty
            wd<=wd0;
            ram_tag[L2_index] <= wd0;
            L2_complete       <= `ENABLE;
        end else if (L2_tag1_rw == `WRITE) begin
            wd<=wd1;
            ram_tag[L2_index] <= wd1;
            L2_complete       <= `ENABLE;
        end else if (L2_tag2_rw == `WRITE) begin
            wd<=wd2;
            ram_tag[L2_index] <= wd2;
            L2_complete       <= `ENABLE;
        end else if (L2_tag3_rw == `WRITE) begin
            wd<=wd3;
            ram_tag[L2_index] <= wd3;
            L2_complete       <= `ENABLE;
        end
    end
        

endmodule

/********** General header file **********/
`include "stddef.h"

module L2_data_ram(
    input           clk,                    // clock
    input           L2_data0_rw,            // the mark of cache_data0 write signal 
    input           L2_data1_rw,            // the mark of cache_data1 write signal 
    input           L2_data2_rw,            // the mark of cache_data2 write signal 
    input           L2_data3_rw,            // the mark of cache_data3 write signal 
    input   [8:0]   L2_index,               // address of cache
    input   [511:0] L2_data_wd,             // write data of L2_cache
    output  [511:0] L2_data0_rd,            // read data of cache_data0
    output  [511:0] L2_data1_rd,            // read data of cache_data1
    output  [511:0] L2_data2_rd,            // read data of cache_data2
    output  [511:0] L2_data3_rd             // read data of cache_data3
    );
    reg     [2047:0]  ram_data[511:0];      // ram of data
    wire    [2047:0]  rd;                   // read data of data
    wire    [2047:0]  read;                 // read data of data
    reg    [2047:0]  wd,wd0,wd1,wd2,wd3;    // write data of data
    integer  i=0;
    initial begin
        while(i <=511) begin
            ram_data[i]<=2048'b0;
            i = i + 1;
        end
    end

    assign L2_data0_rd = rd[511:0];
    assign L2_data1_rd = rd[1023:512];
    assign L2_data2_rd = rd[1535:1024];
    assign L2_data3_rd = rd[2047:1536];
    assign read     = ram_data[L2_index];
    assign rd       = ((L2_data0_rw == `WRITE) || (L2_data1_rw == `WRITE)
                                || (L2_data2_rw == `WRITE)|| (L2_data3_rw == `WRITE)) 
                                                    ? wd : ram_data[L2_index];
    always @(*) begin
        wd0 = {read[2047:1536],read[1535:1024],read[1023:512],L2_data_wd};
        wd1 = {read[2047:1536],read[1535:1024],L2_data_wd,read[511:0]};
        wd2 = {read[2047:1536],L2_data_wd,read[1023:512],read[511:0]};
        wd3 = {L2_data_wd,read[1535:1024],read[1023:512],read[511:0]};
    end
    always @(posedge clk) begin
        if (L2_data0_rw == `WRITE) begin
            wd              <= wd0;
            ram_data[L2_index] <= wd0;
        end else if (L2_data1_rw == `WRITE) begin
            wd              <= wd1;
            ram_data[L2_index] <= wd1;
        end else if (L2_data2_rw == `WRITE) begin
            wd              <= wd2;
            ram_data[L2_index] <= wd2;
        end else if (L2_data3_rw == `WRITE) begin
            wd              <= wd3;
            ram_data[L2_index] <= wd3;
        end
    end
endmodule