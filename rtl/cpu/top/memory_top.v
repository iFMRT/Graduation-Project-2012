////////////////////////////////////////////////////////////////////
// Engineer:       Kippy Chen - 799182081@qq.com                  //
//                                                                //
// Additional contributions by:                                   //
//                 Beyond Sky - fan-dave@163.com                  //
//                 Junhao Chang                                   //
//                 Leway Colin - colin4124@gmail.com              //
//                                                                //
// Design Name:    memory_top                                     //
// Project Name:   FMRT Mini Core                                 //
// Language:       Verilog                                        //
//                                                                //
// Description:    Control part of I-Cache.                       //
//                                                                //
////////////////////////////////////////////////////////////////////

`timescale 1ns/1ps

/********** General header file **********/
`include "common_defines.v"
`include "l1_cache.h"
`include "l2_cache.h"
module memory_top(
	 /*********** Clk & Reset *********/
    input  wire            clk,                // clock
    input  wire            rst,                // reset   
    output wire            memory_en,
    /********* L2_Cache part *********/
    input  wire             l2_busy,
    input  wire     [27:0]  l2_addr,
    input  wire             l2_choose_l1,
    input  wire     [1:0]   l2_choose_way,
    input  wire             l2_cache_rw,    
    output wire            l2_block0_we_mem,       // write signal mark of cache_block0
    output wire            l2_block1_we_mem,       // write signal mark of cache_block1 
    output wire            l2_block2_we_mem,       // write signal mark of cache_block2 
    output wire            l2_block3_we_mem,       // write signal mark of cache_block3
    output wire    [8:0]   l2_index_mem,
    input  wire [`WORD_DATA_BUS] wr_data_l2,
    output wire [`WORD_DATA_BUS] wr_data_mem,
    output wire [`WORD_DATA_BUS] wr_data_read,
    // l2_tag part
    input  wire     [17:0]  l2_tag0_rd,         // read data of tag0
    input  wire     [17:0]  l2_tag1_rd,         // read data of tag1
    input  wire     [17:0]  l2_tag2_rd,         // read data of tag2
    input  wire     [17:0]  l2_tag3_rd,         // read data of tag3  
    output wire     [17:0]  l2_tag_wd_mem, 
    // l2_data part
    input  wire     [511:0] l2_data0_rd,        // read data of cache_data0
    input  wire     [511:0] l2_data1_rd,        // read data of cache_data1
    input  wire     [511:0] l2_data2_rd,        // read data of cache_data2
    input  wire     [511:0] l2_data3_rd,        // read data of cache_data3
    output wire            wd_from_mem_en,     // write data from MEM enable mark 
    output wire            wd_from_l1_en_mem,     // write data from MEM 
    // l2_thread part
    input  wire     [1:0]   l2_thread,           // read data of thread
    output wire    [1:0]   mem_thread,          // write data of thread
    /************* L1 part ***********/   
    /********* I_Cache part **********/
    output wire            mem_wr_ic_en,       // mem write icache mark
    input  wire             ic_en,              // icache request enable mark
    output wire     [27:0] ic_addr_mem,     
    input  wire      [27:0] ic_addr_l2,
    output wire     [7:0]  ic_index_mem,
    output wire     [20:0] ic_tag_wd_mem,
    output wire            ic_block0_we_mem,
    output wire            ic_block1_we_mem,
    /********* D_Cache part **********/
    // input               w_complete,
    input  wire [1:0]   dc_offset_l2,
    output wire  [1:0]   dc_offset_mem,
    output wire            mem_wr_dc_en,       // mem write dcache mark
    input  wire             read_en, 
    input  wire             dc_en,              // dcache request enable mark
    output wire     [7:0]  dc_index_mem,
    output wire     [20:0] dc_tag_wd_mem,
    output wire            dc_block0_we_mem,
    output wire            dc_block1_we_mem,
    output wire    [127:0] data_wd_l2_mem,         // write data to L1 from L2   
    output wire            dc_rw_mem,
    input  wire     [127:0] rd_to_l2,
    output wire    [127:0] rd_to_l2_mem,
    input  wire     [27:0]  dc_addr_l2,
    output wire    [27:0]  dc_addr_mem,
    output wire            l2_choose_l1_read,
    output wire    [1:0]   mem_thread_read,
    output wire            dc_rw_read,
    output wire    [27:0]  dc_addr_read,
    /********** memory part **********/
    input  wire             dc_rw,
    input  wire             access_mem_clean,
    input  wire             access_mem_dirty,
    output wire    [511:0] mem_rd,             // read data of MEM
    output wire    [1:0]   offset_mem,
    output wire            read_l2_en,
    output wire            memory_busy
    ); 
    wire               mem_complete_w;     // complete mark of writing into MEM
    wire               mem_complete_r;     // complete mark of reading from MEM
    
    wire       [511:0] mem_wd;             // write data of MEM
    wire       [25:0]  mem_addr;           // address of memory
    wire               mem_we;             // mark of writing to memory
    wire               mem_re;             // mark of reading from memory
 	/*******   Cache Ram   *******/
    mem mem(
        .clock          (clk),           // clock
        .rst            (rst),           // reset active  
        .rden           (mem_re),
        .wren           (mem_we),
        .address        (mem_addr),
        .mem_rd         (mem_rd),
        .mem_wd         (mem_wd),
        .complete_w     (mem_complete_w),
        .complete_r     (mem_complete_r)
        );

	memory_ctrl memory_ctrl(
        .clk                (clk),           // clock of L2C
        .rst                (rst),           // reset 
        /*l2_cache part*/ 
        .memory_en          (memory_en),
        .l2_busy            (l2_busy), 
        .l2_addr            (l2_addr),    // address of fetching instruction
        .l2_cache_rw        (l2_cache_rw),// read / write signal of CPU
        .l2_choose_l1       (l2_choose_l1),
        .l2_choose_way      (l2_choose_way),
        .l2_block0_we_mem   (l2_block0_we_mem),  // write signal of block0
        .l2_block1_we_mem   (l2_block1_we_mem),  // write signal of block1
        .l2_block2_we_mem   (l2_block2_we_mem),  // write signal of block2
        .l2_block3_we_mem   (l2_block3_we_mem),  // write signal of block3
        .l2_index_mem       (l2_index_mem),  
        .l2_tag0_rd         (l2_tag0_rd),    // read data of tag0
        .l2_tag1_rd         (l2_tag1_rd),    // read data of tag1
        .l2_tag2_rd         (l2_tag2_rd),    // read data of tag2
        .l2_tag3_rd         (l2_tag3_rd),    // read data of tag3
        .l2_tag_wd_mem      (l2_tag_wd_mem),     // write data of tag0                
        .wr_data_l2         (wr_data_l2),
        .wr_data_mem        (wr_data_mem),
        .wr_data_read       (wr_data_read),
        // l2_data part
        .l2_data0_rd        (l2_data0_rd),   // read data of cache_data0
        .l2_data1_rd        (l2_data1_rd),   // read data of cache_data1
        .l2_data2_rd        (l2_data2_rd),   // read data of cache_data2
        .l2_data3_rd        (l2_data3_rd),   // read data of cache_data3
        .wd_from_mem_en     (wd_from_mem_en),
        .wd_from_l1_en_mem  (wd_from_l1_en_mem),
        /*thread part*/
        .l2_thread          (l2_thread),
        .mem_thread         (mem_thread),
        .dc_offset_l2(dc_offset_l2),
        .dc_offset_mem(dc_offset_mem),
        /*I_Cache part*/ 
        .mem_wr_ic_en       (mem_wr_ic_en),
        .ic_en              (ic_en),         // busy signal of l2_cache
        .ic_index_mem       (ic_index_mem),
        .ic_tag_wd_mem      (ic_tag_wd_mem), 
        .ic_block0_we_mem   (ic_block0_we_mem),
        .ic_block1_we_mem   (ic_block1_we_mem),
        /*D_Cache part*/
        .mem_wr_dc_en       (mem_wr_dc_en),
        .read_en            (read_en),
        .dc_en              (dc_en),         // busy signal of l2_cache
        .dc_index_mem       (dc_index_mem),
        .dc_tag_wd_mem      (dc_tag_wd_mem), 
        .dc_block0_we_mem   (dc_block0_we_mem),
        .dc_block1_we_mem   (dc_block1_we_mem),       
        .data_wd_l2_mem     (data_wd_l2_mem),    // write data to L1C       
        .rd_to_l2           (rd_to_l2),
        .rd_to_l2_mem       (rd_to_l2_mem),
        .dc_addr_l2         (dc_addr_l2),
        .dc_addr_mem        (dc_addr_mem),
        .ic_addr_mem        (ic_addr_mem),
        .ic_addr_l2         (ic_addr_l2),
        .l2_choose_l1_read  (l2_choose_l1_read), 
        .mem_thread_read    (mem_thread_read),    
        .dc_rw_read         (dc_rw_read),          
        .dc_addr_read       (dc_addr_read),   
        .dc_rw              (dc_rw),  
        /*memory part*/
        .dc_rw_mem          (dc_rw_mem),
        .offset_mem         (offset_mem),
        .read_l2_en         (read_l2_en),
        .memory_busy        (memory_busy),
        .access_mem_clean   (access_mem_clean), 
        .access_mem_dirty   (access_mem_dirty),
        .mem_complete_w     (mem_complete_w),
        .mem_complete_r     (mem_complete_r),
        .mem_rd             (mem_rd),
        .mem_wd             (mem_wd), 
        .mem_addr           (mem_addr),     // address of memory
        .mem_we             (mem_we),       // mark of writing to memory
        .mem_re             (mem_re)        // mark of reading from memory
    );
endmodule