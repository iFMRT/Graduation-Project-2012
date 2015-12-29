/**
 * filename : ctrl.h
 * author   : cjh
 * time     : 2015-12-28 15:50:16
 */

/******** Memory Opcode ********/
`ifndef  __MEM_HEADER__
    `define _MEM_HEADER_

    `define MEM_OP_W    4        // Memory opcode width
    `define MEM_OP_BUS 	3:0      // Memory opcode bus

    `define MEM_OP_NOP  4'h0
    `define MEM_OP_LB 	4'h1     // Load Byte
    `define MEM_OP_LH	4'h2     // Load Half word
 	`define MEM_OP_LW	4'h3     // Load Word
 	`define MEM_OP_LBU	4'h4     // Load Byte which is Unsigned
    `define MEM_OP_LHU	4'h5     // Load Half word which is Unsiged
    `define MEM_OP_SB	4'h6     // Store Byte
    `define MEM_OP_SH	4'h7     // Store Half word
    `define MEM_OP_SW	4'h8     // Store Word
`endif
