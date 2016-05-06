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
    reg    [511:0]         mem_rd;
    wire   [511:0]         mem_wd;
    wire   [25:0]          mem_addr;      // address of memory
    wire                   mem_rw;        // read / write signal of memory
    /********** memory part **********/
    wire                   mem_complete;
    /**********  Pipeline  Register **********/
    // IF/ID
    wire [`WORD_DATA_BUS]  if_pc;          // Next Program count
    wire [`WORD_DATA_BUS]  pc;             // Current Program count
    wire [`WORD_DATA_BUS]  if_insn;        // Instruction
    wire                   if_en;          // Pipeline data enable
    // ID/EX Pipeline  Register
    wire [1:0]             src_reg_used;
    // wire [`WORD_DATA_BUS]  id_pc;          // Program count
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
    wire [27:0]            l2_addr_ic;  
    wire [27:0]            l2_addr_dc; 
    wire                   l2_cache_rw_ic;
    wire                   l2_cache_rw_dc;
    wire                   irq;
    wire                   drq;
    wire                   ic_rw_en;         // write enable signal
    wire                   dc_rw_en;
    wire [127:0]           data_wd_l2;       // write data to L1 from L2
    wire                   data_wd_l2_en;    // enable signal of writing data to L1 from L2
    wire                   data_wd_dc_en;    // enable signal of writing data to L1 from L2
    wire [127:0]           rd_to_l2;
    wire [17:0]            l2_tag_wd;        // write data of tag
    wire                   l2_rdy;           // ready mark of L2C
    wire                   ic_en;            
    wire                   dc_en;            
    wire [8:0]             l2_index;
    wire [1:0]             l2_offset;
    /*icache part*/
    // tag_ram part
    wire [7:0]             index_ic;         // address of L1_cache
    wire [20:0]            tag0_rd_ic;       // read data of tag0
    wire [20:0]            tag1_rd_ic;       // read data of tag1
    wire [20:0]            tag_wd_ic; 
    wire                   lru_ic;           // read data of tag
    wire                   complete_ic;      // complete write from L2 to L1 
    // data_ram part
    wire [127:0]           data0_rd_ic;      // read data of cache_data0
    wire [127:0]           data1_rd_ic;      // read data of cache_data1
    wire                   block0_we_ic;     // write signal of block0
    wire                   block1_we_ic;     // write signal of block1
    wire                   block0_re_ic;     // read signal of block0
    wire                   block1_re_ic;     // read signal of block1
    // dcache
    wire [7:0]             index_dc;         // address of L1_cache
    wire [1:0]             offset; 
    wire                   tagcomp_hit;
    wire [31:0]            dc_wd;
    wire [20:0]            tag0_rd_dc;       // read data of tag0
    wire [20:0]            tag1_rd_dc;       // read data of tag1
    wire [20:0]            tag_wd_dc; 
    wire                   lru_dc;           // read data of tag
    wire                   complete_dc;      // complete write from L2 to L1 
    wire                   dirty0;
    wire                   dirty1;
    wire                   dirty_wd;
    wire                   block0_we;        // write signal of block0
    wire                   block1_we;        // write signal of block1
    wire                   block0_re;        // read signal of block0
    wire                   block1_re;        // read signal of block1
    // data_ram part
    wire [127:0]           data0_rd_dc;      // read data of cache_data0
    wire [127:0]           data1_rd_dc;      // read data of cache_data1
    // l2_cache
    wire                   l2_tagcomp_hit;
    // l2_tag_ram part
    wire [17:0]            l2_tag0_rd;       // read data of tag0
    wire [17:0]            l2_tag1_rd;       // read data of tag1
    wire [17:0]            l2_tag2_rd;       // read data of tag2
    wire [17:0]            l2_tag3_rd;       // read data of tag3
    wire [2:0]             plru;             // read data of tag
    wire                   l2_complete;      // complete write from MEM to L2
    // l2_data_ram
    wire                   wd_from_mem_en;   
    wire                   wd_from_l1_en;
    wire [511:0]           l2_data0_rd;       // read data of cache_data0
    wire [511:0]           l2_data1_rd;       // read data of cache_data1
    wire [511:0]           l2_data2_rd;       // read data of cache_data2
    wire [511:0]           l2_data3_rd;       // read data of cache_data3 
    // l2_dirty
    wire                   l2_dirty_wd;
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
        .miss_stall     (if_busy),          // the signal of stall caused by cache miss
        /* L1_cache part */
        .lru            (lru_ic),           // mark of replacing
        .tag0_rd        (tag0_rd_ic),       // read data of tag0
        .tag1_rd        (tag1_rd_ic),       // read data of tag1
        .data0_rd       (data0_rd_ic),      // read data of data0
        .data1_rd       (data1_rd_ic),      // read data of data1
        .data_wd_l2     (data_wd_l2),
        .tag_wd         (tag_wd_ic),        // write data of L1_tag
        .block0_we      (block0_we_ic),     // write signal of block0
        .block1_we      (block1_we_ic),     // write signal of block1
        .block0_re      (block0_re_ic),     // read signal of block0
        .block1_re      (block1_re_ic),     // read signal of block1
        .index          (index_ic),         // address of L1_cache
        /* l2_cache part */
        .ic_en          (ic_en),            // busy signal of l2_cache
        .l2_rdy         (l2_rdy),           // ready signal of l2_cache
        .mem_wr_ic_en   (mem_wr_ic_en),
        .complete       (complete_ic),      // complete op writing to L1
        .irq            (irq),
        .ic_rw_en       (ic_rw_en),         // write enable signal of icache      
        .l2_addr        (l2_addr_ic),        
        .l2_cache_rw    (l2_cache_rw_ic),
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
        .ex_out         (ex_out),           // Operating result

        .id_jump_taken  (id_jump_taken),

        .br_addr        (br_addr),
        .br_taken       (br_taken)
    );

    /********** MEM Stage **********/
    mem_stage mem_stage(
        /********** Clock & Reset *********/
        .clk            (clk),           // clock
        .reset          (rst),           // reset
        /**** Pipeline Control Signal *****/
        .stall          (mem_stall),     
        .flush          (mem_flush),  
        /************ Forward *************/
        .fwd_data       (mem_fwd_data),
        /************ CPU part ************/
        .miss_stall     (mem_busy),     // the signal of stall caused by cache miss
        /* L1_cache part */
        .lru            (lru_dc),       // mark of replacing
        .tag0_rd        (tag0_rd_dc),   // read data of tag0
        .tag1_rd        (tag1_rd_dc),   // read data of tag1
        .data0_rd       (data0_rd_dc),  // read data of data0
        .data1_rd       (data1_rd_dc),  // read data of data1
        .data_wd_l2     (data_wd_l2),
        .dirty0         (dirty0),            
        .dirty1         (dirty1),             
        .dirty_wd       (dirty_wd),                
        .block0_we      (block0_we),     // write signal of block0
        .block1_we      (block1_we),     // write signal of block1
        .block0_re      (block0_re),     // read signal of block0
        .block1_re      (block1_re),     // read signal of block1       
        .offset         (offset), 
        .tagcomp_hit    (tagcomp_hit),  
        .rd_to_l2       (rd_to_l2), 
        .tag_wd         (tag_wd_dc),     // write data of L1_tag
        .data_wd_dc_en  (data_wd_dc_en),
        .index          (index_dc),      // address of L1_cache
        .dc_wd          (dc_wd),
        /* l2_cache part */
        .dc_en          (dc_en),         // busy signal of l2_cache
        .l2_rdy         (l2_rdy),        // ready signal of l2_cache
        .mem_wr_dc_en   (mem_wr_dc_en), 
        .complete       (complete_dc),   // complete op writing to L1
        .l2_complete    (l2_complete),
        .drq            (drq),  
        .dc_rw_en       (dc_rw_en),    
        .l2_addr        (l2_addr_dc),     
        .l2_cache_rw    (l2_cache_rw_dc),        
        /********** EX/MEM Pipeline Register **********/
        .ex_en          (ex_en),         // busy signal of l2_cache
        .ex_mem_op      (ex_mem_op),     // ready signal of l2_cache
        // .id_mem_op      (id_mem_op),     // complete op writing to L1
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
    // l2_cache
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
        .complete_ic    (complete_ic),   // complete write from L2 to L1
        .complete_dc    (complete_dc),    
        .data_wd_l2     (data_wd_l2),    // write data to L1C       
        .data_wd_l2_en  (data_wd_l2_en), 
        .wd_from_mem_en (wd_from_mem_en),
        .wd_from_l1_en  (wd_from_l1_en),
        .mem_wr_dc_en   (mem_wr_dc_en), 
        .mem_wr_ic_en   (mem_wr_ic_en),
        /*l2_cache part*/
        .l2_complete    (l2_complete),   // complete write from MEM to L2
        .l2_rdy         (l2_rdy),
        .ic_en          (ic_en),         // busy signal of l2_cache
        .dc_en          (dc_en),         // busy signal of l2_cache
        // l2_tag part
        .plru           (plru),          // replace mark
        .l2_tag0_rd     (l2_tag0_rd),    // read data of tag0
        .l2_tag1_rd     (l2_tag1_rd),    // read data of tag1
        .l2_tag2_rd     (l2_tag2_rd),    // read data of tag2
        .l2_tag3_rd     (l2_tag3_rd),    // read data of tag3
        .l2_tag_wd      (l2_tag_wd),     // write data of tag0                
        // l2_data part
        .l2_data0_rd    (l2_data0_rd),   // read data of cache_data0
        .l2_data1_rd    (l2_data1_rd),   // read data of cache_data1
        .l2_data2_rd    (l2_data2_rd),   // read data of cache_data2
        .l2_data3_rd    (l2_data3_rd),   // read data of cache_data3
        // l2_tag part
        .l2_dirty_wd    (l2_dirty_wd),
        .l2_block0_we   (l2_block0_we),  // write signal of block0
        .l2_block1_we   (l2_block1_we),  // write signal of block1
        .l2_block2_we   (l2_block2_we),  // write signal of block2
        .l2_block3_we   (l2_block3_we),  // write signal of block3
        .l2_block0_re   (l2_block0_re),  // read signal of block0
        .l2_block1_re   (l2_block1_re),  // read signal of block1
        .l2_block2_re   (l2_block2_re),  // read signal of block2
        .l2_block3_re   (l2_block3_re),  // read signal of block3
        .l2_dirty0      (l2_dirty0),
        .l2_dirty1      (l2_dirty1),
        .l2_dirty2      (l2_dirty2), 
        .l2_dirty3      (l2_dirty3),         
        /*memory part*/
        .mem_complete   (mem_complete),
        .mem_rd         (mem_rd), 
        .mem_wd         (mem_wd), 
        .mem_addr       (mem_addr),       // address of memory
        .mem_rw         (mem_rw)          // read / write signal of memory
    );
     /********** Control Module **********/
    ctrl ctrl(
        /********* pipeline control signals ********/
        .rst            (rst),           // reset
        //  State of Pipeline
        .if_busy        (if_busy),        // IF busy mark // miss stall of if_stage
        .br_taken       (br_taken),       // branch hazard mark
        .mem_busy       (mem_busy),       // MEM busy mark // miss stall of mem_stage

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

        // Forward from EX stage

        /********** Forward Output **********/
        .ra_fwd_ctrl    (ra_fwd_ctrl),
        .rb_fwd_ctrl    (rb_fwd_ctrl),
        .ex_ra_fwd_en   (ex_ra_fwd_en),
        .ex_rb_fwd_en   (ex_rb_fwd_en)
        );
    /**********   Cache Ram   **********/
    mem mem(
        .clk        (clk),               // Clock
        .rst        (rst),               // Reset active low
        .rw         (mem_rw),
        .complete   (mem_complete)
      );
    dtag_ram dtag_ram(
        .clk            (clk),           // clock
        .index          (index_dc),      // address of cache
        .block0_we      (block0_we),     // write signal of block0
        .block1_we      (block1_we),     // write signal of block1
        .block0_re      (block0_re),     // read signal of block0
        .block1_re      (block1_re),     // read signal of block1
        .dirty_wd       (dirty_wd), 
        .tag_wd         (tag_wd_dc),     // write data of tag
        .tag0_rd        (tag0_rd_dc),    // read data of tag0
        .tag1_rd        (tag1_rd_dc),    // read data of tag1
        .dirty0         (dirty0),
        .dirty1         (dirty1),
        .lru            (lru_dc),        // read data of tag
        .complete       (complete_dc)    // complete write from L2 to L1
        );
    data_ram ddata_ram(
        .clk            (clk),           // clock
        .index          (index_dc),      // address of cache
        .tagcomp_hit    (tagcomp_hit),    
        .block0_we      (block0_we),     // write signal of block0
        .block1_we      (block1_we),     // write signal of block1
        .block0_re      (block0_re),     // read signal of block0
        .block1_re      (block1_re),     // read signal of block1
        .data_wd_l2     (data_wd_l2),    // write data of l2_cache
        .data_wd_l2_en  (data_wd_l2_en), // write data of l2_cache
        .data_wd_dc_en  (data_wd_dc_en), // write data of l2_cache
        .dc_wd          (dc_wd),
        .offset         (offset), 
        .data0_rd       (data0_rd_dc),   // read data of cache_data0
        .data1_rd       (data1_rd_dc)    // read data of cache_data1
    );
    itag_ram itag_ram(
        .clk            (clk),           // clock
        .block0_we      (block0_we_ic),  // write signal of block0
        .block1_we      (block1_we_ic),  // write signal of block1
        .block0_re      (block0_re_ic),  // read signal of block0
        .block1_re      (block1_re_ic),  // read signal of block1
        .index          (index_ic),      // address of cache
        .tag_wd         (tag_wd_ic),     // write data of tag
        .tag0_rd        (tag0_rd_ic),    // read data of tag0
        .tag1_rd        (tag1_rd_ic),    // read data of tag1
        .lru            (lru_ic),        // read data of tag
        .complete       (complete_ic)    // complete write from L2 to L1
        );
    idata_ram idata_ram(
        .clk            (clk),           // clock
        .block0_we      (block0_we_ic),  // write signal of block0
        .block1_we      (block1_we_ic),  // write signal of block1
        .block0_re      (block0_re_ic),  // read signal of block0
        .block1_re      (block1_re_ic),  // read signal of block1
        .index          (index_ic),      // address of cache__
        .data_wd_l2     (data_wd_l2),    // write data of l2_cache
        .data0_rd       (data0_rd_ic),   // read data of cache_data0
        .data1_rd       (data1_rd_ic)    // read data of cache_data1
    );
    l2_data_ram l2_data_ram(
        .clk            (clk),           // clock of L2C
        .l2_index       (l2_index),      // address of cache
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
        .rst            (rst),              // reset
        .l2_index       (l2_index),      // address of cache
        .l2_tag_wd      (l2_tag_wd),     // write data of tag
        .l2_block0_we   (l2_block0_we),  // write signal of block0
        .l2_block1_we   (l2_block1_we),  // write signal of block1
        .l2_block2_we   (l2_block2_we),  // write signal of block2
        .l2_block3_we   (l2_block3_we),  // write signal of block3
        .l2_block0_re   (l2_block0_re),  // read signal of block0
        .l2_block1_re   (l2_block1_re),  // read signal of block1
        .l2_block2_re   (l2_block2_re),  // read signal of block2
        .l2_block3_re   (l2_block3_re),  // read signal of block3
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
    /********** General purpose Register **********/
    gpr gpr (
        /********** Clock & Reset **********/
        .clk            (clk),              // Clock
        .reset          (rst),              // Asynchronous Reset
        /********** Read Port  0 **********/
        .rd_addr_0      (gpr_rd_addr_0),    // Read  address
        .rd_data_0      (gpr_rd_data_0),    // Read data
        /********** Read Port  1 **********/
        .rd_addr_1      (gpr_rd_addr_1),    // Read  address
        .rd_data_1      (gpr_rd_data_1),    // Read data
        /********** Write Port  **********/
        .we_            (mem_gpr_we_),      // Write enable
        .wr_addr        (mem_dst_addr),     // Write  address
        .wr_data        (mem_out)           //  Write data
    );

    task mem_stage_tb;
        input  [31:0]  _mem_out;       // read data of CPU
        input          _mem_busy;      // the signal of stall caused by cache miss   
        /* L1_cache part */
        input  [20:0]  _tag_wd_dc;     // write data of L1_tag
        input  [7:0]   _index_dc;      // address of L1_cache
        input  [127:0] _rd_to_l2;        
        /* l2_cache part */
        input          _drq;           // icache request
        input  [27:0]  _l2_addr_dc;
        // dirty
        input          _dirty_wd;
        input          _block0_we;
        input          _block1_we;

        begin 
            if( (mem_out     === _mem_out)           && 
                (mem_busy    === _mem_busy)          && 
                (tag_wd_dc   === _tag_wd_dc)         && 
                (index_dc    === _index_dc)          && 
                (drq         === _drq)               &&  
                (_l2_addr_dc === _l2_addr_dc)        && 
                (block0_we   === _block0_we)         && 
                (block1_we   === _block1_we)         && 
                (rd_to_l2    === _rd_to_l2)          && 
                (dirty_wd    === _dirty_wd)
               ) begin 
                 $display("mem_stage Test Succeeded !"); 
            end else begin 
                 $display("mem_stage Test Failed !"); 
            end 
            if (rd_to_l2   !== _rd_to_l2) begin
                $display("rd_to_l2:%h(excepted %h)",rd_to_l2,_rd_to_l2); 
            end
            if (block0_we  !== _block0_we) begin
                $display("block0_we:%h(excepted %h)",block0_we,_block0_we); 
            end
            if (block1_we  !== _block1_we) begin
                $display("block1_we:%h(excepted %h)",block1_we,_block1_we); 
            end
            if (mem_out    !== _mem_out) begin
                $display("mem_out:%h(excepted %h)",mem_out,_mem_out); 
            end
            if (mem_busy   !== _mem_busy) begin
                $display("mem_busy:%h(excepted %h)",mem_busy,_mem_busy); 
            end
            if (tag_wd_dc  !== _tag_wd_dc) begin
                $display("tag_wd_dc:%h(excepted %h)",tag_wd_dc,_tag_wd_dc); 
            end
            if (index_dc   !== _index_dc) begin
                $display("index_dc:%h(excepted %h)",index_dc,_index_dc); 
            end
            if (drq        !== _drq) begin
                $display("drq:%h(excepted %h)",drq,_drq); 
            end
            if (l2_addr_dc !== _l2_addr_dc) begin
                $display("l2_addr_dc:%h(excepted %h)",l2_addr_dc,_l2_addr_dc); 
            end
        end
    endtask 
    task l2_cache_ctrl_tb;
        input           _ic_en;              // L2C busy mark
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
            if( (ic_en         === _ic_en)          && 
                (dc_en         === _dc_en)          && 
                (data_wd_l2    === _data_wd_l2)     && 
                (l2_tag_wd     === _l2_tag_wd)      && 
                (l2_rdy        === _l2_rdy)         && 
                (l2_dirty_wd   === _l2_dirty_wd)    &&
                (l2_block0_we  === _l2_block0_we)   &&
                (l2_block1_we  === _l2_block1_we)   &&
                (l2_block2_we  === _l2_block2_we)   &&
                (l2_block3_we  === _l2_block3_we)   &&
                (mem_addr      === _mem_addr)       && 
                (mem_rw        === _mem_rw)  
               ) begin 
                 $display("l2_cache Test Succeeded !"); 
            end else begin 
                 $display("l2_cache Test Failed !"); 
            end 
            
            // check
            if(ic_en       !== _ic_en)     begin
                $display("ic_en Test Failed !"); 
            end
            if(dc_en       !== _dc_en)     begin
                $display("dc_en Test Failed !"); 
            end
            if(data_wd_l2    !== _data_wd_l2)     begin
                $display("data_wd_l2:%h(excepted %h)",data_wd_l2,_data_wd_l2); 
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
                $display("mem_addr:%h(excepted %h)",mem_addr,_mem_addr); 
            end
            if(mem_rw        !== _mem_rw) begin
                $display("mem_rw Test Failed !"); 
            end 
        end
    endtask
    task dtag_ram_tb;
        input      [20:0]  _tag0_rd_dc;        // read data of tag0
        input      [20:0]  _tag1_rd_dc;        // read data of tag1
        input              _lru_dc;            // read block of tag
        input              _complete_dc;       // complete_dc write from L2 to L1
        begin 
            if( (tag0_rd_dc  === _tag0_rd_dc)     && 
                (tag1_rd_dc  === _tag1_rd_dc)     && 
                (lru_dc      === _lru_dc)         && 
                (complete_dc === _complete_dc)              
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
            if (complete_dc !== _complete_dc) begin
                $display("complete_dc:%h(excepted %h)",complete_dc,_complete_dc); 
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
                (l2_complete === _l2_complete)
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
                $display("plru:%h(excepted %h)",plru,_plru); 
            end
            if (l2_complete !== _l2_complete) begin
                $display("l2_complete:%h(excepted %h)",l2_complete,_l2_complete); 
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
    task if_stage_tb;
        input  [`WORD_DATA_BUS] _if_insn;         // read data of CPU
        input                   _if_busy;         // the signal of stall caused by cache miss
        /* L1_cache part */
        input                   _block0_we_ic;    // read / write signal of L1_block0
        input                   _block1_we_ic;    // read / write signal of L1_block1
        input  [20:0]           _tag_wd_ic;       // write data of L1_tag
        input  [7:0]            _index_ic;        // address of L1_cache
        /* l2_cache part */
        input                   _irq;             // icache request
        input  [27:0]           _l2_addr_ic;
        input  [`WORD_DATA_BUS] _pc;
        input                   _if_en; 
        begin 
            if( (if_insn    === _if_insn)           && 
                (if_busy === _if_busy)              && 
                (block0_we_ic  === _block0_we_ic)   && 
                (block1_we_ic  === _block1_we_ic)   && 
                (tag_wd_ic     === _tag_wd_ic)      && 
                (index_ic      === _index_ic)       && 
                (irq        === _irq)               && 
                (l2_addr_ic  === _l2_addr_ic)       && 
                (pc         === _pc)                && 
                (if_en      === _if_en)    
               ) begin 
                 $display("if_stage Test Succeeded !"); 
            end else begin 
                 $display("if_stage Test Failed !"); 
            end 
            if (pc   !== _pc) begin
                $display("pc:%h(excepted %h)",pc,_pc); 
            end
            if (if_en !== _if_en) begin
                $display("if_en:%h(excepted %h)",if_en,_if_en); 
            end
            if (if_insn   !== _if_insn) begin
                $display("if_insn:%h(excepted %h)",if_insn,_if_insn); 
            end
            if (if_busy !== _if_busy) begin
                $display("if_busy:%h(excepted %h)",if_busy,_if_busy); 
            end
            if (block0_we_ic  !== _block0_we_ic) begin
                $display("block0_we_ic:%h(excepted %h)",block0_we_ic,_block0_we_ic); 
            end
            if (block1_we_ic  !== _block1_we_ic) begin
                $display("block1_we_ic:%h(excepted %h)",block1_we_ic,_block1_we_ic); 
            end
            if (tag_wd_ic     !== _tag_wd_ic) begin
                $display("tag_wd_ic:%h(excepted %h)",tag_wd_ic,_tag_wd_ic); 
            end
            if (index_ic      !== _index_ic) begin
                $display("index_ic:%h(excepted %h)",index_ic,_index_ic); 
            end
            if (irq   !== _irq) begin
                $display("irq:%h(excepted %h)",irq,_irq); 
            end
            if (l2_addr_ic !== _l2_addr_ic) begin
                $display("l2_addr_ic:%h(excepted %h)",l2_addr_ic,_l2_addr_ic); 
            end
        end
    endtask 
    task itag_ram_tb;
        input      [20:0]  _tag0_rd_ic;        // read data of tag0
        input      [20:0]  _tag1_rd_ic;        // read data of tag1
        input              _lru_ic;            // read block of tag
        input              _complete_ic;    // complete_ic write from L2 to L1
        begin 
            if( (tag0_rd_ic  === _tag0_rd_ic)     && 
                (tag1_rd_ic  === _tag1_rd_ic)     && 
                (lru_ic      === _lru_ic)         && 
                (complete_ic === _complete_ic)              
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
            if (complete_ic !== _complete_ic) begin
                $display("complete_ic:%h(excepted %h)",complete_ic,_complete_ic); 
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
            if (pc   !== _pc) begin
                $display("pc:%h(excepted %h)",pc,_pc); 
            end
            if (if_pc !== _if_pc) begin
                $display("if_pc:%h(excepted %h)",if_pc,_if_pc); 
            end
            if (if_insn   !== _if_insn) begin
                $display("if_insn:%h(excepted %h)",if_insn,_if_insn); 
            end
            if (if_en !== _if_en) begin
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
            mem_rd   <= 512'hx00520333_00520333_00520333_00520333_00520333_40402283_40002203_40202223_40102023_00d00193_00900113_00400093;
        end
        #(STEP * 3/4)
        #STEP begin
            rst     <= `DISABLE;
        end
        #STEP begin // L1_ACCESS & L2_IDLE 
            $display("\n========= Clock 1 ========");
            if_stage_tb(
                32'b0,                                   // read data of CPU
                `ENABLE,                                 // the signal of stall caused by cache miss
                1'bx,                                    // write signal of L1_tag0
                1'bx,                                    // write signal of L1_tag1
                21'b1_0000_0000_0000_0000_0000,          // write data of L1_tag
                8'b0,                                    // address of L1_cache
                `ENABLE,                                 // irq
                28'b0,                                   // l2_addr
                32'b0,                                   // pc
                `DISABLE                                 // if_en
                );
            l2_cache_ctrl_tb(             
                `ENABLE,                                 // ic_en
                1'bx,                                    // dc_en
                128'bx,                                  // write data to L1_IC
                18'b1_0000_0000_0000_0000_0,             // write data of tag
                1'bx,                                    // ready signal of l2_cache
                1'bx,                                    // l2_dirty_wd
                1'bx,                                    // write signal of cache_data0 
                1'bx,                                    // write signal of cache_data1 
                1'bx,                                    // write signal of cache_data2 
                1'bx,                                    // write signal of cache_data3                 
                26'bx,                                   // address of memory
                1'bx                                     // read / write signal of memory                
                );  
        end
        #STEP begin // IC_ACCESS_L2 & ACCESS_L2 
            $display("\n========= Clock 2 ========");
            l2_cache_ctrl_tb(             
                `ENABLE,                                  // ic_en
                1'bx,                                     // dc_en
                128'h40102023_00d00193_00900113_00400093, // write data to L1_IC
                18'b1_0000_0000_0000_0000_0,              // write data of tag
                1'bx,                                     // ready signal of l2_cache
                1'b0,                                     // l2_dirty_wd
                `ENABLE,                                  // the mark of cache_data0 write signal 
                1'bx,                                     // the mark of cache_data1 write signal 
                1'bx,                                     // the mark of cache_data2 write signal 
                1'bx,                                     // the mark of cache_data3 write signal 
                26'b0,                                    // address of memory
                `READ                                     // read / write signal of memory                
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
                512'hx,                                   // read data of cache_data0
                512'bx,                                   // read data of cache_data1
                512'bx,                                   // read data of cache_data2
                512'bx                                    // read data of cache_data3
             );
            if_stage_tb(
                32'b0,                                    // read data of CPU
                `DISABLE,                                 // the signal of stall caused by cache miss
                `ENABLE,                                  // read / write signal of L1_tag0
                1'bx,                                     // read / write signal of L1_tag1     
                21'b1_0000_0000_0000_0000_0000,           // write data of L1_tag   
                8'b0,                                     // address of L1_cache
                `ENABLE,                                  // icache request
                28'b0,
                32'b0,
                `DISABLE
                );
            itag_ram_tb(
                21'bx,                                    // read data of tag0
                21'bx,                                    // read data of tag1
                1'bx,                                     // number of replacing block of tag next time
                1'b0                                      // complete write from L2 to L1
                );
            idata_ram_tb(
                128'hx,                                   // read data of cache_data0
                128'hx                                    // read data of cache_data1
                ); 
        end           
        #STEP begin // WRITE_IC & WRITE_TO_L2_CLEAN & access l2_ram
            $display("\n========= Clock 3 ========");
            if_stage_tb(
                32'h00400093,                             // read data of CPU
                `DISABLE,                                 // the signal of stall caused by cache miss
                `DISABLE,                                 // read / write signal of L1_tag0
                `DISABLE,                                 // read / write signal of L1_tag1
                21'b1_0000_0000_0000_0000_0000,           // write data of L1_tag
                8'b0000_0000,                             // address of L1_cache
                `DISABLE,                                 // icache request
                28'b0,
                32'b0,
                `ENABLE
                );
            itag_ram_tb(
                21'b1_0000_0000_0000_0000_0000,           // read data of tag0
                21'bx,                                    // read data of tag1
                1'b1,                                     // number of replacing block of tag next time
                1'b1                                      // complete write from L2 to L1
                );
            idata_ram_tb(
                128'h40102023_00d00193_00900113_00400093, // read data of cache_data0
                128'hx                                    // read data of cache_data1
                ); 
            l2_tag_ram_tb(   
                18'b1_0000_0000_0000_0000_0,              // read data of tag0
                18'bx,                                    // read data of tag1
                18'bx,                                    // read data of tag2
                18'bx,                                    // read data of tag3
                3'bx11,                                   // read data of tag
                `ENABLE                                   // complete write from L2 to L1
                );
            l2_data_ram_tb(
                // read data of cache_data0
                512'hx00520333_00520333_00520333_00520333_00520333_40402283_40002203_40202223_40102023_00d00193_00900113_00400093,
                512'bx,                                   // read data of cache_data1
                512'bx,                                   // read data of cache_data2
                512'bx                                    // read data of cache_data3
                );
            l2_cache_ctrl_tb(         
                `DISABLE,                                 // ic_en
                `DISABLE,                                 // dc_en
                128'h40102023_00d00193_00900113_00400093, // write data to L1_IC
                18'b1_0000_0000_0000_0000_0,              // write data of tag
                1'bx,                                     // ready signal of l2_cache
                1'b0,
                `DISABLE,                                 // the mark of cache_data0 write signal 
                `DISABLE,                                 // the mark of cache_data1 write signal 
                `DISABLE,                                 // the mark of cache_data2 write signal 
                `DISABLE,                                 // the mark of cache_data3 write signal                 
                26'b0,                                    // address of memory
                `READ                                     // read / write signal of memory                
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
        #STEP begin // IC_ACCESS(READ HIT third insn) & l2_IDLE & access l2_ram
            $display("\n========= Clock 4 ========");            
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
            if_stage_tb(
                32'h00900113,                             // if_insn
                `DISABLE,                                 // the signal of stall caused by cache miss
                `DISABLE,                                 // read / write signal of L1_tag0
                `DISABLE,                                 // read / write signal of L1_tag1
                21'b1_0000_0000_0000_0000_0000,           // write data of L1_tag
                8'b0,                                     // address of L1_cache
                `DISABLE,                                 // icache request
                28'b0,                                    // l2_addr
                32'b100,                                  // pc
                `ENABLE        
                );
            l2_cache_ctrl_tb(         
                `DISABLE,                                 // ic_en
                `DISABLE,                                 // dc_en
                128'h40102023_00d00193_00900113_00400093, // write data to L1_IC
                18'b1_0000_0000_0000_0000_0,              // write data of tag
                1'bx,                                     // ready signal of l2_cache
                1'b0,
                `DISABLE,                                 // the mark of cache_data0 write signal 
                `DISABLE,                                 // the mark of cache_data1 write signal 
                `DISABLE,                                 // the mark of cache_data2 write signal 
                `DISABLE,                                 // the mark of cache_data3 write signal 
                26'b0,                                    // address of memory
                `READ                                     // read / write signal of memory                
                );  
            /******** ADDI r2 r0, 9 IF Stage Test Output ********/
            if_tb(
                `WORD_DATA_W'h4,                          // pc
                `WORD_DATA_W'h8,                          // if_pc
                `WORD_DATA_W'h00900113,                   // if_insn
                `ENABLE                                   // if_en
                );
            /******** ADDI r1, r0, 4 ID Stage Test Output ********/
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
            $display("\n========= Clock 5 ========");
            /******** ADDI r3 r0, 13 IF Stage Test Output ********/
            if_tb(
                `WORD_DATA_W'h8,                          // if_pc
                `WORD_DATA_W'hc,                          // if_pc_plus4
                `WORD_DATA_W'hd00193,                     // if_insn
                `ENABLE
                );

            /********ADDI r2 r0, 9  ID Stage Test Output ********/
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

            /******** ADDI r1, r0, 4 EX Stage Test Output ********/
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
            $display("\n========= Clock 6 ========");
            /******** SW   r1, r0(1024) IF Stage Test Output ********/
            if_tb(
                `WORD_DATA_W'hc,
                `WORD_DATA_W'h10,
                `WORD_DATA_W'h40102023,
                `ENABLE
                );

            /******** ADDI r3, r0, 13 ID Stage Test Output ********/
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

            /******** ADDI r2, r0, 9  EX Stage Test Output ********/
            ex_stage_tb(
                `WORD_DATA_W'hd,
                `ENABLE,
                `MEM_OP_NOP,
                `WORD_DATA_W'hx,
                `REG_ADDR_W'h2,
                `ENABLE_,
                `WORD_DATA_W'h9
                );

            /******** ADDI r1, r0, 4  MEM Stage Test Output ********/
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
            if_stage_tb(
                32'h40102023,                             // if_insn
                `ENABLE,                                  // miss
                `DISABLE,                                 // write signal of L1_tag0
                `DISABLE,                                 // write signal of L1_tag1
                21'b1_0000_0000_0000_0000_0000,           // write data of L1_tag
                8'b1,                                     // address of L1_cache
                `ENABLE,                                  // irq
                28'b1,                                    // l2_addr
                `WORD_DATA_W'hc,                          // pc
                `ENABLE        
                );
            l2_cache_ctrl_tb(         
                `ENABLE,                                  // ic_en
                `DISABLE,                                 // dc_en
                128'h40102023_00d00193_00900113_00400093, // write data to L1_IC
                18'b1_0000_0000_0000_0000_0,              // write data of tag
                1'bx,                                     // ready signal of l2_cache
                1'b0,
                `DISABLE,                                 // write mark of cache_data0 
                `DISABLE,                                 // write mark of cache_data1 
                `DISABLE,                                 // write mark of cache_data2 
                `DISABLE,                                 // write mark of cache_data3 
                26'b0,                                    // address of memory
                `READ                                     // read / write signal of memory                
                );  
        end
        # STEP begin // IC_ACCESS_L2(first insn) & ACCESS_L2(read hit) 
            $display("\n========= Clock 7 ========");
            /******** SW   r1, r0(1024) IF Stage Test Output ********/
            if_tb(
                `WORD_DATA_W'hc,
                `WORD_DATA_W'h10,
                `WORD_DATA_W'h40102023,
                `ENABLE
                );

            /******** ADDI r3, r0, 13 ID Stage Test Output ********/
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

            /******** ADDI r2, r0, 9  EX Stage Test Output ********/
            ex_stage_tb(
                `WORD_DATA_W'hd,
                `ENABLE,
                `MEM_OP_NOP,
                `WORD_DATA_W'hx,
                `REG_ADDR_W'h2,
                `ENABLE_,
                `WORD_DATA_W'h9
                );

            /******** ADDI r1, r0, 4  MEM Stage Test Output ********/
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
            if_stage_tb(
                32'h40102023,                             // if_insn
                `DISABLE,                                 // miss
                `ENABLE,                                  // write signal of L1_tag0
                `DISABLE,                                 // write signal of L1_tag1
                21'b1_0000_0000_0000_0000_0000,           // write data of L1_tag
                8'b1,                                     // address of L1_cache
                `ENABLE,                                  // irq
                28'b1,                                    // l2_addr
                `WORD_DATA_W'hc,                          // pc
                `ENABLE        
                );
            l2_cache_ctrl_tb(         
                `ENABLE,                                  // ic_en
                `DISABLE,                                 // dc_en
                128'h00520333_40402283_40002203_40202223, // write data to L1_IC
                18'b1_0000_0000_0000_0000_0,              // write data of tag
                `ENABLE,                                  // ready signal of l2_cache
                1'b0,
                `DISABLE,                                 // write mark of cache_data0 
                `DISABLE,                                 // write mark of cache_data1 
                `DISABLE,                                 // write mark of cache_data2 
                `DISABLE,                                 // write mark of cache_data3                 
                26'b0,                                    // address of memory
                `READ                                     // read / write signal of memory                
                );
        end
        # STEP begin
            $display("\n========= Clock 8 ========");
            /******** SW   r2, r0(1028) IF Stage Test Output ********/
            if_tb(
                `WORD_DATA_W'h10,
                `WORD_DATA_W'h14,
                `WORD_DATA_W'h40202223,
                `ENABLE
                );

            /******** SW   r1, r0(1024) ID Stage Test Output ********/
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

            /******** ADDI r3, r0, 13  EX Stage Test Output ********/
            ex_stage_tb(
                `WORD_DATA_W'h400,
                `ENABLE,
                `MEM_OP_NOP,
                `WORD_DATA_W'hx,
                `REG_ADDR_W'h3,
                `ENABLE_,
                `WORD_DATA_W'hd
                );

            /******** ADDI r2, r0, 9  MEM Stage Test Output ********/
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
        # STEP begin  
            $display("\n========= Clock 9 ========");
            /******** LW    r4, r0(1024) IF Stage Test Output ********/
            if_tb(
                `WORD_DATA_W'h14,
                `WORD_DATA_W'h18,
                `WORD_DATA_W'h40002203,
                `ENABLE
                );

            /******** SW   r2, r0(1028) ID Stage Test Output ********/
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

            /******** SW   r1, r0(1024)  EX Stage Test Output ********/
            ex_stage_tb(
                `WORD_DATA_W'h404,
                `ENABLE,
                `MEM_OP_SW,
                `WORD_DATA_W'h4,
                `REG_ADDR_W'h0,
                `DISABLE_,
                `WORD_DATA_W'h400
                );

            /******** ADDI r3, r0, 13  MEM Stage Test Output ********/
            mem_tb(
                `WORD_DATA_W'h0,
                `ENABLE,
                `REG_ADDR_W'h3,
                `ENABLE_,
                `WORD_DATA_W'hd
                );

            $display("WB Stage ...");           

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
        # STEP begin  // IC_ACCESS & DC_ACCESS & L2_IDLE (drq == `ENABLE)
            $display("\n========= Clock 10 ========");
            /******** LW   r5, r0(1028) IF Stage Test Output ********/
            if_tb(`WORD_DATA_W'h18,
                  `WORD_DATA_W'h1c,
                  `WORD_DATA_W'h40402283,
                  `ENABLE
                 );

            /******** LW   r4, r0(1024) ID Stage Test Output ********/
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

            /******** SW   r2, r0(1028)  EX Stage Test Output ********/
            ex_stage_tb(`WORD_DATA_W'h400,
                  `ENABLE,
                  `MEM_OP_SW,
                  `WORD_DATA_W'h9,
                  `REG_ADDR_W'h4,
                  `DISABLE_,
                  `WORD_DATA_W'h404
                 );

            /******** SW   r1, r0(1024)  MEM Stage Test Output ********/
            mem_tb(`WORD_DATA_W'h0,
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
            mem_rd = 512'bx;                              // addr = 1024
        end
        # STEP begin // IC_ACCESS(miss) & DC_ACCESS_L2(miss) & ACCESS_L2 
            $display("\n========= Clock 11 ========");
            if_stage_tb(
                32'h40402283,                             // if_insn
                `DISABLE,                                 // miss
                `DISABLE,                                 // write signal of L1_tag0
                `DISABLE,                                 // write signal of L1_tag1
                21'b1_0000_0000_0000_0000_0000,           // write data of L1_tag
                8'b1,                                     // address of L1_cache
                `DISABLE,                                 // irq
                28'b1,                                    // l2_addr
                `WORD_DATA_W'b11000,                      // pc
                `ENABLE        
                );
            l2_cache_ctrl_tb(         
                `DISABLE,                                 // ic_en
                `ENABLE,                                  // dc_en
                128'hx,                                   // write data to L1_IC
                18'b1_0000_0000_0000_0000_0,              // write data of tag
                `DISABLE,                                 // ready signal of l2_cache
                1'b0,
                `ENABLE,                                  // write mark of cache_data0 
                `DISABLE,                                 // write mark of cache_data1 
                `DISABLE,                                 // write mark of cache_data2 
                `DISABLE,                                 // write mark of cache_data3                 
                26'h10,                                   // address of memory
                `READ                                     // read / write signal of memory                
                );
            mem_stage_tb(
                32'h0,                                    // read data of CPU
                `ENABLE,                                  // the signal of stall caused by cache miss
                21'b1_0000_0000_0000_0000_0000,           // write data of L1_tag
                8'b0100_0000,                             // address of L1_cache
                128'hx,                                   // data_rd choosing from data_rd1~data_rd3
                `ENABLE,                                  // drq
                28'h40,                                   // l2_addr
                1'b0,                                     // dirty_wd
                `WRITE,                                   // dirty0_rw
                1'bx                                      // dirty1_rw
                );
        end  
        # STEP begin // IC_ACCESS_L2 & WRITE_DC_W & WRITE_TO_L2_CLEAN 
            $display("\n========= Clock 12 ========");
            l2_cache_ctrl_tb(         
                `DISABLE,                                 // ic_en
                `ENABLE,                                  // dc_en
                128'hx,                                   // write data to L1_IC
                18'b1_0000_0000_0000_0000_0,              // write data of tag
                `DISABLE,                                 // ready signal of l2_cache
                1'b0,
                `ENABLE,                                  // write mark of cache_data0 
                `DISABLE,                                 // write mark of cache_data1 
                `DISABLE,                                 // write mark of cache_data2 
                `DISABLE,                                 // write mark of cache_data3                 
                26'h10,                                   // address of memory
                `READ                                     // read / write signal of memory                
                );
            mem_stage_tb(
                32'b0,                                    // read data of CPU
                `ENABLE,                                  // the signal of stall caused by cache miss
                21'b1_0000_0000_0000_0000_0000,           // write data of L1_tag
                8'b0100_0000,                             // address of L1_cache
                128'hx,                                   // data_rd choosing from data_rd1~data_rd3
                `DISABLE,                                 // drq
                28'h40,                                   // l2_addr
                1'b1,                                     // dirty_wd
                `ENABLE,                                  // block0_we
                `DISABLE                                  // block1_we
                );
            dtag_ram_tb(
                21'b1_0000_0000_0000_0000_0000,           // read data of tag0
                21'bx,                                    // read data of tag1
                1'b1,                                     // number of replacing block of tag next time
                1'b1                                      // complete write from L2 to L1
                );
            data_ram_tb(
                128'hx,                                   // read data of cache_data0
                128'hx                                    // read data of cache_data1
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
        #STEP begin // WRITE_HIT(DC) & WRITE_TO_L2_CLEAN & (IC_IDEL MISS)
            $display("\n========= Clock 13 ========");    
            l2_tag_ram_tb(   
                18'b1_0000_0000_0000_0000_0,              // read data of tag0
                18'bx,                                    // read data of tag1
                18'bx,                                    // read data of tag2
                18'bx,                                    // read data of tag3
                3'bx11,                                   // read data of tag
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
                1'b1,                                     // number of replacing block of tag next time
                1'b1                                      // complete write from L2 to L1
                );
            data_ram_tb(
                128'hx_00000004,                          // read data of cache_data0
                128'hx                                    // read data of cache_data1
                );
            l2_cache_ctrl_tb(         
                `DISABLE,                                 // ic_en
                `DISABLE,                                 // dc_en
                128'hx,                                   // write data to L1_IC
                18'b1_0000_0000_0000_0000_0,              // write data of tag
                `DISABLE,                                 // ready signal of l2_cache
                1'b0,
                `DISABLE,                                 // write mark of cache_data0 
                `DISABLE,                                 // write mark of cache_data1 
                `DISABLE,                                 // write mark of cache_data2 
                `DISABLE,                                 // write mark of cache_data3                 
                26'h10,                                   // address of memory
                `READ                                     // read / write signal of memory                
                );
            mem_stage_tb(
                32'b0,                                    // read data of CPU
                `DISABLE,                                 // the signal of stall caused by cache miss
                21'b1_0000_0000_0000_0000_0000,           // write data of L1_tag
                8'b0100_0000,                             // address of L1_cache
                128'hx,                                   // data_rd choosing from data_rd1~data_rd3
                `DISABLE,                                 // drq
                28'h40,                                   // l2_addr
                1'b1,                                     // dirty_wd
                `DISABLE,                                 // block0_we
                `DISABLE                                  // block1_we
                );

            ctrl_tb(
                `DISABLE,                               // if_stall
                `DISABLE,                               // id_stall
                `DISABLE,                               // ex_stall
                `DISABLE,                               // mem_stall
                `DISABLE,                               // if_flush
                `DISABLE,                               // id_flush
                `DISABLE,                               // ex_flush
                `DISABLE,                               // mem_flush
                `WORD_DATA_W'h0,                        // new_pc
                `FWD_CTRL_NONE,                         // ra_fwd_ctrl
                `FWD_CTRL_NONE,                         // rb_fwd_ctrl
                `DISABLE,                               // ex_ra_fwd_en
                `DISABLE                                // ex_rb_fwd_en
                );
            /******** LW   r5, r0(1028) IF Stage Test Output ********/
            if_tb(
                `WORD_DATA_W'h18,
                `WORD_DATA_W'h1c,
                `WORD_DATA_W'h40402283,
                `ENABLE
                );

            /******** LW   r4, r0(1024) ID Stage Test Output ********/
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

            /******** SW   r2, r0(1028)  EX Stage Test Output ********/
            ex_stage_tb(
                `WORD_DATA_W'h400,
                `ENABLE,
                `MEM_OP_SW,
                `WORD_DATA_W'h9,
                `REG_ADDR_W'h4,
                `DISABLE_,
                `WORD_DATA_W'h404
                );

            /******** SW   r1, r0(1024)  MEM Stage Test Output ********/
            mem_tb(
                `WORD_DATA_W'h0,
                `ENABLE,
                `REG_ADDR_W'h0,
                `DISABLE_,
                `WORD_DATA_W'h0
                );
            mem_rd   <= 512'hx00520333_00520333_00520333_00520333_00520333_40402283_40002203_40202223_40102023_00d00193_00900113_00400093;
        end
        # STEP begin // DC_ACCESS(write hit) & ACCESS_L2 & IC_ACCESS (read miss)
            $display("\n========= Clock 14 ========");
            /******** ADD  r6, r4, r5 IF Stage Test Output ********/
            if_tb(
                `WORD_DATA_W'h1c,
                `WORD_DATA_W'h20,
                `WORD_DATA_W'h00520333,
                `ENABLE
                );

            /******** LW   r5, r0(1028) ID Stage Test Output ********/
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

            /******** LW   r4, r0(1024)  EX Stage Test Output ********/
            ex_stage_tb(
                `WORD_DATA_W'h404,
                `ENABLE,
                `MEM_OP_LW,
                `WORD_DATA_W'h0,
                `REG_ADDR_W'h4,
                `ENABLE_,
                `WORD_DATA_W'h400
                );

            /******** SW   r2, r0(1028)  MEM Stage Test Output ********/
            mem_tb(
                `WORD_DATA_W'hx,    
                `ENABLE,
                `REG_ADDR_W'h4,
                `DISABLE_,
                `WORD_DATA_W'h0     // 9
                );

            $display("WB Stage ...");

            ctrl_tb(
                `ENABLE,                                // if_stall
                `ENABLE,                                // id_stall
                `ENABLE,                                // ex_stall
                `ENABLE,                                // mem_stall
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
            if_stage_tb(
                32'h00520333,                             // if_insn
                `ENABLE,                                  // miss
                `DISABLE,                                 // write signal of L1_tag0
                `DISABLE,                                 // write signal of L1_tag1
                21'b1_0000_0000_0000_0000_0000,           // write data of L1_tag
                8'b10,                                    // address of L1_cache
                `ENABLE,                                  // irq
                28'b10,                                   // l2_addr
                `WORD_DATA_W'b11100,                      // pc
                `ENABLE        
                );
            l2_cache_ctrl_tb(         
                `ENABLE,                                  // ic_en
                `DISABLE,                                 // dc_en
                128'hx,                                   // write data to L1_IC
                18'b1_0000_0000_0000_0000_0,              // write data of tag
                `DISABLE,                                 // ready signal of l2_cache
                1'b0,
                `DISABLE,                                 // write mark of cache_data0 
                `DISABLE,                                 // write mark of cache_data1 
                `DISABLE,                                 // write mark of cache_data2 
                `DISABLE,                                 // write mark of cache_data3                 
                26'h10,                                   // address of memory
                `READ                                     // read / write signal of memory                
                );
            mem_stage_tb(
                32'b0,                                    // read data of CPU
                `ENABLE,                                  // the signal of stall caused by cache miss
                21'b1_0000_0000_0000_0000_0000,           // write data of L1_tag
                8'b0100_0000,                             // address of L1_cache
                128'hx,                                   // data_rd choosing from data_rd1~data_rd3
                `DISABLE,                                 // drq
                28'h40,                                   // l2_addr
                1'b1,                                     // dirty_wd
                `ENABLE,                                  // block0_we
                `DISABLE                                  // block1_we
                );
        end
        # STEP begin // WRITE_HIT & ACCESS_L2 & IC_ACCESS_L2 
            $display("\n========= Clock 15 ========");    
            dtag_ram_tb(
                21'b1_0000_0000_0000_0000_0000,           // read data of tag0
                21'bx,                                    // read data of tag1
                1'b1,                                     // number of replacing block of tag next time
                1'b1                                      // complete write from L2 to L1
                );
            data_ram_tb(
                128'hx_00000009_00000004,                 // read data of cache_data0
                128'hx                                    // read data of cache_data1
                );
            /******** ADD  r6, r4, r5 IF Stage Test Output ********/
            if_tb(
                `WORD_DATA_W'h1c,
                `WORD_DATA_W'h20,
                `WORD_DATA_W'h00520333,
                `ENABLE
                );

            /******** LW   r5, r0(1028) ID Stage Test Output ********/
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

            /******** LW   r4, r0(1024)  EX Stage Test Output ********/
            ex_stage_tb(
                `WORD_DATA_W'h404,
                `ENABLE,
                `MEM_OP_LW,
                `WORD_DATA_W'h0,
                `REG_ADDR_W'h4,
                `ENABLE_,
                `WORD_DATA_W'h400
                );

            /******** SW   r2, r0(1028)  MEM Stage Test Output ********/
            mem_tb(
                `WORD_DATA_W'h4,
                `ENABLE,
                `REG_ADDR_W'h4,
                `DISABLE_,
                `WORD_DATA_W'h0
                );

            ctrl_tb(
                `ENABLE,                                // if_stall
                `DISABLE,                               // id_stall
                `DISABLE,                               // ex_stall
                `DISABLE,                               // mem_stall
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
            mem_stage_tb(
                32'b0,                                    // read data of CPU
                `DISABLE,                                 // the signal of stall caused by cache miss
                21'b1_0000_0000_0000_0000_0000,           // write data of L1_tag
                8'b0100_0000,                             // address of L1_cache
                128'hx,                                   // data_rd choosing from data_rd1~data_rd3
                `DISABLE,                                 // drq
                28'h40,                                   // l2_addr
                1'b1,                                     // dirty_wd
                `DISABLE,                                 // block0_we
                `DISABLE                                  // block1_we
                );
            if_stage_tb(
                32'h00520333,                             // if_insn
                `DISABLE,                                 // miss
                `ENABLE,                                  // write signal of L1_tag0
                `DISABLE,                                 // write signal of L1_tag1
                21'b1_0000_0000_0000_0000_0000,           // write data of L1_tag
                8'b10,                                    // address of L1_cache
                `ENABLE,                                  // irq
                28'b10,                                   // l2_addr
                `WORD_DATA_W'h1c,                         // pc
                `ENABLE        
                );
            l2_cache_ctrl_tb(         
                `ENABLE,                                  // ic_en
                `DISABLE,                                 // dc_en
                128'h00520333_00520333_00520333_00520333, // write data to L1_IC
                18'b1_0000_0000_0000_0000_0,              // write data of tag
                `ENABLE,                                  // ready signal of l2_cache
                1'b0,
                `DISABLE,                                 // write mark of cache_data0 
                `DISABLE,                                 // write mark of cache_data1 
                `DISABLE,                                 // write mark of cache_data2 
                `DISABLE,                                 // write mark of cache_data3                 
                26'h10,                                   // address of memory
                `READ                                     // read / write signal of memory                
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
                512'hx00520333_00520333_00520333_00520333_00520333_40402283_40002203_40202223_40102023_00d00193_00900113_00400093,                // read data of cache_data0
                512'bx,                                   // read data of cache_data1
                512'bx,                                   // read data of cache_data2
                512'bx                                    // read data of cache_data3
                );
            
            itag_ram_tb(
                21'bx,                                    // read data of tag0
                21'bx,                                    // read data of tag1
                1'bx,                                     // number of replacing block of tag next time
                1'b0                                      // complete write from L2 to L1
                );
            idata_ram_tb(
                128'hx,                                   // read data of cache_data0
                128'hx                                    // read data of cache_data1
                );
        end           
        #STEP begin // DC_ACCESS(read hit) & L2_WRITE_HIT(access l2_ram) & WRITE_IC
            $display("\n========= Clock 16 ========");
            if_stage_tb(
                32'h00520333,                             // read data of CPU
                `DISABLE,                                 // the signal of stall caused by cache miss
                `DISABLE,                                 // read / write signal of L1_tag0
                `DISABLE,                                 // read / write signal of L1_tag1
                21'b1_0000_0000_0000_0000_0000,           // write data of L1_tag
                8'b0000_0010,                             // address of L1_cache
                `DISABLE,                                 // icache request
                28'h2,
                32'h1c,
                `ENABLE
                );
            mem_stage_tb(
                32'h4,                                    // read data of CPU
                `DISABLE,                                 // the signal of stall caused by cache miss
                21'b1_0000_0000_0000_0000_0000,           // write data of L1_tag
                8'b0100_0000,                             // address of L1_cache
                128'hx,                                   // data_rd choosing from data_rd1~data_rd3
                `DISABLE,                                 // drq
                28'h40,                                   // l2_addr
                1'b1,                                     // dirty_wd
                `DISABLE,                                 // block0_we
                `DISABLE                                  // block1_we
                );
            itag_ram_tb(
                21'b1_0000_0000_0000_0000_0000,           // read data of tag0
                21'bx,                                    // read data of tag1
                1'b1,                                     // number of replacing block of tag next time
                1'b1                                      // complete write from L2 to L1
                );
            idata_ram_tb(
                128'h00520333_00520333_00520333_00520333,                // read data of cache_data0
                128'hx                                    // read data of cache_data1
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
            l2_cache_ctrl_tb(         
                `DISABLE,                                 // ic_en
                `DISABLE,                                 // dc_en
                128'h00520333_00520333_00520333_00520333, // write data to L1_IC
                18'b1_0000_0000_0000_0000_0,              // write data of tag
                `DISABLE,                                 // ready signal of l2_cache
                1'b0,
                `DISABLE,                                 // the mark of cache_data0 write signal 
                `DISABLE,                                 // the mark of cache_data1 write signal 
                `DISABLE,                                 // the mark of cache_data2 write signal 
                `DISABLE,                                 // the mark of cache_data3 write signal 
                26'h10,                                   // address of memory
                `READ                                     // read / write signal of memory                
                );

            /******** ADD  r6, r4, r5 IF Stage Test Output ********/
            if_tb(
                `WORD_DATA_W'h1c,
                `WORD_DATA_W'h20,
                `WORD_DATA_W'h00520333,
                `ENABLE
                );

            /******** NOP               ID Stage Test Output ********/
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

            /******** LW   r5, r0(1028)  EX Stage Test Output ********/
            ex_stage_tb(
                `WORD_DATA_W'h0,
                `ENABLE,
                `MEM_OP_LW,
                `WORD_DATA_W'hx,
                `REG_ADDR_W'h5,
                `ENABLE_,
                `WORD_DATA_W'h404
                );

            /******** LW   r4, r0(1024)  MEM Stage Test Output ********/
            mem_tb(
                `WORD_DATA_W'h9,
                `ENABLE,
                `REG_ADDR_W'h4,
                `ENABLE_,
                `WORD_DATA_W'h4
                );

            $display("WB Stage ...");

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
        end 
        /* First instruction into ID stage*/         
        #STEP begin // DC_ACCESS(read hit) & L2_IDLE &  IC_ACCESS(READ HIT third insn)
            $display("\n========= Clock 17 ========");            
            if_stage_tb(
                32'h00520333,                             // read data of CPU
                `DISABLE,                                 // the signal of stall caused by cache miss
                `DISABLE,                                 // read / write signal of L1_tag0
                `DISABLE,                                 // read / write signal of L1_tag1
                21'b1_0000_0000_0000_0000_0000,           // write data of L1_tag
                8'b0000_0010,                             // address of L1_cache
                `DISABLE,                                 // icache request
                28'h2,
                32'h20,
                `ENABLE
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
                512'hx00520333_00520333_00520333_00520333_00520333_40402283_40002203_40202223_40102023_00d00193_00900113_00400093, // read data of cache_data0
                512'bx,                                   // read data of cache_data1
                512'bx,                                   // read data of cache_data2
                512'bx                                    // read data of cache_data3
                );
            l2_cache_ctrl_tb(         
                `DISABLE,                                 // ic_en
                `DISABLE,                                 // dc_en
                128'h00520333_00520333_00520333_00520333, // write data to L1_IC
                18'b1_0000_0000_0000_0000_0,              // write data of tag
                `DISABLE,                                 // ready signal of l2_cache
                `DISABLE,                                 // the mark of cache_data0 write signal 
                `DISABLE,                                 // the mark of cache_data1 write signal 
                `DISABLE,                                 // the mark of cache_data2 write signal 
                `DISABLE,                                 // the mark of cache_data3 write signal 
                1'b0,
                26'h10,                                   // address of memory
                `READ                                     // read / write signal of memory                
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

            /******** ADD  r6, r4, r5 IF Stage Test Output ********/
            if_tb(
                `WORD_DATA_W'h20,
                `WORD_DATA_W'h24,
                `WORD_DATA_W'h520333,
                `ENABLE
                );

            /******** ADD  r6, r4, r5 ID Stage Test Output ********/
            id_stage_tb( 
                `ENABLE,
                `ALU_OP_ADD,
                `WORD_DATA_W'h4,
                `WORD_DATA_W'h9,
                `MEM_OP_NOP,
                `WORD_DATA_W'h9,
                `REG_ADDR_W'h6,
                `ENABLE_,
                `EX_OUT_ALU,
                `WORD_DATA_W'h20
                );

            /******** NOP                 EX Stage Test Output ********/
            ex_stage_tb(
                `WORD_DATA_W'hd,
                `DISABLE,
                `MEM_OP_NOP,
                `WORD_DATA_W'h0,
                `REG_ADDR_W'h0,
                `DISABLE_,
                `WORD_DATA_W'h0
                );

            /******** LW   r5, r0(1028)  MEM Stage Test Output ********/
            mem_tb(
                `WORD_DATA_W'h0,
                `ENABLE,
                `REG_ADDR_W'h5,
                `ENABLE_,
                `WORD_DATA_W'h9
                );

            $display("WB Stage ...");

            $finish;
        end
    end
  /******** Output Waveform ********/
    initial begin
       $dumpfile("cpu_top_test.vcd");
       $dumpvars(0,mem,ctrl,gpr,l2_cache_ctrl,
                dtag_ram,ddata_ram,itag_ram,idata_ram,l2_tag_ram,l2_data_ram,
                if_stage,id_stage,ex_stage,mem_stage);
    end
endmodule
