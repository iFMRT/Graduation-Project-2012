/*
 -- ============================================================================
 -- FILE NAME   : l2_cache.h
 -- DESCRIPTION : header file of L2_cache
 -- ----------------------------------------------------------------------------
 -- Date:2016/3/22        Coding_by:kippy
 -- ============================================================================
*/

 `ifndef __L2_CACHE_HEADER__
    `define __L2_CACHE_HEADER__   

//------------------------------------------------------------------------------
// Operation
//------------------------------------------------------------------------------
    // path chooses
    `define L2_WAY0              2'h0  // first WAY
    `define L2_WAY1              2'h1  // second WAY
    `define L2_WAY2              2'h2  // third WAY
    `define L2_WAY3              2'h3  // forth WAY
    // state of L2_icache
    `define L2_IDLE              4'h0  // free
    `define ACCESS_L2            4'h1  // access L2_cache
    `define WRITE_MEM			 4'h2  // load L2_cache's dirty block to memory
    `define WRITE_TO_L2_CLEAN    4'h3  // access MEM with clean,then write block of MEM to L2_cache 
    `define WRITE_TO_L2_DIRTY_R  4'h4  // access MEM with dirty,then write block of MEM to L2_cache
    `define WRITE_TO_L2_DIRTY_W  4'h5  // access MEM with dirty,then write block of MEM to L2_cache
    `define L2_WRITE_HIT         4'h6  // write block to L2_cache from L1
    `define L2_WRITE_L1          4'h7
    `define READ_MEM             4'h8
    `define COMPLETE_WRITE_CLEAN 4'h9
`endif