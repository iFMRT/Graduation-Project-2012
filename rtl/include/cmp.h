/**
 * filename: cmp.h
 * author  : besky
 * time    : 2015-12-15 21:35:36
 */

`ifndef __CMP_HEADER__
	`define __CMP_HEADER__			         // Include Guard
	
	`define CMP_OP_NOP        3'o0       // option: nop
	`define CMP_OP_EQ         3'o1       // option: ==  equal
	`define CMP_OP_NE         3'o2       // option: !=  not equal
	`define CMP_OP_LT         3'o3       // option: <   lower than
	`define CMP_OP_LTU        3'o4       // option: <u  lower than unsigned
	`define CMP_OP_GE         3'o5       // option: >=  greater equal
	`define CMP_OP_GEU        3'o6       // option: >=u greater equal unsigned

	`define CMP_OP_W          3          // option width
	`define CMP_OP_BUS          2:0        // option bus

	`define CMP_TRUE          1'b1       // compare result: true
	`define CMP_FALSE         1'b0       // compare result: false
`endif

