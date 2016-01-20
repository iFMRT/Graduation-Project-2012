/*
 -- ============================================================================
 -- FILE NAME   : icache_top.v
 -- DESCRIPTION : 指令高速缓存器顶层
 -- ----------------------------------------------------------------------------
 -- Date:2016/1/9         Coding_by:kippy
 -- Data:2016/1/20        
 -- Comment：It is the top of L1_icache.Now it is useless for new L2C.
 -- ============================================================================
*/

/********** General header file **********/
`include "stddef.h"

module icache_top(
  input         clk,        // clock
  input         rst,        // reset  
  input  [31:0] if_addr,    // address of fetching instruction
  input         rw,         // read / write signal of CPU
  input  [31:0] wd,         // write data of CPU
  output [31:0] cpu_data,   // read data of CPU
  output        miss_stall  // the signal of stall caused by cache miss
 );
  wire          valid;      // the mark if tag is valid
  wire [20:0]   tag_rd;     // read data of tag
  wire [19:0]   tag_wd;     // write data of tag
  wire [127:0]  cache_rd;   // read data of cache
  wire [127:0]  cache_wd;   // write data of cache
  wire          cache_rw;   // read / write signal of cache
  wire [7:0]    index;      // address of cache
  wire [27:0]   mem_addr;   // address of memory
  wire          mem_rw;     // read / write signal of memory
  wire [31:0]   mem_rd3;    // read data of ram3
  wire [31:0]   mem_rd2;    // read data of ram2
  wire [31:0]   mem_rd1;    // read data of ram1
  wire [31:0]   mem_rd0;    // read data of ram0

    icache icache(
        .rst        (rst),          // reset
        /* CPU part */
        .if_addr    (if_addr),      // address of fetching instruction
        .rw         (rw),           // read / write signal of CPU
        .wd         (wd),           // write data of CPU
        .cpu_data   (cpu_data),     // read data of CPU
        .miss_stall (miss_stall),   // the signal of stall caused by cache miss
        /*cache part*/
        .valid      (tag_rd[20]),   // the mark if tag is valid
        .tag_rd     (tag_rd[19:0]), // read data of tag
        .cache_rd   (cache_rd),     // read data of cache
        .cache_rw   (cache_rw),     // read / write signal of cache
        .tag_wd     (tag_wd),       // write data of tag
        .index      (index),        // address of cache
        /*memory part*/
        .mem_addr   (mem_addr),     // address of memory
        .mem_rw     (mem_rw)        // read / write signal of memory
        );

    tag_ram tag_ram(
        .clk    (clk),              // clock
        .we     (cache_rw),         // read / write signal of cache     
        .a      (index),            // address of cache
        .wd     (tag_wd),           // write data of tag
        .rd     (tag_rd),           // read data of tag
        .valid  (valid)             // the mark if tag is valid
        );

    data_ram data_ram(
        .clk    (clk),              // clock
        .we     (cache_rw),         // read / write signal of cache
        .a      (index),            // address of cache
        .wd     (cache_wd),         // write data of cache
        .rd     (cache_rd)          // read data of cache
        );

    ram0 ram0(
        .a      (mem_addr),         // address of memory
        .rd     (mem_rd0)           // read data of ram0
        );

    ram1 ram1(
        .a      (mem_addr),         // address of memory
        .rd     (mem_rd1)           // read data of ram1
        );

    ram2 ram2(
        .a      (mem_addr),         // address of memory
        .rd     (mem_rd2)           // read data of ram2
        );

    ram3 ram3(
        .a      (mem_addr),         // address of memory
        .rd     (mem_rd3)           // read data of ram3
        );
  assign cache_wd = {mem_rd3,mem_rd2,mem_rd1,mem_rd0};

  endmodule
