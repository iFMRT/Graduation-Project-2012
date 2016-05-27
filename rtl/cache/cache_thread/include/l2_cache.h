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
    `define L2_IDLE              3'h0  // free
    `define ACCESS_L2            3'h1  // access L2_cache
    `define MEM_BUSY             3'h2
    `define L2_WRITE_L1          3'h3
    `define COMPLETE_ACCESS_MEM  3'h4
    `define L2_WRITE_HIT         3'h5  // write block to L2_cache from L1
`endif