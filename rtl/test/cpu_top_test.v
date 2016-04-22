/******** Time scale ********/
`timescale 1ns/1ps
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
    wire                   clk_mem;
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
    wire                   clk_l2;
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
    wire [31:0]            wr_data_m;
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
    
    /*********** Clock ************/
    clk_n clk_n(
        .clk            (clk),           // clock
        .rst            (rst),           // reset
        .clk_2          (clk_l2),        // two divided-frequency clock
        .clk_4          (clk_mem)        // four divided-frequency clock
        );
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
        .wr_data_m      (wr_data_m),
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
        .id_mem_op      (id_mem_op),     // complete op writing to L1
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
        .clk        (clk_mem),           // Clock
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
        .wr_data_m      (wr_data_m),
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
        .clk            (clk_l2),        // clock of L2C
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
        .clk            (clk_l2),        // clock of L2C
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

    task cpu_top_tb;
        input [511:0] _mem_wd;
        input [25:0]  _mem_addr;
        input         _mem_rw;

        begin
            if((mem_wd   === _mem_wd)    &&
               (mem_addr === _mem_addr)  &&
               (mem_rw   === _mem_rw)
              ) begin
                $display("Test Succeeded !");
            end else begin
                $display("Test Failed !");
            end
        end

    endtask
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
                $display("rd_to_l2:%b(excepted %b)",rd_to_l2,_rd_to_l2); 
            end
            if (block0_we  !== _block0_we) begin
                $display("block0_we:%b(excepted %b)",block0_we,_block0_we); 
            end
            if (block1_we  !== _block1_we) begin
                $display("block1_we:%b(excepted %b)",block1_we,_block1_we); 
            end
            if (mem_out    !== _mem_out) begin
                $display("mem_out:%b(excepted %b)",mem_out,_mem_out); 
            end
            if (mem_busy   !== _mem_busy) begin
                $display("mem_busy:%b(excepted %b)",mem_busy,_mem_busy); 
            end
            if (tag_wd_dc  !== _tag_wd_dc) begin
                $display("tag_wd_dc:%b(excepted %b)",tag_wd_dc,_tag_wd_dc); 
            end
            if (index_dc   !== _index_dc) begin
                $display("index_dc:%b(excepted %b)",index_dc,_index_dc); 
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
                $display("tag0_rd_dc:%b(excepted %b)",tag0_rd_dc,_tag0_rd_dc); 
            end
            if (tag1_rd_dc  !== _tag1_rd_dc) begin
                $display("tag1_rd_dc:%b(excepted %b)",tag1_rd_dc,_tag1_rd_dc); 
            end
            if (lru_dc      !== _lru_dc) begin
                $display("lru_dc:%b(excepted %b)",lru_dc,_lru_dc); 
            end
            if (complete_dc !== _complete_dc) begin
                $display("complete_dc:%b(excepted %b)",complete_dc,_complete_dc); 
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
                $display("data0_rd:%b(excepted %b)",data0_rd_dc,_data0_rd_dc); 
            end
            if(data1_rd_dc !== _data1_rd_dc) begin
                $display("data1_rd:%b(excepted %b)",data1_rd_dc,_data1_rd_dc); 
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
            if (l2_complete !== _l2_complete) begin
                $display("l2_complete:%b(excepted %b)",l2_complete,_l2_complete); 
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
                $display("pc:%b(excepted %b)",pc,_pc); 
            end
            if (if_en !== _if_en) begin
                $display("if_en:%b(excepted %b)",if_en,_if_en); 
            end
            if (if_insn   !== _if_insn) begin
                $display("if_insn:%b(excepted %b)",if_insn,_if_insn); 
            end
            if (if_busy !== _if_busy) begin
                $display("if_busy:%b(excepted %b)",if_busy,_if_busy); 
            end
            if (block0_we_ic  !== _block0_we_ic) begin
                $display("block0_we_ic:%b(excepted %b)",block0_we_ic,_block0_we_ic); 
            end
            if (block1_we_ic  !== _block1_we_ic) begin
                $display("block1_we_ic:%b(excepted %b)",block1_we_ic,_block1_we_ic); 
            end
            if (tag_wd_ic     !== _tag_wd_ic) begin
                $display("tag_wd_ic:%b(excepted %b)",tag_wd_ic,_tag_wd_ic); 
            end
            if (index_ic      !== _index_ic) begin
                $display("index_ic:%b(excepted %b)",index_ic,_index_ic); 
            end
            if (irq   !== _irq) begin
                $display("irq:%b(excepted %b)",irq,_irq); 
            end
            if (l2_addr_ic !== _l2_addr_ic) begin
                $display("l2_addr_ic:%b(excepted %b)",l2_addr_ic,_l2_addr_ic); 
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
                $display("tag0_rd_ic:%b(excepted %b)",tag0_rd_ic,_tag0_rd_ic); 
            end
            if (tag1_rd_ic  !== _tag1_rd_ic) begin
                $display("tag1_rd_ic:%b(excepted %b)",tag1_rd_ic,_tag1_rd_ic); 
            end
            if (lru_ic      !== _lru_ic) begin
                $display("lru_ic:%b(excepted %b)",lru_ic,_lru_ic); 
            end
            if (complete_ic !== _complete_ic) begin
                $display("complete_ic:%b(excepted %b)",complete_ic,_complete_ic); 
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
            mem_rd   <= 512'h13_00000013_00000013_00000013_002232b3_002222b3_00319213_ffc0b193_ffc0a193_ffff8117_000040b7;
        end
        #(STEP * 3/4)
        #STEP begin
            rst     <= `DISABLE;
            /* IF stage */ 
            // L1_ACCESS & L2_IDLE 
            $display("\n========= Clock 0 ========");
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
                1'bx,                                    // write signal of cache_data0 
                1'bx,                                    // write signal of cache_data1 
                1'bx,                                    // write signal of cache_data2 
                1'bx,                                    // write signal of cache_data3 
                1'bx,
                26'bx,                                   // address of memory
                1'bx                                     // read / write signal of memory                
                );  
        end
        #STEP begin // IC_ACCESS_L2 & ACCESS_L2 
            $display("\n========= Clock 1 ========");
            l2_cache_ctrl_tb(             
                `ENABLE,                                 // ic_en
                1'bx,                                    // dc_en
                128'hffc0b193_ffc0a193_ffff8117_000040b7, // write data to L1_IC
                18'b1_0000_0000_0000_0000_0,              // write data of tag
                1'bx,                                     // ready signal of l2_cache
                1'b0,                                     // the mark of cache_data0 write signal 
                `ENABLE,                                  // the mark of cache_data1 write signal 
                1'bx,                                     // the mark of cache_data2 write signal 
                1'bx,                                     // the mark of cache_data3 write signal 
                1'bx,
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
                `ENABLE,                                  // the signal of stall caused by cache miss
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
        #STEP begin // WRITE_IC & WRITE_L2 & access l2_ram
            $display("\n========= Clock 2 ========");
            if_stage_tb(
                32'b0,                                    // read data of CPU
                `DISABLE,                                 // the signal of stall caused by cache miss
                `DISABLE,                                 // read / write signal of L1_tag0
                `DISABLE,                                 // read / write signal of L1_tag1
                21'b1_0000_0000_0000_0000_0000,           // write data of L1_tag
                8'b0000_0000,                             // address of L1_cache
                `DISABLE,                                 // icache request
                28'b0,
                32'b0,
                `DISABLE
                );
            itag_ram_tb(
                21'b1_0000_0000_0000_0000_0000,           // read data of tag0
                21'bx,                                    // read data of tag1
                1'b1,                                     // number of replacing block of tag next time
                1'b1                                      // complete write from L2 to L1
                );
            idata_ram_tb(
                128'hffc0b193_ffc0a193_ffff8117_000040b7, // read data of cache_data0
                128'hx                                    // read data of cache_data1
                ); 
        end 
        /* First instruction into ID stage*/         
        #STEP begin // IC_ACCESS(READ HIT secode word) & WRITE_TO_L2_CLEAN & access l2_ram
            $display("\n========= Clock 3 ========");            
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
                512'h13_00000013_00000013_00000013_002232b3_002222b3_00319213_ffc0b193_ffc0a193_ffff8117_000040b7,
                512'bx,                                   // read data of cache_data1
                512'bx,                                   // read data of cache_data2
                512'bx                                    // read data of cache_data3
             );
            if_stage_tb(
                32'h000040b7,                             // if_insn
                `DISABLE,                                 // the signal of stall caused by cache miss
                `DISABLE,                                 // read / write signal of L1_tag0
                `DISABLE,                                 // read / write signal of L1_tag1
                21'b1_0000_0000_0000_0000_0000,           // write data of L1_tag
                8'b0,                                     // address of L1_cache
                `DISABLE,                                 // icache request
                28'b0,                                    // l2_addr
                32'b0,                                    // pc
                `ENABLE        
                );
            l2_cache_ctrl_tb(         
                `DISABLE,                                 // ic_en
                `DISABLE,                                 // dc_en
                128'hffc0b193_ffc0a193_ffff8117_000040b7, // write data to L1_IC
                18'b1_0000_0000_0000_0000_0,              // write data of tag
                1'bx,                                     // ready signal of l2_cache
                `DISABLE,                                 // the mark of cache_data0 write signal 
                `DISABLE,                                 // the mark of cache_data1 write signal 
                `DISABLE,                                 // the mark of cache_data2 write signal 
                `DISABLE,                                 // the mark of cache_data3 write signal 
                1'b0,
                26'b0,                                    // address of memory
                `READ                                     // read / write signal of memory                
                );       
        end
        /* First instruction into MEM stage*/  
        #STEP begin // IC_ACCESS(READ HIT third word)  & l2_IDLE        
            $display("\n========= Clock 4 ========");
            // l2_cache_ctrl_tb(         
            //     `DISABLE,                                 // ic_en
            //     1'bx,                                     // dc_en
            //     128'h0876547A_00000000_ABF00000_123BC000, // write data to L1_IC
            //     18'b1_0000_0000_0000_0000_0,              // write data of tag
            //     1'bx,                                     // ready signal of l2_cache
            //     `DISABLE,                                 // the mark of cache_data0 write signal 
            //     `DISABLE,                                 // the mark of cache_data1 write signal 
            //     `DISABLE,                                 // the mark of cache_data2 write signal 
            //     `DISABLE,                                 // the mark of cache_data3 write signal 
            //     1'b0,
            //     26'b1110_0001_00,                         // address of memory
            //     `READ                                     // read / write signal of memory                
            //     );
            // if_stage_tb(
            //     32'hABF00000,                             // read data of CPU
            //     `DISABLE,                                 // the signal of stall caused by cache miss
            //     `DISABLE,                                 // read / write signal of L1_tag0
            //     `DISABLE,                                 // read / write signal of L1_tag1
            //     21'b1_0000_0000_0000_0000_0000,           // write data of L1_tag
            //     8'b0001_0000,                             // address of L1_cache
            //     `DISABLE,                                 // icache request
            //     28'b1110_0001_0000,                       // l2_addr
            //     32'b1110_0001_0000_0100,                  // pc
            //     `ENABLE                                   // if_en
            //     ); 
            // cpu_top_tb(
            //     placeholder, // mem_wd
            //     placeholder, // mem_addr
            //     placeholder  // mem_rw
            //     );
            $finish;
        end
    end
	/******** Output Waveform ********/
    initial begin
       $dumpfile("cpu_top.vcd");
       $dumpvars(0,clk_n,mem,ctrl,mem,dtag_ram,ddata_ram,itag_ram,idata_ram,l2_tag_ram,l2_data_ram,l2_cache_ctrl,
                l2_cache_ctrl,if_stage,id_stage,gpr,ex_stage,mem_stage);
    end

endmodule
