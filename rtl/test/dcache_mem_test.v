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
    wire             block0_we;     // write signal of block0
    wire             block1_we;     // write signal of block1
    wire             block0_re;     // read signal of block0
    wire             block1_re;     // read signal of block1
    wire     [20:0]  tag_wd;        // write data of L1_tag
    wire     [7:0]   index;         // address of L1_cache
    wire     [1:0]   offset;
    /* l2_cache part */
    wire             irq;           // icache request
    wire             drq;
    wire             ic_rw_en;      // write enable signal
    wire             dc_rw_en;
    wire     [27:0]  l2_addr_ic; 
    wire     [27:0]  l2_addr_dc;   
    wire             l2_cache_rw_ic;
    wire             l2_cache_rw_dc;
    wire     [8:0]   l2_index;
    wire     [1:0]   l2_offset;
    /*cache part*/
    wire             dc_en;         // busy mark of L2C
    wire     [127:0] rd_to_l2;
    wire             l2_block0_we;  // write signal of block0
    wire             l2_block1_we;  // write signal of block1
    wire             l2_block2_we;  // write signal of block2
    wire             l2_block3_we;  // write signal of block3
    wire             l2_block0_re;  // read signal of block0
    wire             l2_block1_re;  // read signal of block1
    wire             l2_block2_re;  // read signal of block2
    wire             l2_block3_re;  // read signal of block3
    wire     [17:0]  l2_tag_wd;     // write data of tag
    wire             l2_rdy;        // ready mark of L2C
    wire             mem_wr_dc_en;
    wire             mem_wr_ic_en;
    /*memory part*/
    wire     [25:0]  mem_addr;      // address of memory
    wire             mem_re;        // read / write signal of memory
    wire             mem_we;        // read / write signal of memory
    wire     [511:0] mem_wd;
    reg      [511:0] mem_rd;
    wire             mem_complete_w;
    wire             mem_complete_r;
    // tag_ram part
    wire     [20:0]  tag0_rd;       // read data of tag0
    wire     [20:0]  tag1_rd;       // read data of tag1
    wire             lru;           // read data of tag
    wire             w_complete_ic;   // complete write from L2 to L1
    wire             w_complete_dc; // complete write to L1
    wire             r_complete_dc; // complete read from L1
    // data_ram part 
    wire     [31:0]  dc_wd;
    wire     [127:0] data0_rd;      // read data of cache_data0
    wire     [127:0] data1_rd;      // read data of cache_data1
    wire     [127:0] data_wd_l2;
    wire             data_wd_dc_en;
    wire             data_wd_l2_en;
    // l2_tag_ram part
    wire     [17:0]  l2_tag0_rd;    // read data of tag0
    wire     [17:0]  l2_tag1_rd;    // read data of tag1
    wire     [17:0]  l2_tag2_rd;    // read data of tag2
    wire     [17:0]  l2_tag3_rd;    // read data of tag3
    wire     [2:0]   plru;          // read data of tag
    wire             l2_complete_w; // complete write to L2
    wire             l2_complete_r; // complete read from L2
    // l2_data_ram
    wire             wd_from_mem_en;
    wire             wd_from_l1_en;
    wire     [511:0] l2_data_wd;     // write data of l2_cache
    wire     [511:0] l2_data0_rd;    // read data of cache_data0
    wire     [511:0] l2_data1_rd;    // read data of cache_data1
    wire     [511:0] l2_data2_rd;    // read data of cache_data2
    wire     [511:0] l2_data3_rd;    // read data of cache_data3 
    // l2_dirty
    wire             l2_dirty_wd;
    wire             l2_dirty0;
    wire             l2_dirty1;
    wire             l2_dirty2;
    wire             l2_dirty3;
    wire             hitway;
    /********* pipeline control signals ********/
    //  State of Pipeline
    wire                  br_taken;     // branch hazard mark
    reg                   if_busy;
    /********** Data Forward **********/
    wire     [1:0]        src_reg_used;
    // LOAD Hazard
    wire                  id_en;        // Pipeline Register enable
    wire [`REG_ADDR_BUS]  id_dst_addr;  // GPR write address
    wire                  id_gpr_we_;   // GPR write enable
    wire [`INS_OP_BUS]    op; 
    wire [`REG_ADDR_BUS]  ra_addr;
    wire [`REG_ADDR_BUS]  rb_addr;
    // LOAD STORE Forward
    wire [`REG_ADDR_BUS]  id_ra_addr;
    wire [`REG_ADDR_BUS]  id_rb_addr;
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
        .rst            (rst),           // reset
        //  State of Pipeline
        .if_busy        (if_busy),        // IF busy mark // miss stall of if_stage
        .br_taken       (br_taken),       // branch hazard mark
        .mem_busy       (miss_stall),     // MEM busy mark // miss stall of mem_stage

        /********** Data Forward **********/
        .src_reg_used   (src_reg_used),
        // LOAD Hazard
        .id_en          (id_en),          // Pipeline Register enable
        .id_dst_addr    (id_dst_addr),    // GPR write address
        .id_gpr_we_     (id_gpr_we_),     // GPR write enable
        .id_mem_op      (id_mem_op),      // Mem operation
        .op             (op), 
        .ra_addr        (ra_addr),
        .rb_addr        (rb_addr),
         // LOAD STORE Forward
        .id_ra_addr     (id_ra_addr),
        .id_rb_addr     (id_rb_addr),

        .ex_en          (ex_en),          // Pipeline Register enable
        .ex_dst_addr    (ex_dst_addr),    // GPR write address
        .ex_gpr_we_     (ex_gpr_we_),     // GPR write enable
        .ex_mem_op      (ex_mem_op),      // Mem operation

        // Stall Signal
        .if_stall       (if_stall),     // IF stage stall
        .id_stall       (id_stall),     // ID stage stall
        .ex_stall       (ex_stall),     // EX stage stall
        .mem_stall      (mem_stall),    // MEM stage stall
        // Flush Signal
        .if_flush       (if_flush),     // IF stage flush
        .id_flush       (id_flush),     // ID stage flush
        .ex_flush       (ex_flush),     // EX stage flush
        .mem_flush      (mem_flush),    // MEM stage flush
        .new_pc         (new_pc),        // New program counter

        // Forward from EX stage

        /********** Forward Output **********/
        .ra_fwd_ctrl    (ra_fwd_ctrl),
        .rb_fwd_ctrl    (rb_fwd_ctrl),
        .ex_ra_fwd_en   (ex_ra_fwd_en),
        .ex_rb_fwd_en   (ex_rb_fwd_en)
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
        .dirty0         (dirty0),            
        .dirty1         (dirty1),             
        .dirty_wd       (dirty_wd),            
        .tagcomp_hit    (tagcomp_hit),      
        .offset         (offset), 
        .rd_to_l2       (rd_to_l2), 
        .block0_we      (block0_we),     // write signal of block0
        .block1_we      (block1_we),     // write signal of block1
        .block0_re      (block0_re),     // read signal of block0
        .block1_re      (block1_re),     // read signal of block1
        .tag_wd         (tag_wd),        // write data of L1_tag
        .data_wd_dc_en  (data_wd_dc_en),
        .mem_wr_dc_en   (mem_wr_dc_en), 
        .index          (index),         // address of L1_cache
        .dc_wd          (dc_wd),
        /* l2_cache part */
        .dc_en          (dc_en),         // busy signal of l2_cache
        .l2_rdy         (l2_rdy),        // ready signal of l2_cache
        .w_complete_dc  (w_complete_dc), // complete write to L1
        .r_complete_dc  (r_complete_dc), // complete write from L1
        .l2_complete_w  (l2_complete_w),
        .data_wd_l2     (data_wd_l2),
        .drq            (drq),  
        .dc_rw_en       (dc_rw_en),    
        .l2_addr        (l2_addr_dc),     
        .l2_cache_rw    (l2_cache_rw_dc),        
        /********** EX/MEM Pipeline Register **********/
        .ex_en          (ex_en),          // busy signal of l2_cache
        .ex_mem_op      (ex_mem_op),      // ready signal of l2_cache
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
        .clk            (clk),           // clock of L2C
        .rst            (rst),           // reset
        /* CPU part */
        .l2_addr_ic     (l2_addr_ic),    // address of fetching instruction
        .l2_cache_rw_ic (l2_cache_rw_ic),// read / write signal of CPU
        .l2_addr_dc     (l2_addr_dc),    // address of fetching instruction
        .l2_cache_rw_dc (l2_cache_rw_dc),// read / write signal of CPU
        .l2_index       (l2_index),
        .offset         (l2_offset), 
        .tagcomp_hit    (l2_tagcomp_hit),      
        /*cache part*/
        .irq            (irq),           // icache request
        .drq            (drq),
        .ic_rw_en       (ic_rw_en),      // write enable signal of icache
        .dc_rw_en       (dc_rw_en),
        .w_complete_ic  (w_complete_ic), // complete write to L1P
        .w_complete_dc  (w_complete_dc), // complete write to L1D       
        .data_wd_l2     (data_wd_l2),    // write data to L1C       
        .data_wd_l2_en  (data_wd_l2_en), 
        .wd_from_mem_en (wd_from_mem_en),
        .wd_from_l1_en  (wd_from_l1_en),
        .mem_wr_dc_en   (mem_wr_dc_en), 
        .mem_wr_ic_en   (mem_wr_ic_en),
        /*l2_cache part*/
        .l2_complete_w  (l2_complete_w), // complete write from MEM to L2
        .l2_complete_r  (l2_complete_r), // complete mark of reading from l2_cache
        .l2_rdy         (l2_rdy),
        .ic_en          (ic_en),
        .dc_en          (dc_en),
        // l2_tag part
        .plru           (plru),          // replace mark
        .l2_tag0_rd     (l2_tag0_rd),    // read data of tag0
        .l2_tag1_rd     (l2_tag1_rd),    // read data of tag1
        .l2_tag2_rd     (l2_tag2_rd),    // read data of tag2
        .l2_tag3_rd     (l2_tag3_rd),    // read data of tag3
        .l2_block0_we   (l2_block0_we),  // write signal of block0
        .l2_block1_we   (l2_block1_we),  // write signal of block1
        .l2_block2_we   (l2_block2_we),  // write signal of block2
        .l2_block3_we   (l2_block3_we),  // write signal of block3
        .l2_block0_re   (l2_block0_re),  // read signal of block0
        .l2_block1_re   (l2_block1_re),  // read signal of block1
        .l2_block2_re   (l2_block2_re),  // read signal of block2
        .l2_block3_re   (l2_block3_re),  // read signal of block3
        .l2_tag_wd      (l2_tag_wd),     // write data of tag0                
        // l2_data part
        .l2_data0_rd    (l2_data0_rd),   // read data of cache_data0
        .l2_data1_rd    (l2_data1_rd),   // read data of cache_data1
        .l2_data2_rd    (l2_data2_rd),   // read data of cache_data2
        .l2_data3_rd    (l2_data3_rd),   // read data of cache_data3
        // l2_dirty part
        .l2_dirty_wd    (l2_dirty_wd),
        .l2_dirty0      (l2_dirty0),
        .l2_dirty1      (l2_dirty1),
        .l2_dirty2      (l2_dirty2), 
        .l2_dirty3      (l2_dirty3),         
        /*memory part*/
        .mem_complete_w (mem_complete_w),
        .mem_complete_r (mem_complete_r),
        .mem_rd         (mem_rd),
        .mem_wd         (mem_wd), 
        .mem_addr       (mem_addr),     // address of memory
        .mem_we         (mem_we),       // mark of writing to memory
        .mem_re         (mem_re)        // mark of reading from memory
    );
    mem mem(
        .clk            (clk),           // clock
        .rst            (rst),           // reset active  
        .re             (mem_re),
        .we             (mem_we),
        .complete_w     (mem_complete_w),
        .complete_r     (mem_complete_r)
        );
    dtag_ram dtag_ram(
        .clk            (clk),           // clock
        .block0_we      (block0_we),     // write signal of block0
        .block1_we      (block1_we),     // write signal of block1
        .block0_re      (block0_re),     // read signal of block0
        .block1_re      (block1_re),     // read signal of block1
        .index          (index),         // address of cache
        .dirty_wd       (dirty_wd),   
        .tag_wd         (tag_wd),        // write data of tag
        .tag0_rd        (tag0_rd),       // read data of tag0
        .tag1_rd        (tag1_rd),       // read data of tag1
        .dirty0         (dirty0),
        .dirty1         (dirty1),
        .lru            (lru),           // read data of tag
        .w_complete     (w_complete_dc), // complete write to L1
        .r_complete     (r_complete_dc)  // complete write from L1
        );
    data_ram ddata_ram(
        .clk            (clk),           // clock
        .index          (index),         // address of cache
        .tagcomp_hit    (tagcomp_hit),   // +++++++++
        .block0_we      (block0_we),     // write signal of block0
        .block1_we      (block1_we),     // write signal of block1
        .block0_re      (block0_re),     // read signal of block0
        .block1_re      (block1_re),     // read signal of block1
        .data_wd_l2     (data_wd_l2),    // write data of l2_cache
        // .data_wd_dc     (data_wd_dc),    // write data of l2_cache
        .data_wd_l2_en  (data_wd_l2_en), // write data of l2_cache
        .data_wd_dc_en  (data_wd_dc_en), // write data of l2_cache
        .dc_wd          (dc_wd),
        .offset         (offset), 
        .data0_rd       (data0_rd),      // read data of cache_data0
        .data1_rd       (data1_rd)       // read data of cache_data1
    );
    l2_data_ram l2_data_ram(
        .clk            (clk),           // clock of L2C
        .l2_index       (l2_index),
        .mem_rd         (mem_rd),
        .offset         (l2_offset),
        .rd_to_l2       (rd_to_l2),
        .wd_from_mem_en (wd_from_mem_en),
        .wd_from_l1_en  (wd_from_l1_en),
        .tagcomp_hit    (l2_tagcomp_hit), 
        .l2_block0_we   (l2_block0_we),  // write signal of block0
        .l2_block1_we   (l2_block1_we),  // write signal of block1
        .l2_block2_we   (l2_block2_we),  // write signal of block2
        .l2_block3_we   (l2_block3_we),  // write signal of block3
        .l2_block0_re   (l2_block0_re),  // read signal of block0
        .l2_block1_re   (l2_block1_re),  // read signal of block1
        .l2_block2_re   (l2_block2_re),  // read signal of block2
        .l2_block3_re   (l2_block3_re),  // read signal of block3
        .l2_data0_rd    (l2_data0_rd),   // read data of cache_data0
        .l2_data1_rd    (l2_data1_rd),   // read data of cache_data1
        .l2_data2_rd    (l2_data2_rd),   // read data of cache_data2
        .l2_data3_rd    (l2_data3_rd)    // read data of cache_data3
    );
    l2_tag_ram l2_tag_ram(    
        .clk            (clk),           // clock of L2C
        .rst            (rst),
        .l2_index       (l2_index),
        .l2_block0_we   (l2_block0_we),  // write signal of block0
        .l2_block1_we   (l2_block1_we),  // write signal of block1
        .l2_block2_we   (l2_block2_we),  // write signal of block2
        .l2_block3_we   (l2_block3_we),  // write signal of block3
        .l2_block0_re   (l2_block0_re),  // read signal of block0
        .l2_block1_re   (l2_block1_re),  // read signal of block1
        .l2_block2_re   (l2_block2_re),  // read signal of block2
        .l2_block3_re   (l2_block3_re),  // read signal of block3
        .l2_tag_wd      (l2_tag_wd),     // write data of tag
        .l2_dirty_wd    (l2_dirty_wd),
        .l2_tag0_rd     (l2_tag0_rd),    // read data of tag0
        .l2_tag1_rd     (l2_tag1_rd),    // read data of tag1
        .l2_tag2_rd     (l2_tag2_rd),    // read data of tag2
        .l2_tag3_rd     (l2_tag3_rd),    // read data of tag3
        .plru           (plru),          // read data of plru_field
        .l2_complete_w  (l2_complete_w), // complete write to L2
        .l2_complete_r  (l2_complete_r), // complete read from L2
        .l2_dirty0      (l2_dirty0),
        .l2_dirty1      (l2_dirty1),
        .l2_dirty2      (l2_dirty2),
        .l2_dirty3      (l2_dirty3)
    );
    task ctrl_tb;
        input          _if_stall;        // read data of CPU
        input          _id_stall;        // the signal of stall caused by cache miss     
        /* L1_cache part */
        input          _ex_stall;        // read / write signal of L1_tag0
        input          _mem_stall;       // read / write signal of L1_tag1
        input          _if_flush;        // write data of L1_tag
        input          _id_flush;        // read / write signal of data0
        input          _ex_flush;        // read / write signal of data1
        input          _mem_flush;       // address of L1_cache

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
            if (if_stall   !== _if_stall) begin
                $display("if_stall:%b(excepted %b)",if_stall,_if_stall); 
            end
            if (id_stall   !== _id_stall) begin
                $display("id_stall:%b(excepted %b)",id_stall,_id_stall); 
            end
            if (ex_stall   !== _ex_stall) begin
                $display("ex_stall:%b(excepted %b)",ex_stall,_ex_stall); 
            end
            if (mem_stall   !== _mem_stall) begin
                $display("mem_stall:%b(excepted %b)",mem_stall,_mem_stall); 
            end
            if (if_flush   !== _if_flush) begin
                $display("if_flush:%b(excepted %b)",if_flush,_if_flush); 
            end
            if (id_flush !== _id_flush) begin
                $display("id_flush:%b(excepted %b)",id_flush,_id_flush); 
            end
            if (ex_flush    !== _ex_flush) begin
                $display("ex_flush:%b(excepted %b)",ex_flush,_ex_flush); 
            end
            if (mem_flush    !== _mem_flush) begin
                $display("mem_flush:%b(excepted %b)",mem_flush,_mem_flush); 
            end
        end
    endtask 
    task mem_stage_tb;
        input  [31:0]  _mem_out;        // read data of CPU
        input          _miss_stall;      // the signal of stall caused by cache miss   
        /* L1_cache part */
        input  [20:0]  _tag_wd;          // write data of L1_tag
        input  [7:0]   _index;           // address of L1_cache
        input  [127:0] _rd_to_l2;        
        /* l2_cache part */
        input          _drq;             // icache request
        input  [27:0]  _l2_addr_dc;
        // dirty
        input          _dirty_wd;
        input          _block0_we;
        input          _block1_we;
        input          _mem_en;

        begin 
            if( (mem_out     === _mem_out)           && 
                (miss_stall  === _miss_stall)        && 
                (tag_wd      === _tag_wd)            && 
                (index       === _index)             && 
                (drq         === _drq)               &&  
                (_l2_addr_dc === _l2_addr_dc)        && 
                (block0_we   === _block0_we)         && 
                (block1_we   === _block1_we)         && 
                (rd_to_l2    === _rd_to_l2)          && 
                (dirty_wd    === _dirty_wd)          && 
                (mem_en      === _mem_en)
               ) begin 
                 $display("mem_stage Test Succeeded !"); 
            end else begin 
                 $display("mem_stage Test Failed !"); 
            end 
            if (mem_en     !== _mem_en) begin
                $display("mem_en:%b(excepted %b)",mem_en,_mem_en); 
            end
            if (rd_to_l2   !== _rd_to_l2) begin
                $display("rd_to_l2:%b(excepted %b)",rd_to_l2,_rd_to_l2); 
            end
            if (block0_we   !== _block0_we) begin
                $display("block0_we:%b(excepted %b)",block0_we,_block0_we); 
            end
            if (block1_we   !== _block1_we) begin
                $display("block1_we:%b(excepted %b)",block1_we,_block1_we); 
            end
            if (mem_out   !== _mem_out) begin
                $display("mem_out:%b(excepted %b)",mem_out,_mem_out); 
            end
            if (miss_stall !== _miss_stall) begin
                $display("miss_stall:%b(excepted %b)",miss_stall,_miss_stall); 
            end
            if (tag_wd     !== _tag_wd) begin
                $display("tag_wd:%b(excepted %b)",tag_wd,_tag_wd); 
            end
            if (index      !== _index) begin
                $display("index:%b(excepted %b)",index,_index); 
            end
            if (drq        !== _drq) begin
                $display("drq:%b(excepted %b)",drq,_drq); 
            end
            if (l2_addr_dc !== _l2_addr_dc) begin
                $display("l2_addr_dc:%b(excepted %b)",l2_addr_dc,_l2_addr_dc); 
            end
        end
    endtask 
    task l2_cache_ctrl_tb;
        input           _dc_en;              // L2C busy mark
        input   [127:0] _data_wd_l2;         // write data to L1_IC
        input   [17:0]  _l2_tag_wd;          // write data of tag0
        input           _l2_rdy;             // ready signal of l2_cache
        // l2_dirty part
        input           _l2_dirty_wd;
        input           _l2_block0_we;
        input           _l2_block1_we;
        input           _l2_block2_we;
        input           _l2_block3_we;
        input   [25:0]  _mem_addr;           // address of memory
        input           _mem_rw;             // read / write signal of memory
        begin 
            if( (dc_en       === _dc_en)            && 
                (data_wd_l2    === _data_wd_l2)     && 
                (l2_tag_wd     === _l2_tag_wd)      && 
                (l2_rdy        === _l2_rdy)         && 
                (l2_dirty_wd  === _l2_dirty_wd)     &&
                (l2_block0_we  === _l2_block0_we)   &&
                (l2_block1_we  === _l2_block1_we)   &&
                (l2_block2_we  === _l2_block2_we)   &&
                (l2_block3_we  === _l2_block3_we)   &&
                (mem_addr      === _mem_addr)       && 
                (mem_we        === _mem_rw)  
               ) begin 
                 $display("l2_dcache Test Succeeded !"); 
            end else begin 
                 $display("l2_dcache Test Failed !"); 
            end 
            
            // check
            if(dc_en       !== _dc_en)     begin
                $display("dc_en Test Failed !"); 
            end
            if(data_wd_l2    !== _data_wd_l2)     begin
                $display("data_wd_l2:%b(excepted %b)",data_wd_l2,_data_wd_l2); 
            end
            if(l2_tag_wd     !== _l2_tag_wd)   begin
                $display("l2_tag_wd Test Failed !"); 
            end
            if(l2_rdy        !== _l2_rdy)      begin
                $display("l2_rdy Test Failed !"); 
            end
            if (l2_block0_we !== _l2_block0_we) begin
                $display("l2_block0_we Test Failed !"); 
            end
            if (l2_block1_we !== _l2_block1_we) begin
                $display("l2_block1_we Test Failed !"); 
            end
            if (l2_block2_we !== _l2_block2_we) begin
                $display("l2_block2_we Test Failed !"); 
            end
            if (l2_block3_we !== _l2_block3_we) begin
                $display("l2_block3_we Test Failed !"); 
            end
            if(mem_addr      !== _mem_addr)    begin
                $display("mem_addr Test Failed !"); 
            end
            if(mem_we        !== _mem_rw) begin
                $display("mem_we Test Failed !"); 
            end 
        end
    endtask
    task tag_ram_tb;
        input      [20:0]  _tag0_rd;        // read data of tag0
        input      [20:0]  _tag1_rd;        // read data of tag1
        input              _lru;            // read block of tag
        input              _complete_dc;       // complete_dc write from L2 to L1
        begin 
            if( (tag0_rd     === _tag0_rd)     && 
                (tag1_rd     === _tag1_rd)     && 
                (lru         === _lru)         && 
                (w_complete_dc === _complete_dc)              
               ) begin 
                 $display("Tag_ram Test Succeeded !"); 
            end else begin 
                 $display("Tag_ram Test Failed !"); 
            end             
            if (tag0_rd  !== _tag0_rd) begin
                $display("tag0_rd:%b(excepted %b)",tag0_rd,_tag0_rd); 
            end
            if (tag1_rd  !== _tag1_rd) begin
                $display("tag1_rd:%b(excepted %b)",tag1_rd,_tag1_rd); 
            end
            if (lru      !== _lru) begin
                $display("lru:%b(excepted %b)",lru,_lru); 
            end
            if (w_complete_dc !== _complete_dc) begin
                $display("complete_dc:%b(excepted %b)",w_complete_dc,_complete_dc); 
            end
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
                (l2_complete_w === _l2_complete)
               ) begin 
                 $display("l2_tag_ram Test Succeeded !"); 
            end else begin 
                 $display("l2_tag_ram Test Failed !"); 
            end 
            if (l2_tag0_rd  !== _l2_tag0_rd) begin
                $display("l2_tag0_rd:%b(excepted %b)",l2_tag0_rd,_l2_tag0_rd); 
            end
            if (l2_tag1_rd  !== _l2_tag1_rd) begin
                $display("l2_tag1_rd:%b(excepted %b)",l2_tag1_rd,_l2_tag1_rd); 
            end
            if (l2_tag2_rd  !== _l2_tag2_rd) begin
                $display("l2_tag2_rd:%b(excepted %b)",l2_tag2_rd,_l2_tag2_rd); 
            end
            if (l2_tag3_rd  !== _l2_tag3_rd) begin
                $display("l2_tag3_rd:%b(excepted %b)",l2_tag3_rd,_l2_tag3_rd); 
            end
            if (plru        !== _plru) begin
                $display("plru:%b(excepted %b)",plru,_plru); 
            end
            if (l2_complete_w !== _l2_complete) begin
                $display("l2_complete:%b(excepted %b)",l2_complete_w,_l2_complete); 
            end
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
            if (l2_data0_rd  !== _l2_data0_rd) begin
                $display("l2_data0_rd:%b(excepted %b)",l2_data0_rd,_l2_data0_rd); 
            end
            if (l2_data1_rd  !== _l2_data1_rd) begin
                $display("l2_data1_rd:%b(excepted %b)",l2_data1_rd,_l2_data1_rd); 
            end
            if (l2_data2_rd  !== _l2_data2_rd) begin
                $display("l2_data2_rd:%b(excepted %b)",l2_data2_rd,_l2_data2_rd); 
            end
            if (l2_data3_rd  !== _l2_data3_rd) begin
                $display("l2_data3_rd:%b(excepted %b)",l2_data3_rd,_l2_data3_rd); 
            end
        end       
    endtask

    /******** Define Simulation Loop********/ 
    parameter  STEP = 10; 

    /******* Generated Clocks *******/
    always #(STEP / 2)
        begin
            clk <= ~clk;  
        end      
    /********** Testbench **********/
    initial begin
        #0 begin
            clk     <= `ENABLE;
            rst     <= `ENABLE;
        end
        #(STEP * 3/4)
        #STEP begin 
            /******** Initialize Test Output ********/
            rst       <= `DISABLE;      
            if_busy   <= `DISABLE;
            ex_en     <= `ENABLE;
            ex_mem_op <= `MEM_OP_LW;
            ex_out    <= 32'b1110_0001_0000_0000;
            mem_rd    <= 512'h123BC000_0876547A_00000000_ABF00000_123BC000_00000000_0876547A_00000000_ABF00000_123BC000;      // write data of l2_cache
        end
        #STEP begin // DC_ACCESS & L2_IDLE 
            $display("\n========= Clock 1 ========");
            l2_cache_ctrl_tb(            
                `ENABLE,                                  // L2C busy mark
                128'bx,                                   // write data to L1_IC
                18'b1_0000_0000_0000_0000_1,              // write data of tag
                1'bx,                                     // l2_rdy
                1'bx,                                     // l2_dirty_wd
                1'bx,                                     // l2_block0_we
                1'bx,                                     // l2_block1_we
                1'bx,                                     // l2_block2_we
                1'bx,                                     // l2_block3_we
                26'bx,                                    // address of memory
                1'bx                                      // read / write signal of memory                
                ); 
        end
        #(STEP*4) begin // DC_ACCESS_L2 & ACCESS_L2 
            $display("\n========= Clock 5 ========");
            mem_stage_tb(
                32'bx,                                    // read data of CPU
                `ENABLE,                                  // the signal of stall caused by cache miss
                21'b1_0000_0000_0000_0000_1110,           // write data of L1_tag
                8'b0001_0000,                             // address of L1_cache
                128'hx,                                   // data_rd choosing from data_rd1~data_rd3
                `ENABLE,                                  // drq
                28'b1110_0001_0000,                       // l2_addr
                1'b0,                                     // dirty_wd
                `WRITE,                                   // dirty0_rw
                1'bx,                                     // dirty1_rw
                `ENABLE 
                );
            tag_ram_tb(
                21'bx,                                    // read data of tag0
                21'bx,                                    // read data of tag1
                1'bx,                                     // number of replacing block of tag next time
                1'b0                                      // complete write from L2 to L1
                );
            data_ram_tb(
                128'hx,                                   // read data of cache_data0
                128'hx                                    // read data of cache_data1
                );  
            l2_cache_ctrl_tb(
                `ENABLE,                                  // L2C busy mark
                128'h0876547A_00000000_ABF00000_123BC000, // write data to L1_IC
                18'b1_0000_0000_0000_0000_1,              // write data of tag
                1'bx,                                     // ready signal of l2_cache
                1'b0,
                `ENABLE,                                  // l2_block0_we
                `DISABLE,                                 // l2_block1_we 
                `DISABLE,                                 // l2_block2_we 
                `DISABLE,                                 // l2_block3_we
                26'b1110_0001_00,                         // address of memory
                1'bx                                      // read / write signal of memory                
                ); 
            l2_tag_ram_tb(   
                18'bx,                                    // read data of tag0
                18'bx,                                    // read data of tag1
                18'bx,                                    // read data of tag2
                18'bx,                                    // read data of tag3
                3'bxxx,                                   // read data of tag
                `DISABLE                                  // complete write from L2 to L1
                );
            l2_data_ram_tb(
                512'bx,                                   // read data of cache_data0
                512'bx,                                   // read data of cache_data1
                512'bx,                                   // read data of cache_data2
                512'bx                                    // read data of cache_data3
                );     
        end
        #STEP begin // WRITE_DC_R & WRITE_TO_L2_CLEAN 
            $display("\n========= Clock 6 ========");
            mem_stage_tb(
                32'hx,                                     // read data of CPU
                `DISABLE,                                  // the signal of stall caused by cache miss
                21'b1_0000_0000_0000_0000_1110,            // write data of L1_tag
                8'b0001_0000,                              // address of L1_cache
                128'hx,                                    // data_rd choosing from data_rd1~data_rd3
                `DISABLE,                                  // drq
                28'b1110_0001_0000,                        // l2_addr
                1'b0,                                      // dirty_wd
                `DISABLE,                                  // dirty0_rw
                `DISABLE,                                  // dirty1_rw
                `ENABLE
                );
            tag_ram_tb(
                21'bx,                                      // read data of tag0
                21'bx,                                      // read data of tag1
                1'bx,                                       // number of replacing block of tag next time
                1'b1                                        // complete write from L2 to L1
                );
            data_ram_tb(
                128'hx,                                     // read data of cache_data0
                128'hx                                      // read data of cache_data1
                );
            // tag_ram_tb(
            //     21'b1_0000_0000_0000_0000_1110,             // read data of tag0
            //     21'bx,                                      // read data of tag1
            //     1'b1,                                       // number of replacing block of tag next time
            //     1'b1                                        // complete write from L2 to L1
            //     );
            // data_ram_tb(
            //     128'h0876547A_00000000_ABF00000_123BC000,   // read data of cache_data0
            //     128'hx                                      // read data of cache_data1
            //     );             
        end   
        #STEP begin // MEM stage // DC_ACCESS(read hit)  & COMPLETE_WRITE_CLEAN    
            $display("\n========= Clock 7 ========");
            mem_stage_tb(
                32'h123BC000,                               // read data of CPU
                `DISABLE,                                   // the signal of stall caused by cache miss
                21'b1_0000_0000_0000_0000_1110,             // write data of L1_tag
                8'b0001_0000,                               // address of L1_cache
                128'bx,                                     // data_rd choosing from data_rd1~data_rd3
                `DISABLE,                                   // icache request
                28'b1110_0001_0000,                         // l2_adddr
                1'b0,                                       // dirty_wd
                `DISABLE,                                   // dirty0_rw
                `DISABLE,                                   // dirty1_rw
                `ENABLE
                );
            l2_cache_ctrl_tb(            
                `DISABLE,                                   // L2C busy mark
                128'h0876547A_00000000_ABF00000_123BC000,   // write data to L1_IC
                18'b1_0000_0000_0000_0000_1,                // write data of tag
                1'bx,                                       // ready signal of l2_cache
                1'b0,
                `DISABLE,
                `DISABLE,
                `DISABLE,
                `DISABLE,
                26'b1110_0001_00,                           // address of memory
                1'bx                                        // read / write signal of memory                
                ); 
            l2_tag_ram_tb(   
                18'bx,                                      // read data of tag0
                18'bx,                                      // read data of tag1
                18'bx,                                      // read data of tag2
                18'bx,                                      // read data of tag3
                3'bxxx,                                     // read data of tag
                `ENABLE                                     // complete write to L2
                );
            l2_data_ram_tb(
                512'hx,                                     // read data of cache_data0
                512'bx,                                     // read data of cache_data1
                512'bx,                                     // read data of cache_data2
                512'bx                                      // read data of cache_data3
                );
            $finish;     // iverilog
        end
    end
    /********** output wave **********/
    initial begin
        $dumpfile("dcache_mem_test.vcd");
        $dumpvars(0,mem_stage,ctrl,mem,dtag_ram,ddata_ram,l2_tag_ram,l2_data_ram,l2_cache_ctrl);
    end
endmodule 