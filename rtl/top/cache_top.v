/*
 -- ============================================================================
 -- FILE NAME   : l2_top.v
 -- DESCRIPTION : top of l2_cache
 -- ----------------------------------------------------------------------------
 -- Date:2016/4/13         Coding_by:kippy   
 -- ============================================================================
*/
`timescale 1ns/1ps

`include "stddef.h"
`include "l2_cache.h"
`include "icache.h"
`include "dcache.h"

module cache_top(
    input               clk,            // clock
    input               clk_2,          // clock of L2C
    input               rst,            // reset
    /*CPU part*/
    input      [31:0]   addr,           // address of accessing memory
    input      [31:0]   wr_data_m,
    input               memwrite_m,     // read / write signal of CPU
    input               access_mem,
    input               access_mem_ex,
    input      [31:0]   if_pc,          // address of fetching instruction
    output     [31:0]   insn,           // read data of CPU
    output              if_busy,        // the signal of stall caused by cache miss   
    output     [31:0]   read_data_m,    // read data of CPU
    output              mem_busy,       // the signal of stall caused by cache miss
    /*dcache part*/
    output              hitway,         // path hit mark                
    /*if_reg part*/
    output              data_rdy,       // tag hit mark
    /*l2_cache part*/       
    output              l2_miss_stall,
    /*memory part*/
    input               mem_complete,
    input       [511:0] mem_rd,
    output      [511:0] mem_wd,
    output      [25:0]  mem_addr,       // address of memory
    output              mem_rw          // read / write signal of memory
    ); 
       
    /*dcache part*/
    wire                drq; 
    wire                dc_rw_en;       // write enable signal
    wire                complete_dc;    // complete write from L2 to dcache
    wire        [127:0] data_rd;        // read data of L1_cache's data
    /*icache part*/
    wire                irq;
    wire                ic_rw_en;       // write enable signal 
    wire                complete_ic;    // complete write from L2 to icache
    /*l2_cache part*/
    wire                l2_complete;
    wire                l2_rdy;         // ready signal of L2_cache 
    wire                l2_busy;        // busy signal of L2_cache
    wire        [31:0]  l2_addr_ic;     // addr of l2_cache
    wire        [31:0]  l2_addr_dc;     // addr of l2_cache
    wire                l2_cache_rw_ic;
    wire                l2_cache_rw_dc; 
    wire        [127:0] data_wd_l2;     // write data to L1    
    wire                data_wd_l2_en;  

    l1_dc_top l1_dc_top(
        .clk            (clk),           // clock
        .rst            (rst),           // reset
        /* CPU part */
        .addr           (addr),          // address of fetching instruction
        .wr_data_m      (wr_data_m),
        .memwrite_m     (memwrite_m),    // read / write signal of CPU
        .access_mem     (access_mem), 
        .access_mem_ex  (access_mem_ex), 
        .read_data_m    (read_data_m),   // read data of CPU
        .mem_busy       (mem_busy),      // the signal of stall caused by cache miss
        /* L1_cache part */
        .hitway         (hitway),  
        .data_rd        (data_rd),    
        /* l2_cache part */
        .data_wd_l2     (data_wd_l2),    // write data of l2_cache
        .data_wd_l2_en  (data_wd_l2_en), // write data of l2_cache
        .l2_complete    (l2_complete),
        .l2_busy        (l2_busy),       // busy signal of l2_cache
        .l2_rdy         (l2_rdy),        // ready signal of l2_cache
        .complete_dc    (complete_dc),   // complete op writing to L1
        .drq            (drq),  
        .dc_rw_en       (dc_rw_en),     
        .l2_addr_dc     (l2_addr_dc),    
        .l2_cache_rw_dc (l2_cache_rw_dc)        
        );

    l1_ic_top l1_ic_top(
        .clk            (clk),              // clock
        .rst            (rst),              // reset
        /* CPU part */
        .if_pc          (if_pc),            // address of fetching instruction
        .insn           (insn),             // read data from cache to CPU
        .if_busy        (if_busy),          // the signal of stall caused by cache miss
        /* l2_cache part */
        .l2_busy        (l2_busy),          // busy signal of l2_cache
        .l2_rdy         (l2_rdy),           // ready signal of l2_cache
        .data_wd_l2     (data_wd_l2),       // write data of l2_cache
        .data_wd_l2_en  (data_wd_l2_en),    // write data of l2_cache
        .complete_ic    (complete_ic),      // complete op writing to L1
        .irq            (irq),
        .ic_rw_en       (ic_rw_en),       
        .l2_addr_ic     (l2_addr_ic),        
        .l2_cache_rw_ic (l2_cache_rw_ic),
        /* if_reg part */
        .data_rdy       (data_rdy)        
        );

    l2_top l2_top(
        .clk            (clk),              // clock of L2C
        .clk_2          (clk_2),
        .rst            (rst),              // reset
        /* CPU part */
        .l2_addr_ic     (l2_addr_ic),       // address of fetching instruction      
        .l2_addr_dc     (l2_addr_dc),       // address of fetching instruction
        .l2_cache_rw_ic (l2_cache_rw_ic),   // read / write signal of CPU
        .l2_cache_rw_dc (l2_cache_rw_dc),   // read / write signal of CPU
        .l2_busy        (l2_busy),
        .l2_miss_stall  (l2_miss_stall),    // stall caused by l2_miss
        .l2_rdy         (l2_rdy),
        .l2_complete    (l2_complete),
        /*icache part*/
        .drq            (drq),
        .dc_rw_en       (dc_rw_en),
        .complete_dc    (complete_dc),
        /*dcache part*/
        .irq            (irq),           // icache request
        .ic_rw_en       (ic_rw_en),      // write enable signal of icache
        .complete_ic    (complete_ic),   // complete write from L2 to L1
        /*l1_cache part*/
        .data_rd        (data_rd),       // write data to L1C       
        .data_wd_l2     (data_wd_l2),    // write data to L1C       
        .data_wd_l2_en  (data_wd_l2_en), 
        /*memory part*/
        .mem_complete   (mem_complete),
        .mem_rd         (mem_rd),
        .mem_wd         (mem_wd), 
        .mem_addr       (mem_addr),      // address of memory
        .mem_rw         (mem_rw)         // read / write signal of memory
    );
endmodule