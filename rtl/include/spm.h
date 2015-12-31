`ifndef __SPM_HEADER__
	`define __SPM_HEADER__
/*
 *   SPM Size:   16384 Byte (16KB)
 *	 SPM_DEPTH:  16384 / 4  = 4096
 *	 SPM_ADDR_W: log2(4096) = 12
 */

	`define SPM_SIZE   16384 // 16384Byte（16KB）
	`define SPM_DEPTH  4096	 // SPM depth
	`define SPM_ADDR_W 12	 // Address width
	`define SpmAddrBus 11:0	 // Address bus
	`define SpmAddrLoc 11:0	 // Address location

`endif

