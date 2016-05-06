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

module cpu_top(
    input                  clk,             // clock
    input                  rst,             //  reset
    /*memory part*/
    input    [511:0]       mem_rd,
    output   [511:0]       mem_wd,
    output   [25:0]        mem_addr,        // address of memory
    output                 mem_rw           // read / write signal of memory
    );
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
    wire [`WORD_DATA_BUS]  id_pc;          // Program count
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
    wire                   ld_hazard;      // Hazard
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
    wire                   l2_busy;          // busy mark of L2C
    wire [127:0]           data_wd_l2;       // write data to L1 from L2
    wire [127:0]           data_wd_dc;       // write data to L1 from CPU
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
    wire [511:0]           l2_data_wd;        // write data of l2_cache
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
    wire                   data_rdy;
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
        .rst            (rst),           // reset
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
endmodule