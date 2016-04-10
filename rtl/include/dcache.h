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
    
    // state of L1_icache
    `define L1_IDLE              3'h0  // free
    `define L1_ACCESS            3'h1  // access L1_icache
    `define L2_ACCESS            3'h2  // access L2_icache   
    `define WRITE_L1             3'h3  // write block to L1_icache
    `define WRITE_L2             3'h4  // write block to L1_icache
    `define WRITE_HIT            3'h5  // write block to L1_icache
    `define WAIT_L2_BUSY_CLEAN   3'h6  // wait for L2_icache
    `define WAIT_L2_BUSY_DIRTY   3'h7  // wait for L2_icache
`endif