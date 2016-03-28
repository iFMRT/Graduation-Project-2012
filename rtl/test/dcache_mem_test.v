/*
 -- ============================================================================
 -- FILE NAME   : dcache_mem_test.v
 -- DESCRIPTION : testbench of mem_stage with dcache
 -- ----------------------------------------------------------------------------
 -- Date:2016/3/27        Coding_by:kippy
 -- ============================================================================
*/
`timescale 1ns/1ps
/********** header file **********/
`include "stddef.h"
`include "dcache.h"
`include "l2_cache.h"
`include "cpu.h"
`include "mem.h"
`include "bus.h"
`include "ctrl.h"

module dcache_mem_test();
    // icache part
    reg              clk;           // clock
    reg              rst;           // reset
    /* CPU part */
    wire             miss_stall;    // the signal of stall caused by cache miss
    /* L1_cache part */
    wire             tag0_rw;       // read / write signal of L1_tag0
    wire             tag1_rw;       // read / write signal of L1_tag1
    wire     [20:0]  tag_wd;        // write data of L1_tag
    // wire     [19:0]  tag_wd;        // write data of L1_tag
    wire             data0_rw;      // read / write signal of cache_data0
    wire             data1_rw;      // read / write signal of cache_data1
    wire     [7:0]   index;         // address of L1_cache
    /* l2_cache part */
    wire             irq;           // icache request
    // reg              l2_busy;    // L2C busy mark
    // reg              l2_rdy;     // L2C ready mark
    // reg      [127:0] data_wd;    // write data to L1_IC
    // l2_icache
    /* CPU part */
    wire     [31:0]  l2_addr;  
    wire             l2_miss_stall; // stall caused by l2_miss
    wire             l2_cache_rw;
    /*cache part*/
    wire             l2_busy;       // busy mark of L2C
    wire     [127:0] data_rd;
    wire             l2_tag0_rw;    // read / write signal of tag0
    wire             l2_tag1_rw;    // read / write signal of tag1
    wire             l2_tag2_rw;    // read / write signal of tag0
    wire             l2_tag3_rw;    // read / write signal of tag1
    wire     [17:0]  l2_tag_wd;     // write data of tag
    // wire     [16:0]  l2_tag_wd;     // write data of tag
    wire             l2_rdy;        // ready mark of L2C
    wire             l2_data0_rw;   // the mark of cache_data0 write signal 
    wire             l2_data1_rw;   // the mark of cache_data1 write signal 
    wire             l2_data2_rw;   // the mark of cache_data2 write signal 
    wire             l2_data3_rw;   // the mark of cache_data3 write signal 
    wire     [8:0]   l2_index;      // address of cache
    /*memory part*/
    wire     [25:0]  mem_addr;      // address of memory
    wire             mem_rw;        // read / write signal of memory
    wire     [511:0] mem_wd;
    reg      [511:0] mem_rd;
    wire             mem_complete;
    // tag_ram part
    wire     [20:0]  tag0_rd;       // read data of tag0
    wire     [20:0]  tag1_rd;       // read data of tag1
    wire             lru;           // read data of tag
    wire             complete;      // complete write from L2 to L1
    // data_ram part 
    wire     [127:0] data0_rd;      // read data of cache_data0
    wire     [127:0] data1_rd;      // read data of cache_data1
    wire     [127:0] data_wd_l2;
    wire     [127:0] data_wd_dc;
    wire             data_wd_dc_en;
    wire             data_wd_l2_en;
    // l2_tag_ram part
    wire     [17:0]  l2_tag0_rd;    // read data of tag0
    wire     [17:0]  l2_tag1_rd;    // read data of tag1
    wire     [17:0]  l2_tag2_rd;    // read data of tag2
    wire     [17:0]  l2_tag3_rd;    // read data of tag3
    wire     [2:0]   plru;          // read data of tag
    wire             l2_complete;   // complete write from MEM to L2
    // l2_data_ram
    wire     [511:0] l2_data_wd;     // write data of l2_cache
    wire     [511:0] l2_data0_rd;    // read data of cache_data0
    wire     [511:0] l2_data1_rd;    // read data of cache_data1
    wire     [511:0] l2_data2_rd;    // read data of cache_data2
    wire     [511:0] l2_data3_rd;    // read data of cache_data3 
    // l2_dirty
    wire             l2_dirty_wd;
    wire             l2_dirty0_rw;
    wire             l2_dirty1_rw;
    wire             l2_dirty2_rw;
    wire             l2_dirty3_rw;
    wire             l2_dirty0;
    wire             l2_dirty1;
    wire             l2_dirty2;
    wire             l2_dirty3;
    wire             hitway;
    reg              clk_tmp;        // temporary clock of L2C
    reg              clk_mem;
    /********* pipeline control signals ********/
    //  State of Pipeline
     wire                  br_taken;    // branch hazard mark
    //   wire                   br_flag;      // branch instruction flag
    reg                    if_busy;
    /********** Data Forward **********/
    wire     [1:0]         src_reg_used;
    // LOAD Hazard
    wire                   id_en;          // Pipeline Register enable
    wire [`REG_ADDR_BUS]   id_dst_addr;    // GPR write address
    wire                   id_gpr_we_;     // GPR write enable
    wire [`INS_OP_BUS]     op; 
    wire [`REG_ADDR_BUS]   ra_addr;
    wire [`REG_ADDR_BUS]   rb_addr;
    // LOAD STORE Forward
    wire [`REG_ADDR_BUS]   id_ra_addr;
    wire [`REG_ADDR_BUS]   id_rb_addr;
    // Stall Signal
    wire                  if_stall;     // IF stage stall
    wire                  id_stall;     // ID stage stall
    wire                  ex_stall;     // EX stage stall
    wire                  mem_stall;    // MEM stage stall
    // Flush Signal
    wire                  if_flush;     // IF stage flush
    wire                  id_flush;     // ID stage flush
    wire                  ex_flush;     // EX stage flush
    wire                  mem_flush;    // MEM stage flush
    wire [`WORD_DATA_BUS] new_pc;        // New program counter
    wire [`WORD_DATA_BUS] fwd_data;
    // Forward from EX stage

    /********** Forward output **********/
    wire [`FWD_CTRL_BUS]   ra_fwd_ctrl;
    wire [`FWD_CTRL_BUS]   rb_fwd_ctrl;
    wire                   ex_ra_fwd_en;
    wire                   ex_rb_fwd_en;
    // if_stage
    wire [`WORD_DATA_BUS] pc;             // Current Program counter
    wire                  if_en;           // Effective mark of pipeline
    wire [`WORD_DATA_BUS] br_addr;     // Branch target
    
    /********** EX/MEM Pipeline Register **********/
    reg                    ex_en;          // If Pipeline data enable
    reg  [`MEM_OP_BUS]     ex_mem_op;      // Memory operation
    wire [`MEM_OP_BUS]     id_mem_op;
    wire [`WORD_DATA_BUS]  ex_mem_wr_data; // Memory write data
    wire [`REG_ADDR_BUS]   ex_dst_addr;    // General purpose register write address
    wire                   ex_gpr_we_;     // General purpose register enable
    reg  [`WORD_DATA_BUS]  ex_out;         // EX Stage operating reslut
    /********** MEM/WB Pipeline Register **********/
    wire                  mem_en;         // If Pipeline data enables
    wire [`REG_ADDR_BUS]  mem_dst_addr;   // General purpose register write address
    wire                  mem_gpr_we_;    // General purpose register enable
    wire [`WORD_DATA_BUS] mem_out;
    
    ctrl ctrl(
	    /********* pipeline control signals ********/
	    //  State of Pipeline
	    .if_busy		(if_busy),        // IF busy mark // miss stall of if_stage
	    .br_taken		(br_taken),       // branch hazard mark
	    //  br_flag,      // branch instruction flag
	    .mem_busy		(miss_stall),     // MEM busy mark // miss stall of mem_stage

	    /********** Data Forward **********/
	    .src_reg_used	(src_reg_used),
	    // LOAD Hazard
	    .id_en			(id_en),          // Pipeline Register enable
	    .id_dst_addr	(id_dst_addr),    // GPR write address
	    .id_gpr_we_		(id_gpr_we_),     // GPR write enable
	    .id_mem_op		(id_mem_op),      // Mem operation
	    .op				(op), 
	    .ra_addr		(ra_addr),
	    .rb_addr        (rb_addr),
	     // LOAD STORE Forward
	    .id_ra_addr		(id_ra_addr),
	    .id_rb_addr		(id_rb_addr),

	    .ex_en			(ex_en),          // Pipeline Register enable
	    .ex_dst_addr	(ex_dst_addr),    // GPR write address
	    .ex_gpr_we_		(ex_gpr_we_),     // GPR write enable
	    .ex_mem_op		(ex_mem_op),      // Mem operation

	    // Stall Signal
	    .if_stall		(if_stall),     // IF stage stall
	    .id_stall		(id_stall),     // ID stage stall
	    .ex_stall		(ex_stall),     // EX stage stall
	    .mem_stall		(mem_stall),    // MEM stage stall
	    // Flush Signal
	    .if_flush		(if_flush),     // IF stage flush
	    .id_flush		(id_flush),     // ID stage flush
	    .ex_flush		(ex_flush),     // EX stage flush
	    .mem_flush		(mem_flush),    // MEM stage flush
	    .new_pc			(new_pc),        // New program counter

	    // Forward from EX stage

	    /********** Forward Output **********/
	    .ra_fwd_ctrl	(ra_fwd_ctrl),
	    .rb_fwd_ctrl	(rb_fwd_ctrl),
	    .ex_ra_fwd_en	(ex_ra_fwd_en),
	    .ex_rb_fwd_en	(ex_rb_fwd_en)
		);
    mem_stage mem_stage(
        /********** Clock & Reset *********/
        .clk            (clk),           // clock
        .reset          (rst),           // reset
        /**** Pipeline Control Signal *****/
        .stall          (mem_stall),     
        .flush          (mem_flush),  
        /************ Forward *************/
        .fwd_data       (fwd_data),
        /************ CPU part ************/
        .miss_stall     (miss_stall),    // the signal of stall caused by cache miss
        /* L1_cache part */
        .lru            (lru),           // mark of replacing
        .tag0_rd        (tag0_rd),       // read data of tag0
        .tag1_rd        (tag1_rd),       // read data of tag1
        .data0_rd       (data0_rd),      // read data of data0
        .data1_rd       (data1_rd),      // read data of data1
        .dirty0         (dirty0),        // 
        .dirty1         (dirty1),        //  
        .dirty_wd       (dirty_wd),      //       
        .dirty0_rw      (dirty0_rw),     //       
        .dirty1_rw      (dirty1_rw),     //  
        .data_wd_dc     (data_wd_dc), 
        .tag0_rw        (tag0_rw),       // read / write signal of L1_tag0
        .tag1_rw        (tag1_rw),       // read / write signal of L1_tag1
        .tag_wd         (tag_wd),        // write data of L1_tag
        .data_wd_dc_en  (data_wd_dc_en),
        .data0_rw       (data0_rw),      // read / write signal of data0
        .data1_rw       (data1_rw),      // read / write signal of data1
        .index          (index),         // address of L1_cache
        .data_rd        (data_rd),
        /* l2_cache part */
        .l2_busy        (l2_busy),       // busy signal of l2_cache
        .l2_rdy         (l2_rdy),        // ready signal of l2_cache
        .complete       (complete),      // complete op writing to L1
        .irq            (irq),      
        .l2_addr        (l2_addr), 
        .l2_index       (l2_index),       
        .l2_cache_rw    (l2_cache_rw),        
        /********** EX/MEM Pipeline Register **********/
        .ex_en          (ex_en),       // busy signal of l2_cache
        .ex_mem_op      (ex_mem_op),        // ready signal of l2_cache
        .id_mem_op      (id_mem_op),      // complete op writing to L1
        .ex_mem_wr_data (ex_mem_wr_data),      
        .ex_dst_addr    (ex_dst_addr), 
        .ex_gpr_we_     (ex_gpr_we_),       
        .ex_out         (ex_out),
        /********** MEM/WB Pipeline Register **********/
        .mem_en         (mem_en),      
        .mem_dst_addr   (mem_dst_addr), 
        .mem_gpr_we_    (mem_gpr_we_),       
        .mem_out        (mem_out)
        );
    l2_cache_ctrl l2_cache_ctrl(
        .clk            (clk_tmp),       // clock of L2C
        .rst            (rst),           // reset
        /* CPU part */
        .l2_addr        (l2_addr),       // address of fetching instruction
        .l2_cache_rw    (l2_cache_rw),   // read / write signal of CPU
        .l2_miss_stall  (l2_miss_stall), // stall caused by l2_miss
        /*cache part*/
        .irq            (irq),           // icache request
        .complete       (complete),      // complete write from L2 to L1
        .data_rd        (data_rd),       // write data to L1C       
        .data_wd_l2     (data_wd_l2),       // write data to L1C       
        .data_wd_l2_en  (data_wd_l2_en), 
        /*l2_cache part*/
        .l2_complete    (l2_complete),   // complete write from MEM to L2
        .l2_rdy         (l2_rdy),
        .l2_busy        (l2_busy),
        // l2_tag part
        .plru           (plru),          // replace mark
        .l2_tag0_rd     (l2_tag0_rd),    // read data of tag0
        .l2_tag1_rd     (l2_tag1_rd),    // read data of tag1
        .l2_tag2_rd     (l2_tag2_rd),    // read data of tag2
        .l2_tag3_rd     (l2_tag3_rd),    // read data of tag3
        .l2_tag0_rw     (l2_tag0_rw),    // read / write signal of tag0
        .l2_tag1_rw     (l2_tag1_rw),    // read / write signal of tag1
        .l2_tag2_rw     (l2_tag2_rw),    // read / write signal of tag0
        .l2_tag3_rw     (l2_tag3_rw),    // read / write signal of tag1
        .l2_tag_wd      (l2_tag_wd),     // write data of tag0                
        // l2_data part
        .l2_data0_rd    (l2_data0_rd),   // read data of cache_data0
        .l2_data1_rd    (l2_data1_rd),   // read data of cache_data1
        .l2_data2_rd    (l2_data2_rd),   // read data of cache_data2
        .l2_data3_rd    (l2_data3_rd),   // read data of cache_data3
        .l2_data_wd     (l2_data_wd),           
        .l2_data0_rw    (l2_data0_rw),   // the mark of cache_data0 write signal 
        .l2_data1_rw    (l2_data1_rw),   // the mark of cache_data1 write signal 
        .l2_data2_rw    (l2_data2_rw),   // the mark of cache_data2 write signal 
        .l2_data3_rw    (l2_data3_rw),   // the mark of cache_data3 write signal         
        // l2_dirty part
        .l2_dirty_wd    (l2_dirty_wd),
        .l2_dirty0_rw   (l2_dirty0_rw),
        .l2_dirty1_rw   (l2_dirty1_rw),
        .l2_dirty2_rw   (l2_dirty2_rw),
        .l2_dirty3_rw   (l2_dirty3_rw),
        .l2_dirty0      (l2_dirty0),
        .l2_dirty1      (l2_dirty1),
        .l2_dirty2      (l2_dirty2), 
        .l2_dirty3      (l2_dirty3),         
        /*memory part*/
        .mem_complete   (mem_complete),
        .mem_rd         (mem_rd),
        .mem_wd         (mem_wd), 
        .mem_addr       (mem_addr),     // address of memory
        .mem_rw         (mem_rw)        // read / write signal of memory
    );
    ram ram(
        .clk        (clk_mem),    // Clock
        .rst        (rst),    // Asynchronous reset active low
        .rw         (mem_rw),
        .complete   (mem_complete)
      );
    dtag_ram dtag_ram(
        .clk            (clk),           // clock
        .tag0_rw        (tag0_rw),       // read / write signal of tag0
        .tag1_rw        (tag1_rw),       // read / write signal of tag1
        .index          (index),         // address of cache
        .dirty0_rw      (dirty0_rw),        
        .dirty1_rw      (dirty1_rw),   
        .dirty_wd       (dirty_wd), 
        .tag_wd         (tag_wd),        // write data of tag
        .tag0_rd        (tag0_rd),       // read data of tag0
        .tag1_rd        (tag1_rd),       // read data of tag1
        .dirty0         (dirty0),
        .dirty1         (dirty1),
        .lru            (lru),           // read data of tag
        .complete       (complete)       // complete write from L2 to L1
        );
    data_ram ddata_ram(
        .clk            (clk),           // clock
        .data0_rw       (data0_rw),      // the mark of cache_data0 write signal 
        .data1_rw       (data1_rw),      // the mark of cache_data1 write signal 
        .index          (index),         // address of cache__
        .data_wd_l2     (data_wd_l2),    // write data of l2_cache
        .data_wd_dc     (data_wd_dc),    // write data of l2_cache
        .data_wd_l2_en  (data_wd_l2_en), // write data of l2_cache
        .data_wd_dc_en  (data_wd_dc_en), // write data of l2_cache
        .data0_rd       (data0_rd),      // read data of cache_data0
        .data1_rd       (data1_rd)       // read data of cache_data1
    );
    l2_data_ram l2_data_ram(
        .clk            (clk_tmp),       // clock of L2C
        .l2_data0_rw    (l2_data0_rw),   // the mark of cache_data0 write signal 
        .l2_data1_rw    (l2_data1_rw),   // the mark of cache_data1 write signal 
        .l2_data2_rw    (l2_data2_rw),   // the mark of cache_data2 write signal 
        .l2_data3_rw    (l2_data3_rw),   // the mark of cache_data3 write signal 
        .l2_index       (l2_index),      // address of cache
        .l2_data_wd     (l2_data_wd),    // write data of l2_cache
        .l2_data0_rd    (l2_data0_rd),   // read data of cache_data0
        .l2_data1_rd    (l2_data1_rd),   // read data of cache_data1
        .l2_data2_rd    (l2_data2_rd),   // read data of cache_data2
        .l2_data3_rd    (l2_data3_rd)    // read data of cache_data3
    );
    l2_tag_ram l2_tag_ram(    
        .clk            (clk_tmp),       // clock of L2C
        .l2_tag0_rw     (l2_tag0_rw),    // read / write signal of tag0
        .l2_tag1_rw     (l2_tag1_rw),    // read / write signal of tag1
        .l2_tag2_rw     (l2_tag2_rw),    // read / write signal of tag2
        .l2_tag3_rw     (l2_tag3_rw),    // read / write signal of tag3
        .l2_index       (l2_index),      // address of cache
        .l2_tag_wd      (l2_tag_wd),     // write data of tag
        .l2_dirty0_rw   (l2_dirty0_rw),
        .l2_dirty1_rw   (l2_dirty1_rw),
        .l2_dirty2_rw   (l2_dirty2_rw),
        .l2_dirty3_rw   (l2_dirty3_rw),
        .l2_dirty_wd    (l2_dirty_wd),
        .l2_tag0_rd     (l2_tag0_rd),    // read data of tag0
        .l2_tag1_rd     (l2_tag1_rd),    // read data of tag1
        .l2_tag2_rd     (l2_tag2_rd),    // read data of tag2
        .l2_tag3_rd     (l2_tag3_rd),    // read data of tag3
        .plru           (plru),          // read data of plru_field
        .l2_complete    (l2_complete),   // complete write from L2 to L1
        .l2_dirty0      (l2_dirty0),
        .l2_dirty1      (l2_dirty1),
        .l2_dirty2      (l2_dirty2),
        .l2_dirty3      (l2_dirty3)
    );
	task ctrl_tb;
        input          _if_stall;        // read data of CPU
        input          _id_stall;      // the signal of stall caused by cache miss
        // input          _hitway;       
        /* L1_cache part */
        input          _ex_stall;         // read / write signal of L1_tag0
        input          _mem_stall;         // read / write signal of L1_tag1
        input          _if_flush;          // write data of L1_tag
        input          _id_flush;        // read / write signal of data0
        input          _ex_flush;        // read / write signal of data1
        input          _mem_flush;           // address of L1_cache

        begin 
            if( (if_stall   === _if_stall)   && 
                (id_stall   === _id_stall)   && 
                (ex_stall   === _ex_stall)   && 
                (mem_stall  === _mem_stall)  && 
                (if_flush   === _if_flush)   && 
                (id_flush   === _id_flush)   && 
                (ex_flush   === _ex_flush)   && 
                (mem_flush  === _mem_flush) 
               ) begin 
                 $display("ctrl Test Succeeded !"); 
            end else begin 
                 $display("ctrl Test Failed !"); 
            end 
            // if (if_stall   !== _if_stall) begin
            //     $display("if_stall:%b(excepted %b)",if_stall,_if_stall); 
            // end
            // if (id_stall   !== _id_stall) begin
            //     $display("id_stall:%b(excepted %b)",id_stall,_id_stall); 
            // end
            // if (ex_stall   !== _ex_stall) begin
            //     $display("ex_stall:%b(excepted %b)",ex_stall,_ex_stall); 
            // end
            // if (mem_stall   !== _mem_stall) begin
            //     $display("mem_stall:%b(excepted %b)",mem_stall,_mem_stall); 
            // end
            // if (if_flush   !== _if_flush) begin
            //     $display("if_flush:%b(excepted %b)",if_flush,_if_flush); 
            // end
            // if (id_flush !== _id_flush) begin
            //     $display("id_flush:%b(excepted %b)",id_flush,_id_flush); 
            // end
            // if (ex_flush    !== _ex_flush) begin
            //     $display("ex_flush:%b(excepted %b)",ex_flush,_ex_flush); 
            // end
            // if (mem_flush    !== _mem_flush) begin
            //     $display("mem_flush:%b(excepted %b)",mem_flush,_mem_flush); 
            // end
        end
    endtask 
    task mem_stage_tb;
        input  [31:0]  _mem_out;        // read data of CPU
        input          _miss_stall;      // the signal of stall caused by cache miss
        // input          _hitway;       
        /* L1_cache part */
        input          _tag0_rw;         // read / write signal of L1_tag0
        input          _tag1_rw;         // read / write signal of L1_tag1
        input  [20:0]  _tag_wd;          // write data of L1_tag
        input          _data0_rw;        // read / write signal of data0
        input          _data1_rw;        // read / write signal of data1
        input  [7:0]   _index;           // address of L1_cache
        input  [127:0] _data_wd_dc;
        input  [127:0] _data_rd;        
        /* l2_cache part */
        input          _irq;             // icache request
        input  [8:0]   _l2_index;
        input  [31:0]  _l2_addr;
        // dirty
        input          _dirty_wd;
        input          _dirty0_rw;
        input          _dirty1_rw;

        begin 
            if( (mem_out   === _mem_out)    && 
                (miss_stall === _miss_stall)        && 
                (tag0_rw    === _tag0_rw)           && 
                (tag1_rw    === _tag1_rw)           && 
                (tag_wd     === _tag_wd)            && 
                (data0_rw   === _data0_rw)          && 
                (data1_rw   === _data1_rw)          && 
                (index      === _index)             && 
                (irq        === _irq)               && 
                (l2_index   === _l2_index)          && 
                (l2_addr    === _l2_addr)           && 
                (data_wd_dc   === _data_wd_dc)      && 
                (dirty0_rw  === _dirty0_rw)         && 
                (dirty1_rw  === _dirty1_rw)         && 
                (data_rd    === _data_rd)           && 
                (data_wd_dc    === _data_wd_dc)
               ) begin 
                 $display("mem_stage Test Succeeded !"); 
            end else begin 
                 $display("mem_stage Test Failed !"); 
            end 
            if (data_wd_dc   !== _data_wd_dc) begin
                $display("data_wd_dc:%b(excepted %b)",data_wd_dc,_data_wd_dc); 
            end
            if (data_rd   !== _data_rd) begin
                $display("data_rd:%b(excepted %b)",data_rd,_data_rd); 
            end
            if (dirty0_rw   !== _dirty0_rw) begin
                $display("dirty0_rw:%b(excepted %b)",dirty0_rw,_dirty0_rw); 
            end
            if (dirty1_rw   !== _dirty1_rw) begin
                $display("dirty1_rw:%b(excepted %b)",dirty1_rw,_dirty1_rw); 
            end
            if (mem_out   !== _mem_out) begin
                $display("mem_out:%b(excepted %b)",mem_out,_mem_out); 
            end
            if (miss_stall !== _miss_stall) begin
                $display("miss_stall:%b(excepted %b)",miss_stall,_miss_stall); 
            end
            if (tag0_rw    !== _tag0_rw) begin
                $display("tag0_rw:%b(excepted %b)",tag0_rw,_tag0_rw); 
            end
            if (tag1_rw    !== _tag1_rw) begin
                $display("tag1_rw:%b(excepted %b)",tag1_rw,_tag1_rw); 
            end
            if (tag_wd     !== _tag_wd) begin
                $display("tag_wd:%b(excepted %b)",tag_wd,_tag_wd); 
            end
            if (data0_rw   !== _data0_rw) begin
                $display("data0_rw:%b(excepted %b)",data0_rw,_data0_rw); 
            end
            if (data1_rw   !== _data1_rw) begin
                $display("data1_rw:%b(excepted %b)",data1_rw,_data1_rw); 
            end
            if (index      !== _index) begin
                $display("index:%b(excepted %b)",index,_index); 
            end
            if (irq   !== _irq) begin
                $display("irq:%b(excepted %b)",irq,_irq); 
            end
            if (l2_index   !== _l2_index) begin
                $display("l2_index:%b(excepted %b)",l2_index,_l2_index); 
            end
            if (l2_addr      !== _l2_addr) begin
                $display("l2_addr:%b(excepted %b)",l2_addr,_l2_addr); 
            end
        end
    endtask 
    task l2_cache_ctrl_tb;
        input           _l2_miss_stall;      // miss caused by L2C
        input           _l2_busy;            // L2C busy mark
        input   [127:0] _data_wd_l2;            // write data to L1_IC
        input           _l2_tag0_rw;         // read / write signal of tag0
        input           _l2_tag1_rw;         // read / write signal of tag1
        input           _l2_tag2_rw;         // read / write signal of tag0
        input           _l2_tag3_rw;         // read / write signal of tag1
        input   [17:0]  _l2_tag_wd;          // write data of tag0
        input           _l2_rdy;             // ready signal of l2_cache
        input           _l2_data0_rw;        // the mark of cache_data0 write signal 
        input           _l2_data1_rw;        // the mark of cache_data1 write signal 
        input           _l2_data2_rw;        // the mark of cache_data2 write signal 
        input           _l2_data3_rw;        // the mark of cache_data3 write signal 
        input   [511:0] _l2_data_wd;
        // l2_dirty part
        input           _l2_dirty_wd;
        input           _l2_dirty0_rw;
        input           _l2_dirty1_rw;
        input           _l2_dirty2_rw;
        input           _l2_dirty3_rw;
        input   [25:0]  _mem_addr;           // address of memory
        input           _mem_rw;             // read / write signal of memory
        begin 
            if( (l2_miss_stall === _l2_miss_stall)  && 
                (l2_busy       === _l2_busy)        && 
                (data_wd_l2    === _data_wd_l2)     && 
                (l2_tag0_rw    === _l2_tag0_rw)     && 
                (l2_tag1_rw    === _l2_tag1_rw)     && 
                (l2_tag2_rw    === _l2_tag2_rw)     && 
                (l2_tag3_rw    === _l2_tag3_rw)     && 
                (l2_tag_wd     === _l2_tag_wd)      && 
                (l2_rdy        === _l2_rdy)         && 
                (l2_data0_rw   === _l2_data0_rw)    && 
                (l2_data1_rw   === _l2_data1_rw)    && 
                (l2_data2_rw   === _l2_data2_rw)    && 
                (l2_data3_rw   === _l2_data3_rw)    && 
                (l2_data_wd    === _l2_data_wd)     &&
                (l2_dirty_wd  === _l2_dirty_wd)     &&
                (l2_dirty0_rw  === _l2_dirty0_rw)   &&
                (l2_dirty1_rw  === _l2_dirty1_rw)   &&
                (l2_dirty2_rw  === _l2_dirty2_rw)   &&
                (l2_dirty3_rw  === _l2_dirty3_rw)   &&
                (mem_addr      === _mem_addr)       && 
                (mem_rw        === _mem_rw)  
               ) begin 
                 $display("l2_dcache Test Succeeded !"); 
            end else begin 
                 $display("l2_dcache Test Failed !"); 
            end 
            
            // check
            if(l2_miss_stall !== _l2_miss_stall)begin 
                $display("l2_miss_stall:%b(excepted %b)",l2_miss_stall,_l2_miss_stall); 
            end
            if(l2_busy       !== _l2_busy)     begin
                $display("l2_busy Test Failed !"); 
            end
            if(data_wd_l2    !== _data_wd_l2)     begin
                $display("data_wd_l2:%b(excepted %b)",data_wd_l2,_data_wd_l2); 
            end
            if(l2_tag0_rw    !== _l2_tag0_rw)  begin
                $display("l2_tag0_rw Test Failed !"); 
            end
            if(l2_tag1_rw    !== _l2_tag1_rw)  begin
                $display("l2_tag1_rw Test Failed !"); 
            end
            if(l2_tag2_rw    !== _l2_tag2_rw)  begin
                $display("l2_tag2_rw Test Failed !"); 
            end
            if(l2_tag3_rw    !== _l2_tag3_rw)  begin
                $display("l2_miss_stall Test Failed !"); 
            end
            if(l2_tag_wd     !== _l2_tag_wd)   begin
                $display("l2_tag_wd Test Failed !"); 
            end
            if(l2_rdy        !== _l2_rdy)      begin
                $display("l2_rdy Test Failed !"); 
            end
            if(l2_data0_rw   !== _l2_data0_rw) begin
                $display("l2_data0_rw Test Failed !"); 
            end
            if(l2_data1_rw   !== _l2_data1_rw) begin
                $display("l2_data1_rw Test Failed !"); 
            end
            if(l2_data2_rw   !== _l2_data2_rw) begin
                $display("l2_data2_rw Test Failed !"); 
            end
            if(l2_data3_rw   !== _l2_data3_rw) begin
                $display("l2_data3_rw Test Failed !"); 
            end
            if (l2_dirty0_rw !== _l2_dirty0_rw) begin
                $display("l2_dirty0_rw Test Failed !"); 
            end
            if (l2_dirty1_rw !== _l2_dirty1_rw) begin
                $display("l2_dirty1_rw Test Failed !"); 
            end
            if(mem_addr      !== _mem_addr)    begin
                $display("mem_addr Test Failed !"); 
            end
            if(mem_rw        !== _mem_rw) begin
                $display("mem_rw Test Failed !"); 
            end 
        end
    endtask
    task tag_ram_tb;
        input      [20:0]  _tag0_rd;        // read data of tag0
        input      [20:0]  _tag1_rd;        // read data of tag1
        input              _lru;            // read block of tag
        input              _complete;       // complete write from L2 to L1
        begin 
            if( (tag0_rd  === _tag0_rd)     && 
                (tag1_rd  === _tag1_rd)     && 
                (lru      === _lru)         && 
                (complete === _complete)              
               ) begin 
                 $display("Tag_ram Test Succeeded !"); 
            end else begin 
                 $display("Tag_ram Test Failed !"); 
            end             
            // if (tag0_rd  !== _tag0_rd) begin
            //     $display("tag0_rd:%b(excepted %b)",tag0_rd,_tag0_rd); 
            // end
            // if (tag1_rd  !== _tag1_rd) begin
            //     $display("tag1_rd:%b(excepted %b)",tag1_rd,_tag1_rd); 
            // end
            // if (lru      !== _lru) begin
            //     $display("lru:%b(excepted %b)",lru,_lru); 
            // end
            // if (complete !== _complete) begin
            //     $display("complete:%b(excepted %b)",complete,_complete); 
            // end
        end
    endtask
    task data_ram_tb;
        input  [127:0] _data0_rd;        // read data of cache_data0
        input  [127:0] _data1_rd;        // read data of cache_data1
        begin 
            if( (data0_rd  === _data0_rd)   && 
                (data1_rd  === _data1_rd)             
               ) begin 
                 $display("Data_ram Test Succeeded !"); 
            end else begin 
                 $display("Data_ram Test Failed !"); 
            end 
            if(data0_rd !== _data0_rd) begin
                $display("data0_rd:%b(excepted %b)",data0_rd,_data0_rd); 
            end
            if(data1_rd !== _data1_rd) begin
                $display("data1_rd:%b(excepted %b)",data1_rd,_data1_rd); 
            end           
        end
    endtask 
    task l2_tag_ram_tb;    
        input      [18:0]  _l2_tag0_rd;        // read data of tag0
        input      [18:0]  _l2_tag1_rd;        // read data of tag1
        input      [18:0]  _l2_tag2_rd;        // read data of tag2
        input      [18:0]  _l2_tag3_rd;        // read data of tag3
        input      [2:0]   _plru;              // read data of tag
        input              _l2_complete;       // complete write from L2 to L1
        begin 
            if( (l2_tag0_rd  === _l2_tag0_rd)   && 
                (l2_tag1_rd  === _l2_tag1_rd)   && 
                (l2_tag2_rd  === _l2_tag2_rd)   && 
                (l2_tag3_rd  === _l2_tag3_rd)   && 
                (plru        === _plru)         && 
                (l2_complete === _l2_complete)
               ) begin 
                 $display("l2_tag_ram Test Succeeded !"); 
            end else begin 
                 $display("l2_tag_ram Test Failed !"); 
            end 
            // if (l2_tag0_rd  !== _l2_tag0_rd) begin
            //     $display("l2_tag0_rd:%b(excepted %b)",l2_tag0_rd,_l2_tag0_rd); 
            // end
            // if (l2_tag1_rd  !== _l2_tag1_rd) begin
            //     $display("l2_tag1_rd:%b(excepted %b)",l2_tag1_rd,_l2_tag1_rd); 
            // end
            // if (l2_tag2_rd  !== _l2_tag2_rd) begin
            //     $display("l2_tag2_rd:%b(excepted %b)",l2_tag2_rd,_l2_tag2_rd); 
            // end
            // if (l2_tag3_rd  !== _l2_tag3_rd) begin
            //     $display("l2_tag3_rd:%b(excepted %b)",l2_tag3_rd,_l2_tag3_rd); 
            // end
            // if (plru        !== _plru) begin
            //     $display("plru:%b(excepted %b)",plru,_plru); 
            // end
            // if (l2_complete !== _l2_complete) begin
            //     $display("l2_complete:%b(excepted %b)",l2_complete,_l2_complete); 
            // end
        end
    endtask
    task l2_data_ram_tb;
        input  [511:0] _l2_data0_rd;         // read data of cache_data0
        input  [511:0] _l2_data1_rd;         // read data of cache_data1
        input  [511:0] _l2_data2_rd;         // read data of cache_data2
        input  [511:0] _l2_data3_rd;         // read data of cache_data3
        begin 
            if( (l2_data0_rd  === _l2_data0_rd)   && 
                (l2_data1_rd  === _l2_data1_rd)   && 
                (l2_data2_rd  === _l2_data2_rd)   && 
                (l2_data3_rd  === _l2_data3_rd)                 
               ) begin 
                 $display("l2_data_ram Test Succeeded !"); 
            end else begin 
                 $display("l2_data_ram Test Failed !"); 
            end 
        end
        // if (l2_data0_rd  !== _l2_data0_rd) begin
        //     $display("l2_data0_rd:%b(excepted %b)",l2_data0_rd,_l2_data0_rd); 
        // end
        // if (l2_data1_rd  !== _l2_data1_rd) begin
        //     $display("l2_data1_rd:%b(excepted %b)",l2_data1_rd,_l2_data1_rd); 
        // end
        // if (l2_data2_rd  !== _l2_data2_rd) begin
        //     $display("l2_data2_rd:%b(excepted %b)",l2_data2_rd,_l2_data2_rd); 
        // end
        // if (l2_data3_rd  !== _l2_data3_rd) begin
        //     $display("l2_data3_rd:%b(excepted %b)",l2_data3_rd,_l2_data3_rd); 
        // end
    endtask

    /******** Define Simulation Loop********/ 
    parameter  STEP = 10; 

    /******* Generated Clocks *******/
    always #(STEP / 2)
        begin
            clk <= ~clk;  
        end
    always #STEP
        begin
            clk_tmp <= ~clk_tmp;  
        end    
    always #(2*STEP)
        begin
            clk_mem <= ~clk_mem;  
        end      
    /********** Testbench **********/
    initial begin
        #0 begin
            clk     <= `ENABLE;
            clk_tmp <= `ENABLE;
            rst     <= `ENABLE;
        end
        #(STEP * 3/4)
        #STEP begin 
            /******** Initialize Test Output ********/
            rst        <= `DISABLE;      
            // addr   <= 32'b1110_0001_0000_0000;
            // access_mem <= `ENABLE;
            // memwrite_m <= `READ;
            if_busy   <= `DISABLE;
            ex_en     <= `ENABLE;
            ex_mem_op <= `MEM_OP_LW;
            ex_out  <= 32'b1110_0001_0000_0000;
            mem_rd <= 512'h123BC000_0876547A_00000000_ABF00000_123BC000_00000000_0876547A_00000000_ABF00000_123BC000;      // write data of l2_cache
            // l2_busy <= `DISABLE;                                      // busy signal of l2_cache
            // l2_rdy  <= `ENABLE;                                       // ready signal of l2_cache
            // data_wd <= 128'h0876547A_00000000_ABF00000_123BC000;      // write data of L1_cache
        end
        #STEP begin // L1_IDLE & L2_IDLE 
            $display("\n========= Clock 1 ========");
        end
        #STEP begin // L1_ACCESS & L2_IDLE 
            $display("\n========= Clock 2 ========");
            mem_stage_tb(
                32'bx,          // mem_out of CPU
                `ENABLE,        // the signal of stall caused by cache miss
                // 1'bx,           // hitway
                `READ,          // read / write signal of L1_tag0
                `READ,          // read / write signal of L1_tag1
                21'b1_0000_0000_0000_0000_1110,       // write data of L1_tag
                `READ,          // read / write signal of data0
                `READ,          // read / write signal of data1
                8'b0001_0000,   // address of L1_cache
                128'bx,         // data_wd
                128'bx,         // data_rd choosing from data_rd1~data_rd3
                `ENABLE,         // icache request
                9'b110_0001_00,
                32'b1110_0001_0000_0000,
                1'bx,                    // dirty_wd
                `READ,                    // dirty0_rw
                `READ                     // dirty1_rw
                );
        end
        #STEP begin // L2_ACCESS & ACCESS_L2 
            $display("\n========= Clock 3 ========");
            mem_stage_tb(
                32'bx,          // mem_out of CPU
                `ENABLE,        // the signal of stall caused by cache miss
                // 1'bx,           // hitway
                `READ,          // read / write signal of L1_tag0
                `READ,          // read / write signal of L1_tag1
                21'b1_0000_0000_0000_0000_1110,       // write data of L1_tag
                `READ,          // read / write signal of data0
                `READ,          // read / write signal of data1
                8'b0001_0000,   // address of L1_cache
                128'bx,         // data_wd
                128'bx,         // data_rd choosing from data_rd1~data_rd3
                `ENABLE,         // icache request
                9'b110_0001_00,
                32'b1110_0001_0000_0000,
                1'bx,                    // dirty_wd
                `READ,                    // dirty0_rw
                `READ                    // dirty1_rw
                );
        end      
        // 2* clk state ACCESS_L2 really 
        #STEP begin // L2_ACCESS & 2* clk state change to ACCESS_L2 really 
            $display("\n========= Clock 4 ========");
            l2_cache_ctrl_tb(
                `DISABLE,           // miss caused by L2C             
                `ENABLE,            // L2C busy mark
                128'bx,             // write data to L1_IC
                `READ,              // read / write signal of tag0
                `READ,              // read / write signal of tag1
                `READ,              // read / write signal of tag2
                `READ,              // read / write signal of tag3
                18'bx,              // write data of tag
                `DISABLE,           // ready signal of l2_cache
                `READ,              // the mark of cache_data0 write signal 
                `READ,              // the mark of cache_data1 write signal 
                `READ,              // the mark of cache_data2 write signal 
                `READ,              // the mark of cache_data3 write signal 
                512'bx,
                1'bx,
                `READ,
                `READ,
                `READ,
                `READ,
                26'bx,              // address of memory
                1'bx                // read / write signal of memory                
                );        
        end
        #STEP begin // L2_ACCESS & MEM_ACCESS first clk
            $display("\n========= Clock 5 ========");
            l2_cache_ctrl_tb(
                `ENABLE,            // miss caused by L2C             
                `ENABLE,            // L2C busy mark
                128'bx,             // write data to L1_IC
                `READ,              // read / write signal of tag0
                `READ,              // read / write signal of tag1
                `READ,              // read / write signal of tag2
                `READ,              // read / write signal of tag3
                18'bx,              // write data of tag
                `DISABLE,           // ready signal of l2_cache
                `READ,              // the mark of cache_data0 write signal 
                `READ,              // the mark of cache_data1 write signal 
                `READ,              // the mark of cache_data2 write signal 
                `READ,              // the mark of cache_data3 write signal 
                512'bx,
                1'bx,
                `READ,
                `READ,
                `READ,
                `READ,
                26'b1110_0001_00,   // address of memory
                `READ               // read / write signal of memory                
                );
        end
        #STEP begin // l2_ACCESS & 2* MEM_ACCESS last clk
            $display("\n========= Clock 6 ========");
            // mem op
        end        
        #STEP begin // l2_ACCESS & WRITE_L2 & access l2_ram
            $display("\n========= Clock 7 ========");            
            l2_cache_ctrl_tb(
                `ENABLE,            // miss caused by L2C             
                `ENABLE,            // L2C busy mark
                128'bx,             // write data to L1_IC
                `WRITE,              // read / write signal of tag0
                `READ,              // read / write signal of tag1
                `READ,              // read / write signal of tag2
                `READ,              // read / write signal of tag3
                18'b1_0000_0000_0000_0000_1,              // write data of tag
                `DISABLE,           // ready signal of l2_cache
                `WRITE,              // the mark of cache_data0 write signal 
                `READ,              // the mark of cache_data1 write signal 
                `READ,              // the mark of cache_data2 write signal 
                `READ,              // the mark of cache_data3 write signal 
                512'h123BC000_0876547A_00000000_ABF00000_123BC000_00000000_0876547A_00000000_ABF00000_123BC000,
                1'b0,
                `WRITE,
                `READ,
                `READ,
                `READ,
                26'b1110_0001_00,   // address of memory
                `READ               // read / write signal of memory                
                );
        end
        #STEP begin // l2_ACCESS & WRITE_L2 & access l2_ram
            $display("\n========= Clock 8 ========"); 
            l2_tag_ram_tb(   
                18'b0,            // read data of tag0
                18'b0,            // read data of tag1
                18'b0,            // read data of tag2
                18'b0,            // read data of tag3
                3'b000,           // read data of tag
                `DISABLE          // complete write from L2 to L1
            );
        end
        #STEP begin // l2_ACCESS  &  ACCESS_L2
            $display("\n========= Clock 9 ========"); 
            l2_tag_ram_tb(   
                18'b1_0000_0000_0000_0000_1,    // read data of tag0
                18'b0,                          // read data of tag1
                18'b0,                          // read data of tag2
                18'b0,                          // read data of tag3
                3'b011,                         // read data of tag
                `ENABLE                         // complete write from L2 to L1
            );
            l2_data_ram_tb(
                512'h123BC000_0876547A_00000000_ABF00000_123BC000_00000000_0876547A_00000000_ABF00000_123BC000,         // read data of cache_data0
                512'b0,             // read data of cache_data1
                512'b0,             // read data of cache_data2
                512'b0              // read data of cache_data3
             );
            mem_stage_tb(
                32'bx,          // mem_out of CPU
                `ENABLE,        // the signal of stall caused by cache miss
                // 1'bx,           // hitway
                `READ,          // read / write signal of L1_tag0
                `READ,          // read / write signal of L1_tag1
                21'b1_0000_0000_0000_0000_1110,       // write data of L1_tag
                `READ,          // read / write signal of data0
                `READ,          // read / write signal of data1
                8'b0001_0000,   // address of L1_cache
                128'bx,         // data_wd
                128'bx,         // data_rd choosing from data_rd1~data_rd3
                `ENABLE,         // icache request
                9'b110_0001_00,
                32'b1110_0001_0000_0000,
                1'bx,                    // dirty_wd
                `READ,                    // dirty0_rw
                `READ                    // dirty1_rw
                );
            l2_cache_ctrl_tb(
                `ENABLE,            // miss caused by L2C             
                `ENABLE,            // L2C busy mark
                128'bx,             // write data to L1_IC
                `READ,              // read / write signal of tag0
                `READ,              // read / write signal of tag1
                `READ,              // read / write signal of tag2
                `READ,              // read / write signal of tag3
                18'b1_0000_0000_0000_0000_1,              // write data of tag
                `DISABLE,           // ready signal of l2_cache
                `READ,              // the mark of cache_data0 write signal 
                `READ,              // the mark of cache_data1 write signal 
                `READ,              // the mark of cache_data2 write signal 
                `READ,              // the mark of cache_data3 write signal 
                512'h123BC000_0876547A_00000000_ABF00000_123BC000_00000000_0876547A_00000000_ABF00000_123BC000,
                1'b0,
                `READ,
                `READ,
                `READ,
                `READ,
                26'b1110_0001_00,   // address of memory
                `READ               // read / write signal of memory                
                );        
        end
        #STEP begin // l2_ACCESS  & 2* clk state change to ACCESS_L2 really  
            $display("\n========= Clock 10 ========"); 
        end
        #STEP begin // l2_ACCESS  & WRITE_L1 
            $display("\n========= Clock 11 ========"); 
            l2_cache_ctrl_tb(
                `DISABLE,            // miss caused by L2C             
                `ENABLE,            // L2C busy mark
                128'h0876547A_00000000_ABF00000_123BC000, // write data to L1
                `READ,              // read / write signal of tag0
                `READ,              // read / write signal of tag1
                `READ,              // read / write signal of tag2
                `READ,              // read / write signal of tag3
                18'b1_0000_0000_0000_0000_1,              // write data of tag
                `ENABLE,           // ready signal of l2_cache
                `READ,              // the mark of cache_data0 write signal 
                `READ,              // the mark of cache_data1 write signal 
                `READ,              // the mark of cache_data2 write signal 
                `READ,              // the mark of cache_data3 write signal 
                512'h123BC000_0876547A_00000000_ABF00000_123BC000_00000000_0876547A_00000000_ABF00000_123BC000,
                1'b0,
                `READ,
                `READ,
                `READ,
                `READ,
                26'b1110_0001_00,   // address of memory
                `READ               // read / write signal of memory                
                ); 
            mem_stage_tb(
                32'bx,          // read data of CPU
                `ENABLE,        // the signal of stall caused by cache miss
                `READ,          // read / write signal of L1_tag0
                `READ,          // read / write signal of L1_tag1
                21'b1_0000_0000_0000_0000_1110,       // write data of L1_tag
                `READ,          // read / write signal of data0
                `READ,          // read / write signal of data1
                8'b0001_0000,   // address of L1_cache
                128'bx,         // data_wd
                128'bx,         // data_rd choosing from data_rd1~data_rd3
                `ENABLE,         // icache request
                9'b110_0001_00,
                32'b1110_0001_0000_0000,
                1'bx,                    // dirty_wd
                `READ,                    // dirty0_rw
                `READ                    // dirty1_rw
                );
            tag_ram_tb(
                21'b0,                                  // read data of tag0
                21'b0,                                  // read data of tag1
                1'b0,                                   // number of replacing block of tag next time
                1'b0                                    // complete write from L2 to L1
                );
            data_ram_tb(
                128'h0,   // read data of cache_data0
                128'h0                                      // read data of cache_data1
                );           
        end        
        #STEP begin // WRITE_L1  & 2* clk state change to WRITE_L1 really    
            $display("\n========= Clock 12 ========"); 
            l2_cache_ctrl_tb(
                `DISABLE,            // miss caused by L2C             
                `ENABLE,            // L2C busy mark
                128'h0876547A_00000000_ABF00000_123BC000, // write data to L1
                `READ,              // read / write signal of tag0
                `READ,              // read / write signal of tag1
                `READ,              // read / write signal of tag2
                `READ,              // read / write signal of tag3
                18'b1_0000_0000_0000_0000_1,              // write data of tag
                `ENABLE,           // ready signal of l2_cache
                `READ,              // the mark of cache_data0 write signal 
                `READ,              // the mark of cache_data1 write signal 
                `READ,              // the mark of cache_data2 write signal 
                `READ,              // the mark of cache_data3 write signal 
                512'h123BC000_0876547A_00000000_ABF00000_123BC000_00000000_0876547A_00000000_ABF00000_123BC000,
                1'b0,
                `READ,
                `READ,
                `READ,
                `READ,
                26'b1110_0001_00,   // address of memory
                `READ               // read / write signal of memory                
                );
            mem_stage_tb(
                32'bx,          // read data of CPU
                `ENABLE,        // the signal of stall caused by cache miss
                `WRITE,          // read / write signal of L1_tag0
                `READ,          // read / write signal of L1_tag1
                21'b1_0000_0000_0000_0000_1110,       // write data of L1_tag
                `WRITE,          // read / write signal of data0
                `READ,          // read / write signal of data1
                8'b0001_0000,   // address of L1_cache
                128'bx,         // data_wd
                128'bx,         // data_rd choosing from data_rd1~data_rd3
                `ENABLE,         // icache request
                9'b110_0001_00,
                32'b1110_0001_0000_0000,
                1'b0,                    // dirty_wd
                `WRITE,                    // dirty0_rw
                `READ                     // dirty1_rw
                );
        end        
        #STEP begin // L1_ACCESS  & l2_IDLE        
            $display("\n========= Clock 13 ========");
            l2_cache_ctrl_tb(
                `DISABLE,            // miss caused by L2C             
                `DISABLE,            // L2C busy mark
                128'h0876547A_00000000_ABF00000_123BC000,             // write data to L1_IC
                `READ,              // read / write signal of tag0
                `READ,              // read / write signal of tag1
                `READ,              // read / write signal of tag2
                `READ,              // read / write signal of tag3
                18'b1_0000_0000_0000_0000_1,              // write data of tag
                `DISABLE,           // ready signal of l2_cache
                `READ,              // the mark of cache_data0 write signal 
                `READ,              // the mark of cache_data1 write signal 
                `READ,              // the mark of cache_data2 write signal 
                `READ,              // the mark of cache_data3 write signal 
                512'h123BC000_0876547A_00000000_ABF00000_123BC000_00000000_0876547A_00000000_ABF00000_123BC000,
                1'b0,
                `READ,
                `READ,
                `READ,
                `READ,
                26'b1110_0001_00,   // address of memory
                `READ               // read / write signal of memory                
                );
            mem_stage_tb(
                32'bx,          // out of mem stage
                `ENABLE,        // the signal of stall caused by cache miss
                `READ,          // read / write signal of L1_tag0
                `READ,          // read / write signal of L1_tag1
                21'b1_0000_0000_0000_0000_1110,       // write data of L1_tag
                `READ,          // read / write signal of data0
                `READ,          // read / write signal of data1
                8'b0001_0000,   // address of L1_cache
                128'bx,         // data_wd
                128'bx,         // data_rd choosing from data_rd1~data_rd3
                `DISABLE,         // icache request
                9'b110_0001_00,
                32'b1110_0001_0000_0000,
                1'b0,                    // dirty_wd
                `READ,                    // dirty0_rw
                `READ                    // dirty1_rw
                );
            tag_ram_tb(
                21'b1_0000_0000_0000_0000_1110,         // read data of tag0
                21'b0,                                  // read data of tag1
                1'b1,                                   // number of replacing block of tag next time
                1'b1                                    // complete write from L2 to L1
                );
            data_ram_tb(
                128'h0876547A_00000000_ABF00000_123BC000,   // read data of cache_data0
                128'h0                                      // read data of cache_data1
                ); 
        end
        #STEP begin // MEM stage // L1_IDLE(read hit)  & l2_IDLE    
            $display("\n========= Clock 14 ========");
            mem_stage_tb(
                32'hx,    // read data of CPU
                `DISABLE,        // the signal of stall caused by cache miss
                `READ,          // read / write signal of L1_tag0
                `READ,          // read / write signal of L1_tag1
                21'b1_0000_0000_0000_0000_1110,       // write data of L1_tag
                `READ,          // read / write signal of data0
                `READ,          // read / write signal of data1
                8'b0001_0000,   // address of L1_cache
                128'bx,         // data_wd
                128'bx,         // data_rd choosing from data_rd1~data_rd3
                `DISABLE,         // icache request
                9'b110_0001_00,
                32'b1110_0001_0000_0000,
                1'b0,                    // dirty_wd
                `READ,                    // dirty0_rw
                `READ                    // dirty1_rw
                );
        end
        #STEP begin // WB stage
            $display("\n========= Clock 15 ========");
            mem_stage_tb(
                32'h123BC000,    // read data of CPU
                `DISABLE,        // the signal of stall caused by cache miss
                `READ,          // read / write signal of L1_tag0
                `READ,          // read / write signal of L1_tag1
                21'b1_0000_0000_0000_0000_1110,       // write data of L1_tag
                `READ,          // read / write signal of data0
                `READ,          // read / write signal of data1
                8'b0001_0000,   // address of L1_cache
                128'bx,         // data_wd
                128'bx,         // data_rd choosing from data_rd1~data_rd3
                `DISABLE,         // icache request
                9'b110_0001_00,
                32'b1110_0001_0000_0000,
                1'b0,                    // dirty_wd
                `READ,                    // dirty0_rw
                `READ                    // dirty1_rw
                );
            $finish;
        end
    end
    /********** output wave **********/
    initial begin
        $dumpfile("dcache_mem_test.vcd");
        $dumpvars(0,mem_stage,ram,dtag_ram,ddata_ram,l2_tag_ram,l2_data_ram,l2_cache_ctrl);
    end
endmodule 