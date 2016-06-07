/*
 -- ============================================================================
 -- FILE NAME   : l2_top.v
 -- DESCRIPTION : top of l2_cache
 -- ----------------------------------------------------------------------------
 -- Date:2016/4/13         Coding_by:kippy   
 -- ============================================================================
*/
`timescale 1ns/1ps
/********** General header file **********/
`include "common_defines.v"
`include "l1_cache.h"
`include "l2_cache.h"

module cache_top(
    /*********** Clk & Reset *********/
    input  wire                        clk,                // clock
    input  wire                        rst,                // reset
    /****** Thread choose part *****/
    input  wire    [`THREAD_BUS]       mem_thread,
    input  wire    [`THREAD_BUS]       thread,
    output wire    [`THREAD_BUS]       l2_thread,
    /********* L2_Cache part *********/
    output wire     [`L2_ADDR_BUS]     l2_addr,
    output wire                        l2_cache_rw, 
    output wire                        access_mem_clean,
    output wire                        access_mem_dirty,
    output wire                        l2_choose_l1,
    output wire     [`L2_CHO0SE_BUS]   l2_choose_way,          
    /********* D_Cache part **********/
    // input  wire    [`OFFSET_BUS]       offset,   
    input  wire    [`L1_DATA_BUS]      data_wd_l2_mem,   // wr_data from L2 
    input  wire                        mem_wr_dc_en, 
    output wire                        dc_miss,
    output wire                        read_en, 
    /******** Memory part *********/
    input  wire                        memory_en,
    input  wire    [`L2_ADDR_BUS]      dc_addr_mem,
    input  wire    [`L1_TAG_BUS]       dc_tag_wd_mem,
    input  wire    [`L1_INDEX_BUS]     dc_index_mem,
    input  wire    [`OFFSET_BUS]       offset_mem,
    input  wire                        dc_block0_we_mem,
    input  wire                        dc_block1_we_mem,
    input  wire                        dc_rw_mem,
    /******* I_Cache part *******/
    input  wire    [`L1_TAG_BUS]       ic_tag_wd_mem,
    input  wire    [`L1_INDEX_BUS]     ic_index_mem,
    input  wire                        ic_block0_we_mem,
    input  wire                        ic_block1_we_mem,
    input  wire    [`L2_ADDR_BUS]      ic_addr_mem,
    input  wire                        if_stall,
    /********** memory part **********/
    input  wire                        l2_block0_we_mem,
    input  wire                        l2_block1_we_mem,
    input  wire                        l2_block2_we_mem,
    input  wire                        l2_block3_we_mem,
    input  wire                        wd_from_mem_en,
    input  wire                        wd_from_l1_en_mem,
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
    input  wire     [`WORD_DATA_BUS]   wr_data_read,
    input  wire     [`WORD_DATA_BUS]   wr_data_mem,
    output wire     [`WORD_DATA_BUS]   wr_data_l2,
    /********** CPU part **********/
    input  wire    [`OFFSET_BUS]       offset_m,
    input  wire    [`WORD_ADDR_BUS]    br_addr_ic,        // Branch target
    input  wire                        br_taken,
    input  wire    [`WORD_ADDR_BUS]    if_addr,     // if_pc[31:2]      // address of fetching instruction   
    output wire    [`WORD_DATA_BUS]    insn,         // read data of CPU
    output wire                        if_busy,       // the signal of stall caused by cache miss 
    output wire                        ic_miss,
    output wire                        data_rdy,         // data to CPU ready mark
    input  wire    [`WORD_ADDR_BUS]    next_addr,   // alu_out[31:2]        // address of accessing memory
    input  wire                        memwrite_m,    // read / write signal of CPU
    input  wire                        access_mem,    // access MEM mark
    input  wire    [`WORD_DATA_BUS]    wr_data,       // write data from CPU
    input  wire                        out_rdy,
    output wire    [`WORD_DATA_BUS]    read_data_m,   // read data of CPU
    output wire                        dc_thread_rdy,
    output wire    [`THREAD_BUS]       thread_rdy_thread,
    output wire                        ic_thread_rdy,
    output wire    [`THREAD_BUS]       ic_thread_wd,
    output wire                        dc_busy,                  
    output wire                        dc_rw_l2,
    output wire    [`WORD_DATA_BUS]    rd_to_write_m,
    output wire    [`OFFSET_BUS]       dc_offset_l2,
    input  wire    [`OFFSET_BUS]       dc_offset_mem,
    /******** D_Cache part ********/
    /********* I_Cache part **********/   
    /******* L2_Cache part *******/
    input  wire                        mem_wr_ic_en,     // enable signal that MEM write I_Cache    
    output wire                        ic_en,              // icache request enable mark
    output wire                        dc_en,
    output wire                        l2_busy,            // busy mark
    output wire     [`L2_ADDR_BUS]     dc_addr_l2,
    output wire     [`L2_ADDR_BUS]     ic_addr_l2,
    output wire     [`L2_DATA_BUS]     l2_data0_rd,    // read data of cache_data0
    output wire     [`L2_DATA_BUS]     l2_data1_rd,    // read data of cache_data1
    output wire     [`L2_DATA_BUS]     l2_data2_rd,    // read data of cache_data2
    output wire     [`L2_DATA_BUS]     l2_data3_rd,    // read data of cache_data3 
    output wire     [`L2_TAG_BUS]      l2_tag0_rd,    // read data of tag0
    output wire     [`L2_TAG_BUS]      l2_tag1_rd,    // read data of tag1
    output wire     [`L2_TAG_BUS]      l2_tag2_rd,    // read data of tag2
    output wire     [`L2_TAG_BUS]      l2_tag3_rd,    // read data of tag3
    // d_data    
    /************* L1 part ***********/
    input  wire                        memory_busy
    );
    wire       [`L1_DATA_BUS]      data_wd_l2;         // write data to L1 from L2    
    
    wire       [`L1_DATA_BUS]      dirty_data;
    wire       [`L1_TAG_BUS]       dirty_tag;         // write data of dtag
    wire       [`WORD_DATA_BUS]    wr_data_dc;
    // signals between dcache and l2
    wire       [`L1_INDEX_BUS]     dc_index_l2;
    wire       [`L1_TAG_BUS]       dc_tag_wd_l2;
    wire                           dc_block0_we_l2;
    wire                           dc_block1_we_l2;
    wire                           dc_choose_way;
    /****** Thread choose part *****/
    wire                           ic_choose_way;
    wire       [`THREAD_BUS]       ic_thread;
    wire       [`THREAD_BUS]       dc_thread;          // read data of thread   
    // signals between icache and l2
    wire       [`WORD_ADDR_BUS]    ic_addr;
    
    wire       [`L1_INDEX_BUS]     ic_index_l2;
    wire       [`L1_TAG_BUS]       ic_tag_wd;
    wire                           ic_block0_we_l2;
    wire                           ic_block1_we_l2;
    wire                           data_wd_l2_en_dc; 
    // l2_Cache
    wire                          l2_en;
    wire                          dc_rw; 
    wire                          l2_rdy;             // ready mark
    /*dcache part*/
    wire                          drq; 
    wire                          irq;
    wire      [`OFFSET_BUS]       l2_offset,dc_offset; 

    /*icache part*/
    wire      [`L2_ADDR_BUS]      dc_addr;
    
    /*l2_cache part*/
    wire                          access_l2_clean;
    wire                          access_l2_dirty;

    l1_dc_top l1_dc_top(
        .clk               (clk),           // clock
        .rst               (rst),           // reset
        /******** Memory part *********/
        .memory_en         (memory_en),
        .l2_en             (l2_en),
        .dc_addr_mem       (dc_addr_mem),
        .dc_addr_l2        (dc_addr_l2),
        .dc_index_mem      (dc_index_mem),
        .dc_tag_wd_mem     (dc_tag_wd_mem),
        .data_wd_l2_mem    (data_wd_l2_mem), 
        .offset_mem        (dc_offset_mem),
        .dc_block0_we_mem  (dc_block0_we_mem),
        .dc_block1_we_mem  (dc_block1_we_mem),
        .dc_rw_mem         (dc_rw_mem),  
        .wr_data_l2        (wr_data_l2),
        .wr_data_mem       (wr_data_mem),
        .wr_data_dc        (wr_data_dc),
        /* CPU part */
        .offset_m          (offset_m),
        .next_addr         (next_addr), // address of fetching instruction
        .memwrite_m        (memwrite_m),    // Read/Write 
        .access_mem        (access_mem),
        .wr_data           (wr_data),       // read / write signal of CPU
        .out_rdy           (out_rdy),
        .read_data_m       (read_data_m),   // read data of CPU
        .dc_miss           (dc_miss),    // the signal of stall caused by cache miss
        .access_l2_clean   (access_l2_clean),
        .access_l2_dirty   (access_l2_dirty),
        .choose_way        (dc_choose_way),
        .dc_addr           (dc_addr),
        .thread_rdy        (dc_thread_rdy),
        .thread_rdy_thread (thread_rdy_thread),
        /*thread part*/
        .l2_thread         (l2_thread),
        .mem_thread        (mem_thread),
        .thread            (thread),
        .dc_thread         (dc_thread), 
        .dc_busy           (dc_busy),
        .dc_offset         (dc_offset),
        .drq               (drq), 
        .data_wd_l2_en_dc  (data_wd_l2_en_dc),
        .dc_rw             (dc_rw),
        .dirty_data        (dirty_data),
        .dirty_tag         (dirty_tag),
        .rd_to_write_m     (rd_to_write_m),
        /* l2_cache part */
        .dc_index_l2       (dc_index_l2),
        .dc_tag_wd_l2      (dc_tag_wd_l2),
        .dc_block0_we_l2   (dc_block0_we_l2),
        .dc_block1_we_l2   (dc_block1_we_l2),
        .dc_rw_l2          (dc_rw_l2),  
        .offset_l2         (dc_offset_l2),         
        .l2_busy           (l2_busy), 
        .dc_en             (dc_en),         // busy signal of l2_cache
        .l2_rdy            (l2_rdy),        // ready signal of l2_cache
        .mem_wr_dc_en      (mem_wr_dc_en),   
        .data_wd_l2        (data_wd_l2)      
        );

    l1_ic_top l1_ic_top(
        .clk                (clk),           // clock
        .rst                (rst),         // reset
        /* CPU part */
        .br_taken           (br_taken),
        .br_addr_ic         (br_addr_ic), 
        .ic_addr_mem        (ic_addr_mem),
        .ic_addr_l2         (ic_addr_l2),
        .memory_en          (memory_en),
        .l2_en              (l2_en),
        .if_stall           (if_stall),
        // .offset             (offset),
        .if_addr            (if_addr),   // address of fetching instruction
        .ic_addr            (ic_addr),
        .insn               (insn),          // read data of CPU
        .ic_miss            (ic_miss),    // the signal of stall caused by cache miss
        .choose_way         (ic_choose_way),
        .thread_rdy         (ic_thread_rdy),
        .ic_thread_wd       (ic_thread_wd),
        /*thread part*/
        .l2_thread          (l2_thread),
        .mem_thread         (mem_thread),
        .thread             (thread),
        .ic_thread          (ic_thread), 
        .if_busy            (if_busy),    
        /* L1_cache part */
        .data_wd_l2         (data_wd_l2), 
        .data_wd_l2_mem     (data_wd_l2_mem), 
        /******* Memory part *******/
        .ic_index_mem       (ic_index_mem),
        .ic_tag_wd_mem      (ic_tag_wd_mem), 
        .ic_block0_we_mem   (ic_block0_we_mem),
        .ic_block1_we_mem   (ic_block1_we_mem),
        /******* L2_Cache part *******/
        .l2_busy            (l2_busy),
        .ic_index_l2        (ic_index_l2),
        .ic_tag_wd          (ic_tag_wd),
        .ic_block0_we_l2    (ic_block0_we_l2),
        .ic_block1_we_l2    (ic_block1_we_l2),
        .ic_en              (ic_en),         // busy signal of l2_cache
        .l2_rdy             (l2_rdy),        // ready signal of l2_cache
        .mem_wr_ic_en       (mem_wr_ic_en), 
        .irq                (irq),
        .data_rdy           (data_rdy)          
        );

    l2_top l2_top(
        .clk                 (clk),            // clock of L2C
        .rst                 (rst),            // reset
        .dc_rw               (dc_rw),          // Read/Write 
        .l2_en               (l2_en),
        /*** L2_Cache part ****/
        .l2_offset           (l2_offset),
        .l2_cache_rw         (l2_cache_rw),    // read / write signal of CPU
        .l2_addr             (l2_addr), 
        .access_l2_clean     (access_l2_clean),
        .access_l2_dirty     (access_l2_dirty),
        .access_mem_clean    (access_mem_clean), 
        .access_mem_dirty    (access_mem_dirty), 
        .l2_choose_l1        (l2_choose_l1),
        .choose_way          (l2_choose_way), 
        .l2_rdy              (l2_rdy),
        .l2_busy             (l2_busy), 
        .l2_data0_rd         (l2_data0_rd),   // read data of cache_data0
        .l2_data1_rd         (l2_data1_rd),   // read data of cache_data1
        .l2_data2_rd         (l2_data2_rd),   // read data of cache_data2
        .l2_data3_rd         (l2_data3_rd),   // read data of cache_data3
        .l2_tag0_rd          (l2_tag0_rd),    // read data of tag0
        .l2_tag1_rd          (l2_tag1_rd),    // read data of tag1
        .l2_tag2_rd          (l2_tag2_rd),    // read data of tag2
        .l2_tag3_rd          (l2_tag3_rd),    // read data of tag3
        /*thread part*/
        .l2_thread           (l2_thread),
        .ic_thread           (ic_thread),
        .dc_thread           (dc_thread),
        .mem_thread          (mem_thread),
        /*icache part*/
        .irq                 (irq),             // icache request
        .ic_addr             (ic_addr),
        .ic_choose_way       (ic_choose_way),
        .ic_addr_l2          (ic_addr_l2),
        .ic_en               (ic_en),
        .ic_index            (ic_index_l2),
        .ic_tag_wd           (ic_tag_wd),
        .ic_block0_we        (ic_block0_we_l2),
        .ic_block1_we        (ic_block1_we_l2),
        .data_wd_l2_en_dc    (data_wd_l2_en_dc),
        /*dcache part*/
        .dc_offset           (dc_offset),
        .dc_offset_l2        (dc_offset_l2),
        .wr_data_l2          (wr_data_l2),
        .wr_data_dc          (wr_data_dc),
        .wr_data_read        (wr_data_read),
        .drq                 (drq),  
        .dc_choose_way       (dc_choose_way),
        .dc_addr             (dc_addr),           // alu_out[31:4]
        .dc_en               (dc_en),
        .read_en             (read_en),
        .dc_index            (dc_index_l2),
        .dc_tag_wd           (dc_tag_wd_l2),
        .dc_block0_we        (dc_block0_we_l2),
        .dc_block1_we        (dc_block1_we_l2),
        .dirty_data          (dirty_data),
        .dirty_tag           (dirty_tag),  
        .dc_addr_l2          (dc_addr_l2),
        .data_wd_l2          (data_wd_l2),        // write data to L1C       
        .l2_block0_we_mem    (l2_block0_we_mem),  // write signal of block0
        .l2_block1_we_mem    (l2_block1_we_mem),  // write signal of block1
        .l2_block2_we_mem    (l2_block2_we_mem),  // write signal of block2
        .l2_block3_we_mem    (l2_block3_we_mem),  // write signal of block3
        .wd_from_mem_en      (wd_from_mem_en),
        .wd_from_l1_en_mem   (wd_from_l1_en_mem),
        .rd_to_l2_mem        (rd_to_l2_mem),
        .rd_to_l2            (rd_to_l2),    
        .offset_mem          (offset_mem),
        .mem_rd              (mem_rd),
        .l2_index_mem        (l2_index_mem),      // address of cache
        .l2_tag_wd_mem       (l2_tag_wd_mem),
        .l2_choose_l1_read   (l2_choose_l1_read), 
        .mem_thread_read     (mem_thread_read),    
        .dc_rw_read          (dc_rw_read),          
        .dc_addr_read        (dc_addr_read), 
        .read_l2_en          (read_l2_en),
        .dc_rw_l2            (dc_rw_l2), 
        .memory_busy         (memory_busy)        
    );
endmodule