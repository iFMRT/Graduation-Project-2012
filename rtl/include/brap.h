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
	`define TarEnBus				32:0 		// the bus for target address an en
	`define DataTag 				53:33 		// tag in ram data
	`define PcAddress 				10:2 		// adrress in pc
	`define PcTag					31:11		// tag in pc
	`define DataTaren 				32:0 		// tar and en in block data
	`define DarenTar				32:1 		// tar in tar and en
`endif

	