/*
 -- ============================================================================
 -- FILE NAME   : dcache_write_test.v
 -- DESCRIPTION : testbench of icache
 -- ----------------------------------------------------------------------------
 -- Date:2016/3/24        Coding_by:kippy
 -- ============================================================================
*/
`timescale 1ns/1ps
/********** header file **********/
`include "stddef.h"
`include "dcache.h"
`include "l2_cache.h"

module dcache_write_test();
    // icache part
    reg              clk;           // clock
    reg              rst;           // reset
    /* CPU part */
    reg      [29:0]  aluout_m;      // address of fetching instruction
    reg      [31:0]  wr_data;
    wire     [31:0]  dc_wd;
    reg              memwrite_m;    // read / write signal of CPU
    reg              access_mem;
    reg              access_mem_ex;
    wire     [31:0]  read_data_m;   // read data of CPU
    wire             miss_stall;    // the signal of stall caused by cache miss
    /* L1_cache part */
    wire     [20:0]  tag_wd;        // write data of L1_tag
    wire     [7:0]   index;         // address of L1_cache
    wire             block0_we;     // write signal of block0
    wire             block1_we;     // write signal of block1
    wire             block0_re;     // read signal of block0
    wire             block1_re;     // read signal of block1
    /* l2_cache part */
    wire             l2_block0_we;
    wire             l2_block1_we;
    wire             l2_block2_we;
    wire             l2_block3_we;
    wire             l2_block0_re;
    wire             l2_block1_re;
    wire             l2_block2_re;
    wire             l2_block3_re;
    wire             irq;           // icache request
    wire             drq;           // dcache request
    wire             ic_rw_en;      // write enable signal
    wire             dc_rw_en;
    // l2_icache
    wire     [27:0]  l2_addr_ic; 
    wire     [27:0]  l2_addr_dc; 
    wire             l2_miss_stall; // stall caused by l2_miss
    wire             l2_cache_rw_ic;
    wire             l2_cache_rw_dc;
    wire     [8:0]   l2_index;
    wire     [1:0]   offset;
    wire     [1:0]   l2_offset;
    /*cache part*/
    wire             ic_en;      
    wire             dc_en;  
    wire     [127:0] rd_to_l2;
    wire     [17:0]  l2_tag_wd;     // write data of tag
    wire             l2_rdy;        // ready mark of L2C
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
    wire             complete_ic;   // complete write from L2 to L1
    wire             complete_dc;   // complete write from L2 to L1
    wire             dirty_wd; 
    wire             dirty0;       
    wire             dirty1;
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
    wire             l2_dirty0;
    wire             l2_dirty1;
    wire             l2_dirty2;
    wire             l2_dirty3;
    wire             clk_l2;         // temporary clock of L2C
    wire             clk_mem;        // temporary clock of L2C
    wire             mem_wr_dc_en;
    wire             mem_wr_ic_en;
    clk_2 clk_2(
        .clk            (clk),           // clock
        .rst            (rst),           // reset
        .clk_2          (clk_l2)         // two divided-frequency clock
        );
    clk_4 clk_4(
        .clk_2          (clk_l2),        // clock
        .rst            (rst),           // reset
        .clk_4          (clk_mem)        // four divided-frequency clock
        );
    mem mem(
        .clk            (clk_mem),       // clock
        .rst            (rst),           // reset active  
        .rw             (mem_rw),
        .complete       (mem_complete)
        );
    dcache_ctrl dcache_ctrl(
        .clk            (clk),            // clock
        .rst            (rst),            // reset
        /* CPU part */
        .addr           (aluout_m),       // address of fetching instruction
        .memwrite_m     (memwrite_m),     // read / write signal of CPU
        .access_mem     (access_mem), 
        .wr_data        (wr_data),
        .dc_wd          (dc_wd),
        .read_data_m    (read_data_m),    // read data of CPU
        .miss_stall     (miss_stall),     // the signal of stall caused by cache miss
        /* L1_cache part */
        .lru            (lru),            // mark of replacing
        .tag0_rd        (tag0_rd),        // read data of tag0
        .tag1_rd        (tag1_rd),        // read data of tag1
        .data0_rd       (data0_rd),       // read data of data0
        .data1_rd       (data1_rd),       // read data of data1
        .dirty0         (dirty0),         
        .dirty1         (dirty1),          
        .dirty_wd       (dirty_wd),                    
        .offset         (offset),       
        .tagcomp_hit    (tagcomp_hit),   
        .block0_we      (block0_we),       // write signal of block0
        .block1_we      (block1_we),       // write signal of block1
        .block0_re      (block0_re),       // read signal of block0
        .block1_re      (block1_re),       // read signal of block1
        .tag_wd         (tag_wd),          // write data of L1_tag
        .data_wd_dc_en  (data_wd_dc_en),
        .hitway         (hitway),
        .index          (index),           // address of L1_cache
        .rd_to_l2       (rd_to_l2),
        /* l2_cache part */
        .l2_complete    (l2_complete),     // complete signal of l2_cache
        .dc_en          (dc_en),           // busy signal of l2_cache
        .l2_rdy         (l2_rdy),          // ready signal of l2_cache
        .mem_wr_dc_en   (mem_wr_dc_en), 
        .complete       (complete_dc),     // complete op writing to L1
        .data_wd_l2     (data_wd_l2),
        .drq            (drq),      
        .dc_rw_en       (dc_rw_en), 
        .l2_addr        (l2_addr_dc),      
        .l2_cache_rw    (l2_cache_rw_dc)        
        );
    l2_cache_ctrl l2_cache_ctrl(
        .clk            (clk),              // clock of L2C
        .rst            (rst),              // reset
        /* CPU part */
        .l2_addr_ic     (l2_addr_ic),       // address of fetching instruction
        .l2_cache_rw_ic (l2_cache_rw_ic),   // read / write signal of CPU
        .l2_addr_dc     (l2_addr_dc),       // address of fetching instruction
        .l2_cache_rw_dc (l2_cache_rw_dc),   // read / write signal of CPU
        .l2_index       (l2_index),
        .offset         (l2_offset),
        .tagcomp_hit    (l2_tagcomp_hit),      
        /*cache part*/
        .irq            (irq),              // icache request
        .drq            (drq),
        .ic_rw_en       (ic_rw_en),         // write enable signal of icache
        .dc_rw_en       (dc_rw_en),
        .complete_ic    (complete_ic),      // complete write from L2 to L1
        .complete_dc    (complete_dc),      // complete write from L2 to L1    
        .data_wd_l2     (data_wd_l2),       // write data to L1C       
        .data_wd_l2_en  (data_wd_l2_en), 
        .wd_from_l1_en  (wd_from_l1_en), 
        .wd_from_mem_en (wd_from_mem_en), 
        .mem_wr_dc_en   (mem_wr_dc_en), 
        .mem_wr_ic_en   (mem_wr_ic_en),
        /*l2_cache part*/
        .l2_complete    (l2_complete),      // complete write from MEM to L2
        .l2_rdy         (l2_rdy),
        .ic_en          (ic_en),
        .dc_en          (dc_en),
        // l2_tag part
        .l2_block0_we   (l2_block0_we),      // write signal of block0
        .l2_block1_we   (l2_block1_we),      // write signal of block1
        .l2_block2_we   (l2_block2_we),      // write signal of block2
        .l2_block3_we   (l2_block3_we),      // write signal of block3
        .l2_block0_re   (l2_block0_re),      // read signal of block0
        .l2_block1_re   (l2_block1_re),      // read signal of block1
        .l2_block2_re   (l2_block2_re),      // read signal of block2
        .l2_block3_re   (l2_block3_re),      // read signal of block3    
        .plru           (plru),              // replace mark
        .l2_tag0_rd     (l2_tag0_rd),        // read data of tag0
        .l2_tag1_rd     (l2_tag1_rd),        // read data of tag1
        .l2_tag2_rd     (l2_tag2_rd),        // read data of tag2
        .l2_tag3_rd     (l2_tag3_rd),        // read data of tag3
        .l2_tag_wd      (l2_tag_wd),         // write data of tag0                
        // l2_data part
        .l2_data0_rd    (l2_data0_rd),       // read data of cache_data0
        .l2_data1_rd    (l2_data1_rd),       // read data of cache_data1
        .l2_data2_rd    (l2_data2_rd),       // read data of cache_data2
        .l2_data3_rd    (l2_data3_rd),       // read data of cache_data3
        // l2_dirty part
        .l2_dirty_wd    (l2_dirty_wd),
        .l2_dirty0      (l2_dirty0),
        .l2_dirty1      (l2_dirty1),
        .l2_dirty2      (l2_dirty2), 
        .l2_dirty3      (l2_dirty3),         
        /*memory part*/
        .mem_complete   (mem_complete),
        .mem_rd         (mem_rd),
        .mem_wd         (mem_wd), 
        .mem_addr       (mem_addr),          // address of memory
        .mem_rw         (mem_rw)             // read / write signal of memory
    );
    dtag_ram dtag_ram(
        .clk            (clk),                // clock
        .index          (index),              // address of cache
        .block0_we      (block0_we),          // write signal of block0
        .block1_we      (block1_we),          // write signal of block1
        .block0_re      (block0_re),          // read signal of block0
        .block1_re      (block1_re),          // read signal of block1
        .dirty_wd       (dirty_wd),   
        .tag_wd         (tag_wd),             // write data of tag
        .tag0_rd        (tag0_rd),            // read data of tag0
        .tag1_rd        (tag1_rd),            // read data of tag1
        .dirty0         (dirty0),
        .dirty1         (dirty1),
        .lru            (lru),                // read data of tag
        .complete       (complete_dc)         // complete write from L2 to L1
        );
    data_ram ddata_ram(
        .clk            (clk),                // clock
        .index          (index),              // address of cache
        .tagcomp_hit    (tagcomp_hit),    
        .block0_we      (block0_we),          // write signal of block0
        .block1_we      (block1_we),          // write signal of block1
        .block0_re      (block0_re),          // read signal of block0
        .block1_re      (block1_re),          // read signal of block1
        .data_wd_l2     (data_wd_l2),         // write data of l2_cache
        .data_wd_l2_en  (data_wd_l2_en),      // write data of l2_cache
        .data_wd_dc_en  (data_wd_dc_en),      // write data of l2_cache
        .dc_wd          (dc_wd),
        .offset         (offset), 
        .data0_rd       (data0_rd),           // read data of cache_data0
        .data1_rd       (data1_rd)            // read data of cache_data1
    );
    l2_data_ram l2_data_ram(
        .clk            (clk_l2),            // clock of L2C
        .l2_index       (l2_index),
        .mem_rd         (mem_rd),
        .offset         (l2_offset),
        .rd_to_l2       (rd_to_l2),
        .wd_from_mem_en (wd_from_mem_en),
        .wd_from_l1_en  (wd_from_l1_en),
        .tagcomp_hit    (l2_tagcomp_hit),     
        .l2_block0_we   (l2_block0_we),       // write signal of block0
        .l2_block1_we   (l2_block1_we),       // write signal of block1
        .l2_block2_we   (l2_block2_we),       // write signal of block2
        .l2_block3_we   (l2_block3_we),       // write signal of block3
        .l2_block0_re   (l2_block0_re),       // read signal of block0
        .l2_block1_re   (l2_block1_re),       // read signal of block1
        .l2_block2_re   (l2_block2_re),       // read signal of block2
        .l2_block3_re   (l2_block3_re),       // read signal of block3
        .l2_data0_rd    (l2_data0_rd),        // read data of cache_data0
        .l2_data1_rd    (l2_data1_rd),        // read data of cache_data1
        .l2_data2_rd    (l2_data2_rd),        // read data of cache_data2
        .l2_data3_rd    (l2_data3_rd)         // read data of cache_data3
    );
    l2_tag_ram l2_tag_ram(    
        .clk            (clk_l2),            // clock of L2C
        .l2_index       (l2_index),
        .l2_block0_we   (l2_block0_we),       // write signal of block0
        .l2_block1_we   (l2_block1_we),       // write signal of block1
        .l2_block2_we   (l2_block2_we),       // write signal of block2
        .l2_block3_we   (l2_block3_we),       // write signal of block3
        .l2_block0_re   (l2_block0_re),       // read signal of block0
        .l2_block1_re   (l2_block1_re),       // read signal of block1
        .l2_block2_re   (l2_block2_re),       // read signal of block2
        .l2_block3_re   (l2_block3_re),       // read signal of block3ck3
        .l2_tag_wd      (l2_tag_wd),          // write data of tag
        .l2_dirty_wd    (l2_dirty_wd),
        .l2_tag0_rd     (l2_tag0_rd),         // read data of tag0
        .l2_tag1_rd     (l2_tag1_rd),         // read data of tag1
        .l2_tag2_rd     (l2_tag2_rd),         // read data of tag2
        .l2_tag3_rd     (l2_tag3_rd),         // read data of tag3
        .plru           (plru),               // read data of plru_field
        .l2_complete    (l2_complete),        // complete write to L2
        .l2_dirty0      (l2_dirty0),
        .l2_dirty1      (l2_dirty1),
        .l2_dirty2      (l2_dirty2),
        .l2_dirty3      (l2_dirty3)
    );

    task dcache_ctrl_tb;
        input  [31:0]  _read_data_m;     // read data of CPU
        input          _miss_stall;      // the signal of stall caused by cache miss 
        /* L1_cache part */
        input          _block0_we;       // read / write signal of L1_block0
        input          _block1_we;       // read / write signal of L1_block1
        input  [20:0]  _tag_wd;          // write data of L1_tag
        input  [7:0]   _index;           // address of L1_cache
        input  [127:0] _rd_to_l2;        
        /* l2_cache part */
        input          _drq;             // dcache request
        input  [27:0]  _l2_addr_dc;
        // dirty
        input          _dirty_wd;

        begin 
            if( (read_data_m === _read_data_m)       && 
                (miss_stall  === _miss_stall)        && 
                (block0_we   === _block0_we)         && 
                (block1_we   === _block1_we)         && 
                (tag_wd      === _tag_wd)            && 
                (index       === _index)             && 
                (drq         === _drq)               && 
                (l2_addr_dc  === _l2_addr_dc)        && 
                (rd_to_l2    === _rd_to_l2)
               ) begin 
                 $display("dcache Test Succeeded !"); 
            end else begin 
                 $display("dcache Test Failed !"); 
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
            if (read_data_m   !== _read_data_m) begin
                $display("read_data_m:%b(excepted %b)",read_data_m,_read_data_m); 
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
            if (drq   !== _drq) begin
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
        input           _l2_block0_we;       // read / write signal of block0
        input           _l2_block1_we;       // read / write signal of block1
        input           _l2_block2_we;       // read / write signal of block0
        input           _l2_block3_we;       // read / write signal of block1
        input   [17:0]  _l2_tag_wd;          // write data of tag0
        input           _l2_rdy;             // ready signal of l2_cache
        // l2_dirty part
        input           _l2_dirty_wd;
        input   [25:0]  _mem_addr;           // address of memory
        input           _mem_rw;             // read / write signal of memory
        begin 
            if( (dc_en         === _dc_en)          && 
                (data_wd_l2    === _data_wd_l2)     && 
                (l2_block0_we  === _l2_block0_we)   && 
                (l2_block1_we  === _l2_block1_we)   && 
                (l2_block2_we  === _l2_block2_we)   && 
                (l2_block3_we  === _l2_block3_we)   && 
                (l2_tag_wd     === _l2_tag_wd)      && 
                (l2_rdy        === _l2_rdy)         && 
                (l2_dirty_wd   === _l2_dirty_wd)    &&
                (mem_addr      === _mem_addr)       && 
                (mem_rw        === _mem_rw)  
               ) begin 
                 $display("l2_cache Test Succeeded !"); 
            end else begin 
                 $display("l2_cache Test Failed !"); 
            end 
            // check
            if(dc_en        !== _dc_en) begin
                $display("dc_en Test Failed !"); 
            end
            if(data_wd_l2   !== _data_wd_l2) begin
                $display("data_wd_l2:%b(excepted %b)",data_wd_l2,_data_wd_l2); 
            end
            if(l2_tag_wd    !== _l2_tag_wd) begin
                $display("l2_tag_wd Test Failed !"); 
            end
            if(l2_rdy       !== _l2_rdy) begin
                $display("l2_rdy Test Failed !"); 
            end
            if (l2_dirty_wd !== _l2_dirty_wd) begin
                $display("l2_dirty_wd Test Failed !"); 
            end
            if(mem_addr     !== _mem_addr) begin
                $display("mem_addr Test Failed !"); 
            end
            if(mem_rw       !== _mem_rw) begin
                $display("mem_rw Test Failed !"); 
            end 
        end
    endtask
    task tag_ram_tb;
        input      [20:0]  _tag0_rd;        // read data of tag0
        input      [20:0]  _tag1_rd;        // read data of tag1
        input              _lru;            // read block of tag
        input              _complete_dc;    // complete_dc write from L2 to L1
        begin 
            if( (tag0_rd  === _tag0_rd)     && 
                (tag1_rd  === _tag1_rd)     && 
                (lru      === _lru)         && 
                (complete_dc === _complete_dc)              
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
            if (complete_dc !== _complete_dc) begin
                $display("complete_dc:%b(excepted %b)",complete_dc,_complete_dc); 
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
            rst        <= `DISABLE;      
            aluout_m   <= 30'b1110_0001_0000_00;
            access_mem <= `ENABLE;
            memwrite_m <= `WRITE;
            wr_data  <= 32'h123B;
            // write data of l2_cache
            mem_rd     <= 512'h123BC000_0876547A_00000000_ABF00000_123BC000_00000000_0876547A_00000000_ABF00000_123BC000;         
        end
        #STEP begin // DC_ACCESS & L2_IDLE 
            $display("\n========= Clock 1 ========");
            l2_cache_ctrl_tb(           
                `ENABLE,                                   // L2C busy mark
                128'bx,                                    // write data to L1_IC
                1'bx,                                      // read / write signal of tag0
                1'bx,                                      // read / write signal of tag1
                1'bx,                                      // read / write signal of tag2
                1'bx,                                      // read / write signal of tag3
                18'b1_0000_0000_0000_0000_1,               // write data of tag
                1'bx,                                      // ready signal of l2_cache
                1'bx,
                26'bx,                                     // address of memory
                1'bx                                       // read / write signal of memory                
                ); 
            dcache_ctrl_tb(
                32'bx,                                     // read_data_m of CPU
                `ENABLE,                                   // the signal of stall caused by cache miss
                1'bx,                                      // read / write signal of L1_tag0
                1'bx,                                      // read / write signal of L1_tag1
                21'b1_0000_0000_0000_0000_1110,            // write data of L1_tag
                8'b0001_0000,                              // address of L1_cache
                128'bx,                                    // data_rd choosing from data_rd1~data_rd3
                `ENABLE,                                   // drq
                28'b1110_0001_0000,                        // l2_addr
                1'bx                                       // dirty_wd
                );
        end
        #STEP begin // DC_ACCESS_L2 & ACCESS_L2 
            $display("\n========= Clock 2 ========");
            dcache_ctrl_tb(
                32'bx,                                     // read_data_m of CPU
                `ENABLE,                                   // the signal of stall caused by cache miss
                `ENABLE,                                   // read / write signal of L1_tag0
                1'bx,                                      // read / write signal of L1_tag1
                21'b1_0000_0000_0000_0000_1110,            // write data of L1_tag
                8'b0001_0000,                              // address of L1_cache
                128'bx,                                    // data_rd choosing from data_rd1~data_rd3
                `ENABLE,                                   // icache request
                28'b1110_0001_0000,                        // l2_addr
                1'bx                                       // dirty_wd
                );
            l2_cache_ctrl_tb(           
                `ENABLE,                                   // L2C busy mark
                128'h0876547A_00000000_ABF00000_123BC000,  // write data to L1_IC
                `ENABLE,                                   // read / write signal of tag0
                1'bx,                                      // read / write signal of tag1
                1'bx,                                      // read / write signal of tag2
                1'bx,                                      // read / write signal of tag3
                18'b1_0000_0000_0000_0000_1,               // write data of tag
                1'bx,                                      // ready signal of l2_cache
                1'b0,
                26'b1110_0001_00,                          // address of memory
                `READ                                      // read / write signal of memory                
                );
            l2_tag_ram_tb(   
                18'bx,                                     // read data of tag0
                18'bx,                                     // read data of tag1
                18'bx,                                     // read data of tag2
                18'bx,                                     // read data of tag3
                3'bxxx,                                    // read data of tag
                `DISABLE                                   // complete write from L2 to L1
            );
        end       
        #STEP begin // WRITE_DC_W & WRITE_TO_L2_CLEAN & access l2_ram
            $display("\n========= Clock 3 ========");            
            l2_tag_ram_tb(   
                18'b1_0000_0000_0000_0000_1,               // read data of tag0
                18'bx,                                     // read data of tag1
                18'bx,                                     // read data of tag2
                18'bx,                                     // read data of tag3
                3'bx11,                                    // read data of tag
                `ENABLE                                    // complete write from L2 to L1
            );
            l2_data_ram_tb(
                512'h123BC000_0876547A_00000000_ABF00000_123BC000_00000000_0876547A_00000000_ABF00000_123BC000,         // read data of cache_data0
                512'bx,                                    // read data of cache_data1
                512'bx,                                    // read data of cache_data2
                512'bx                                     // read data of cache_data3
             );
            l2_cache_ctrl_tb(          
                `DISABLE,                                  // L2C busy mark
                128'h0876547A_00000000_ABF00000_123BC000,  // write data to L1_IC
                `DISABLE,                                  // write signal of tag0
                `DISABLE,                                  // write signal of tag1
                `DISABLE,                                  // write signal of tag2
                `DISABLE,                                  // write signal of tag3
                18'b1_0000_0000_0000_0000_1,               // write data of tag
                1'bx,                                      // ready signal of l2_cache
                1'b0,
                26'b1110_0001_00,                          // address of memory
                `READ                                      // read / write signal of memory                
                ); 
            tag_ram_tb(
                21'b1_0000_0000_0000_0000_1110,            // read data of tag0
                21'bx,                                     // read data of tag1
                1'b1,                                      // number of replacing block of tag next time
                1'b1                                       // complete write from L2 to L1
                );
            data_ram_tb(
                128'h0876547A_00000000_ABF00000_123BC000,  // read data of cache_data0
                128'hx                                     // read data of cache_data1
                );      
            l2_cache_ctrl_tb(             
                `DISABLE,                                  // L2C busy mark
                128'h0876547A_00000000_ABF00000_123BC000,  // write data to L1_IC
                `DISABLE,                                  // write signal of tag0
                `DISABLE,                                  // write signal of tag1
                `DISABLE,                                  // write signal of tag2
                `DISABLE,                                  // write signal of tag3
                18'b1_0000_0000_0000_0000_1,               // write data of tag
                1'bx,                                      // ready signal of l2_cache
                1'b0,
                26'b1110_0001_00,                          // address of memory
                `READ                                      // read / write signal of memory                
                );
            dcache_ctrl_tb(
                32'bx,                                     // read data of CPU
                `ENABLE,                                   // the signal of stall caused by cache miss
                `ENABLE,                                   // read / write signal of L1_tag0
                `DISABLE,                                  // read / write signal of L1_tag1
                21'b1_0000_0000_0000_0000_1110,            // write data of L1_tag
                8'b0001_0000,                              // address of L1_cache
                128'hx,                                    // data_rd choosing from data_rd0~data_rd1
                `DISABLE,                                  // icache request
                28'b1110_0001_0000,                        // l2_addr
                1'b1                                       // dirty_wd
                );             
        end        
        #STEP begin // WRITE_HIT & l2_IDLE        
            $display("\n========= Clock 4 ========");
            dcache_ctrl_tb(
                32'bx,                                     // read_data_m of CPU
                `DISABLE,                                  // miss_stall caused by cache miss
                `DISABLE,                                  // BLOCK0_we
                `DISABLE,                                  // BLOCK1_we
                21'b1_0000_0000_0000_0000_1110,            // tag_wd
                8'b0001_0000,                              // index
                128'hx,                                    // data_rd choosing from data_rd0~data_rd1
                `DISABLE,                                  // drq
                28'b1110_0001_0000,                        // l2_addr
                1'b1                                       // dirty_wd
                );
            tag_ram_tb(
                21'b1_0000_0000_0000_0000_1110,            // read data of tag0
                21'bx,                                     // read data of tag1
                1'b1,                                      // number of replacing block of tag next time
                1'b1                                       // complete write from L2 to L1
                );
            data_ram_tb(
                128'h0876547A_00000000_ABF00000_0000123B,  // read data of cache_data0
                128'hx                                     // read data of cache_data1
                ); 
            aluout_m   <= 30'b1110_0_110_0001_00_00_00;
            memwrite_m <= `WRITE;
            wr_data  <= 32'h4A985;
            mem_rd     <= 512'h00000000_0876547A_00000000_ABF00000_123BC000_00000000_0876547A_00000000_ABF00000_00000000;      // write data of l2_cache
        end
        #STEP begin // L1_ACCESS & l2_IDLE        
            $display("\n========= Clock 5 ========");
            tag_ram_tb(
                21'b1_0000_0000_0000_0000_1110,            // read data of tag0
                21'bx,                                     // read data of tag1
                1'b1,                                      // number of replacing block of tag next time
                1'b0                                       // complete write from L2 to L1
                );
            data_ram_tb(
                128'h0876547A_00000000_ABF00000_0000123B,  // read data of cache_data0
                128'hx                                     // read data of cache_data1
                );    
            
            dcache_ctrl_tb(
                32'bx,                                     // read_data_m of CPU
                `ENABLE,                                   // miss_stall caused by cache miss
                `DISABLE,                                  // tag0_rw
                `DISABLE,                                  // tag1_rw
                21'b1_0000_0000_0000_1110_0_110,           // tag_wd
                8'b0001_0000,                              // index
                128'hx,                                    // data_rd choosing from data_rd0~data_rd1
                `ENABLE,                                   // drq
                28'b1110_0_110_0001_00_00,                 // l2_addr
                1'b1                                       // dirty_wd
                );
            l2_cache_ctrl_tb(       
                `ENABLE,                                   // dc_en 
                128'h0876547A_00000000_ABF00000_123BC000,  // data_wd_l2 to L1_IC
                `DISABLE,                                  // l2_tag0_rw
                `DISABLE,                                  // l2_tag1_rw
                `DISABLE,                                  // l2_tag2_rw
                `DISABLE,                                  // l2_tag3_rw
                18'b1_0000_0000_0000_1110_0,               // l2_tag_wd
                1'bx,                                      // l2_rdy signal of l2_cache
                1'b0,                                      // l2_dirty0wd
                26'b1110_0001_00,                          // mem_addr
                `READ                                      // mem_rw                
                );
        end
        #STEP begin // L2_ACCESS & ACCESS_L2    
            $display("\n========= Clock 6 ========");
            l2_cache_ctrl_tb(         
                `ENABLE,                                   // dc_en 
                128'h0876547A_00000000_ABF00000_00000000,  // data_wd_l2 to L1_IC
                `DISABLE,                                  // l2_tag0_rw
                `ENABLE,                                   // l2_tag1_rw
                `DISABLE,                                  // l2_tag2_rw
                `DISABLE,                                  // l2_tag3_rw
                18'b1_0000_0000_0000_1110_0,               // l2_tag_wd
                1'bx,                                      // l2_rdy 
                1'b0,                                      // l2_dirty_wd
                26'b1110_0110_0001_00,                     // mem_addr
                `READ                                      // mem_rw                
                );
            tag_ram_tb(
                21'b1_0000_0000_0000_0000_1110,            // read data of tag0
                21'bx,                                     // read data of tag1
                1'b1,                                      // number of replacing block of tag next time
                1'b0                                       // complete write from L2 to L1
                );
            data_ram_tb(
                128'h0876547A_00000000_ABF00000_0000123B,  // read data of cache_data0
                128'hx                                     // read data of cache_data1
                );
            dcache_ctrl_tb(
                32'bx,                                     // read data of CPU
                `ENABLE,                                   // the signal of stall caused by cache miss
                `DISABLE,                                  // read / write signal of L1_tag0
                `ENABLE,                                   // read / write signal of L1_tag1
                21'b1_0000_0000_0000_1110_0_110,           // tag_wd
                8'b0001_0000,                              // address of L1_cache
                128'hx,                                    // data_rd choosing from data_rd0~data_rd1
                `ENABLE,                                   // dcache request
                28'b1110_0_110_0001_00_00,                 // l2_addr
                1'b1                                       // dirty_wd
                );
        end
        #STEP begin // WRITE_L1_W & WRITE_TO_L2      
            $display("\n========= Clock 7 ========");           
            tag_ram_tb(
                21'b1_0000_0000_0000_0000_1110,            // read data of tag0
                21'b1_0000_0000_0000_1110_0_110,           // read data of tag1
                1'b0,                                      // number of replacing block of tag next time
                1'b1                                       // complete write from L2 to L1
                );
            data_ram_tb(
                128'h0876547A_00000000_ABF00000_0000123B,  // read data of cache_data0
                128'h0876547A_00000000_ABF00000_00000000   // read data of cache_data1
                );
            dcache_ctrl_tb(
                32'bx,                                     // read data of CPU
                `ENABLE,                                   // the signal of stall caused by cache miss
                `DISABLE,                                  // read / write signal of L1_tag0
                `ENABLE,                                   // read / write signal of L1_tag1
                21'b1_0000_0000_0000_1110_0_110,           // tag_wd
                8'b0001_0000,                              // address of L1_cache 
                128'hx,                                    // data_rd choosing from data_rd0~data_rd1
                `DISABLE,                                  // icache request
                28'b1110_0_110_0001_00_00,                 // l2_addr
                1'b1                                       // dirty_wd
                ); 
        end
        #STEP begin // WRITE_HIT & WRITE_TO_L2        
            $display("\n========= Clock 8 ========");
            l2_cache_ctrl_tb(     
                `DISABLE,                                  // dc_en 
                128'h0876547A_00000000_ABF00000_00000000,  // data_wd_l2 to L1_IC
                `DISABLE,                                  // l2_tag0_rw
                `DISABLE,                                  // l2_tag1_rw
                `DISABLE,                                  // l2_tag2_rw
                `DISABLE,                                  // l2_tag3_rw
                18'b1_0000_0000_0000_1110_0,               // l2_tag_wd
                1'bx,                                      // l2_rdy 
                1'b0,                                      // l2_dirty_wd
                26'b1110_0110_0001_00,                     // mem_addr
                `READ                                      // mem_rw                
                );
            l2_tag_ram_tb(   
                18'b1_0000_0000_0000_0000_1,               // read data of tag0
                18'b1_0000_0000_0000_1110_0,               // read data of tag1
                18'bx,                                     // read data of tag2
                18'bx,                                     // read data of tag3
                3'bx01,                                    // read data of tag
                `ENABLE                                    // complete write from L2 to L1
            );
            l2_data_ram_tb(
                512'h123BC000_0876547A_00000000_ABF00000_123BC000_00000000_0876547A_00000000_ABF00000_123BC000,         // read data of cache_data0
                512'h00000000_0876547A_00000000_ABF00000_123BC000_00000000_0876547A_00000000_ABF00000_00000000,             // read data of cache_data1
                512'bx,                                    // read data of cache_data2
                512'bx                                     // read data of cache_data3
             );
            dcache_ctrl_tb(
                32'bx,                                     // read data of CPU
                `DISABLE,                                  // the signal of stall caused by cache miss
                `DISABLE,                                  // read / write signal of L1_tag0
                `DISABLE,                                  // read / write signal of L1_tag1
                21'b1_0000_0000_0000_1110_0_110,           // write data of L1_tag
                8'b0001_0000,                              // address of L1_cache
                128'hx,                                    // data_rd choosing from data_rd0~data_rd1
                `DISABLE,                                  // icache request
                28'b1110_0_110_0001_00_00,                 // l2_addr
                1'b1                                       // dirty_wd
                ); 
            tag_ram_tb(
                21'b1_0000_0000_0000_0000_1110,            // read data of tag0
                21'b1_0000_0000_0000_1110_0_110,           // read data of tag1
                1'b0,                                      // number of replacing block of tag next time
                1'b1                                       // complete write from L2 to L1
                );
            data_ram_tb(
                128'h0876547A_00000000_ABF00000_0000123B,  // read data of cache_data0
                128'h0876547A_00000000_ABF00000_0004A985   // read data of cache_data1
                );
            aluout_m   <= 30'b0101_1111_0_110_0001_00_00_00;
            memwrite_m <= `WRITE;
            wr_data  <= 32'h4A00;
            mem_rd     <= 512'h00000000_0876547A_00000000_ABF00000_123BC000_00000000_0876547A_00000000_ABF00000_00123400;      // write data of l2_cache
        end
        #STEP begin // DC_ACCESS & l2_IDLE         
            $display("\n========= Clock 9 ========");
            tag_ram_tb(
                21'b1_0000_0000_0000_0000_1110,            // read data of tag0
                21'b1_0000_0000_0000_1110_0_110,           // read data of tag1
                1'b0,                                      // number of replacing block of tag next time
                1'b0                                       // complete write from L2 to L1
                );
            data_ram_tb(
                128'h0876547A_00000000_ABF00000_0000123B,  // read data of cache_data0
                128'h0876547A_00000000_ABF00000_0004A985   // read data of cache_data1
                );
            
            l2_cache_ctrl_tb(        
                `ENABLE,                                   // dc_en 
                128'h0876547A_00000000_ABF00000_00000000,  // data_wd_l2 to L1_IC
                `DISABLE,                                  // l2_tag0_rw
                `DISABLE,                                  // l2_tag1_rw
                `DISABLE,                                  // l2_tag2_rw
                `DISABLE,                                  // l2_tag3_rw
                18'b1_0000_0000_0000_0000_1,               // l2_tag_wd
                1'bx,                                      // l2_rdy 
                1'b0,                                      // l2_dirty_wd
                26'b1110_0110_0001_00,                     // mem_addr
                `READ                                      // mem_rw                
                ); 
            dcache_ctrl_tb(
                32'bx,                                     // read_data_m of CPU
                `ENABLE,                                   // miss_stall caused by cache miss
                `DISABLE,                                  // tag0_rw
                `DISABLE,                                  // tag1_rw
                21'b1_0000_0000_0101_1111_0_110,           // tag_wd of L1_tag
                8'b0001_0000,                              // index
                128'h0876547A_00000000_ABF00000_0000123B,  // data_rd choosing from data_rd0~data_rd1
                `ENABLE,                                   // drq
                28'b0000_0000_0000_0000_1110_0001_00_00,   // l2_addr
                1'b1                                       // dirty_wd
                );   
        end
        #STEP begin // DC_WRITE_L2 & ACCESS_L2       
            $display("\n========= Clock 10 ========");
             l2_cache_ctrl_tb(         
                `ENABLE,                                   // dc_en 
                128'h0876547A_00000000_ABF00000_00000000,  // data_wd_l2 to L1_IC
                `ENABLE,                                   // l2_tag0_rw
                `DISABLE,                                  // l2_tag1_rw
                `DISABLE,                                  // l2_tag2_rw
                `DISABLE,                                  // l2_tag3_rw
                18'b1_0000_0000_0000_0000_1,               // l2_tag_wd
                1'bx,                                      // l2_rdy 
                1'b1,                                      // l2_dirty_wd
                26'b1110_0110_0001_00,                     // mem_addr
                `READ                                      // mem_rw                
                );
            dcache_ctrl_tb(
                32'bx,                                     // read_data_m of CPU
                `ENABLE,                                   // miss_stall caused by cache miss
                `DISABLE,                                  // tag0_rw
                `DISABLE,                                  // tag1_rw
                21'b1_0000_0000_0101_1111_0_110,           // tag_wd of L1_tag
                8'b0001_0000,                              // index
                128'h0876547A_00000000_ABF00000_0000123B,  // data_rd choosing from data_rd0~data_rd1
                `ENABLE,                                   // drq
                28'b0000_0000_0000_0000_1110_0001_00_00,   // l2_addr
                1'b1                                       // dirty_wd
                ); 
        end
        #STEP begin // DC_WRITE_L2 & L2_WRITE_HIT      
            $display("\n========= Clock 11 ========"); 
            l2_cache_ctrl_tb(          
                `ENABLE,                                   // dc_en 
                128'h0876547A_00000000_ABF00000_00000000,  // data_wd_l2 to L1_IC
                `DISABLE,                                  // l2_tag0_rw
                `DISABLE,                                  // l2_tag1_rw
                `DISABLE,                                  // l2_tag2_rw
                `DISABLE,                                  // l2_tag3_rw
                18'b1_0000_0000_0101_1111_0,               // l2_tag_wd
                1'bx,                                      // l2_rdy 
                1'b1,                                      // l2_dirty_wd
                26'b1110_0110_0001_00,                     // mem_addr
                `READ                                      // mem_rw                
                );
            dcache_ctrl_tb(
                32'bx,                                     // read_data_m of CPU
                `ENABLE,                                   // miss_stall caused by cache miss
                `DISABLE,                                  // tag0_rw
                `DISABLE,                                  // tag1_rw
                21'b1_0000_0000_0101_1111_0_110,           // tag_wd of L1_tag
                8'b0001_0000,                              // index
                128'h0876547A_00000000_ABF00000_0000123B,  // data_rd choosing from data_rd0~data_rd1
                `ENABLE,                                   // drq
                28'b0101_1111_0_110_0001_00_00,            // l2_addr
                1'b1                                       // dirty_wd
                ); 
            l2_tag_ram_tb(   
                18'b1_0000_0000_0000_0000_1,               // read data of tag0
                18'b1_0000_0000_0000_1110_0,               // read data of tag1
                18'bx,                                     // read data of tag2
                18'bx,                                     // read data of tag3
                3'bx11,                                    // read data of tag
                `ENABLE                                    // complete write from L2 to L1
            );
            l2_data_ram_tb(
                512'h123BC000_0876547A_00000000_ABF00000_123BC000_00000000_0876547A_00000000_ABF00000_0000123B,         // read data of cache_data0
                512'h00000000_0876547A_00000000_ABF00000_123BC000_00000000_0876547A_00000000_ABF00000_00000000,             // read data of cache_data1
                512'bx,                                    // read data of cache_data2
                512'bx                                     // read data of cache_data3
             );
        end
        #STEP begin // DC_ACCESS_L2 & ACCESS_L2
            $display("\n========= Clock 12 ========");    
            dcache_ctrl_tb(
                32'bx,                                     // read_data_m of CPU
                `ENABLE,                                   // miss_stall caused by cache miss
                `ENABLE,                                   // tag0_rw
                `DISABLE,                                  // tag1_rw
                21'b1_0000_0000_0101_1111_0_110,           // tag_wd of L1_tag
                8'b0001_0000,                              // index
                128'h0876547A_00000000_ABF00000_0000123B,  // data_rd choosing from data_rd0~data_rd1
                `ENABLE,                                   // drq
                28'b0101_1111_0_110_0001_00_00,            // l2_addr
                1'b0                                       // dirty_wd
                );  
            l2_cache_ctrl_tb(          
                `ENABLE,                                   // dc_en 
                128'h0876547A_00000000_ABF00000_00123400,  // data_wd_l2 to L1_IC
                `DISABLE,                                  // l2_tag0_rw
                `DISABLE,                                  // l2_tag1_rw
                `ENABLE,                                   // l2_tag2_rw
                `DISABLE,                                  // l2_tag3_rw
                18'b1_0000_0000_0101_1111_0,               // l2_tag_wd
                1'bx,                                      // l2_rdy 
                1'b0,                                      // l2_dirty_wd
                26'b0101_1111_0_110_0001_00,               // mem_addr
                `READ                                      // mem_rw                
                );
        end
        #STEP begin // WRITE_DC_W & WRITE_TO_L2_CLEAN
            $display("\n========= Clock 13 ========");  
            l2_cache_ctrl_tb(            
                `DISABLE,                                  // dc_en 
                128'h0876547A_00000000_ABF00000_00123400,  // data_wd_l2 to L1_IC
                `DISABLE,                                  // l2_tag0_rw
                `DISABLE,                                  // l2_tag1_rw
                `DISABLE,                                  // l2_tag2_rw
                `DISABLE,                                  // l2_tag3_rw
                18'b1_0000_0000_0101_1111_0,               // l2_tag_wd
                1'bx,                                      // l2_rdy 
                1'b0,                                      // l2_dirty_wd
                26'b0101_1111_0_110_0001_00,               // mem_addr
                `READ                                      // mem_rw                
                );
            l2_tag_ram_tb(   
                18'b1_0000_0000_0000_0000_1,               // read data of tag0
                18'b1_0000_0000_0000_1110_0,               // read data of tag1
                18'b1_0000_0000_0101_1111_0,               // read data of tag2
                18'bx,                                     // read data of tag3
                3'b110,                                    // read data of tag
                `ENABLE                                    // complete write to L2
            );
            l2_data_ram_tb(
                512'h123BC000_0876547A_00000000_ABF00000_123BC000_00000000_0876547A_00000000_ABF00000_0000123B,         // read data of cache_data0
                512'h00000000_0876547A_00000000_ABF00000_123BC000_00000000_0876547A_00000000_ABF00000_00000000,             // read data of cache_data1
                512'h00000000_0876547A_00000000_ABF00000_123BC000_00000000_0876547A_00000000_ABF00000_00123400,             // read data of cache_data2
                512'bx                                     // read data of cache_data3
             );
            dcache_ctrl_tb(
                32'bx,                                     // read_data_m of CPU
                `ENABLE,                                   // miss_stall caused by cache miss
                `ENABLE ,                                  // tag0_rw
                `READ,                                     // tag1_rw
                21'b1_0000_0000_0101_1111_0_110,           // tag_wd of L1_tag
                8'b0001_0000,                              // index
                128'h0876547A_00000000_ABF00000_0000123B,  // data_rd choosing from data_rd0~data_rd1
                `DISABLE,                                  // drq
                28'b0101_1111_0_110_0001_00_00,            // l2_addr
                1'b0                                       // dirty_wd
                ); 
            tag_ram_tb(
                21'b1_0000_0000_0101_1111_0_110,           // read data of tag0
                21'b1_0000_0000_0000_1110_0_110,           // read data of tag1
                1'b1,                                      // number of replacing block of tag next time
                1'b1                                       // complete write from L2 to L1
                );
            data_ram_tb(
                128'h0876547A_00000000_ABF00000_00123400,  // read data of cache_data0
                128'h0876547A_00000000_ABF00000_0004A985   // read data of cache_data1
                );
        end
        #STEP begin // WRITE_HIT & L2_IDLE 
            $display("\n========= Clock 14 ========");          
            dcache_ctrl_tb(
                32'bx,                                     // read_data_m of CPU
                `DISABLE,                                  // miss_stall caused by cache miss
                `DISABLE ,                                 // tag0_rw
                `DISABLE,                                  // tag1_rw
                21'b1_0000_0000_0101_1111_0_110,           // tag_wd of L1_tag
                8'b0001_0000,                              // index
                128'h0876547A_00000000_ABF00000_0000123B,  // data_rd choosing from data_rd0~data_rd1
                `DISABLE,                                  // drq
                28'b0101_1111_0_110_0001_00_00,            // l2_addr
                1'b0                                       // dirty_wd
                ); 
            l2_cache_ctrl_tb(        
                `DISABLE,                                  // dc_en 
                128'h0876547A_00000000_ABF00000_00123400,  // data_wd_l2 to L1_IC
                `DISABLE,                                  // l2_tag0_rw
                `DISABLE,                                  // l2_tag1_rw
                `DISABLE,                                  // l2_tag2_rw
                `DISABLE,                                  // l2_tag3_rw
                18'b1_0000_0000_0101_1111_0,               // l2_tag_wd
                1'bx,                                      // l2_rdy 
                1'b0,                                      // l2_dirty_wd
                26'b0101_1111_0_110_0001_00,               // mem_addr
                `READ                                      // mem_rw                
                );
            tag_ram_tb(
                21'b1_0000_0000_0101_1111_0_110,           // read data of tag0
                21'b1_0000_0000_0000_1110_0_110,           // read data of tag1
                1'b1,                                      // number of replacing block of tag next time
                1'b1                                       // complete write from L2 to L1
                );
            data_ram_tb(
                128'h0876547A_00000000_ABF00000_00004A00,  // read data of cache_data0
                128'h0876547A_00000000_ABF00000_0004A985   // read data of cache_data1
                );
            // $stop;       // modelsim
            $finish;     // iverilog
        end
    end
    
    /********** output wave **********/
    initial begin
        $dumpfile("dcache_write_test.vcd");
        $dumpvars(0,dcache_ctrl,clk_2,clk_4,mem,dtag_ram,ddata_ram,l2_tag_ram,l2_data_ram,l2_cache_ctrl);
    end

endmodule 