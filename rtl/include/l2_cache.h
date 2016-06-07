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
    // data base
    `define L2_DATA_BUS          511:0 // L2 DATA_BLOCK data bus
    `define L2_ADDR_BUS          27:0  // L2 address bus
    `define L2_TAG_BUS           17:0  // L2 DATA_BLOCK data bus
    `define L2_INDEX_BUS         8:0   // L2 INDEX bus
    `define L2_CHO0SE_BUS        1:0  // Byte data bus
    // path chooses
    `define L2_WAY0              2'h0  // first WAY
    `define L2_WAY1              2'h1  // second WAY
    `define L2_WAY2              2'h2  // third WAY
    `define L2_WAY3              2'h3  // forth WAY
    // state of L2_icache
    `define L2_IDLE              3'h0  // free
    `define ACCESS_L2            3'h1  // access L2_cache
    `define MEM_BUSY             3'h2
    `define L2_WRITE_HIT         3'h3  // write block to L2_cache from L1
    `define WRITE_DC_W           3'h4  // write block to L1_dcache,CPU wr signal is write
    `define L1_WRITE_L2          3'h5  // access MEM with dirty,then write block of MEM to L2_cache    
    `define MEM_WRITE_L2         3'h6  
`endif