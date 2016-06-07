/*
 -- ============================================================================
 -- FILE NAME   : l2_top.v
 -- DESCRIPTION : top of l2_cache
 -- ----------------------------------------------------------------------------
 -- Date:2016/4/13         Coding_by:kippy   
 -- ============================================================================
*/
`timescale 1ns/1ps

`include "common_defines.v"
`include "l1_cache.h"
`include "l2_cache.h"

module l2_top(
    /*********** Clk & Reset *********/
    input  wire                        clk,                // clock
    input  wire                        rst,                // reset
    input  wire                        dc_rw,             // read / write signal of CPU
    output wire                        l2_en,
    /********* L2_Cache part *********/
    output wire     [`OFFSET_BUS]      l2_offset,
    // output wire     [`OFFSET_BUS]      dc_offset_l2,
    // input  wire     [`OFFSET_BUS]      dc_offset_mem,
    output wire     [`L2_ADDR_BUS]     l2_addr,
    output wire                        l2_cache_rw,
    input  wire                        access_l2_clean,
    input  wire                        access_l2_dirty,
    output wire                        access_mem_clean,
    output wire                        access_mem_dirty,
    output wire                        l2_choose_l1,
    output wire     [`L2_CHO0SE_BUS]   choose_way,          
    output wire                        l2_rdy,             // ready mark
    output wire                        l2_busy,            // busy mark
    output wire     [`L2_DATA_BUS]     l2_data0_rd,    // read data of cache_data0
    output wire     [`L2_DATA_BUS]     l2_data1_rd,    // read data of cache_data1
    output wire     [`L2_DATA_BUS]     l2_data2_rd,    // read data of cache_data2
    output wire     [`L2_DATA_BUS]     l2_data3_rd,    // read data of cache_data3 
    output wire     [`L2_TAG_BUS]      l2_tag0_rd,    // read data of tag0
    output wire     [`L2_TAG_BUS]      l2_tag1_rd,    // read data of tag1
    output wire     [`L2_TAG_BUS]      l2_tag2_rd,    // read data of tag2
    output wire     [`L2_TAG_BUS]      l2_tag3_rd,    // read data of tag3
    
    // thread part
    input  wire     [`THREAD_BUS]      ic_thread,
    input  wire     [`THREAD_BUS]      dc_thread,
    input  wire     [`THREAD_BUS]      mem_thread,
    output wire     [`THREAD_BUS]      l2_thread,           // read data of thread
    /********* I_Cache part **********/
    input  wire                        irq,                // icache request
    input  wire                        ic_choose_way,
    input  wire     [`WORD_ADDR_BUS]   ic_addr,            // address of fetching instruction
    output wire     [`L2_ADDR_BUS]     ic_addr_l2,         // address of fetching instruction
    output wire                        ic_en,              // icache request enable mark
    output wire      [`L1_INDEX_BUS]   ic_index,
    output wire      [`L1_TAG_BUS]     ic_tag_wd,
    output wire                        ic_block0_we,
    output wire                        ic_block1_we,
    output wire                        data_wd_l2_en_dc,
    /********* D_Cache part **********/
    input  wire [1:0]   dc_offset,
    output wire  [1:0]   dc_offset_l2,
    input  wire                        drq,                // dcache request
    input  wire                        dc_choose_way,
    input  wire     [`L2_ADDR_BUS]     dc_addr,            // address of fetching instruction
    output wire                        dc_en,              // dcache request enable mark 
    output wire                        read_en,
    output wire     [`L1_INDEX_BUS]    dc_index,
    output wire     [`L1_TAG_BUS]      dc_tag_wd,
    output wire                        dc_block0_we,
    output wire                        dc_block1_we,
    input  wire     [`L1_DATA_BUS]     dirty_data,
    input  wire     [`L1_TAG_BUS]      dirty_tag,         // write data of dtag
    output wire     [`L2_ADDR_BUS]     dc_addr_l2,
    input  wire     [`WORD_DATA_BUS]   wr_data_dc,
    input  wire     [`WORD_DATA_BUS]   wr_data_read,
    output wire     [`WORD_DATA_BUS]   wr_data_l2,
    /************* L1 part ***********/
    output wire     [`L1_DATA_BUS]     data_wd_l2,         // write data to L1 from L2   
    /********** memory part **********/
    input  wire                        l2_block0_we_mem,
    input  wire                        l2_block1_we_mem,
    input  wire                        l2_block2_we_mem,
    input  wire                        l2_block3_we_mem,
    input  wire                        wd_from_mem_en,
    input  wire                        wd_from_l1_en_mem,
    input  wire     [`OFFSET_BUS]      offset_mem,
    input  wire     [`L1_DATA_BUS]     rd_to_l2_mem,
    output wire     [`L1_DATA_BUS]     rd_to_l2,
    input  wire     [`L2_DATA_BUS]     mem_rd,
    input  wire     [`L2_INDEX_BUS]    l2_index_mem,
    input  wire     [`L2_TAG_BUS]      l2_tag_wd_mem,
    input  wire                        l2_choose_l1_read,
    input  wire     [`THREAD_BUS]      mem_thread_read,
    input  wire                        dc_rw_read,
    input  wire     [`L2_ADDR_BUS]     dc_addr_read,
    input  wire                        read_l2_en,
    
    output wire                        dc_rw_l2,
    input  wire                        memory_busy
    ); 
    // l2_cache
    wire                           l2_block0_we;
    wire                           l2_block1_we;
    wire                           l2_block2_we;
    wire                           l2_block3_we;
    wire                           l2_block0_re;
    wire                           l2_block1_re;
    wire                           l2_block2_re;
    wire                           l2_block3_re;
    wire                           wd_from_l1_en;
    wire                           mem_wr_l2_en;
    wire     [`L2_TAG_BUS]         l2_tag_wd;     // write data of tag
    wire     [`L2_INDEX_BUS]       l2_index;
    // l2_tag_ram part
    wire     [`PLRU_BUS]           plru;          // read data of tag
    wire     [`THREAD_BUS]         l2_thread0;          // read data of thread0
    wire     [`THREAD_BUS]         l2_thread1;          // read data of thread1
    wire     [`THREAD_BUS]         l2_thread2;          // read data of thread2
    wire     [`THREAD_BUS]         l2_thread3;          // read data of thread3
    wire     [`THREAD_BUS]         l2_thread_wd; 
    wire                           l2_complete_r;
    wire                           l2_complete_w;
    // l2_data_ram
    wire     [`L2_DATA_BUS]        l2_data_wd_mem;     // write data of l2_cache
       // l2_dirty
    wire                           l2_dirty0;
    wire                           l2_dirty1;
    wire                           l2_dirty2;
    wire                           l2_dirty3;

    // l2_cache
    l2_cache_ctrl l2_cache_ctrl(
        .clk                 (clk),            // clock of L2C
        .rst                 (rst),            // reset
        .dc_rw               (dc_rw),          // Read/Write 
        .l2_en               (l2_en),
        /*** L2_Cache part ****/
        .l2_cache_rw         (l2_cache_rw),    // read / write signal of CPU
        .l2_addr             (l2_addr), 
        .access_l2_clean     (access_l2_clean),
        .access_l2_dirty     (access_l2_dirty),
        .access_mem_clean    (access_mem_clean), 
        .access_mem_dirty    (access_mem_dirty), 
        .rd_to_l2            (rd_to_l2),
        .l2_index            (l2_index),
        .offset              (l2_offset), 
        .l2_choose_l1        (l2_choose_l1),
        .choose_way          (choose_way), 
        .l2_rdy              (l2_rdy),
        .l2_busy             (l2_busy),     
        .l2_block0_we        (l2_block0_we),  // write signal of block0
        .l2_block1_we        (l2_block1_we),  // write signal of block1
        .l2_block2_we        (l2_block2_we),  // write signal of block2
        .l2_block3_we        (l2_block3_we),  // write signal of block3
        .l2_block0_re        (l2_block0_re),  // read signal of block0
        .l2_block1_re        (l2_block1_re),  // read signal of block1
        .l2_block2_re        (l2_block2_re),  // read signal of block2
        .l2_block3_re        (l2_block3_re),  // read signal of block3      
        // l2_tag part
        .plru                (plru),          // replace mark
        .l2_complete_w       (l2_complete_w), // complete write from MEM to L2
        .l2_complete_r       (l2_complete_r), // complete mark of reading from l2_cache
        .l2_tag0_rd          (l2_tag0_rd),    // read data of tag0
        .l2_tag1_rd          (l2_tag1_rd),    // read data of tag1
        .l2_tag2_rd          (l2_tag2_rd),    // read data of tag2
        .l2_tag3_rd          (l2_tag3_rd),    // read data of tag3
        .l2_tag_wd           (l2_tag_wd),     // write data of tag0                
        .l2_dirty0           (l2_dirty0),
        .l2_dirty1           (l2_dirty1),
        .l2_dirty2           (l2_dirty2), 
        .l2_dirty3           (l2_dirty3), 
        // l2_datapart
        .l2_data0_rd         (l2_data0_rd),   // read data of cache_data0
        .l2_data1_rd         (l2_data1_rd),   // read data of cache_data1
        .l2_data2_rd         (l2_data2_rd),   // read data of cache_data2
        .l2_data3_rd         (l2_data3_rd),   // read data of cache_data3
        .wd_from_l1_en       (wd_from_l1_en),
        /*thread part*/
        .l2_thread           (l2_thread),
        .ic_thread           (ic_thread),
        .dc_thread           (dc_thread),
        .mem_thread          (mem_thread),
        .l2_thread0          (l2_thread0),
        .l2_thread1          (l2_thread1),
        .l2_thread2          (l2_thread2),
        .l2_thread3          (l2_thread3),
        .l2_thread_wd        (l2_thread_wd),
        /*icache part*/
        .irq                 (irq),           // icache request
        // .ic_addr             (if_pc[31:2]),
        .ic_addr             (ic_addr),
        .ic_choose_way       (ic_choose_way),
        .ic_addr_l2          (ic_addr_l2),
        .ic_en               (ic_en),
        .ic_index            (ic_index),
        .ic_tag_wd           (ic_tag_wd),
        .ic_block0_we        (ic_block0_we),
        .ic_block1_we        (ic_block1_we),
        /*dcache part*/
        .dc_offset           (dc_offset),
        .dc_offset_l2        (dc_offset_l2),
        .wr_data_l2          (wr_data_l2),
        .wr_data_dc          (wr_data_dc),
        .wr_data_read        (wr_data_read),
        .data_wd_l2_en_dc    (data_wd_l2_en_dc),
        .drq                 (drq),  
        .dirty_data          (dirty_data),
        .dirty_tag           (dirty_tag),    
        .dc_addr             (dc_addr),           // alu_out[31:4]
        .dc_choose_way       (dc_choose_way), 
        .read_en             (read_en),
        .dc_en               (dc_en),
        .dc_index            (dc_index),
        .dc_tag_wd           (dc_tag_wd),
        .dc_block0_we        (dc_block0_we),
        .dc_block1_we        (dc_block1_we),
        .dc_addr_l2          (dc_addr_l2),
        .data_wd_l2          (data_wd_l2),        // write data to L1C       
        .l2_block0_we_mem    (l2_block0_we_mem),  // write signal of block0
        .l2_block1_we_mem    (l2_block1_we_mem),  // write signal of block1
        .l2_block2_we_mem    (l2_block2_we_mem),  // write signal of block2
        .l2_block3_we_mem    (l2_block3_we_mem),  // write signal of block3
        .wd_from_mem_en      (wd_from_mem_en),
        .wd_from_l1_en_mem   (wd_from_l1_en_mem),
        .rd_to_l2_mem        (rd_to_l2_mem),
        .offset_mem          (offset_mem), 
        .l2_index_mem        (l2_index_mem),      // address of cache
        .mem_rd              (mem_rd),
        .l2_tag_wd_mem       (l2_tag_wd_mem),
        .mem_wr_l2_en        (mem_wr_l2_en),
        .l2_data_wd_mem      (l2_data_wd_mem),
        .l2_choose_l1_read   (l2_choose_l1_read), 
        .mem_thread_read     (mem_thread_read),    
        .dc_rw_read          (dc_rw_read),          
        .dc_addr_read        (dc_addr_read), 
        .read_l2_en          (read_l2_en),
        .dc_rw_l2            (dc_rw_l2), 
        .memory_busy         (memory_busy)
    ); 

    l2_data_ram l2_data_ram(
        .clk                (clk),              // clock of L2C
        .l2_index           (l2_index),         // address of cache
        .l2_data_wd_mem     (l2_data_wd_mem),
        .offset             (l2_offset),        
        .rd_to_l2           (rd_to_l2),  
        .mem_wr_l2_en       (mem_wr_l2_en),      
        .wd_from_l1_en      (wd_from_l1_en), 
        .l2_block0_we       (l2_block0_we),
        .l2_block1_we       (l2_block1_we),
        .l2_block2_we       (l2_block2_we),
        .l2_block3_we       (l2_block3_we),
        .l2_block0_re       (l2_block0_re),      // read signal of block0
        .l2_block1_re       (l2_block1_re),      // read signal of block1
        .l2_block2_re       (l2_block2_re),      // read signal of block2
        .l2_block3_re       (l2_block3_re),      // read signal of block3
        .l2_data0_rd        (l2_data0_rd),       // read data of cache_data0
        .l2_data1_rd        (l2_data1_rd),       // read data of cache_data1
        .l2_data2_rd        (l2_data2_rd),       // read data of cache_data2
        .l2_data3_rd        (l2_data3_rd)        // read data of cache_data3
    );

    l2_tag_ram l2_tag_ram(    
        .clk                (clk),                   // clock of L2C
        .rst                (rst),                   // reset
        .mem_wr_l2_en       (mem_wr_l2_en), 
        .wd_from_l1_en      (wd_from_l1_en),   
        .l2_index           (l2_index),       // address of cache
        .l2_tag_wd          (l2_tag_wd),    
        .l2_block0_we       (l2_block0_we),
        .l2_block1_we       (l2_block1_we),
        .l2_block2_we       (l2_block2_we),
        .l2_block3_we       (l2_block3_we),
        .l2_block0_re       (l2_block0_re),       // read signal of block0
        .l2_block1_re       (l2_block1_re),       // read signal of block1
        .l2_block2_re       (l2_block2_re),       // read signal of block2
        .l2_block3_re       (l2_block3_re),       // read signal of block3
        .l2_thread_wd       (l2_thread_wd),
        .l2_tag0_rd         (l2_tag0_rd),    // read data of tag0
        .l2_tag1_rd         (l2_tag1_rd),    // read data of tag1
        .l2_tag2_rd         (l2_tag2_rd),    // read data of tag2
        .l2_tag3_rd         (l2_tag3_rd),    // read data of tag3
        .plru               (plru),          // read data of plru_field
        .l2_complete_w      (l2_complete_w), // complete write to L2
        .l2_complete_r      (l2_complete_r), // complete read from L2
        .l2_thread0         (l2_thread0),
        .l2_thread1         (l2_thread1),
        .l2_thread2         (l2_thread2),
        .l2_thread3         (l2_thread3),
        .l2_dirty0          (l2_dirty0),
        .l2_dirty1          (l2_dirty1),
        .l2_dirty2          (l2_dirty2),
        .l2_dirty3          (l2_dirty3)
    );
endmodule