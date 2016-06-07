/*
 -- ============================================================================
 -- FILE NAME   : l1_cache.h
 -- DESCRIPTION : header file of icache
 -- ----------------------------------------------------------------------------
 -- Date:2016/1/17        Coding_by:kippy
 -- ============================================================================
*/

 `ifndef __L1_CACHE_HEADER__
    `define __L1_CACHE_HEADER__   
//------------------------------------------------------------------------------
// State of L1_icache
//------------------------------------------------------------------------------
    `define L1_DATA_BUS          127:0 // L1 DATA_BLOCK data bus
    `define L1_TAG_BUS           20:0  // L1 DATA_BLOCK data bus
    `define L1_COMP_TAG_BUS      19:0
    `define L1_INDEX_BUS         7:0   // L1 INDEX bus
    `define PLRU_BUS             2:0   // L1 INDEX bus
    `define L1_STATE_BUS         1:0
//------------------------------------------------------------------------------
// State of L1_icache
//------------------------------------------------------------------------------
    `define IC_IDLE              3'h0  // L1_icache is idle
    `define IC_ACCESS            3'h1  // access L1_icache
    `define WAIT_L2_BUSY         3'h2  // wait for L2_cache
    `define WRITE_IC             3'h3  // write block to L1_icache
//------------------------------------------------------------------------------
// State of L1_dcache
//------------------------------------------------------------------------------    
    `define DC_IDLE              3'h0  // free
    `define DC_ACCESS            3'h1  // access L1_dcache 
    `define WAIT_L2_BUSY_CLEAN   3'h2  // wait for L2_cache
    `define WAIT_L2_BUSY_DIRTY   3'h3  // wait for L2_icache
    `define CPU_WRITE_DC         3'h4

`endif