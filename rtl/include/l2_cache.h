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
    `define WAY0                 2'h0  // first WAY
    `define WAY1                 2'h1  // second WAY
    `define WAY2                 2'h2  // third WAY
    `define WAY3                 2'h3  // forth WAY
    // word chooses
    `define WORD0                 2'h0  // first word
    `define WORD1                 2'h1  // second word
    `define WORD2                 2'h2  // third word
    `define WORD3                 2'h3  // forth word
    // state of L2_icache
    `define L2_IDLE              3'h0  // free
    `define ACCESS_L2            3'h1  // access L2_icache
    `define LOAD_BLOCK			 3'h2  // load L2_icache's dirty block to memory
    `define MEM_ACCESS           3'h3  // access memory
    `define WRITE_L1             3'h4  // write block to L1_icache
    `define WRITE_L2             3'h5  // write block to L2_icache from memory
    `define WRITE_HIT            3'h6  // write block to L2_icache from L1
`endif