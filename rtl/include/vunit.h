/**
 * filename: vunit.h
 * author  : besky
 * time    : 2015-12-16 19:09:03
 */

`ifndef __VUNIT_HEADER__
	`define __VUNIT_HEADER__			         // Include Guard
	
	`define VUNIT_OP_W         4           // op width
	`define VUNIT_OP_B         3:0         // op bus

	`define VUNIT_OP_EQ        4'h1        // option: equal
	`define VUNIT_OP_NEQ       4'h2        // option: not equal

	`define VUNIT_STEP         100.0000    // Clock Cycle or Time Delay

	/* only used in the VUNIT ========================================*/
	`define TRUE               1'b1        
	`define FALSE              1'b0

`endif

