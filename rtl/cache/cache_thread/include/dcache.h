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
    `define DC_IDLE              3'h0  // free
    `define DC_ACCESS            3'h1  // access L1_dcache 
    `define WAIT_L2_BUSY_CLEAN   3'h2  // wait for L2_cache
    `define WAIT_L2_BUSY_DIRTY   3'h3  // wait for L2_icache
    `define CPU_WRITE_DC         3'h4
`endif