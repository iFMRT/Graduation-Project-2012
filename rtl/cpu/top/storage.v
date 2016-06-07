////////////////////////////////////////////////////////////////////
// Engineer:       Kippy Chen - 799182081@qq.com                  //
//                                                                //
// Additional contributions by:                                   //
//                 Beyond Sky - fan-dave@163.com                  //
//                 Junhao Chang                                   //
//                 Leway Colin - colin4124@gmail.com              //
//                                                                //
// Design Name:    memory_ctrl                                    //
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
module storage(
    input  wire                        clk,            // clock
    input  wire                        rst,            // reset
    // thread
    input  wire    [`THREAD_BUS]       thread,    
    output wire                        ic_miss,
    output wire                        dc_miss,
    output wire                        dc_thread_rdy,
    output wire    [`THREAD_BUS]       dc_rdy_thread,
    output wire                        ic_thread_rdy,
    output wire    [`THREAD_BUS]       ic_rdy_thread,
    // if_stage
    input  wire                        if_stall,
    input  wire    [`WORD_ADDR_BUS]    if_addr,     // if_pc[31:2]      // address of fetching instruction   
    
    input  wire    [`WORD_ADDR_BUS]    br_addr_ic,        // Branch target
    input  wire                         br_taken, 
    output wire    [`WORD_DATA_BUS]    insn,         // read data of CPU
    output wire                        data_rdy,         // data to CPU ready mark 
    output wire                        if_busy,       // the signal of stall caused by cache miss
    // mem_stage
    input  wire    [`OFFSET_BUS]       offset_m,
    input  wire    [`WORD_ADDR_BUS]    next_addr,     // alu_out[31:2]  // address of accessing memory
    input  wire                        memwrite_m,    // read / write signal of CPU
    input  wire                        access_mem,    // access MEM mark
    input  wire    [`WORD_DATA_BUS]    wr_data,       // write data from CPU
    input  wire                        out_rdy,
    output wire    [`WORD_DATA_BUS]    rd_to_write_m,
    output wire    [`WORD_DATA_BUS]    read_data_m,   // read data of CPU
    output wire                        dc_busy
    ); 
	wire              memory_en;
    /********* L2_Cache part *********/
    wire               dc_rw_l2;
    wire               l2_busy;
    wire       [27:0]  l2_addr;
    wire               l2_choose_l1;
    wire       [1:0]   l2_choose_way;
    wire               l2_cache_rw;    
    wire             l2_block0_we_mem;       // write signal mark of cache_block0
    wire             l2_block1_we_mem;       // write signal mark of cache_block1 
    wire             l2_block2_we_mem;       // write signal mark of cache_block2 
    wire             l2_block3_we_mem;       // write signal mark of cache_block3
    wire     [8:0]   l2_index_mem;
    // l2_tag part
    wire       [17:0]  l2_tag0_rd;         // read data of tag0
    wire       [17:0]  l2_tag1_rd;         // read data of tag1
    wire       [17:0]  l2_tag2_rd;         // read data of tag2
    wire       [17:0]  l2_tag3_rd;         // read data of tag3  
    wire      [17:0]  l2_tag_wd_mem; 
    // l2_data part
    wire       [511:0] l2_data0_rd;        // read data of cache_data0
    wire       [511:0] l2_data1_rd;        // read data of cache_data1
    wire       [511:0] l2_data2_rd;        // read data of cache_data2
    wire       [511:0] l2_data3_rd;        // read data of cache_data3
    wire             wd_from_mem_en;     // write data from MEM enable mark 
    wire             wd_from_l1_en_mem;     // write data from MEM 
    // l2_thread part
    wire       [1:0]   l2_thread;           // read data of thread
    wire     [1:0]   mem_thread;          // write data of thread
    /************* L1 part ***********/   
    /********* I_Cache part **********/
    wire             mem_wr_ic_en;       // mem write icache mark
    wire               ic_en;              // icache request enable mark
    wire      [27:0] ic_addr_mem;     
    wire        [27:0] ic_addr_l2;
    wire      [7:0]  ic_index_mem;
    wire      [20:0] ic_tag_wd_mem;
    wire             ic_block0_we_mem;
    wire             ic_block1_we_mem;
    /********* D_Cache part **********/
    wire             mem_wr_dc_en;       // mem write dcache mark
    wire               read_en; 
    wire               dc_en;              // dcache request enable mark
    wire      [7:0]  dc_index_mem;
    wire      [20:0] dc_tag_wd_mem;
    wire             dc_block0_we_mem;
    wire             dc_block1_we_mem;
    wire     [127:0] data_wd_l2_mem;         // write data to L1 from L2   
    wire             dc_rw_mem;
    wire       [127:0] rd_to_l2;
    wire     [127:0] rd_to_l2_mem;
    wire       [27:0]  dc_addr_l2;
    wire     [27:0]  dc_addr_mem;
    wire             l2_choose_l1_read;
    wire     [1:0]   mem_thread_read;
    wire             dc_rw_read;
    wire     [27:0]  dc_addr_read;
    /********** memory part **********/
    // wire               dc_rw;
    wire               access_mem_clean;
    wire               access_mem_dirty;
    wire     [511:0] mem_rd;             // read data of MEM
    wire     [1:0]   offset_mem;
    wire             read_l2_en;
    wire             memory_busy;
    wire [`WORD_DATA_BUS] wr_data_l2;
    wire [`WORD_DATA_BUS] wr_data_mem;
    wire [`WORD_DATA_BUS] wr_data_read;
    wire [`OFFSET_BUS]    dc_offset_l2,dc_offset_mem;
    cache_top cache_top(
        .clk                (clk),           // clock of L2C
        .rst                (rst),           // reset 
        /*thread part*/
        .thread             (thread),        // +++++++++
        .l2_thread          (l2_thread),
        .mem_thread         (mem_thread),
        /*l2_cache part*/ 
        // .offset             (offset),
        .dc_offset_l2       (dc_offset_l2),
        .dc_offset_mem      (dc_offset_mem),
		.l2_addr            (l2_addr),    // address of fetching instruction
		.l2_cache_rw        (l2_cache_rw),// read / write signal of CPU
		.access_mem_clean   (access_mem_clean), 
        .access_mem_dirty   (access_mem_dirty),
		.l2_choose_l1       (l2_choose_l1),
        .l2_choose_way      (l2_choose_way),
        .read_en            (read_en),
        .data_wd_l2_mem     (data_wd_l2_mem),    // write data to L1C  
        .mem_wr_dc_en       (mem_wr_dc_en),
        .memory_en          (memory_en),
        .dc_addr_mem        (dc_addr_mem),
        .dc_tag_wd_mem      (dc_tag_wd_mem), 
        .dc_index_mem       (dc_index_mem),
        .offset_mem         (offset_mem),
		.dc_block0_we_mem   (dc_block0_we_mem),
        .dc_block1_we_mem   (dc_block1_we_mem),  
        .dc_rw_mem          (dc_rw_mem),
        .ic_index_mem       (ic_index_mem),
        .ic_tag_wd_mem      (ic_tag_wd_mem), 
        .ic_block0_we_mem   (ic_block0_we_mem),
        .ic_block1_we_mem   (ic_block1_we_mem),   
        .ic_addr_mem        (ic_addr_mem),
        .l2_block0_we_mem   (l2_block0_we_mem),  // write signal of block0
        .l2_block1_we_mem   (l2_block1_we_mem),  // write signal of block1
        .l2_block2_we_mem   (l2_block2_we_mem),  // write signal of block2
        .l2_block3_we_mem   (l2_block3_we_mem),  // write signal of block3
        .wd_from_mem_en     (wd_from_mem_en),
        .wd_from_l1_en_mem  (wd_from_l1_en_mem),
		.rd_to_l2_mem       (rd_to_l2_mem),
		.mem_rd             (mem_rd),
		.l2_index_mem       (l2_index_mem), 
		.l2_tag_wd_mem      (l2_tag_wd_mem),     // write data of tag0       
		.l2_choose_l1_read  (l2_choose_l1_read), 
        .mem_thread_read    (mem_thread_read),    
        .dc_rw_read         (dc_rw_read),           
        .dc_addr_read       (dc_addr_read),  
        .read_l2_en         (read_l2_en), 
        .wr_data_l2         (wr_data_l2),
        .wr_data_mem        (wr_data_mem),
        .wr_data_read       (wr_data_read),
        /********** CPU part **********/
        .offset_m           (offset_m),
        .br_taken           (br_taken),     //++++++++++++++++// // dc_rw_l2
        .br_addr_ic         (br_addr_ic), 
        .insn               (insn),          // read data of CPU
        .if_addr            (if_addr), 
        .if_busy            (if_busy), 
        .ic_miss            (ic_miss),
        .if_stall           (if_stall),
        .data_rdy           (data_rdy),
        .next_addr          (next_addr), // address of fetching instruction
        .memwrite_m         (memwrite_m),    // Read/Write 
        .access_mem         (access_mem),
        .wr_data            (wr_data),       // read / write signal of CPU
        .out_rdy            (out_rdy),
        .read_data_m        (read_data_m),   // read data of CPU
        .dc_miss            (dc_miss),    // the signal of stall caused by cache miss
        .dc_thread_rdy      (dc_thread_rdy),
        .thread_rdy_thread  (dc_rdy_thread),
        .ic_thread_rdy      (ic_thread_rdy),
        .ic_thread_wd       (ic_rdy_thread),
        .dc_busy            (dc_busy),
        .rd_to_write_m      (rd_to_write_m),
        /********* I_Cache part **********/  
        .mem_wr_ic_en       (mem_wr_ic_en),
        .memory_busy        (memory_busy),
		.dc_en              (dc_en),         // busy signal of l2_cache
        .ic_en              (ic_en),         // busy signal of l2_cache
        .dc_addr_l2         (dc_addr_l2),
        .ic_addr_l2         (ic_addr_l2),
        .rd_to_l2           (rd_to_l2),
        .dc_rw_l2           (dc_rw_l2),  		           
        /********* L2_Cache part **********/  
        .l2_busy            (l2_busy),         
        .l2_tag0_rd         (l2_tag0_rd),    // read data of tag0
        .l2_tag1_rd         (l2_tag1_rd),    // read data of tag1
        .l2_tag2_rd         (l2_tag2_rd),    // read data of tag2
        .l2_tag3_rd         (l2_tag3_rd),    // read data of tag3              
        // l2_data part
        .l2_data0_rd        (l2_data0_rd),   // read data of cache_data0
        .l2_data1_rd        (l2_data1_rd),   // read data of cache_data1
        .l2_data2_rd        (l2_data2_rd),   // read data of cache_data2
        .l2_data3_rd        (l2_data3_rd)   // read data of cache_data3
    );
	memory_top memory_top(
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
        /*I_Cache part*/ 
        .mem_wr_ic_en       (mem_wr_ic_en),
        .ic_en              (ic_en),         // busy signal of l2_cache
        .ic_index_mem       (ic_index_mem),
        .ic_tag_wd_mem      (ic_tag_wd_mem), 
        .ic_block0_we_mem   (ic_block0_we_mem),
        .ic_block1_we_mem   (ic_block1_we_mem),
        /*D_Cache part*/
        .dc_offset_l2(dc_offset_l2),
        .dc_offset_mem(dc_offset_mem),
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
        .dc_rw              (dc_rw_l2),  
        /*memory part*/
        .mem_rd             (mem_rd),
        .dc_rw_mem          (dc_rw_mem),
        .offset_mem         (offset_mem),
        .read_l2_en         (read_l2_en),
        .memory_busy        (memory_busy),
        .access_mem_clean   (access_mem_clean), 
        .access_mem_dirty   (access_mem_dirty)
    );
endmodule