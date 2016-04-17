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
    `define IC_ACCESS            2'h0  // access L1_icache
    `define IC_ACCESS_L2         2'h1  // access L2_icache
    `define WAIT_L2_BUSY         2'h2  // wait for L2_icache
    `define WRITE_IC             2'h3  // write block to L1_icache
`endif