////////////////////////////////////////////////////////////////////////
// Engineer:       Kippy Chen - 799182081@qq.com                      //
//                                                                    //
// Additional contributions by:                                       //
//                 Beyond Sky - fan-dave@163.com                      //
//                 Leway Colin - colin4124@gmail.com                  //
//                 Junhao Chang                                       //
//                                                                    //
// Design Name:    Rrequently-used Header Files                       //
// Project Name:   FMRT Mini Core                                     //
// Language:       Verilog                                            //
//                                                                    //
// Description:    Defines for frequently-used constants used by      //
//                 all the  components.                               //
//                                                                    //
////////////////////////////////////////////////////////////////////////

`ifndef __COMMON_DEFINES__
`define __COMMON_DEFINES__

// -----------------------------------------------------------------------
// Signal Values
// -----------------------------------------------------------------------

/********** ENABLE / DISABLE *********/
// positive logic
`define DISABLE             1'b0    // Disable
`define ENABLE              1'b1    // Enable

// negative logic
`define DISABLE_            1'b1    // Disable
`define ENABLE_             1'b0    // Enable

/********** Read / Write  *********/
`define READ                1'b0    // Read signal
`define WRITE               1'b1    // Write signal

// -----------------------------------------------------------------------
// Data Bus
// -----------------------------------------------------------------------

/********** Least Significant Bit *********/
// `define LSB                 0    // Least Significant Bit
/********** Byte (8 bit) ********/
// `define BYTE_DATA_W         8    // Byte width
// `define BYTE_MSB            7    // Most Significant Bit
// `define BYTE_DATA_BUS       7:0  // Byte data bus
/********** Word (32 bit) *********/
`define WORD_DATA_W       32   // Word width

`define WORD_MSB            31  // Most Significant Bit
`define WORD_DATA_BUS     31:0 // Word data bus

/********** Word Data Address *********/
`define WORD_ADDR_BUS			29:0	// Word address bus
`define WORD_ADDR_W			  30	 // Word address bus

`endif
