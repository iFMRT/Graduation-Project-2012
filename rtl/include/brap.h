//------------------------------------------------------------
// FILENAME: brap.h
// DESCRIPTION: The header file of branch pridect unit
// CODER: cjh
// TIME: 2016-03-25 16:16:23					
//------------------------------------------------------------- 

`ifndef __BRAP_HEADER__
	`define __BRAP_HEADER__		 

	/********** target address buffer *********/
	`define RamAddressBus			8:0 		// ram address bus 
	`define TargetAddrBus			31:0	 	// target address bus
	`define TargetRamBus 			53:0	 	// ram bus of block0 -- block3 
	`define PlruRamBus 				2:0 		// plru ram bus
	`define TagBus 					20:0 		// target ram tag bus
	`define DataTag 				53:33 		// tag in ram data
	`define PcAddress 				10:2 		// adrress in pc
	`define PcTag					31:11		// tag in pc
	`define DataTar					32:1 		// target in target and en


	/****** branch pridector module *******/
	`define PreTagBus 				7:0 		// predictor tag bus
	`define RdTag					10:3 		// tag in read data
	`define PreCouBus				1:0 		// predictor counter data bus
	`define RdCounter 				2:1 		// counter in data bus
	`define HitBlockBus				1:0 		// hit block bus
	`define Bl0AddrBus 				11:0  		// block0 address bus
	`define Bl0DataBus 				2:0 		// block0 data bus
	`define PcBl0Addr1				13:2 		// block0 address one in pc
	`define PcBl0Addr2				31:21 		// block0 address two in pc
	`define BlAddrBus 				9:0 		// block address bus
	`define BlDataBus 				10:0 		// block data bus
	`define PcBlAddr1				11:2 		// block address one in pc
	`define PcBlAddr2				31:22 		// block address two in pc

	`define HIT_BLOCK0 				2'b00 		// hit block0
	`define HIT_BLOCK1 				2'b01 	 	// hit block1
	`define	HIT_BLOCK2 				2'b10 		// hit block2
	`define HIT_BLOCK3 				2'b11 		// hit block3
	
`endif 