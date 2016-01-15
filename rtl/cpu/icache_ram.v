/*
 -- ============================================================================
 -- FILE NAME   : icache_ram.v
 -- DESCRIPTION : ram of cache
 -- ----------------------------------------------------------------------------
 -- Date:2016/1/8         Coding_by:kippy   
 -- ============================================================================
*/
/********** General header file **********/
`include "stddef.h"

module tag_ram(
    input               clk,    // clock
    input               we,     // read / write signal of cache
    input       [7:0]   a,      // address of cache
    input       [19:0]  wd,     // write data of tag
    output      [19:0]  rd,     // read data of tag
    output reg          valid   // the mark if cache is valid
    );
    reg         [20:0]  ram_tag[255:0];

    assign rd = ram_tag[a];
    always @(posedge clk) 
        if (we == `WRITE) begin
            ram_tag[a]<=wd;
            valid =`ENABLE;
        end
endmodule

/********** General header file **********/
`include "stddef.h"

module data_ram(
    input           clk,    // clock
    input           we,     // read / write signal of cache
    input   [7:0]   a,      // address of cache
    input   [127:0] wd,     // write data of cache
    output  [127:0] rd      // read data of cache
    );
    reg     [127:0] ram_data[255:0];

    assign rd = ram_data[a];
    always @(posedge clk) 
        if (we == `WRITE) 
            ram_data[a]<=wd;
endmodule