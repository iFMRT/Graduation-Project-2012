`timescale 1ns/1ps

`include "stddef.h"
`include "cpu.h"
`include "mem.h"

module mem_stage (
    /********** Clock & Reset *********/
    input                        clk,            // Clock
    input                        reset,          // Asynchronous Reset
    /**** Pipeline Control Signal *****/
    input                        stall,          // Stall
    input                        flush,          // Flush
    /************ Forward *************/
    output     [`WORD_DATA_BUS]  fwd_data,  
    /******** Memory part *********/
    input                        memory_en,
    input                        l2_en,
    input      [27:0]            dc_addr_mem,
    input      [27:0]            dc_addr_l2,  
    input      [20:0]            dc_tag_wd_mem,
    input      [7:0]             dc_index_mem,
    input      [1:0]             offset_mem,
    input                        dc_block0_we_mem,
    input                        dc_block1_we_mem,
    input      [31:0]            dc_wd_mem,
    input                        dc_rw_mem,     
    output                       thread_rdy,
    output                       l2_wr_dc_en,
    input                        data_wd_l2_en_dc,
    output     [1:0]             dc_thread_wd,
    output     [127:0]           data_wd,         
    /*********** Data_cache ***********/
    /* CPU part */
    input                        access_mem,
    output                       miss_stall,    // the signal of stall caused by cache miss
    output                       access_l2_clean,
    output                       access_l2_dirty,
    output                       dc_choose_way,
    /****** Thread choose part *****/
    input      [1:0]             l2_thread,
    input      [1:0]             mem_thread,
    input      [1:0]             thread,
    output     [1:0]             dc_thread,
    output                       dc_busy,   
    /* L1_cache part */
    input      [31:0]            alu_out,
    input                        lru,           // mark of replacing
    input      [1:0]             thread0,       // read data of tag0
    input      [1:0]             thread1,       // read data of tag1
    input      [20:0]            tag0_rd,       // read data of tag0
    input      [20:0]            tag1_rd,       // read data of tag1
    input      [127:0]           data0_rd,      // read data of data0
    input      [127:0]           data1_rd,      // read data of data1
    input      [127:0]           data_wd_l2,
    input      [127:0]           data_wd_l2_mem,
    input                        dirty0,
    input                        dirty1,
    output                       block0_we,     // write signal of block0
    output                       block1_we,     // write signal of block1
    output                       block0_re,     // read signal of block0
    output                       block1_re,     // read signal of block1
    output                       tagcomp_hit,
    output     [1:0]             offset, 
    output     [20:0]            tag_wd,        // write data of L1_tag
    output     [27:0]            dc_addr,
    output                       data_wd_dc_en, // choose signal of data_wd           
    input                        mem_wr_dc_en,
    output     [7:0]             index,         // address of L1_cache
    output     [`WORD_DATA_BUS]  dc_wd,         // Write data
    output                       dc_rw, 
    /* L2_cache part */
    input      [20:0]            dc_tag_wd_l2,
    input      [7:0]             dc_index_l2,
    input                        dc_block0_we_l2,
    input                        dc_block1_we_l2,
    input      [31:0]            dc_wd_l2,
    input                        dc_rw_l2,
    input      [1:0]             offset_l2, 
    input                        l2_busy,
    input                        dc_en,         // busy signal of L2_cache
    input                        l2_rdy,        // ready signal of L2_cache  
    output                       drq,           // icache request
   /********** EX/MEM Pipeline Register **********/
    input                        ex_en,          // If Pipeline data enable
    input      [`MEM_OP_BUS]     ex_mem_op,      // Memory operation
    input      [`WORD_DATA_BUS]  ex_mem_wr_data, // Memory write data
    input      [`REG_ADDR_BUS]   ex_dst_addr,    // General purpose register write address
    input                        ex_gpr_we_,     // General purpose register enable
    input      [`WORD_DATA_BUS]  ex_out,         // EX Stage operating reslut
    /********** MEM/WB Pipeline Register **********/
    output                       mem_en,         // If Pipeline data enables
    output      [`REG_ADDR_BUS]  mem_dst_addr,   // General purpose register write address
    output                       mem_gpr_we_,    // General purpose register enable
    output      [`WORD_DATA_BUS] mem_out
);
        
    /********** Internal signals **********/
    wire [`WORD_DATA_BUS]        wr_data;         // Write data
    wire [`WORD_DATA_BUS]        read_data_m;     // Read data
    wire                         memwrite_m;      // Read/Write
    wire [`WORD_DATA_BUS]        out;             // Memory Access Result
    wire                         miss_align;
    wire                         hitway;
    wire                         out_rdy;
    wire                         load_rdy;

    assign fwd_data  = out;

    // /********** Memory Access Control Module **********/
    mem_ctrl mem_ctrl (
        /********** EX/MEM Pipeline Register **********/
        .ex_en            (ex_en),
        .ex_mem_op        (ex_mem_op),      // Memory operation
        .ex_mem_wr_data   (ex_mem_wr_data), // Memory write data
        .ex_out           (ex_out),
        .offset           (alu_out[1:0]),   // EX Stage operating reslut
        /********** Memory Access Interface **********/
        .read_data_m      (read_data_m),    // Read data
        .rw               (memwrite_m),     // Read/Write                
        .wr_data          (wr_data),        // Write data
        .hitway           (hitway),         // Address Strobe
        .data0_rd         (data0_rd),       // Read/Write
        .data1_rd         (data1_rd),       // Write data
        /********** Memory Access Result **********/        
        .load_rdy         (load_rdy),
        .out              (out),            // Memory Access Result
        .miss_align       (miss_align)
    );
    /********** Dcache Interface **********/
    dcache_ctrl dcache_ctrl(
        .clk               (clk),           // clock
        .rst               (reset),         // reset
        .dc_index_mem      (dc_index_mem),
        .dc_tag_wd_mem     (dc_tag_wd_mem),
        .dc_block0_we_mem  (dc_block0_we_mem),
        .dc_block1_we_mem  (dc_block1_we_mem),
        .dc_wd_mem         (dc_wd_mem), 
        .dc_rw_mem         (dc_rw_mem),  
        .offset_mem        (offset_mem),
        .l2_wr_dc_en       (l2_wr_dc_en),
        .data_wd_l2_en_dc  (data_wd_l2_en_dc),
        .dc_thread_wd      (dc_thread_wd),
        .data_wd           (data_wd),
        /* CPU part */
        .memory_en         (memory_en),
        .l2_en             (l2_en),
        .dc_addr_mem       (dc_addr_mem),
        .dc_addr_l2        (dc_addr_l2),
        .access_l2_clean   (access_l2_clean),
        .access_l2_dirty   (access_l2_dirty),
        .next_addr         (alu_out[31:2]), // address of fetching instruction
        .memwrite_m        (memwrite_m),    // Read/Write 
        .wr_data           (wr_data),       // read / write signal of CPU
        .dc_wd             (dc_wd),
        .access_mem        (access_mem), 
        .out_rdy           (out_rdy),
        .read_data_m       (read_data_m),   // read data of CPU
        .miss_stall        (miss_stall),    // the signal of stall caused by cache miss
        .choose_way        (dc_choose_way),
        .dc_addr           (dc_addr),
        .dc_rw             (dc_rw),
        /*thread part*/
        .l2_thread         (l2_thread),
        .mem_thread        (mem_thread),
        .thread            (thread),
        .dc_thread         (dc_thread),  
        .dc_busy           (dc_busy),
        /* L1_cache part */
        .block0_we         (block0_we),     // write signal of block0
        .block1_we         (block1_we),     // write signal of block1
        .block0_re         (block0_re),     // read signal of block0
        .block1_re         (block1_re),     // read signal of block1      
        .offset            (offset),      
        .tagcomp_hit       (tagcomp_hit),  
        .hitway            (hitway),
        .index             (index),         // address of L1_cache
        .drq               (drq), 
        .lru               (lru),           // mark of replacing
        .tag0_rd           (tag0_rd),       // read data of tag0
        .tag1_rd           (tag1_rd),       // read data of tag1
        .thread0           (thread0),
        .thread1           (thread1),
        .data0_rd          (data0_rd),      // read data of data0
        .data1_rd          (data1_rd),      // read data of data1
        .dirty0            (dirty0),         
        .dirty1            (dirty1),          
        .tag_wd            (tag_wd),        // write data of L1_tag
        .data_wd_dc_en     (data_wd_dc_en),
        /* l2_cache part */
        .dc_index_l2       (dc_index_l2),
        .dc_tag_wd_l2      (dc_tag_wd_l2),
        .dc_block0_we_l2   (dc_block0_we_l2),
        .dc_block1_we_l2   (dc_block1_we_l2),
        .dc_wd_l2          (dc_wd_l2), 
        .dc_rw_l2          (dc_rw_l2),  
        .offset_l2         (offset_l2), 
        .thread_rdy        (thread_rdy),
        .l2_busy           (l2_busy), 
        .dc_en             (dc_en),         // busy signal of l2_cache
        .l2_rdy            (l2_rdy),        // ready signal of l2_cache
        .mem_wr_dc_en      (mem_wr_dc_en), 
        .data_wd_l2_mem    (data_wd_l2_mem), 
        .data_wd_l2        (data_wd_l2)                  
        );
    // /********** MEM Stage Pipeline Register **********/
    mem_reg mem_reg (
        /********** Clock & Reset **********/
        .clk              (clk),             // Clock
        .reset            (reset),           // Asynchronous Reset
        /********** Memory Access Result **********/
        .out              (out),
        .miss_align       (miss_align),
        /********** Pipeline Control Signal **********/
        .stall            (stall),           // Stall
        .flush            (flush),           // Flush
        /********** EX/MEM Pipeline Register **********/
        .ex_en            (ex_en),
        .ex_dst_addr      (ex_dst_addr),     // General purpose register write address
        .ex_gpr_we_       (ex_gpr_we_),      // General purpose register enable
        /********** MEM/WB Pipeline Register **********/
        .mem_en           (mem_en),          
        .mem_dst_addr     (mem_dst_addr),    // General purpose register write address
        .mem_gpr_we_      (mem_gpr_we_),     // General purpose register enable
        .load_rdy         (load_rdy),
        .out_rdy          (out_rdy),
        .mem_out          (mem_out)
        );

endmodule
