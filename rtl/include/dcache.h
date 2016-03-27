/*
 -- ============================================================================
 -- FILE NAME   : dcache.h
 -- DESCRIPTION : header file of dcache
 -- ----------------------------------------------------------------------------
 -- Date:2016/3/22        Coding_by:kippy
 -- ============================================================================
*/

 `ifndef __DCACHE_HEADER__
    `define __DCACHE_HEADER__   

//------------------------------------------------------------------------------
// Operation
//------------------------------------------------------------------------------
    // path chooses
    `define WAY0                 1'h0  // first WAY
    `define WAY1                 1'h1  // second WAY
    // word chooses
    `define WORD0                 2'h0  // first word
    `define WORD1                 2'h1  // second word
    `define WORD2                 2'h2  // third word
    `define WORD3                 2'h3  // forth word
    // state of L1_icache
    `define L1_IDLE              3'h0  // free
    `define L1_ACCESS            3'h1  // access L1_icache
    `define L2_ACCESS            3'h2  // access L2_icache
    `define WAIT_L2_BUSY         3'h3  // wait for L2_icache
    `define WRITE_L1             3'h4  // write block to L1_icache
    `define LOAD_BLOCK			 3'h5  // load dirty block to L2
    `define WRITE_HIT            3'h6  // write block to L1_icache
`endif