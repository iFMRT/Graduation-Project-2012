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
    `define MEM_IDLE             3'h0  // free
    `define READ_MEM             3'h1
    `define WRITE_MEM			 3'h2  // load L2_cache's dirty block to memory
    `define WRITE_TO_L2_CLEAN    3'h3  // access MEM with clean,then write block of MEM to L2_cache 
    `define COMPLETE_WRITE_CLEAN 3'h4
    `define WRITE_TO_L2_DIRTY_R  3'h5  // access MEM with dirty,then write block of MEM to L2_cache
    `define WRITE_TO_L2_DIRTY_W  3'h6  // access MEM with dirty,then write block of MEM to L2_cache    
`endif