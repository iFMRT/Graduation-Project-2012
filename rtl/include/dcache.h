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
    `define DC_IDLE              4'h0  // free
    `define DC_ACCESS            4'h1  // access L1_dcache
    `define DC_ACCESS_L2         4'h2  // access L2_cache   
    `define WAIT_L2_BUSY_CLEAN   4'h3  // wait for L2_cache
    `define WAIT_L2_BUSY_DIRTY   4'h4  // wait for L2_icache
    `define WRITE_DC_R           4'h5  // write block to L1_dcache,CPU wr signal is read
    `define WRITE_DC_W           4'h6  // write block to L1_dcache,CPU wr signal is write
    `define WRITE_HIT            4'h7  // write block to L1_dcache
    `define DC_WRITE_L2          4'h8  // write L1_dcache's block to L2_cache
`endif