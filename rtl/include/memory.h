/*
 -- ============================================================================
 -- FILE NAME   : memory.h
 -- DESCRIPTION : header file of Memory
 -- ----------------------------------------------------------------------------
 -- Date:2016/5/24        Coding_by:kippy
 -- ============================================================================
*/

 `ifndef __MEMORY_HEADER__
    `define __MEMORY_HEADER__   

//------------------------------------------------------------------------------
// Operation
//------------------------------------------------------------------------------
    // state of L2_icache
    `define MEM_IDLE             2'h0  // free
    `define READ_MEM             2'h1
    `define WRITE_MEM			 2'h2  // load L2_cache's dirty block to memory
    `define READ_NEW_L2          2'h3 
`endif