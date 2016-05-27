/*
 -- ============================================================================
 -- FILE NAME   : icache.h
 -- DESCRIPTION : header file of icache
 -- ----------------------------------------------------------------------------
 -- Date:2016/1/17        Coding_by:kippy
 -- ============================================================================
*/

 `ifndef __ICACHE_HEADER__
    `define __ICACHE_HEADER__   

//------------------------------------------------------------------------------
// Operation
//------------------------------------------------------------------------------
    
    // state of L1_icache
    `define IC_IDLE              3'h0  // L1_icache is idle
    `define IC_ACCESS            3'h1  // access L1_icache
    `define IC_ACCESS_L2         3'h2  // access L2_icache
    `define WAIT_L2_BUSY         3'h3  // wait for L2_cache
    `define WRITE_IC             3'h4  // write block to L1_icache
`endif