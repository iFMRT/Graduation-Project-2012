/******** Time scale ********/
`timescale 1ns/1ps

`include "stddef.h"
`include "cpu.h"
`include "mem.h"
`include "spm.h"
`include "alu.h"
`include "cmp.h"
`include "isa.h"
`include "ctrl.h"
`include "ex_stage.h"
`include "icache.h"
`include "l2_cache.h"
`include "dcache.h"

module cpu_top_test;
    reg                    clk;           // Clock
    reg                    rst;           // Asynchronous Reset
    /*memory part*/
    wire     [25:0]        mem_addr;      // address of memory
    wire                   mem_re;        // read / write signal of memory
    wire                   mem_we;        // read / write signal of memory
    wire     [511:0]       mem_wd;
    reg      [511:0]       mem_rd;
    
    wire     [1:0]         l2_thread_wd;
    wire     [511:0]       l2_data_wd_mem;
    wire                   mem_wr_l2_en;
    wire                   mem_complete_w;
    wire                   mem_complete_r;
    wire                   memory_busy;
    wire                   memory_en;
    wire                   ic_en_mem,dc_en_mem,wd_from_l1_en_mem;
    wire                   thread_rdy_mem;
    /**********  Pipeline  Register **********/
    // IF/ID
    wire [`WORD_DATA_BUS]  if_pc;          // Next Program count
    wire [`WORD_DATA_BUS]  pc;             // Current Program count
    wire [`WORD_DATA_BUS]  if_insn;        // Instruction
    wire                   if_en;          // Pipeline data enable
    // ID/EX Pipeline  Register
    wire [1:0]             src_reg_used;
    wire                   id_en;          //  Pipeline data enable
    wire [`ALU_OP_BUS]     id_alu_op;      // ALU operation
    wire [`WORD_DATA_BUS]  id_alu_in_0;    // ALU input 0
    wire [`WORD_DATA_BUS]  id_alu_in_1;    // ALU input 1
    wire [`CMP_OP_BUS]     id_cmp_op;      // CMP Operation
    wire [`WORD_DATA_BUS]  id_cmp_in_0;    // CMP input 0
    wire [`WORD_DATA_BUS]  id_cmp_in_1;    // CMP input 1
    wire                   id_jump_taken;
    wire [`MEM_OP_BUS]     id_mem_op;      // Memory operation
    wire [`WORD_DATA_BUS]  id_mem_wr_data; // Memory Write data
    wire [`REG_ADDR_BUS]   id_dst_addr;    // GPRWrite  address
    wire                   id_gpr_we_;     // GPRWrite enable
    wire [`EX_OUT_SEL_BUS] id_gpr_mux_ex;
    wire [`WORD_DATA_BUS]  id_gpr_wr_data;

    wire [`INS_OP_BUS]     op;
    wire [`REG_ADDR_BUS]   ra_addr;
    wire [`REG_ADDR_BUS]   rb_addr;
    // LOAD STORE Forward
    wire [`REG_ADDR_BUS]   id_ra_addr;
    wire [`REG_ADDR_BUS]   id_rb_addr;

    // EX/MEM Pipeline  Register
    wire [`MEM_OP_BUS]     ex_mem_op;      // Memory operation
    wire [`WORD_DATA_BUS]  ex_mem_wr_data; // Memory Write data
    wire [`REG_ADDR_BUS]   ex_dst_addr;    // General purpose RegisterWrite  address
    wire                   ex_gpr_we_;     // General purpose RegisterWrite enable
    wire [`WORD_DATA_BUS]  ex_out;         // Operating result
    wire [`WORD_DATA_BUS]  alu_out; 
    // MEM/WB Pipeline  Regr
    wire [`REG_ADDR_BUS]   mem_dst_addr;   // General purpose RegisterWrite  address
    wire                   mem_gpr_we_;    // General purpose RegisterWrite enable
    wire [`WORD_DATA_BUS]  mem_out;        // Operating result
    /**********  Pipeline Control Signal **********/
    // Stall  Signal
    wire                   if_stall;       // IF Stage
    wire                   id_stall;       // ID Stage
    wire                   ex_stall;       // EX Stage
    wire                   mem_stall;      // MEM Stage
    // Flush Signal
    wire                   if_flush;       // IF Stage
    wire                   id_flush;       // ID Stage
    wire                   ex_flush;       // EX Stage
    wire                   mem_flush;      // MEM Stage
    // Control Signal
    wire [`WORD_DATA_BUS]  new_pc;         // New PC
    wire [`WORD_DATA_BUS]  br_addr;        // Branch  address
    wire                   br_taken;       // Branch taken
    wire                   if_busy;
    wire                   mem_busy;
    /********** Forward Control **********/
    wire [`FWD_CTRL_BUS]   ra_fwd_ctrl;
    wire [`FWD_CTRL_BUS]   rb_fwd_ctrl;
    wire                   ex_ra_fwd_en;
    wire                   ex_rb_fwd_en;

    /********** General Purpose Register Signal **********/
    wire [`WORD_DATA_BUS]  gpr_rd_data_0;   // Read data 0
    wire [`WORD_DATA_BUS]  gpr_rd_data_1;   // Read data 1
    wire [`REG_ADDR_BUS]   gpr_rd_addr_0;   // Read  address 0
    wire [`REG_ADDR_BUS]   gpr_rd_addr_1;   // Read  address 1

    wire                   ex_en;           //  Pipeline data enable
    wire                   mem_en;
    /********** Forward  Signal **********/
    wire [`WORD_DATA_BUS]  ex_fwd_data;     // EX Stage
    wire [`WORD_DATA_BUS]  mem_fwd_data;    // MEM Stage
    /* cach part */ 
    wire                   access_mem;
    wire                   access_l2_clean;
    wire                   access_l2_dirty;
    wire                   access_mem_clean;
    wire                   access_mem_dirty;
    wire [27:0]            l2_addr;
    wire [27:0]            ic_addr_l2,ic_addr_mem;  
    wire [27:0]            dc_addr_read,dc_addr_mem,dc_addr,dc_addr_l2;
    wire                   read_l2_en,read_en;
    wire                   irq;
    wire                   drq;
    wire [127:0]           data_wd_l2;           // write data to L1 from L2
    wire                   data_wd_l2_en;        // enable signal of writing data to L1 from L2
    wire [127:0]           data_wd_l2_mem;       // write data to L1 from L2
    wire                   data_wd_l2_en_mem;    // enable signal of writing data to L1 from L2
    wire                   data_wd_dc_en;        // enable signal of writing data to L1 from L2
    wire                   data_wd_dc_en_l2; 
    wire                   data_wd_dc_en_mem;   
    wire [127:0]           rd_to_l2,rd_to_l2_mem;
    wire [17:0]            l2_tag_wd_l2;         // write data of tag
    wire [17:0]            l2_tag_wd_mem;        // write data of tag
    wire                   l2_rdy;               // ready mark of L2C
    wire                   ic_en;            
    wire                   dc_en;            
    wire [8:0]             l2_index_mem;
    wire [8:0]             l2_index_l2;
    wire [1:0]             l2_offset,offset_mem;
    /*icache part*/
    // tag_ram part                  
    wire                   ic_busy,ic_choose_way;
    wire [7:0]             ic_index;         // address of L1_cache
    wire [7:0]             ic_index_l2;      // address of L1_cache
    wire [7:0]             ic_index_mem;     // address of L1_cache
    wire [20:0]            tag0_rd_ic;       // read data of tag0
    wire [20:0]            tag1_rd_ic;       // read data of tag1
    wire [20:0]            ic_tag_wd,tag_wd; 
    wire [20:0]            ic_tag_wd_mem;
    wire                   lru_ic;           // read data of tag
    wire [1:0]             thread_wd_ic;
    // data_ram part
    wire [1:0]             dc_thread_wd;
    wire [127:0]           dc_data_wd;
    wire [127:0]           data0_rd_ic;      // read data of cache_data0
    wire [127:0]           data1_rd_ic;      // read data of cache_data1
    wire [127:0]           data_wd;      // read data of cache_data1
    // write signal of block
    wire                   ic_block0_we_l2;
    wire                   ic_block1_we_l2;
    wire                   ic_block0_we_mem;
    wire                   ic_block1_we_mem;
    // read signal of block
    wire                   block0_re_ic;     
    wire                   block1_re_ic;    
    // dcache
    wire                   dc_busy,dc_choose_way;
    wire                   dc_rw,dc_rw_read,dc_rw_l2;
    wire [7:0]             dc_index;         // address of L1_cache
    wire [7:0]             dc_index_l2;      // address of L1_cache
    wire [7:0]             dc_index_mem;     // address of L1_cache
    wire [1:0]             dc_offset,dc_offset_l2,dc_offset_mem; 
    wire                   tagcomp_hit;
    wire [31:0]            dc_wd;
    wire [31:0]            dc_wd_l2;
    wire [31:0]            dc_wd_read;
    wire [31:0]            dc_wd_mem;
    wire [20:0]            tag0_rd_dc;       // read data of tag0
    wire [20:0]            tag1_rd_dc;       // read data of tag1
    wire [20:0]            dc_tag_wd; 
    wire [20:0]            dc_tag_wd_l2;     // read data of tag0
    wire [20:0]            dc_tag_wd_mem;    // read data of tag1
    wire                   lru_dc;           // read data of tag
    wire                   dirty0;
    wire                   dirty1;
    wire                   w_complete;
    // write signal of block
    wire                   dc_block0_we;
    wire                   dc_block1_we;
    wire                   dc_block0_we_l2;
    wire                   dc_block1_we_l2;
    wire                   dc_block0_we_mem;
    wire                   dc_block1_we_mem;
    // read signal of block
    wire                   block0_re;        
    wire                   block1_re;   
    // data_ram part
    wire [127:0]           data0_rd_dc;      // read data of cache_data0
    wire [127:0]           data1_rd_dc;      // read data of cache_data1
    // l2_cache
    wire                   l2_choose_l1,l2_choose_l1_read;
    wire                   l2_busy,l2_en,l2_cache_rw;
    wire                   thread_rdy_l2;
    wire [1:0]             l2_choose_way;
    wire [8:0]             l2_index;
    wire [17:0]            l2_tag_wd;
    wire [1:0]             offset;
    // l2_tag_ram part
    wire [17:0]            l2_tag0_rd;       // read data of tag0
    wire [17:0]            l2_tag1_rd;       // read data of tag1
    wire [17:0]            l2_tag2_rd;       // read data of tag2
    wire [17:0]            l2_tag3_rd;       // read data of tag3
    wire [2:0]             plru;             // read data of tag
    wire                   l2_complete_w;    // complete write to L2
    wire                   l2_complete_r;    // complete read from L2
    // l2_data_ram
    wire                   wd_from_mem_en;   
    wire [511:0]           l2_data0_rd;       // read data of cache_data0
    wire [511:0]           l2_data1_rd;       // read data of cache_data1
    wire [511:0]           l2_data2_rd;       // read data of cache_data2
    wire [511:0]           l2_data3_rd;       // read data of cache_data3 
    // l2_thread
    wire  [1:0]            l2_thread0;
    wire  [1:0]            l2_thread1;
    wire  [1:0]            l2_thread2;
    wire  [1:0]            l2_thread3;
    wire  [1:0]            dc_thread;
    wire  [1:0]            ic_thread;
    wire  [1:0]            mem_thread;
    wire  [1:0]            l2_thread;
    reg   [1:0]            thread;
    wire  [1:0]            thread0_dc;
    wire  [1:0]            thread1_dc;
    wire  [1:0]            thread0_ic;
    wire  [1:0]            thread1_ic;
    wire  [1:0]            mem_thread_read;
    // l2_dirty
    wire                   l2_block0_we;
    wire                   l2_block1_we;
    wire                   l2_block2_we;
    wire                   l2_block3_we;
    wire                   l2_block0_re;
    wire                   l2_block1_re;
    wire                   l2_block2_re;
    wire                   l2_block3_re;
    wire                   l2_dirty0;
    wire                   l2_dirty1;
    wire                   l2_dirty2;
    wire                   l2_dirty3;
    wire                   mem_wr_dc_en;
    wire                   mem_wr_ic_en;
    
    /********** IF Stage **********/
    if_stage if_stage(
        .clk            (clk),              // clock
        .reset          (rst),              // reset
        /* CPU part */
        .ic_addr_mem    (ic_addr_mem),
        .ic_addr_l2     (ic_addr_l2),
        .memory_en      (memory_en),
        .l2_en          (l2_en),
        .mem_busy       (mem_busy),
        .ic_busy        (ic_busy),
        .miss_stall     (if_busy),          // the signal of stall caused by cache miss
        .ic_choose_way  (ic_choose_way),
        /*thread part*/
        .l2_thread      (l2_thread),
        .mem_thread     (mem_thread),
        .thread         (thread),
        .ic_thread      (ic_thread), 
        /* L1_cache part */
        .lru            (lru_ic),           // mark of replacing
        .thread0        (thread0_ic),
        .thread1        (thread1_ic),
        .tag0_rd        (tag0_rd_ic),       // read data of tag0
        .tag1_rd        (tag1_rd_ic),       // read data of tag1
        .data0_rd       (data0_rd_ic),      // read data of data0
        .data1_rd       (data1_rd_ic),      // read data of data1
        .data_wd_l2     (data_wd_l2),
        .data_wd_l2_mem (data_wd_l2_mem), 
        .block0_re      (block0_re_ic),     // read signal of block0
        .block1_re      (block1_re_ic),     // read signal of block1
        .index          (ic_index),         // address of L1_cache
        .data_wd        (data_wd),
        .ic_thread_wd   (thread_wd_ic),
        .block0_we      (block0_we_ic),
        .block1_we      (block1_we_ic),
        .tag_wd         (tag_wd),
        .ic_index_l2        (ic_index_l2),
        .ic_tag_wd          (ic_tag_wd),
        .ic_block0_we_l2    (ic_block0_we_l2),
        .ic_block1_we_l2    (ic_block1_we_l2),
        .ic_index_mem       (ic_index_mem),
        .ic_tag_wd_mem      (ic_tag_wd_mem), 
        .ic_block0_we_mem   (ic_block0_we_mem),
        .ic_block1_we_mem   (ic_block1_we_mem),
        /* l2_cache part */
        .ic_en          (ic_en),            // busy signal of l2_cache
        .l2_rdy         (l2_rdy),           // ready signal of l2_cache
        .mem_wr_ic_en   (mem_wr_ic_en),
        .irq            (irq),
        /* Pipeline control */
        .stall          (if_stall),         
        .flush          (if_flush),        
        .new_pc         (new_pc),           
        .br_taken       (br_taken),
        .br_addr        (br_addr),        
        /* IF/ID Pipeline Register */
        .pc             (pc), 
        .if_pc          (if_pc),       
        .if_insn        (if_insn),        
        .if_en          (if_en)
        );

    /********** ID Stage **********/
    id_stage id_stage (
        /********** Clock & Reset **********/
        .clk            (clk),              // Clock
        .reset          (rst),              // Asynchronous Reset
        /********** GPR Interface **********/
        .gpr_rd_data_0  (gpr_rd_data_0),    // Read data 0
        .gpr_rd_data_1  (gpr_rd_data_1),    // Read data 1
        .gpr_rd_addr_0  (gpr_rd_addr_0),    // Read  address 0
        .gpr_rd_addr_1  (gpr_rd_addr_1),    // Read  address 1

        .ex_en          (ex_en),
        /********** Forward  **********/
        // EX Stage Forward
        .ex_fwd_data    (ex_fwd_data),      // Forward data
        .ex_dst_addr    (ex_dst_addr),      // Write  address
        .ex_gpr_we_     (ex_gpr_we_),       // Write enable
        // MEM Stage Forward
        .mem_fwd_data   (mem_fwd_data),     // Forward data
        /*********  Pipeline Control Signal *********/
        .stall          (id_stall),         // Stall
        .flush          (id_flush),         // Flush

        /********** Forward Signal **********/
        .ra_fwd_ctrl    (ra_fwd_ctrl),
        .rb_fwd_ctrl    (rb_fwd_ctrl),

        /********** IF/ID Pipeline  Register **********/
        .pc             (pc),               // Current Program count
        .if_pc          (if_pc),            // Next Program count
        .if_insn        (if_insn),          // Instruction
        .if_en          (if_en),            // Pipeline data enable

        /********** ID/EX Pipeline  Register **********/
        .id_en          (id_en),            // Pipeline data enable
        .id_alu_op      (id_alu_op),        // ALU operation
        .id_alu_in_0    (id_alu_in_0),      // ALU input 0
        .id_alu_in_1    (id_alu_in_1),      // ALU input 1
        .id_cmp_op      (id_cmp_op),        // CMP Operation
        .id_cmp_in_0    (id_cmp_in_0),      // CMP input 0
        .id_cmp_in_1    (id_cmp_in_1),      // CMP input 1
        .id_ra_addr     (id_ra_addr),
        .id_rb_addr     (id_rb_addr),
        .id_jump_taken  (id_jump_taken),
        .id_mem_op      (id_mem_op),        // Memory operation
        .id_mem_wr_data (id_mem_wr_data),   // Memory Write data
        .id_dst_addr    (id_dst_addr),      // GPRWrite  address
        .id_gpr_we_     (id_gpr_we_),       // GPRWrite enable
        .id_gpr_mux_ex  (id_gpr_mux_ex),
        .id_gpr_wr_data (id_gpr_wr_data),

        .op             (op),
        .ra_addr        (ra_addr),
        .rb_addr        (rb_addr),
        .src_reg_used   (src_reg_used)
    );

    /********** EX Stage **********/
    ex_stage ex_stage (
        /********** Clock & Reset **********/
        .clk            (clk),              // Clock
        .reset          (rst),              // Asynchronous Reset
        /**********  Pipeline Control Signal **********/
        .stall          (ex_stall),         // Stall
        .flush          (ex_flush),         // Flush
        /********** ID/EX Pipeline  Register **********/
        .id_en          (id_en),
        .id_alu_op      (id_alu_op),        // ALU operation
        .id_alu_in_0    (id_alu_in_0),      // ALU input 0
        .id_alu_in_1    (id_alu_in_1),      // ALU input 1
        .id_cmp_op      (id_cmp_op),        // CMP operation
        .id_cmp_in_0    (id_cmp_in_0),      // CMP input 0
        .id_cmp_in_1    (id_cmp_in_1),      // CMP input 1

        .id_mem_op      (id_mem_op),        // Memory operation
        .id_mem_wr_data (id_mem_wr_data),   // Memory Write data
        .id_dst_addr    (id_dst_addr),      // General purpose RegisterWrite  address
        .id_gpr_we_     (id_gpr_we_),       // General purpose RegisterWrite enable
        .ex_out_sel     (id_gpr_mux_ex),
        .id_gpr_wr_data (id_gpr_wr_data),

        // Forward Data From MEM Stage
        .ex_ra_fwd_en   (ex_ra_fwd_en),
        .ex_rb_fwd_en   (ex_rb_fwd_en),
        .mem_fwd_data   (mem_fwd_data),     // MEM Stage

        /********** Forward  **********/
        .fwd_data       (ex_fwd_data),      // Forward data
         /********** EX/MEM Pipeline  Register **********/
        .ex_en          (ex_en),
        .ex_mem_op      (ex_mem_op),        // Memory operation
        .ex_mem_wr_data (ex_mem_wr_data),   // Memory Write data
        .ex_dst_addr    (ex_dst_addr),      // General purpose RegisterWrite address
        .ex_gpr_we_     (ex_gpr_we_),       // General purpose RegisterWrite enable
        
        .alu_out        (alu_out), 
        .ex_out         (ex_out),           // Operating result
        .access_mem     (access_mem),
        .id_jump_taken  (id_jump_taken),

        .br_addr        (br_addr),
        .br_taken       (br_taken)
    );

    /********** MEM Stage **********/
    mem_stage mem_stage(
        /****** Clock & Reset *****/
        .clk            (clk),                // clock
        .reset          (rst),                // reset
        /***** Memory part *******/
        .memory_en      (memory_en),
        .l2_en          (l2_en),
        .dc_addr_mem    (dc_addr_mem),
        .dc_addr_l2     (dc_addr_l2),
        .dc_index_mem      (dc_index_mem),
        .dc_tag_wd_mem     (dc_tag_wd_mem),
        .dc_block0_we_mem  (dc_block0_we_mem),
        .dc_block1_we_mem  (dc_block1_we_mem),
        .dc_wd_mem         (dc_wd_mem), 
        .dc_rw_mem         (dc_rw_mem),  
        .offset_mem        (offset_mem),
        /* Pipeline Control Signal */
        .stall          (mem_stall),     
        .flush          (mem_flush),  
        .l2_wr_dc_en    (l2_wr_dc_en),
        /********** Forward *******/
        .fwd_data       (mem_fwd_data),
        /******** CPU part *******/
        .miss_stall     (mem_busy),          // the signal of stall caused by cache miss
        .access_mem     (access_mem), 
        .access_l2_clean(access_l2_clean),
        .access_l2_dirty(access_l2_dirty),
        .dc_choose_way  (dc_choose_way),
        /*thread part*/
        .l2_thread      (l2_thread),
        .mem_thread     (mem_thread),
        .thread         (thread),
        .dc_thread      (dc_thread),  
        .dc_busy        (dc_busy),
        /* L1_cache part */
        .alu_out        (alu_out), 
        .lru            (lru_dc),       // mark of replacing
        .thread0        (thread0_dc),
        .thread1        (thread1_dc),
        .tag0_rd        (tag0_rd_dc),   // read data of tag0
        .tag1_rd        (tag1_rd_dc),   // read data of tag1
        .tag_wd         (dc_tag_wd),    // write data of L1_tag
        .data0_rd       (data0_rd_dc),  // read data of data0
        .data1_rd       (data1_rd_dc),  // read data of data1
        .data_wd_l2     (data_wd_l2),
        .data_wd_l2_mem (data_wd_l2_mem), 
        .dirty0         (dirty0),            
        .dirty1         (dirty1),                            
        .block0_we      (dc_block0_we),  // write signal of block0
        .block1_we      (dc_block1_we),  // write signal of block1
        .block0_re      (block0_re),     // read signal of block0
        .block1_re      (block1_re),     // read signal of block1       
        .offset         (dc_offset), 
        .dc_addr        (dc_addr),
        .data_wd_l2_en_dc  (data_wd_l2_en_dc),
        .dc_thread_wd      (dc_thread_wd),
        .data_wd           (dc_data_wd),
        .tagcomp_hit    (tagcomp_hit),         
        .data_wd_dc_en  (data_wd_dc_en),
        .mem_wr_dc_en   (mem_wr_dc_en), 
        .index          (dc_index),      // address of L1_cache
        .dc_wd          (dc_wd),
        .dc_rw          (dc_rw),
        /* l2_cache part */
        .dc_index_l2      (dc_index_l2),
        .dc_tag_wd_l2     (dc_tag_wd_l2),
        .dc_block0_we_l2  (dc_block0_we_l2),
        .dc_block1_we_l2  (dc_block1_we_l2),
        .dc_wd_l2         (dc_wd_l2), 
        .dc_rw_l2         (dc_rw_l2),  
        .offset_l2        (l2_offset),
        .l2_busy        (l2_busy),  
        .dc_en          (dc_en),         // busy signal of l2_cache
        .l2_rdy         (l2_rdy),        // ready signal of l2_cache       
        .drq            (drq),         
        /** EX/MEM Pipeline Register **/
        .ex_en          (ex_en),         // busy signal of l2_cache
        .ex_mem_op      (ex_mem_op),     // ready signal of l2_cache
        .ex_mem_wr_data (ex_mem_wr_data),      
        .ex_dst_addr    (ex_dst_addr), 
        .ex_gpr_we_     (ex_gpr_we_),       
        .ex_out         (ex_out),
        .thread_rdy     (thread_rdy_dc),
        /** MEM/WB Pipeline Register **/
        .mem_en         (mem_en),      
        .mem_dst_addr   (mem_dst_addr), 
        .mem_gpr_we_    (mem_gpr_we_),       
        .mem_out        (mem_out)
        );
    // l2_cache
    l2_cache_ctrl l2_cache_ctrl(
        .clk                 (clk),            // clock of L2C
        .rst                 (rst),            // reset
        .dc_rw               (dc_rw),          // Read/Write 
        .mem_busy            (mem_busy), 
        .thread_rdy          (thread_rdy_l2),
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
        .choose_way          (l2_choose_way), 
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
        .ic_addr             (if_pc[31:2]),
        .ic_choose_way       (ic_choose_way),
        .ic_addr_l2          (ic_addr_l2),
        .ic_en               (ic_en),
        .ic_index            (ic_index_l2),
        .ic_tag_wd           (ic_tag_wd),
        .ic_block0_we        (ic_block0_we_l2),
        .ic_block1_we        (ic_block1_we_l2),
        /*dcache part*/
        .data_wd_l2_en_dc    (data_wd_l2_en_dc),
        .dc_offset           (dc_offset),
        .dc_offset_l2        (dc_offset_l2),
        .drq                 (drq),   
        .tag0_rd             (tag0_rd_dc),
        .tag1_rd             (tag1_rd_dc),
        .data0_rd            (data0_rd_dc),
        .data1_rd            (data1_rd_dc),      
        .dc_addr             (dc_addr),           // alu_out[31:4]
        .dc_choose_way       (dc_choose_way), 
        .read_en             (read_en),
        .dc_en               (dc_en),
        .dc_index            (dc_index_l2),
        .dc_tag_wd           (dc_tag_wd_l2),
        .dc_block0_we        (dc_block0_we_l2),
        .dc_block1_we        (dc_block1_we_l2),
        .data_wd_dc_en_l2    (data_wd_dc_en_l2),
        .dc_wd_l2            (dc_wd_l2),
        .dc_wd               (dc_wd),
        .dc_addr_l2          (dc_addr_l2),
        .data_wd_l2          (data_wd_l2),        // write data to L1C       
        .data_wd_l2_en       (data_wd_l2_en),
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
        .dc_wd_read          (dc_wd_read),       
        .dc_addr_read        (dc_addr_read), 
        .read_l2_en          (read_l2_en),
        .dc_rw_l2            (dc_rw_l2), 
        .memory_busy         (memory_busy)
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
        .dc_offset_l2       (dc_offset_l2),
        .dc_offset_mem      (dc_offset_mem),
        .w_complete         (w_complete),
        .mem_wr_dc_en       (mem_wr_dc_en),
        .read_en            (read_en),
        .dc_en              (dc_en),         // busy signal of l2_cache
        .dc_index_mem       (dc_index_mem),
        .dc_tag_wd_mem      (dc_tag_wd_mem), 
        .dc_block0_we_mem   (dc_block0_we_mem),
        .dc_block1_we_mem   (dc_block1_we_mem),       
        .data_wd_l2_mem     (data_wd_l2_mem),    // write data to L1C       
        .data_wd_l2_en_mem  (data_wd_l2_en_mem),     
        // .data_wd_dc_en      (data_wd_dc_en_mem),
        .dc_wd_l2           (dc_wd_l2),
        .dc_wd_mem          (dc_wd_mem),
        .rd_to_l2           (rd_to_l2),
        .rd_to_l2_mem       (rd_to_l2_mem),
        .dc_addr_l2         (dc_addr_l2),
        .dc_addr_mem        (dc_addr_mem),
        .ic_addr_mem        (ic_addr_mem),
        .ic_addr_l2         (ic_addr_l2),
        .l2_choose_l1_read  (l2_choose_l1_read), 
        .mem_thread_read    (mem_thread_read),    
        .dc_rw_read         (dc_rw_read),     
        .dc_wd_read         (dc_wd_read),       
        .dc_addr_read       (dc_addr_read),   
        .dc_rw              (dc_rw),  
        /*memory part*/
        .dc_rw_mem          (dc_rw_mem),
        .offset_mem         (offset_mem),
        .read_l2_en         (read_l2_en),
        .ic_en_mem          (ic_en_mem),
        .dc_en_mem          (dc_en_mem),
        .memory_busy        (memory_busy),
        .access_mem_clean   (access_mem_clean), 
        .access_mem_dirty   (access_mem_dirty),
        .thread_rdy         (thread_rdy_mem),
        .mem_complete_w     (mem_complete_w),
        .mem_complete_r     (mem_complete_r),
        .mem_rd             (mem_rd),
        .mem_wd             (mem_wd), 
        .mem_addr           (mem_addr),     // address of memory
        .mem_we             (mem_we),       // mark of writing to memory
        .mem_re             (mem_re)        // mark of reading from memory
    );
     /********** Control Module **********/
    ctrl ctrl(
        /** pipeline control signals **/
        .rst            (rst),           // reset
        //  State of Pipeline
        .if_busy        (if_busy),        // IF busy mark // miss stall of if_stage
        .br_taken       (br_taken),       // branch hazard mark
        .mem_busy       (mem_busy),       // MEM busy mark // miss stall of mem_stage
        /******** Data Forward ******/
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
        .if_stall       (if_stall),       // IF stage stall
        .id_stall       (id_stall),       // ID stage stall
        .ex_stall       (ex_stall),       // EX stage stall
        .mem_stall      (mem_stall),      // MEM stage stall
        // Flush Signal
        .if_flush       (if_flush),       // IF stage flush
        .id_flush       (id_flush),       // ID stage flush
        .ex_flush       (ex_flush),       // EX stage flush
        .mem_flush      (mem_flush),      // MEM stage flush
        .new_pc         (new_pc),         // New program counter
        /****** Forward Output ******/
        .ra_fwd_ctrl    (ra_fwd_ctrl),
        .rb_fwd_ctrl    (rb_fwd_ctrl),
        .ex_ra_fwd_en   (ex_ra_fwd_en),
        .ex_rb_fwd_en   (ex_rb_fwd_en)
        );
    /*******   Cache Ram   *******/
    mem mem(
        .clk            (clk),           // clock
        .rst            (rst),           // reset active  
        .re             (mem_re),
        .we             (mem_we),
        .complete_w     (mem_complete_w),
        .complete_r     (mem_complete_r)
        );
    dtag_ram dtag_ram(
        .clk               (clk),           // clock
        .data_wd_dc_en     (data_wd_dc_en), // write data of l2_cache
        .l2_wr_dc_en       (l2_wr_dc_en),
        .index             (dc_index),      // address of cache
        .block0_we         (dc_block0_we),      // write signal of block0
        .block1_we         (dc_block1_we),      // write signal of block1
        .block0_re         (block0_re),
        .block1_re         (block1_re), 
        .w_complete        (w_complete),
        .thread_wd         (dc_thread_wd),
        .tag_wd            (dc_tag_wd),     // write data of tag
        .tag0_rd           (tag0_rd_dc),    // read data of tag0
        .tag1_rd           (tag1_rd_dc),    // read data of tag1
        .thread0           (thread0_dc),
        .thread1           (thread1_dc),
        .dirty0            (dirty0),
        .dirty1            (dirty1),
        .lru               (lru_dc)         // read data of tag
        );
    data_ram ddata_ram(
        .clk               (clk),               // clock   
        .index             (dc_index),          // address of cache
        .block0_we         (dc_block0_we),      // write signal of block0
        .block1_we         (dc_block1_we),      // write signal of block1
        .block0_re         (block0_re),         // read signal of block0
        .block1_re         (block1_re),         // read signal of block1
        .dc_data_wd        (dc_data_wd),        // write data of l2_cache
        .l2_wr_dc_en       (l2_wr_dc_en),
        .data_wd_dc_en     (data_wd_dc_en), // write data of l2_cache
        .dc_wd             (dc_wd),
        .dc_offset         (dc_offset),
        .data0_rd          (data0_rd_dc),   // read data of cache_data0
        .data1_rd          (data1_rd_dc)    // read data of cache_data1
    );
    itag_ram itag_ram(
        .clk               (clk),           // clock
        .block0_we         (block0_we_ic),  // write signal of block0
        .block1_we         (block1_we_ic),  // write signal of block1
        .block0_re         (block0_re_ic),  // read signal of block0
        .block1_re         (block1_re_ic),  // read signal of block1
        .thread_wd         (thread_wd_ic),
        .thread0           (thread0_ic),
        .thread1           (thread1_ic),
        .index             (ic_index),      // address of cache
        .tag_wd            (tag_wd),        // write data of tag
        .tag0_rd           (tag0_rd_ic),    // read data of tag0
        .tag1_rd           (tag1_rd_ic),    // read data of tag1
        .lru               (lru_ic)         // read data of tag
        );
    idata_ram idata_ram(
        .clk               (clk),               // clock
        .block0_we         (block0_we_ic),  // write signal of block0
        .block1_we         (block1_we_ic),  // write signal of block1
        .block0_re         (block0_re_ic),      // read signal of block0
        .block1_re         (block1_re_ic),      // read signal of block1
        .index             (ic_index),      // address of cache
        .data_wd           (data_wd), 
        .data0_rd          (data0_rd_ic),       // read data of cache_data0
        .data1_rd          (data1_rd_ic)        // read data of cache_data1
    );
    l2_data_ram l2_data_ram(
        .clk                (clk),              // clock of L2C
        .l2_index           (l2_index),         // address of cache
        .l2_data_wd_mem     (l2_data_wd_mem),
        .offset             (offset),        
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
    /**** General purpose Register *****/
    gpr gpr (
        /**** Clock & Reset *******/
        .clk            (clk),              // Clock
        .reset          (rst),              // Asynchronous Reset
        /***** Read Port  0 ******/
        .rd_addr_0      (gpr_rd_addr_0),    // Read  address
        .rd_data_0      (gpr_rd_data_0),    // Read data
        /***** Read Port  1 ******/
        .rd_addr_1      (gpr_rd_addr_1),    // Read  address
        .rd_data_1      (gpr_rd_data_1),    // Read data
        /***** Write Port  ******/
        .we_            (mem_gpr_we_),      // Write enable
        .wr_addr        (mem_dst_addr),     // Write  address
        .wr_data        (mem_out)           //  Write data
    );

    task dtag_ram_tb;
        input      [20:0]  _tag0_rd_dc;        // read data of tag0
        input      [20:0]  _tag1_rd_dc;        // read data of tag1
        input              _lru_dc;            // read block of tag
        begin 
            if( (tag0_rd_dc  === _tag0_rd_dc)     && 
                (tag1_rd_dc  === _tag1_rd_dc)     && 
                (lru_dc      === _lru_dc)                    
               ) begin 
                 $display("Tag_ram Test Succeeded !"); 
            end else begin 
                 $display("Tag_ram Test Failed !"); 
            end             
            if (tag0_rd_dc  !== _tag0_rd_dc) begin
                $display("tag0_rd_dc:%h(excepted %h)",tag0_rd_dc,_tag0_rd_dc); 
            end
            if (tag1_rd_dc  !== _tag1_rd_dc) begin
                $display("tag1_rd_dc:%h(excepted %h)",tag1_rd_dc,_tag1_rd_dc); 
            end
            if (lru_dc      !== _lru_dc) begin
                $display("lru_dc:%h(excepted %h)",lru_dc,_lru_dc); 
            end
        end
    endtask
    task data_ram_tb;
        input  [127:0] _data0_rd_dc;        // read data of cache_data0
        input  [127:0] _data1_rd_dc;        // read data of cache_data1
        begin 
            if( (data0_rd_dc  === _data0_rd_dc)   && 
                (data1_rd_dc  === _data1_rd_dc)             
               ) begin 
                 $display("Data_ram Test Succeeded !"); 
            end else begin 
                 $display("Data_ram Test Failed !"); 
            end 
            if(data0_rd_dc !== _data0_rd_dc) begin
                $display("data0_rd:%h(excepted %h)",data0_rd_dc,_data0_rd_dc); 
            end
            if(data1_rd_dc !== _data1_rd_dc) begin
                $display("data1_rd:%h(excepted %h)",data1_rd_dc,_data1_rd_dc); 
            end           
        end
    endtask 
    task l2_tag_ram_tb;    
        input      [17:0]  _l2_tag0_rd;        // read data of tag0
        input      [17:0]  _l2_tag1_rd;        // read data of tag1
        input      [17:0]  _l2_tag2_rd;        // read data of tag2
        input      [17:0]  _l2_tag3_rd;        // read data of tag3
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
                $display("l2_tag0_rd:%h(excepted %h)",l2_tag0_rd,_l2_tag0_rd); 
            end
            if (l2_tag1_rd  !== _l2_tag1_rd) begin
                $display("l2_tag1_rd:%h(excepted %h)",l2_tag1_rd,_l2_tag1_rd); 
            end
            if (l2_tag2_rd  !== _l2_tag2_rd) begin
                $display("l2_tag2_rd:%h(excepted %h)",l2_tag2_rd,_l2_tag2_rd); 
            end
            if (l2_tag3_rd  !== _l2_tag3_rd) begin
                $display("l2_tag3_rd:%h(excepted %h)",l2_tag3_rd,_l2_tag3_rd); 
            end
            if (plru        !== _plru) begin
                $display("plru:%b(excepted %b)",plru,_plru); 
            end
            if (l2_complete_w !== _l2_complete) begin
                $display("l2_complete_w:%b(excepted %b)",l2_complete_w,_l2_complete); 
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
                $display("l2_data0_rd:%h(excepted %h)",l2_data0_rd,_l2_data0_rd); 
            end
            if (l2_data1_rd  !== _l2_data1_rd) begin
                $display("l2_data1_rd:%h(excepted %h)",l2_data1_rd,_l2_data1_rd); 
            end
            if (l2_data2_rd  !== _l2_data2_rd) begin
                $display("l2_data2_rd:%h(excepted %h)",l2_data2_rd,_l2_data2_rd); 
            end
            if (l2_data3_rd  !== _l2_data3_rd) begin
                $display("l2_data3_rd:%h(excepted %h)",l2_data3_rd,_l2_data3_rd); 
            end
        end       
    endtask
    task itag_ram_tb;
        input      [20:0]  _tag0_rd_ic;        // read data of tag0
        input      [20:0]  _tag1_rd_ic;        // read data of tag1
        input              _lru_ic;            // read block of tag
        begin 
            if( (tag0_rd_ic  === _tag0_rd_ic)     && 
                (tag1_rd_ic  === _tag1_rd_ic)     && 
                (lru_ic      === _lru_ic)                  
               ) begin 
                 $display("Tag_ram Test Succeeded !"); 
            end else begin 
                 $display("Tag_ram Test Failed !"); 
            end             
            if (tag0_rd_ic  !== _tag0_rd_ic) begin
                $display("tag0_rd_ic:%h(excepted %h)",tag0_rd_ic,_tag0_rd_ic); 
            end
            if (tag1_rd_ic  !== _tag1_rd_ic) begin
                $display("tag1_rd_ic:%h(excepted %h)",tag1_rd_ic,_tag1_rd_ic); 
            end
            if (lru_ic      !== _lru_ic) begin
                $display("lru_ic:%h(excepted %h)",lru_ic,_lru_ic); 
            end
        end
    endtask
    task idata_ram_tb;
        input  [127:0] _data0_rd_ic;        // read data of cache_data0
        input  [127:0] _data1_rd_ic;        // read data of cache_data1
        begin 
            if( (data0_rd_ic  === _data0_rd_ic)   && 
                (data1_rd_ic  === _data1_rd_ic)             
               ) begin 
                 $display("Data_ram Test Succeeded !"); 
            end else begin 
                 $display("Data_ram Test Failed !"); 
            end 
        end
    endtask

    task if_tb;
        input [`WORD_DATA_BUS] _pc;
        input [`WORD_DATA_BUS] _if_pc;
        input [`WORD_DATA_BUS] _if_insn;
        input                  _if_en;

        begin
            if( (pc          === _pc)           &&
                (if_pc       === _if_pc)        &&
                (if_insn     === _if_insn)      &&
                (if_en       === _if_en)
              ) begin
                $display("IF  Stage Test Succeeded !");
            end else begin
                $display("IF  Stage Test Failed !");
            end
            if (pc      !== _pc) begin
                $display("pc:%h(excepted %h)",pc,_pc); 
            end
            if (if_pc   !== _if_pc) begin
                $display("if_pc:%h(excepted %h)",if_pc,_if_pc); 
            end
            if (if_insn !== _if_insn) begin
                $display("if_insn:%h(excepted %h)",if_insn,_if_insn); 
            end
            if (if_en   !== _if_en) begin
                $display("if_en:%h(excepted %h)",if_en,_if_en); 
            end
        end
    endtask

    task id_tb;
        input                   _id_en;          //  Pipeline data enable
        input [`ALU_OP_BUS]     _id_alu_op;      // ALU operation
        input [`WORD_DATA_BUS]  _id_alu_in_0;    // ALU input 0
        input [`WORD_DATA_BUS]  _id_alu_in_1;    // ALU input 1
        input [`CMP_OP_BUS]     _id_cmp_op;     // CMP Operation
        input [`WORD_DATA_BUS]  _id_cmp_in_0;   // CMP input 0
        input [`WORD_DATA_BUS]  _id_cmp_in_1;   // CMP input 1
        input [`REG_ADDR_BUS]   _id_ra_addr;
        input [`REG_ADDR_BUS]   _id_rb_addr;
        input                   _id_jump_taken;
        input [`MEM_OP_BUS]     _id_mem_op;      // Memory operation
        input [`WORD_DATA_BUS]  _id_mem_wr_data; // Memory Write data
        input [`REG_ADDR_BUS]   _id_dst_addr;    // GPRWrite  address
        input                   _id_gpr_we_;     // GPRWrite enable
        input [`EX_OUT_SEL_BUS] _id_gpr_mux_ex;
        input [`WORD_DATA_BUS]  _id_gpr_wr_data;
        input [`INS_OP_BUS]     _op;
        input [`REG_ADDR_BUS]   _ra_addr;
        input [`REG_ADDR_BUS]   _rb_addr;
        input [1:0]             _src_reg_used;

        begin
            if( (id_en          === _id_en)          &&
                (id_alu_op      === _id_alu_op)      &&
                (id_alu_in_0    === _id_alu_in_0)    &&
                (id_alu_in_1    === _id_alu_in_1)    &&
                (id_cmp_op      === _id_cmp_op)      &&
                (id_cmp_in_0    === _id_cmp_in_0)    &&
                (id_cmp_in_1    === _id_cmp_in_1)    &&
                (id_ra_addr     === _id_ra_addr)     &&
                (id_rb_addr     === _id_rb_addr)     &&
                (id_jump_taken  === _id_jump_taken)  &&
                (id_mem_op      === _id_mem_op)      &&
                (id_mem_wr_data === _id_mem_wr_data) &&
                (id_dst_addr    === _id_dst_addr)    &&
                (id_gpr_we_     === _id_gpr_we_)     &&
                (id_gpr_mux_ex  === _id_gpr_mux_ex)  &&
                (id_gpr_wr_data === _id_gpr_wr_data) &&
                (op             === _op)             &&
                (ra_addr        === _ra_addr)        &&
                (rb_addr        === _rb_addr)        &&
                (src_reg_used   === _src_reg_used)

              ) begin
                $display("ID  Stage Test Succeeded !");
            end else begin
                $display("ID  Stage Test Failed !");
            end
            if (id_en   !== _id_en) begin
                $display("id_en:%h(excepted %h)",id_en,_id_en); 
            end
            if (id_alu_op !== _id_alu_op) begin
                $display("id_alu_op:%h(excepted %h)",id_alu_op,_id_alu_op); 
            end
            if (id_alu_in_0   !== _id_alu_in_0) begin
                $display("id_alu_in_0:%h(excepted %h)",id_alu_in_0,_id_alu_in_0); 
            end
            if (id_alu_in_1 !== _id_alu_in_1) begin
                $display("id_alu_in_1:%h(excepted %h)",id_alu_in_1,_id_alu_in_1); 
            end
            if (id_cmp_op  !== _id_cmp_op) begin
                $display("id_cmp_op:%h(excepted %h)",id_cmp_op,_id_cmp_op); 
            end
            if (id_cmp_in_0  !== _id_cmp_in_0) begin
                $display("id_cmp_in_0:%h(excepted %h)",id_cmp_in_0,_id_cmp_in_0); 
            end
            if (id_cmp_in_1     !== _id_cmp_in_1) begin
                $display("id_cmp_in_1:%h(excepted %h)",id_cmp_in_1,_id_cmp_in_1); 
            end
            if (id_ra_addr      !== _id_ra_addr) begin
                $display("id_ra_addr:%h(excepted %h)",id_ra_addr,_id_ra_addr); 
            end
            if (id_jump_taken   !== _id_jump_taken) begin
                $display("id_jump_taken:%h(excepted %h)",id_jump_taken,_id_jump_taken); 
            end
            if (id_rb_addr !== _id_rb_addr) begin
                $display("id_rb_addr:%h(excepted %h)",id_rb_addr,_id_rb_addr); 
            end

            if (id_mem_op   !== _id_mem_op) begin
                $display("id_mem_op:%h(excepted %h)",id_mem_op,_id_mem_op); 
            end
            if (id_mem_wr_data !== _id_mem_wr_data) begin
                $display("id_mem_wr_data:%h(excepted %h)",id_mem_wr_data,_id_mem_wr_data); 
            end
            if (id_gpr_we_   !== _id_gpr_we_) begin
                $display("id_gpr_we_:%h(excepted %h)",id_gpr_we_,_id_gpr_we_); 
            end
            if (id_dst_addr !== _id_dst_addr) begin
                $display("id_dst_addr:%h(excepted %h)",id_dst_addr,_id_dst_addr); 
            end
            if (id_gpr_mux_ex  !== _id_gpr_mux_ex) begin
                $display("id_gpr_mux_ex:%h(excepted %h)",id_gpr_mux_ex,_id_gpr_mux_ex); 
            end
            if (id_gpr_wr_data  !== _id_gpr_wr_data) begin
                $display("id_gpr_wr_data:%h(excepted %h)",id_gpr_wr_data,_id_gpr_wr_data); 
            end
            if (op     !== _op) begin
                $display("op:%h(excepted %h)",op,_op); 
            end
            if (ra_addr      !== _ra_addr) begin
                $display("ra_addr:%h(excepted %h)",ra_addr,_ra_addr); 
            end
            if (rb_addr   !== _rb_addr) begin
                $display("rb_addr:%h(excepted %h)",rb_addr,_rb_addr); 
            end
            if (src_reg_used !== _src_reg_used) begin
                $display("src_reg_used:%h(excepted %h)",src_reg_used,_src_reg_used); 
            end
        end
    endtask

    task ex_tb;
        input [`WORD_DATA_BUS] _ex_fwd_data;
        input                  _ex_en;
        input [`MEM_OP_BUS]    _ex_mem_op;      // Memory operation
        input [`WORD_DATA_BUS] _ex_mem_wr_data; // Memory Write data
        input [`REG_ADDR_BUS]  _ex_dst_addr;    // General purpose RegisterWrite  address
        input                  _ex_gpr_we_;     // General purpose RegisterWrite enable
        input [`WORD_DATA_BUS] _ex_out;         // Operating result

        input [`WORD_DATA_BUS] _br_addr;        // target pc value of branch or jump
        input                  _br_taken;       // ture - take branch or jump

        begin
            if( (ex_fwd_data    === _ex_fwd_data)     &&
                (ex_en          === _ex_en)           &&
                (ex_mem_op      === _ex_mem_op)       &&      // Memory operation
                (ex_mem_wr_data === _ex_mem_wr_data)  &&      // Memory Write data
                (ex_dst_addr    === _ex_dst_addr)     &&      // General purpose RegisterWrite address
                (ex_gpr_we_     === _ex_gpr_we_)      &&      // General purpose RegisterWrite enable
                (ex_out         === _ex_out)          &&      // Operating result
                (br_addr        === _br_addr)         &&      // Operating result
                (br_taken       === _br_taken)                // Operating result
              ) begin
                $display("EX  Stage Test Succeeded !");
            end else begin
                $display("EX  Stage Test Failed !");
            end
            if (ex_fwd_data   !== _ex_fwd_data) begin
                $display("ex_fwd_data:%h(excepted %h)",ex_fwd_data,_ex_fwd_data); 
            end
            if (ex_en !== _ex_en) begin
                $display("ex_en:%h(excepted %h)",ex_en,_ex_en); 
            end
            if (ex_mem_op   !== _ex_mem_op) begin
                $display("ex_mem_op:%h(excepted %h)",ex_mem_op,_ex_mem_op); 
            end
            if (ex_mem_wr_data !== _ex_mem_wr_data) begin
                $display("ex_mem_wr_data:%h(excepted %h)",ex_mem_wr_data,_ex_mem_wr_data); 
            end
            if (ex_dst_addr   !== _ex_dst_addr) begin
                $display("ex_dst_addr:%h(excepted %h)",ex_dst_addr,_ex_dst_addr); 
            end
            if (ex_gpr_we_ !== _ex_gpr_we_) begin
                $display("ex_gpr_we_:%h(excepted %h)",ex_gpr_we_,_ex_gpr_we_); 
            end
            if (ex_out   !== _ex_out) begin
                $display("ex_out:%h(excepted %h)",ex_out,_ex_out); 
            end
            if (br_addr !== _br_addr) begin
                $display("br_addr:%h(excepted %h)",br_addr,_br_addr); 
            end
            if (br_taken   !== _br_taken) begin
                $display("br_taken:%h(excepted %h)",br_taken,_br_taken); 
            end
        end
    endtask

    task mem_tb;
        input [`WORD_DATA_BUS] _mem_fwd_data;
        input                  _mem_en;
        input [`REG_ADDR_BUS]  _mem_dst_addr; // General purpose RegisterWrite  address
        input                  _mem_gpr_we_;  // General purpose RegisterWrite enable
        input [`WORD_DATA_BUS] _mem_out;      // Operating result

        begin
            if( (mem_fwd_data  === _mem_fwd_data)     &&
                (mem_en        === _mem_en)           &&
                (mem_dst_addr  === _mem_dst_addr)     &&      // Memory operation
                (mem_gpr_we_   === _mem_gpr_we_)      &&      // Memory Write data
                (mem_out       === _mem_out)                  // General purpose RegisterWrite address
              ) begin
                $display("MEM Stage Test Succeeded !");
            end else begin
                $display("MEM Stage Test Failed !");
            end
            if (mem_fwd_data   !== _mem_fwd_data) begin
                $display("mem_fwd_data:%h(excepted %h)",mem_fwd_data,_mem_fwd_data); 
            end
            if (mem_en !== _mem_en) begin
                $display("mem_en:%h(excepted %h)",mem_en,_mem_en); 
            end
            if (mem_dst_addr   !== _mem_dst_addr) begin
                $display("mem_dst_addr:%h(excepted %h)",mem_dst_addr,_mem_dst_addr); 
            end
            if (mem_gpr_we_ !== _mem_gpr_we_) begin
                $display("mem_gpr_we_:%h(excepted %h)",mem_gpr_we_,_mem_gpr_we_); 
            end
            if (mem_out  !== _mem_out) begin
                $display("mem_out:%h(excepted %h)",mem_out,_mem_out); 
            end
        end
    endtask

    task ctrl_tb;
        input                  _if_stall;     // IF stage stall
        input                  _id_stall;     // ID stage stall
        input                  _ex_stall;     // EX stage stall
        input                  _mem_stall;    // MEM stage stall
        input                  _if_flush;     // IF stage flush
        input                  _id_flush;     // ID stage flush
        input                  _ex_flush;     // EX stage flush
        input                  _mem_flush;    // MEM stage flush

        input [`WORD_DATA_BUS] _new_pc;

        /********** Forward Output **********/
        input [`FWD_CTRL_BUS]  _ra_fwd_ctrl;
        input [`FWD_CTRL_BUS]  _rb_fwd_ctrl;
        input                  _ex_ra_fwd_en;
        input                  _ex_rb_fwd_en;

        begin
            if( (if_stall     === _if_stall)     &&
                (id_stall     === _id_stall)     &&
                (ex_stall     === _ex_stall)     &&
                (mem_stall    === _mem_stall)    &&
                (if_flush     === _if_flush)     &&
                (id_flush     === _id_flush)     &&
                (ex_flush     === _ex_flush)     &&
                (mem_flush    === _mem_flush)    &&
                (new_pc       === _new_pc)       &&
                (ra_fwd_ctrl  === _ra_fwd_ctrl)  &&
                (rb_fwd_ctrl  === _rb_fwd_ctrl)  &&
                (ex_ra_fwd_en === _ex_ra_fwd_en) &&
                (ex_rb_fwd_en === _ex_rb_fwd_en)
              ) begin
                $display("Ctrl      Test Succeeded !");
            end else begin
                $display("Ctrl      Test Failed !");
            end
            if (if_stall   !== _if_stall) begin
                $display("if_stall:%h(excepted %h)",if_stall,_if_stall); 
            end
            if (id_stall !== _id_stall) begin
                $display("id_stall:%h(excepted %h)",id_stall,_id_stall); 
            end
            if (ex_stall   !== _ex_stall) begin
                $display("ex_stall:%h(excepted %h)",ex_stall,_ex_stall); 
            end
            if (mem_stall   !== _mem_stall) begin
                $display("mem_stall:%h(excepted %h)",mem_stall,_mem_stall); 
            end
            if (if_flush !== _if_flush) begin
                $display("if_flush:%h(excepted %h)",if_flush,_if_flush); 
            end
            if (id_flush  !== _id_flush) begin
                $display("id_flush:%h(excepted %h)",id_flush,_id_flush); 
            end
            if (ex_flush  !== _ex_flush) begin
                $display("ex_flush:%h(excepted %h)",ex_flush,_ex_flush); 
            end
            if (mem_flush     !== _mem_flush) begin
                $display("mem_flush:%h(excepted %h)",mem_flush,_mem_flush); 
            end
            if (new_pc      !== _new_pc) begin
                $display("new_pc:%h(excepted %h)",new_pc,_new_pc); 
            end
            if (ra_fwd_ctrl   !== _ra_fwd_ctrl) begin
                $display("ra_fwd_ctrl:%h(excepted %h)",ra_fwd_ctrl,_ra_fwd_ctrl); 
            end
            if (rb_fwd_ctrl !== _rb_fwd_ctrl) begin
                $display("rb_fwd_ctrl:%h(excepted %h)",rb_fwd_ctrl,_rb_fwd_ctrl); 
            end
            if (ex_ra_fwd_en   !== _ex_ra_fwd_en) begin
                $display("ex_ra_fwd_en:%h(excepted %h)",ex_ra_fwd_en,_ex_ra_fwd_en); 
            end
            if (ex_rb_fwd_en !== _ex_rb_fwd_en) begin
                $display("ex_rb_fwd_en:%h(excepted %h)",ex_rb_fwd_en,_ex_rb_fwd_en); 
            end
        end
    endtask
    task id_stage_tb;
        input                   _id_en;          //  Pipeline data enable
        input [`ALU_OP_BUS]     _id_alu_op;      // ALU operation
        input [`WORD_DATA_BUS]  _id_alu_in_0;    // ALU input 0
        input [`WORD_DATA_BUS]  _id_alu_in_1;    // ALU input 1
        input [`MEM_OP_BUS]     _id_mem_op;      // Memory operation
        input [`WORD_DATA_BUS]  _id_mem_wr_data; // Memory Write data
        input [`REG_ADDR_BUS]   _id_dst_addr;    // GPRWrite  address
        input                   _id_gpr_we_;     // GPRWrite enable
        input [`EX_OUT_SEL_BUS] _id_gpr_mux_ex;
        input [`WORD_DATA_BUS]  _id_gpr_wr_data;

        begin
            if( (id_en          === _id_en)          &&
                (id_alu_op      === _id_alu_op)      &&
                (id_alu_in_0    === _id_alu_in_0)    &&
                (id_alu_in_1    === _id_alu_in_1)    &&
                (id_mem_op      === _id_mem_op)      &&
                (id_mem_wr_data === _id_mem_wr_data) &&
                (id_dst_addr    === _id_dst_addr)    &&
                (id_gpr_we_     === _id_gpr_we_)     &&
                (id_gpr_mux_ex  === _id_gpr_mux_ex)  &&
                (id_gpr_wr_data === _id_gpr_wr_data)
              ) begin
                $display("ID  Stage Test Succeeded !");
            end else begin
                $display("ID  Stage Test Failed !");
            end
            if (id_en   !== _id_en) begin
                $display("id_en:%h(excepted %h)",id_en,_id_en); 
            end
            if (id_alu_op !== _id_alu_op) begin
                $display("id_alu_op:%h(excepted %h)",id_alu_op,_id_alu_op); 
            end
            if (id_alu_in_0   !== _id_alu_in_0) begin
                $display("id_alu_in_0:%h(excepted %h)",id_alu_in_0,_id_alu_in_0); 
            end
            if (id_alu_in_1 !== _id_alu_in_1) begin
                $display("id_alu_in_1:%h(excepted %h)",id_alu_in_1,_id_alu_in_1); 
            end
            if (id_mem_op   !== _id_mem_op) begin
                $display("id_mem_op:%h(excepted %h)",id_mem_op,_id_mem_op); 
            end
            if (id_mem_wr_data !== _id_mem_wr_data) begin
                $display("id_mem_wr_data:%h(excepted %h)",id_mem_wr_data,_id_mem_wr_data); 
            end            
            if (id_dst_addr !== _id_dst_addr) begin
                $display("id_dst_addr:%h(excepted %h)",id_dst_addr,_id_dst_addr); 
            end
            if (id_gpr_we_   !== _id_gpr_we_) begin
                $display("id_gpr_we_:%h(excepted %h)",id_gpr_we_,_id_gpr_we_); 
            end
            if (id_gpr_mux_ex  !== _id_gpr_mux_ex) begin
                $display("id_gpr_mux_ex:%h(excepted %h)",id_gpr_mux_ex,_id_gpr_mux_ex); 
            end
            if (id_gpr_wr_data  !== _id_gpr_wr_data) begin
                $display("id_gpr_wr_data:%h(excepted %h)",id_gpr_wr_data,_id_gpr_wr_data); 
            end
        end
    endtask
             
    task ex_stage_tb;
        input [`WORD_DATA_BUS]     _ex_fwd_data;
        input                      _ex_en; 
        input [`MEM_OP_BUS]        _ex_mem_op;      // Memory operation
        input [`WORD_DATA_BUS]     _ex_mem_wr_data; // Memory Write data
        input [`REG_ADDR_BUS]      _ex_dst_addr;    // General purpose RegisterWrite  address
        input                      _ex_gpr_we_;     // General purpose RegisterWrite enable
        input [`WORD_DATA_BUS]     _ex_out;         // Operating result

        begin
            if( (ex_fwd_data    === _ex_fwd_data)     &&
                (ex_en          === _ex_en)           &&
                (ex_mem_op      === _ex_mem_op)       &&      // Memory operation
                (ex_mem_wr_data === _ex_mem_wr_data)  &&      // Memory Write data
                (ex_dst_addr    === _ex_dst_addr)     &&      // General purpose RegisterWrite address
                (ex_gpr_we_     === _ex_gpr_we_)      &&      // General purpose RegisterWrite enable
                (ex_out         === _ex_out)                  // Operating result
              ) begin
                $display("EX  Stage Test Succeeded !");
            end else begin
                $display("EX  Stage Test Failed !");
            end
            if (ex_fwd_data   !== _ex_fwd_data) begin
                $display("ex_fwd_data:%h(excepted %h)",ex_fwd_data,_ex_fwd_data); 
            end
            if (ex_en !== _ex_en) begin
                $display("ex_en:%h(excepted %h)",ex_en,_ex_en); 
            end
            if (ex_mem_op   !== _ex_mem_op) begin
                $display("ex_mem_op:%h(excepted %h)",ex_mem_op,_ex_mem_op); 
            end
            if (ex_mem_wr_data !== _ex_mem_wr_data) begin
                $display("ex_mem_wr_data:%h(excepted %h)",ex_mem_wr_data,_ex_mem_wr_data); 
            end
            if (ex_dst_addr   !== _ex_dst_addr) begin
                $display("ex_dst_addr:%h(excepted %h)",ex_dst_addr,_ex_dst_addr); 
            end
            if (ex_gpr_we_ !== _ex_gpr_we_) begin
                $display("ex_gpr_we_:%h(excepted %h)",ex_gpr_we_,_ex_gpr_we_); 
            end
            if (ex_out   !== _ex_out) begin
                $display("ex_out:%h(excepted %h)",ex_out,_ex_out); 
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
    /******** Test Case ********/
    initial begin
        #0 begin
            clk      <= `ENABLE;
            rst      <= `ENABLE;
            thread   <= 2'b0;
            mem_rd   <= 512'hx00520333_00520333_00520333_00520333_00520333_40402283_40002203_40202223_40102023_00d00193_00900113_00400093;
        end
        #(STEP * 3/4)
        #STEP begin
            rst     <= `DISABLE;
        end
        #STEP begin // L1_ACCESS & L2_IDLE 
            $display("\n========= Clock 1 ========");
        end
        #(STEP*4) begin // IC_ACCESS_L2 & L2_IDLE & READ_MEM
            $display("\n========= Clock 5 ========");
            l2_tag_ram_tb(   
                18'bx,                                    // read data of tag0
                18'bx,                                    // read data of tag1
                18'bx,                                    // read data of tag2
                18'bx,                                    // read data of tag3
                3'bxxx,                                   // read data of tag
                `DISABLE                                  // complete write from L2 to L1
            );
            l2_data_ram_tb(
                512'hx,                                   // read data of cache_data0
                512'bx,                                   // read data of cache_data1
                512'bx,                                   // read data of cache_data2
                512'bx                                    // read data of cache_data3
             );
            itag_ram_tb(
                21'bx,                                    // read data of tag0
                21'bx,                                    // read data of tag1
                1'bx                                      // number of replacing block of tag next time
                // 1'b0                                      // complete write from L2 to L1
                );
            idata_ram_tb(
                128'hx,                                   // read data of cache_data0
                128'hx                                    // read data of cache_data1
                ); 
        end           
        #STEP begin // WRITE_IC & MEM_WRITE_L1 & access l2_ram
            $display("\n========= Clock 6 ========");
            itag_ram_tb(
                21'bx,                                    // read data of tag0
                21'bx,                                    // read data of tag1
                1'bx                                      // number of replacing block of tag next time
                // 1'b1                                      // complete write from L2 to L1
                );
            idata_ram_tb(
                128'hx,                                   // read data of cache_data0
                128'hx                                    // read data of cache_data1
                );             
            /******** ADDI r1, r0, 4 IF Stage Test Output ********/
            if_tb(
                `WORD_DATA_W'h0,                          // pc
                `WORD_DATA_W'h4,                          // if_pc
                `WORD_DATA_W'h00400093,                   // if_insn
                `ENABLE                                   // if_en
                );
            ctrl_tb(
                `DISABLE,                                 // if_stall
                `DISABLE,                                 // id_stall
                `DISABLE,                                 // ex_stall
                `DISABLE,                                 // mem_stall
                `DISABLE,                                 // if_flush
                `DISABLE,                                 // id_flush
                `DISABLE,                                 // ex_flush
                `DISABLE,                                 // mem_flush
                `WORD_DATA_W'h0,                          // new_pc
                `FWD_CTRL_NONE,                           // ra_fwd_ctrl
                `FWD_CTRL_NONE,                           // rb_fwd_ctrl
                `DISABLE,                                 // ex_ra_fwd_en
                `DISABLE                                  // ex_rb_fwd_en
               );
        end 
        /* First instruction into ID stage*/         
        #STEP begin // IC_ACCESS(READ HIT third insn) & MEM_WRITE_L1 & access l2_ram
            $display("\n========= Clock 7 ========");            
            itag_ram_tb(
                21'b1_0000_0000_0000_0000_0000,           // read data of tag0
                21'bx,                                    // read data of tag1
                1'b1                                      // number of replacing block of tag next time
                );
            idata_ram_tb(
                128'h40102023_00d00193_00900113_00400093, // read data of cache_data0
                128'hx                                    // read data of cache_data1
                );
            l2_tag_ram_tb(   
                18'bx,                                    // read data of tag0
                18'bx,                                    // read data of tag1
                18'bx,                                    // read data of tag2
                18'bx,                                    // read data of tag3
                3'bx,                                     // read data of tag
                `ENABLE                                   // complete write from L2 to L1
                );
            l2_data_ram_tb(                
                512'hx,                                   // read data of cache_data0
                512'bx,                                   // read data of cache_data1
                512'bx,                                   // read data of cache_data2
                512'bx                                    // read data of cache_data3
                );
            /******** ADDI r2 r0, 9 ID Stage Test Output ********/
            if_tb(
                `WORD_DATA_W'h4,                          // pc
                `WORD_DATA_W'h8,                          // if_pc
                `WORD_DATA_W'h00900113,                   // if_insn
                `ENABLE                                   // if_en
                );
            /******** ADDI r1, r0, 4 EX Stage Test Output ********/
            id_stage_tb(
                `ENABLE,                                  // id_en
                `ALU_OP_ADD,                              // id_alu_op
                `WORD_DATA_W'h0,                          // id_alu_in_0
                `WORD_DATA_W'h4,                          // id_alu_in_1
                `MEM_OP_NOP,                              // id_mem_op
                `WORD_DATA_W'hx,                          // id_mem_wr_data
                `REG_ADDR_W'h1,                           // id_dst_addr
                `ENABLE_,                                 // id_gpr_we_
                `EX_OUT_ALU,                              // id_gpr_mux_ex
                `WORD_DATA_W'h4                           // id_gpr_wr_data
                );
            ctrl_tb(
                `DISABLE,                                 // if_stall
                `DISABLE,                                 // id_stall
                `DISABLE,                                 // ex_stall
                `DISABLE,                                 // mem_stall
                `DISABLE,                                 // if_flush
                `DISABLE,                                 // id_flush
                `DISABLE,                                 // ex_flush
                `DISABLE,                                 // mem_flush
                `WORD_DATA_W'h0,                          // new_pc
                `FWD_CTRL_NONE,                           // ra_fwd_ctrl
                `FWD_CTRL_NONE,                           // rb_fwd_ctrl
                `DISABLE,                                 // ex_ra_fwd_en
                `DISABLE                                  // ex_rb_fwd_en
                );
        end
        /* First instruction into EX stage*/  
        #STEP begin // IC_ACCESS(READ HIT forth word)  & l2_IDLE        
            $display("\n========= Clock 8 ========");
            /******** ADDI r3 r0, 13 ID Stage Test Output ********/
            if_tb(
                `WORD_DATA_W'h8,                          // if_pc
                `WORD_DATA_W'hc,                          // if_pc_plus4
                `WORD_DATA_W'hd00193,                     // if_insn
                `ENABLE
                );

            /********ADDI r2 r0, 9  EX Stage Test Output ********/
            id_stage_tb(
                `ENABLE,                                  // id_en
                `ALU_OP_ADD,                              // id_alu_op
                `WORD_DATA_W'h0,                          // id_alu_in_0
                `WORD_DATA_W'h9,                          // id_alu_in_1
                `MEM_OP_NOP,                              // id_mem_op
                `WORD_DATA_W'hx,
                `REG_ADDR_W'h2,
                `ENABLE_,
                `EX_OUT_ALU,
                `WORD_DATA_W'h8
                );

            /******** ADDI r1, r0, 4 MEM Stage Test Output ********/
            ex_stage_tb(
                `WORD_DATA_W'h9,
                `ENABLE,
                `MEM_OP_NOP,
                `WORD_DATA_W'hx,
                `REG_ADDR_W'h1,
                `ENABLE_,
                `WORD_DATA_W'h4
                );

            ctrl_tb(
                `DISABLE,                                 // if_stall
                `DISABLE,                                 // id_stall
                `DISABLE,                                 // ex_stall
                `DISABLE,                                 // mem_stall
                `DISABLE,                                 // if_flush
                `DISABLE,                                 // id_flush
                `DISABLE,                                 // ex_flush
                `DISABLE,                                 // mem_flush
                `WORD_DATA_W'h0,                          // new_pc
                `FWD_CTRL_NONE,                           // ra_fwd_ctrl
                `FWD_CTRL_NONE,                           // rb_fwd_ctrl
                `DISABLE,                                 // ex_ra_fwd_en
                `DISABLE                                  // ex_rb_fwd_en
               );
        end
        # STEP begin // IC_ACCESS(miss)  & l2_IDLE 
            $display("\n========= Clock 9 ========");
            /******** SW   r1, r0(1024) ID Stage Test Output ********/
            if_tb(
                `WORD_DATA_W'hc,
                `WORD_DATA_W'h10,
                `WORD_DATA_W'h40102023,
                `ENABLE
                );

            /******** ADDI r3, r0, 13 EX Stage Test Output ********/
            id_stage_tb(
                `ENABLE,
                `ALU_OP_ADD,
                `WORD_DATA_W'h0,
                `WORD_DATA_W'hd,   
                `MEM_OP_NOP,
                `WORD_DATA_W'hx,
                `REG_ADDR_W'h3,
                `ENABLE_,
                `EX_OUT_ALU,
                `WORD_DATA_W'hc
                );

            /******** ADDI r2, r0, 9  MEM Stage Test Output ********/
            ex_stage_tb(
                `WORD_DATA_W'hd,
                `ENABLE,
                `MEM_OP_NOP,
                `WORD_DATA_W'hx,
                `REG_ADDR_W'h2,
                `ENABLE_,
                `WORD_DATA_W'h9
                );

            /******** ADDI r1, r0, 4  WB Stage Test Output ********/
            mem_tb(
                `WORD_DATA_W'h9,
                `ENABLE,
                `REG_ADDR_W'h1,
                `ENABLE_,
                `WORD_DATA_W'h4
                );

            ctrl_tb(
                `ENABLE,                                  // if_stall
                `ENABLE,                                  // id_stall
                `ENABLE,                                  // ex_stall
                `ENABLE,                                  // mem_stall
                `DISABLE,                                 // if_flush
                `DISABLE,                                 // id_flush
                `DISABLE,                                 // ex_flush
                `DISABLE,                                 // mem_flush
                `WORD_DATA_W'h0,                          // new_pc
                `FWD_CTRL_NONE,                           // ra_fwd_ctrl
                `FWD_CTRL_NONE,                           // rb_fwd_ctrl
                `DISABLE,                                 // ex_ra_fwd_en
                `DISABLE                                  // ex_rb_fwd_en
                ); 
        end
        # (STEP*2) begin // IC_ACCESS_L2(first insn) & ACCESS_L2(read hit) 
            $display("\n========= Clock 11 ========");
            l2_tag_ram_tb(   
                18'b1_0000_0000_0000_0000_0,              // read data of tag0
                18'bx,                                    // read data of tag1
                18'bx,                                    // read data of tag2
                18'bx,                                    // read data of tag3
                3'bx11,                                   // read data of tag
                `DISABLE                                  // complete write from L2 to L1
                );
            l2_data_ram_tb(
                // read data of cache_data0
                512'hx00520333_00520333_00520333_00520333_00520333_40402283_40002203_40202223_40102023_00d00193_00900113_00400093,
                512'bx,                                   // read data of cache_data1
                512'bx,                                   // read data of cache_data2
                512'bx                                    // read data of cache_data3
                );
            /******** SW   r1, r0(1024) ID Stage Test Output ********/
            if_tb(
                `WORD_DATA_W'hc,
                `WORD_DATA_W'h10,
                `WORD_DATA_W'h40102023,
                `ENABLE
                );

            /******** ADDI r3, r0, 13 EX Stage Test Output ********/
            id_stage_tb(
                `ENABLE,
                `ALU_OP_ADD,
                `WORD_DATA_W'h0,
                `WORD_DATA_W'hd,  
                `MEM_OP_NOP,
                `WORD_DATA_W'hx,
                `REG_ADDR_W'h3,
                `ENABLE_,
                `EX_OUT_ALU,
                `WORD_DATA_W'hc
                );

            /******** ADDI r2, r0, 9  MEM Stage Test Output ********/
            ex_stage_tb(
                `WORD_DATA_W'hd,
                `ENABLE,
                `MEM_OP_NOP,
                `WORD_DATA_W'hx,
                `REG_ADDR_W'h2,
                `ENABLE_,
                `WORD_DATA_W'h9
                );

            /******** ADDI r1, r0, 4  WB Stage Test Output ********/
            mem_tb(
                `WORD_DATA_W'h9,
                `ENABLE,
                `REG_ADDR_W'h1,
                `ENABLE_,
                `WORD_DATA_W'h4
                );

            ctrl_tb(
                `DISABLE,                                 // if_stall
                `DISABLE,                                 // id_stall
                `DISABLE,                                 // ex_stall
                `DISABLE,                                 // mem_stall
                `DISABLE,                                 // if_flush
                `DISABLE,                                 // id_flush
                `DISABLE,                                 // ex_flush
                `DISABLE,                                 // mem_flush
                `WORD_DATA_W'h0,                          // new_pc
                `FWD_CTRL_NONE,                           // ra_fwd_ctrl
                `FWD_CTRL_NONE,                           // rb_fwd_ctrl
                `DISABLE,                                 // ex_ra_fwd_en
                `DISABLE                                  // ex_rb_fwd_en
                );
        end
        # STEP begin // WRITE_IC(second insn) & L2_WRITE_L1 (drq == `ENABLE)
            $display("\n========= Clock 12 ========");
            /******** SW   r2, r0(1028) ID Stage Test Output ********/
            if_tb(
                `WORD_DATA_W'h10,
                `WORD_DATA_W'h14,
                `WORD_DATA_W'h40202223,
                `ENABLE
                );

            /******** SW   r1, r0(1024) EX Stage Test Output ********/
            id_stage_tb(
                `ENABLE,
                `ALU_OP_ADD,
                `WORD_DATA_W'h0,
                `WORD_DATA_W'h400,
                `MEM_OP_SW,
                `WORD_DATA_W'h4,
                `REG_ADDR_W'h0,
                `DISABLE_,
                `EX_OUT_ALU,
                `WORD_DATA_W'h10
                );

            /******** ADDI r3, r0, 13  MEM Stage Test Output ********/
            ex_stage_tb(
                `WORD_DATA_W'h400,
                `ENABLE,
                `MEM_OP_NOP,
                `WORD_DATA_W'hx,
                `REG_ADDR_W'h3,
                `ENABLE_,
                `WORD_DATA_W'hd
                );

            /******** ADDI r2, r0, 9  WB Stage Test Output ********/
            mem_tb(
                `WORD_DATA_W'hd,
                `ENABLE,
                `REG_ADDR_W'h2,
                `ENABLE_,
                `WORD_DATA_W'h9
                );

            $display("WB Stage ...");

            ctrl_tb(
                `DISABLE,                                  // if_stall
                `DISABLE,                                  // id_stall
                `DISABLE,                                  // ex_stall
                `DISABLE,                                  // mem_stall
                `DISABLE,                                  // if_flush
                `DISABLE,                                  // id_flush
                `DISABLE,                                  // ex_flush
                `DISABLE,                                  // mem_flush
                `WORD_DATA_W'h0,                           // new_pc
                `FWD_CTRL_NONE,                            // ra_fwd_ctrl
                `FWD_CTRL_NONE,                            // rb_fwd_ctrl
                `DISABLE,                                  // ex_ra_fwd_en
                `DISABLE                                   // ex_rb_fwd_en
                );
        end
        # STEP begin // WRITE_IC(third insn) & DC_ACCESS(miss) & L2_IDLE (drq == `ENABLE)
            $display("\n========= Clock 13 ========");
            /******** LW    r4, r0(1024) ID Stage Test Output ********/
            if_tb(
                `WORD_DATA_W'h14,
                `WORD_DATA_W'h18,
                `WORD_DATA_W'h40002203,
                `ENABLE
                );
            /******** SW   r2, r0(1028) EX Stage Test Output ********/
            id_stage_tb(
                `ENABLE,
                `ALU_OP_ADD,
                `WORD_DATA_W'h0,
                `WORD_DATA_W'h404,
                `MEM_OP_SW,
                `WORD_DATA_W'h9,
                `REG_ADDR_W'h4,
                `DISABLE_,
                `EX_OUT_ALU,
                `WORD_DATA_W'h14
                );

            /******** SW   r1, r0(1024)  MEM Stage Test Output ********/
            ex_stage_tb(
                `WORD_DATA_W'h404,
                `ENABLE,
                `MEM_OP_SW,
                `WORD_DATA_W'h4,
                `REG_ADDR_W'h0,
                `DISABLE_,
                `WORD_DATA_W'h400
                );

            /******** ADDI r3, r0, 13  WB Stage Test Output ********/
            mem_tb(
                `WORD_DATA_W'h0,
                `ENABLE,
                `REG_ADDR_W'h3,
                `ENABLE_,
                `WORD_DATA_W'hd
                );

            $display("WB Stage ...");  

            ctrl_tb(
                `ENABLE,                                  // if_stall
                `ENABLE,                                  // id_stall
                `ENABLE,                                  // ex_stall
                `ENABLE,                                  // mem_stall
                `DISABLE,                                 // if_flush
                `DISABLE,                                 // id_flush
                `DISABLE,                                 // ex_flush
                `DISABLE,                                 // mem_flush
                `WORD_DATA_W'h0,                          // new_pc
                `FWD_CTRL_NONE,                           // ra_fwd_ctrl
                `FWD_CTRL_NONE,                           // rb_fwd_ctrl
                `DISABLE,                                 // ex_ra_fwd_en
                `DISABLE                                  // ex_rb_fwd_en
                );
            mem_rd = 512'bx;                              // addr = 1024
         end
        # STEP begin // IC_ACCESS(third insn) & DC_IDLE(miss) & ACCESS_L2 
            $display("\n========= Clock 14 ========"); 
            ctrl_tb(
                `ENABLE,                                  // if_stall
                `ENABLE,                                  // id_stall
                `ENABLE,                                  // ex_stall
                `ENABLE,                                  // mem_stall
                `DISABLE,                                 // if_flush
                `DISABLE,                                 // id_flush
                `DISABLE,                                 // ex_flush
                `DISABLE,                                 // mem_flush
                `WORD_DATA_W'h0,                          // new_pc
                `FWD_CTRL_NONE,                           // ra_fwd_ctrl
                `FWD_CTRL_NONE,                           // rb_fwd_ctrl
                `DISABLE,                                 // ex_ra_fwd_en
                `DISABLE                                  // ex_rb_fwd_en
                );
        end
        # STEP begin // IC_ACCESS(third insn) & DC_IDLE(miss) & ACCESS_L2 & MEM_IDLE
            $display("\n========= Clock 15 ========");  
            ctrl_tb(
                `ENABLE,                                  // if_stall
                `ENABLE,                                  // id_stall
                `ENABLE,                                  // ex_stall
                `ENABLE,                                  // mem_stall
                `DISABLE,                                 // if_flush
                `DISABLE,                                 // id_flush
                `DISABLE,                                 // ex_flush
                `DISABLE,                                 // mem_flush
                `WORD_DATA_W'h0,                          // new_pc
                `FWD_CTRL_NONE,                           // ra_fwd_ctrl
                `FWD_CTRL_NONE,                           // rb_fwd_ctrl
                `DISABLE,                                 // ex_ra_fwd_en
                `DISABLE                                  // ex_rb_fwd_en
                );           
        end
        # STEP begin // IC_ACCESS(third insn) & DC_IDLE(miss) & L2_IDLE & READ_MEM   
            $display("\n========= Clock 16 ========");  
            ctrl_tb(
                `ENABLE,                                  // if_stall
                `ENABLE,                                  // id_stall
                `ENABLE,                                  // ex_stall
                `ENABLE,                                  // mem_stall
                `DISABLE,                                 // if_flush
                `DISABLE,                                 // id_flush
                `DISABLE,                                 // ex_flush
                `DISABLE,                                 // mem_flush
                `WORD_DATA_W'h0,                          // new_pc
                `FWD_CTRL_NONE,                           // ra_fwd_ctrl
                `FWD_CTRL_NONE,                           // rb_fwd_ctrl
                `DISABLE,                                 // ex_ra_fwd_en
                `DISABLE                                  // ex_rb_fwd_en
                ); 
        end
        # STEP begin // IC_ACCESS(third insn) & ACCESS_L2(read_hit) & DC_IDLE(miss) && READ_MEM 
            $display("\n========= Clock 17 ========");
            ctrl_tb(
                `ENABLE,                                  // if_stall
                `ENABLE,                                  // id_stall
                `ENABLE,                                  // ex_stall
                `ENABLE,                                  // mem_stall
                `DISABLE,                                 // if_flush
                `DISABLE,                                 // id_flush
                `DISABLE,                                 // ex_flush
                `DISABLE,                                 // mem_flush
                `WORD_DATA_W'h0,                          // new_pc
                `FWD_CTRL_NONE,                           // ra_fwd_ctrl
                `FWD_CTRL_NONE,                           // rb_fwd_ctrl
                `DISABLE,                                 // ex_ra_fwd_en
                `DISABLE                                  // ex_rb_fwd_en
                ); 
        end
        # STEP begin // IC_ACCESS(third insn) & WRITE_IC & L2_WRITE_L1 & DC_IDLE & MEM_WRITE_L1_W
            $display("\n========= Clock 18 ========");
            ctrl_tb(
                `DISABLE,                                 // if_stall
                `DISABLE,                                 // id_stall
                `DISABLE,                                 // ex_stall
                `DISABLE,                                 // mem_stall
                `DISABLE,                                 // if_flush
                `DISABLE,                                 // id_flush
                `DISABLE,                                 // ex_flush
                `DISABLE,                                 // mem_flush
                `WORD_DATA_W'h0,                          // new_pc
                `FWD_CTRL_NONE,                           // ra_fwd_ctrl
                `FWD_CTRL_NONE,                           // rb_fwd_ctrl
                `DISABLE,                                 // ex_ra_fwd_en
                `DISABLE                                  // ex_rb_fwd_en
                );           
        end
        # STEP begin  // IC_ACCESS(third insn) & ACCESS_L2 & DC_ACCESS(write hit miss) & MEM_IDLE(first SW compelete) 
            $display("\n========= Clock 19 ========");
            l2_tag_ram_tb(   
                18'bx,                                    // read data of tag0
                18'bx,                                    // read data of tag1
                18'bx,                                    // read data of tag2
                18'bx,                                    // read data of tag3
                3'bx,                                     // read data of tag
                `ENABLE                                   // complete write from L2 to L1
                );
            l2_data_ram_tb(                
                512'hx,                                   // read data of cache_data0
                512'bx,                                   // read data of cache_data1
                512'bx,                                   // read data of cache_data2
                512'bx                                    // read data of cache_data3
                );
            dtag_ram_tb(
                21'b1_0000_0000_0000_0000_0000,           // read data of tag0
                21'bx,                                    // read data of tag1
                1'b1                                      // number of replacing block of tag next time
                );
            data_ram_tb(
                128'hx_00000004,                          // read data of cache_data0
                128'hx                                    // read data of cache_data1
                );
            /******** LW   r5, r0(1028) ID Stage Test Output ********/
            if_tb(
                `WORD_DATA_W'h18,
                `WORD_DATA_W'h1c,
                `WORD_DATA_W'h40402283,
                `ENABLE
                );
            /******** LW   r4, r0(1024) EX Stage Test Output ********/
            id_stage_tb( 
                `ENABLE,
                `ALU_OP_ADD,
                `WORD_DATA_W'h0,
                `WORD_DATA_W'h400,
                `MEM_OP_LW,
                `WORD_DATA_W'h0,
                `REG_ADDR_W'h4,
                `ENABLE_,
                `EX_OUT_ALU,
                `WORD_DATA_W'h18
                );
            /******** SW   r2, r0(1028)  MEM Stage Test Output ********/
            ex_stage_tb(
                `WORD_DATA_W'h400,
                `ENABLE,
                `MEM_OP_SW,
                `WORD_DATA_W'h9,
                `REG_ADDR_W'h4,
                `DISABLE_,
                `WORD_DATA_W'h404
                );
            /******** SW   r1, r0(1024)  WB Stage Test Output ********/
            mem_tb(
                `WORD_DATA_W'h0,
                `ENABLE,
                `REG_ADDR_W'h0,
                `DISABLE_,
                `WORD_DATA_W'h0
                );

            $display("WB Stage ...");

            ctrl_tb(
                `ENABLE,                                  // if_stall
                `ENABLE,                                  // id_stall
                `ENABLE,                                  // ex_stall
                `ENABLE,                                  // mem_stall
                `DISABLE,                                 // if_flush
                `DISABLE,                                 // id_flush
                `DISABLE,                                 // ex_flush
                `DISABLE,                                 // mem_flush
                `WORD_DATA_W'h0,                          // new_pc
                `FWD_CTRL_NONE,                           // ra_fwd_ctrl
                `FWD_CTRL_NONE,                           // rb_fwd_ctrl
                `DISABLE,                                 // ex_ra_fwd_en
                `DISABLE                                  // ex_rb_fwd_en
                ); 
        end
        # STEP begin // IC_ACCESS(third insn) & DC_IDLE 
            $display("\n========= Clock 20 ========");
             ctrl_tb(
                `DISABLE,                                  // if_stall
                `DISABLE,                                  // id_stall
                `DISABLE,                                  // ex_stall
                `DISABLE,                                  // mem_stall
                `DISABLE,                                 // if_flush
                `DISABLE,                                 // id_flush
                `DISABLE,                                 // ex_flush
                `DISABLE,                                 // mem_flush
                `WORD_DATA_W'h0,                          // new_pc
                `FWD_CTRL_NONE,                           // ra_fwd_ctrl
                `FWD_CTRL_NONE,                           // rb_fwd_ctrl
                `DISABLE,                                 // ex_ra_fwd_en
                `DISABLE                                  // ex_rb_fwd_en
                );
        end
        # STEP begin // DC_ACCESS(read hit) & IC_ACCESS(forth insn) 
            $display("\n========= Clock 21 ========");
            /******** ADD  r6, r4, r5 ID Stage Test Output ********/
            if_tb(
                `WORD_DATA_W'h1c,
                `WORD_DATA_W'h20,
                `WORD_DATA_W'h00520333,
                `ENABLE
                );

            /******** LW   r5, r0(1028) EX Stage Test Output ********/
            id_stage_tb( 
                `ENABLE,                        // id_en
                `ALU_OP_ADD,                    // id_alu_op
                `WORD_DATA_W'h0,                // id_alu_in_0
                `WORD_DATA_W'h404,              // id_alu_in_1
                `MEM_OP_LW,                     // id_mem_op
                `WORD_DATA_W'hx,                // id_mem_wr_data
                `REG_ADDR_W'h5,                 // id_dst_addr
                `ENABLE_,                       // id_gpr_we_
                `EX_OUT_ALU,                    // id_gpr_mux_ex
                `WORD_DATA_W'h1c                // id_gpr_wr_data 
                );

            /******** LW   r4, r0(1024)  MEM Stage Test Output ********/
            ex_stage_tb(
                `WORD_DATA_W'h404,
                `ENABLE,
                `MEM_OP_LW,
                `WORD_DATA_W'h0,
                `REG_ADDR_W'h4,
                `ENABLE_,
                `WORD_DATA_W'h400
                );

            /******** SW   r2, r0(1028)  WB Stage Test Output ********/
            mem_tb(
                `WORD_DATA_W'h4,      
                `ENABLE,
                `REG_ADDR_W'h4,
                `DISABLE_,
                `WORD_DATA_W'h0     
                );

            $display("WB Stage ...");

            ctrl_tb(
                `ENABLE,                                // if_stall
                `ENABLE,                               // id_stall
                `ENABLE,                               // ex_stall
                `ENABLE,                               // mem_stall
                `DISABLE,                               // if_flush
                `ENABLE,                                // id_flush
                `DISABLE,                               // ex_flush
                `DISABLE,                               // mem_flush
                `WORD_DATA_W'h0,                        // new_pc
                `FWD_CTRL_MEM,                          // ra_fwd_ctrl
                `FWD_CTRL_EX,                           // rb_fwd_ctrl
                `DISABLE,                               // ex_ra_fwd_en
                `DISABLE                                // ex_rb_fwd_en
                );

            dtag_ram_tb(
                21'b1_0000_0000_0000_0000_0000,           // read data of tag0
                21'bx,                                    // read data of tag1
                1'b1                                      // number of replacing block of tag next time
                );
            data_ram_tb(
                128'hx_00000009_00000004,                          // read data of cache_data0
                128'hx                                    // read data of cache_data1
                );
       end
        # STEP begin // DC_ACCESS(read hit) & IC_ACCESS(miss)  
            $display("\n========= Clock 22 ========");
            itag_ram_tb(
                21'bx,                                    // read data of tag0
                21'bx,                                    // read data of tag1
                1'bx                                      // number of replacing block of tag next time
                );
            idata_ram_tb(
                128'hx,                                   // read data of cache_data0
                128'hx                                    // read data of cache_data1
                );
            dtag_ram_tb(
                21'b1_0000_0000_0000_0000_0000,           // read data of tag0
                21'bx,                                    // read data of tag1
                1'b1                                      // number of replacing block of tag next time
                );
            data_ram_tb(
                128'hx00000009_00000004,                  // read data of cache_data0
                128'hx                                    // read data of cache_data1
                );       
        end
        # STEP begin // DC_ACCESS(read hit) & ACCESS_L2(read hit) & IC_ACCESS_L2 (read first)
            $display("\n========= Clock 23 ========"); 
            ctrl_tb(
                `ENABLE,                                // if_stall
                `DISABLE,                                // id_stall
                `DISABLE,                                // ex_stall
                `DISABLE,                                // mem_stall
                `DISABLE,                               // if_flush
                `ENABLE,                                // id_flush
                `DISABLE,                               // ex_flush
                `DISABLE,                               // mem_flush
                `WORD_DATA_W'h0,                        // new_pc
                `FWD_CTRL_MEM,                          // ra_fwd_ctrl
                `FWD_CTRL_EX,                           // rb_fwd_ctrl
                `DISABLE,                               // ex_ra_fwd_en
                `DISABLE                                // ex_rb_fwd_en
                );
            l2_tag_ram_tb(   
                18'b1_0000_0000_0000_0000_0,              // read data of tag0
                18'bx,                                    // read data of tag1
                18'bx,                                    // read data of tag2
                18'bx,                                    // read data of tag3
                3'bx11,                                   // read data of tag
                `DISABLE                                  // complete write from L2 to L1
                );
            l2_data_ram_tb(
                // read data of cache_data0
                512'hx00520333_00520333_00520333_00520333_00520333_40402283_40002203_40202223_40102023_00d00193_00900113_00400093,
                512'bx,                                   // read data of cache_data1
                512'bx,                                   // read data of cache_data2
                512'bx                                    // read data of cache_data3
                );
        end
        # STEP begin // DC_ACCESS(read hit) & ACCESS_L2(read hit) & WRITE_IC 
            $display("\n========= Clock 24 ========");          
            /******** ADD  r6, r4, r5 ID Stage Test Output ********/
            if_tb(
                `WORD_DATA_W'h1c,
                `WORD_DATA_W'h20,
                `WORD_DATA_W'h00520333,
                `ENABLE
                );
            /******** NOP             EX Stage Test Output ********/
            id_stage_tb( 
                `DISABLE,
                `ALU_OP_NOP,
                `WORD_DATA_W'h0,
                `WORD_DATA_W'h0,
                `MEM_OP_NOP,
                `WORD_DATA_W'h0,
                `REG_ADDR_W'h0,
                `DISABLE_,
                `EX_OUT_ALU,
                `WORD_DATA_W'h0
                );
            /******** LW   r5, r0(1028)  MEM Stage Test Output ********/
            ex_stage_tb(
                `WORD_DATA_W'h0,
                `ENABLE,
                `MEM_OP_LW,
                `WORD_DATA_W'hx,
                `REG_ADDR_W'h5,
                `ENABLE_,
                `WORD_DATA_W'h404
                );

            /******** LW   r4, r0(1024)  WB Stage Test Output ********/
            mem_tb(
                `WORD_DATA_W'h9,
                `ENABLE,
                `REG_ADDR_W'h4,
                `ENABLE_,
                `WORD_DATA_W'h4
                );

            $display("WB Stage ..."); 

            dtag_ram_tb(
                21'b1_0000_0000_0000_0000_0000,           // read data of tag0
                21'bx,                                    // read data of tag1
                1'b1                                      // number of replacing block of tag next time
                );
            data_ram_tb(
                128'hx00000009_00000004,                  // read data of cache_data0
                128'hx                                    // read data of cache_data1
                );
            itag_ram_tb(
                21'bx,                                    // read data of tag0
                21'bx,                                    // read data of tag1
                1'bx                                      // number of replacing block of tag next time
                );
            idata_ram_tb(
                128'hx,                                   // read data of cache_data0
                128'hx                                    // read data of cache_data1
                );
            ctrl_tb(
                `DISABLE,                                 // if_stall
                `DISABLE,                                 // id_stall
                `DISABLE,                                 // ex_stall
                `DISABLE,                                 // mem_stall
                `DISABLE,                                 // if_flush
                `DISABLE,                                 // id_flush
                `DISABLE,                                 // ex_flush
                `DISABLE,                                 // mem_flush
                `WORD_DATA_W'h0,                          // new_pc
                `FWD_CTRL_NONE,                           // ra_fwd_ctrl
                `FWD_CTRL_MEM,                            // rb_fwd_ctrl
                `DISABLE,                                 // ex_ra_fwd_en
                `DISABLE                                  // ex_rb_fwd_en
               );       
            $stop;
        end
    end
endmodule
