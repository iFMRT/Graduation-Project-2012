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
    `define DC_ACCESS_L2         3'h2  // access L2_cache   
    `define WAIT_L2_BUSY_CLEAN   3'h3  // wait for L2_cache
    `define WAIT_L2_BUSY_DIRTY   3'h4  // wait for L2_icache
    `define WRITE_DC_R           3'h5  // write block to L1_dcache,CPU wr signal is read
    `define WRITE_DC_W           3'h6  // write block to L1_dcache,CPU wr signal is write
    `define WRITE_HIT            3'h7  // write block to L1_dcache
`endif