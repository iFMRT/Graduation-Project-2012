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

/********** Default Net Type **********/
`default_nettype none      // none (Recommended)
//  `default_nettype wire      // wire (Verilog Standard)
// -----------------------------------------------------------------------------
// Thread in Cache
// -----------------------------------------------------------------------------
    `define THREAD_BUS              1:0  // Byte data bus
// -----------------------------------------------------------------------------
// word chooses in cache
// -----------------------------------------------------------------------------
    `define OFFSET_BUS              1:0  // Byte data bus
// -----------------------------------------------------------------------------
// word chooses in cache
// -----------------------------------------------------------------------------
    `define CLOCK0                  2'h0  // first clock
    `define CLOCK1                  2'h1  // second clock
    `define CLOCK2                  2'h2  // third clock
    `define CLOCK3                  2'h3  // forth clock
// -----------------------------------------------------------------------------
// word chooses in cache
// -----------------------------------------------------------------------------
    `define WORD0                   2'h0  // first word
    `define WORD1                   2'h1  // second word
    `define WORD2                   2'h2  // third word
    `define WORD3                   2'h3  // forth word
    // path chooses in L1_cache
    `define WAY0                    1'h0  // first WAY
    `define WAY1                    1'h1  // second WAY

// -----------------------------------------------------------------------
// Signal Values
// -----------------------------------------------------------------------                  
    /********** ENABLE / DISABLE *********/
    // positive logic
    `define DISABLE                 1'b0    // Disable
    `define ENABLE                  1'b1    // Enable

    // negative logic
    `define DISABLE_                1'b1    // Disable
    `define ENABLE_                 1'b0    // Enable

    /********** Read / Write  *********/
    `define READ                    1'b0    // Read signal
    `define WRITE                   1'b1    // Write signal

// -----------------------------------------------------------------------
// Data Bus
// -----------------------------------------------------------------------

    /********** Least Significant Bit *********/
    `define LSB                 0    // Least Significant Bit
    /********** Byte (8 bit) ********/
    `define BYTE_DATA_W         8    // Byte width
    `define BYTE_MSB            7    // Most Significant Bit
    `define BYTE_DATA_BUS       7:0  // Byte data bus
    /********** 字七位移 *********/ 
    `define BYTE_OFFSET_W           2     // 位移位宽 
    `define BYTE_OFFSET_BUS         1:0   // 位移总线 
    /********** 字地址索引 *********/ 
    `define WORD_ADDR_LOC           31:2  // 字地址位置    
    `define BYTE_OFFSET_LOC         1:0   // 字节位移位置 
    /********** 字节的偏移值 *********/ 
    `define BYTE_OFFSET_WORD        2'b00 // 字边界 
    `define BYTE_OFFSET_HALF_WORD   1'b0  // 半字边界
    
    /********** Word (32 bit) *********/
    `define WORD_DATA_W             32   // Word width

    `define WORD_MSB                31  // Most Significant Bit
    `define WORD_DATA_BUS           31:0 // Word data bus

    /********** Word Data Address *********/
    `define WORD_ADDR_BUS           29:0    // Word address bus
    `define WORD_ADDR_MSB           29      // 最高位 
    `define WORD_ADDR_W             30      // Word address bus

    // Memory
    `define RAM_DEPTH               16384
`endif
