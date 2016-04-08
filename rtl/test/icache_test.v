/*
 -- ============================================================================
 -- FILE NAME   : icache_test.v
 -- DESCRIPTION : testbench of icache
 -- ----------------------------------------------------------------------------
 -- Date:2016/1/18        Coding_by:kippy
 -- ============================================================================
*/
`timescale 1ns/1ps
/********** header file **********/
`include "stddef.h"
`include "icache.h"
`include "l2_cache.h"

module icache_test();
    // icache part
    reg              clk;           // clock
    reg              rst;           // reset
    /* CPU part */
    reg      [31:0]  if_addr;       // address of fetching instruction
    reg              rw;            // read / write signal of CPU
    wire     [31:0]  cpu_data;      // read data of CPU
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
    wire     [127:0] data_wd_l2;    // write data to L1 from L2
    wire     [127:0] data_wd_dc;    // write data to L1 from CPU
    wire             data_wd_l2_en; // enable signal of writing data to L1 from L2
    wire             data_wd_dc_en; // enable signal of writing data to L1 from L2
    wire     [127:0] data_rd;
    wire             l2_tag0_rw;    // read / write signal of tag0
    wire             l2_tag1_rw;    // read / write signal of tag1
    wire             l2_tag2_rw;    // read / write signal of tag0
    wire             l2_tag3_rw;    // read / write signal of tag1
    wire     [17:0]  l2_tag_wd;     // write data of tag
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
    reg              mem_complete;
    // tag_ram part
    wire     [20:0]  tag0_rd;       // read data of tag0
    wire     [20:0]  tag1_rd;       // read data of tag1
    wire             lru;           // read data of tag
    wire             complete;      // complete write from L2 to L1 
    // data_ram part
    wire     [127:0] data0_rd;      // read data of cache_data0
    wire     [127:0] data1_rd;      // read data of cache_data1
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
    reg              clk_tmp;        // temporary clock of L2C
    wire             data_rdy;
    icache_ctrl icache_ctrl(
        .clk            (clk),           // clock
        .rst            (rst),           // reset
        /* CPU part */
        .if_addr        (if_addr),       // address of fetching instruction
        .rw             (rw),            // read / write signal of CPU
        .cpu_data       (cpu_data),      // read data of CPU
        .miss_stall     (miss_stall),    // the signal of stall caused by cache miss
        /* L1_cache part */
        .lru            (lru),           // mark of replacing
        .tag0_rd        (tag0_rd),       // read data of tag0
        .tag1_rd        (tag1_rd),       // read data of tag1
        .data0_rd       (data0_rd),      // read data of data0
        .data1_rd       (data1_rd),      // read data of data1
        .tag0_rw        (tag0_rw),       // read / write signal of L1_tag0
        .tag1_rw        (tag1_rw),       // read / write signal of L1_tag1
        .tag_wd         (tag_wd),        // write data of L1_tag
        .data0_rw       (data0_rw),      // read / write signal of data0
        .data1_rw       (data1_rw),      // read / write signal of data1
        .index          (index),         // address of L1_cache
        /* l2_cache part */
        .l2_busy        (l2_busy),       // busy signal of l2_cache
        .l2_rdy         (l2_rdy),        // ready signal of l2_cache
        .complete       (complete),      // complete op writing to L1
        .irq            (irq),
        .l2_index       (l2_index),        
        .l2_addr        (l2_addr),        
        .l2_cache_rw    (l2_cache_rw), 
        .data_rdy       (data_rdy)        
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
        .l2_dirty_wd   (l2_dirty_wd),
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
    itag_ram itag_ram(
        .clk            (clk),           // clock
        .tag0_rw        (tag0_rw),       // read / write signal of tag0
        .tag1_rw        (tag1_rw),       // read / write signal of tag1
        .index          (index),         // address of cache
        .tag_wd         (tag_wd),        // write data of tag
        .tag0_rd        (tag0_rd),       // read data of tag0
        .tag1_rd        (tag1_rd),       // read data of tag1
        .lru            (lru),           // read data of tag
        .complete       (complete)       // complete write from L2 to L1
        );
    data_ram data_ram(
        .clk            (clk),           // clock
        .data0_rw       (data0_rw),      // the mark of cache_data0 write signal 
        .data1_rw       (data1_rw),      // the mark of cache_data1 write signal 
        .index          (index),         // address of cache__
        .data_wd_l2     (data_wd_l2),       // write data of l2_cache
        .data_wd_dc     (data_wd_dc),       // write data of l2_cache
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

    task icache_ctrl_tb;
        input  [31:0]  _cpu_data;        // read data of CPU
        input          _miss_stall;      // the signal of stall caused by cache miss
        /* L1_cache part */
        input          _tag0_rw;         // read / write signal of L1_tag0
        input          _tag1_rw;         // read / write signal of L1_tag1
        input  [20:0]  _tag_wd;          // write data of L1_tag
        input          _data0_rw;        // read / write signal of data0
        input          _data1_rw;        // read / write signal of data1
        input  [7:0]   _index;           // address of L1_cache
        /* l2_cache part */
        input          _irq;             // icache request
        input  [8:0]   _l2_index;
        input  [31:0]  _l2_addr;
        begin 
            if( (cpu_data   === _cpu_data)          && 
                (miss_stall === _miss_stall)        && 
                (tag0_rw    === _tag0_rw)           && 
                (tag1_rw    === _tag1_rw)           && 
                (tag_wd     === _tag_wd)            && 
                (data0_rw   === _data0_rw)          && 
                (data1_rw   === _data1_rw)          && 
                (index      === _index)             && 
                (irq        === _irq)               && 
                (l2_index   === _l2_index)          && 
                (l2_addr    === _l2_addr)    
               ) begin 
                 $display("Icache Test Succeeded !"); 
            end else begin 
                 $display("Icache Test Failed !"); 
            end 
            if (cpu_data   !== _cpu_data) begin
                $display("cpu_data:%b(excepted %b)",cpu_data,_cpu_data); 
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
                 $display("l2_icache Test Succeeded !"); 
            end else begin 
                 $display("l2_icache Test Failed !"); 
            end 
            // check
            if(l2_miss_stall !== _l2_miss_stall)begin 
                $display("l2_miss_stall Test Failed !"); 
            end
            if(l2_busy       !== _l2_busy)     begin
                $display("l2_busy Test Failed !"); 
            end
            if(data_wd_l2       !== _data_wd_l2)     begin
                $display("data_wd_l2 Test Failed !"); 
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
            if (l2_dirty_wd !== _l2_dirty_wd) begin
                $display("l2_dirty0_wd Test Failed !"); 
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
            if (tag0_rd  !== _tag0_rd) begin
                $display("tag0_rd:%b(excepted %b)",tag0_rd,_tag0_rd); 
            end
            if (tag1_rd  !== _tag1_rd) begin
                $display("tag1_rd:%b(excepted %b)",tag1_rd,_tag1_rd); 
            end
            if (lru      !== _lru) begin
                $display("lru:%b(excepted %b)",lru,_lru); 
            end
            if (complete !== _complete) begin
                $display("complete:%b(excepted %b)",complete,_complete); 
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
            clk = ~clk;  
        end
    always #STEP
        begin
            clk_tmp = ~clk_tmp;  
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
            if_addr    <= 32'b1110_0001_0000_0000;
            rw         <= `READ;
            mem_rd <= 512'h123BC000_0876547A_00000000_ABF00000_123BC000_00000000_0876547A_00000000_ABF00000_123BC000;      // write data of l2_cache
            // l2_busy <= `DISABLE;                                      // busy signal of l2_cache
            // l2_rdy  <= `ENABLE;                                       // ready signal of l2_cache
            // data_wd <= 128'h0876547A_00000000_ABF00000_123BC000;      // write data of L1_cache
        end
        #STEP begin // L1_IDLE & L2_IDLE 
            $display("\n========= Clock 1 ========");
            l2_cache_ctrl_tb(
                `DISABLE,           // miss caused by L2C             
                `DISABLE,            // L2C busy mark
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
        #STEP begin // L1_ACCESS & L2_IDLE 
            $display("\n========= Clock 2 ========");
        end
        #STEP begin // L2_ACCESS & ACCESS_L2 
            $display("\n========= Clock 3 ========");
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
            l2_tag_ram_tb(   
                18'b0,            // read data of tag0
                18'b0,            // read data of tag1
                18'b0,            // read data of tag2
                18'b0,            // read data of tag3
                3'b000,           // read data of tag
                `DISABLE          // complete write from L2 to L1
            );
        end      
        // 2* clk state ACCESS_L2 really 
        #STEP begin // L2_ACCESS & 2* clk state change to ACCESS_L2 really 
            $display("\n========= Clock 4 ========");
                  
        end       
        #STEP begin // l2_ACCESS & WRITE_L2 & access l2_ram
            $display("\n========= Clock 5 ========");            
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
            icache_ctrl_tb(
                32'bx,          // read data of CPU
                `ENABLE,        // the signal of stall caused by cache miss
                `READ,          // read / write signal of L1_tag0
                `READ,          // read / write signal of L1_tag1
                21'bx,       // write data of L1_tag
                `READ,          // read / write signal of data0
                `READ,          // read / write signal of data1
                8'b0001_0000,   // address of L1_cache
                `ENABLE,         // icache request
                9'b110_0001_00,
                32'b1110_0001_0000_0000
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
        #STEP begin // l2_ACCESS & WRITE_L2 & access l2_ram
            $display("\n========= Clock 6 ========"); 
            
        end
        #STEP begin // l2_ACCESS  &  ACCESS_L2
            $display("\n========= Clock 7 ========"); 
            l2_cache_ctrl_tb(
                `DISABLE,           // miss caused by L2C             
                `ENABLE,            // L2C busy mark
                128'h0876547A_00000000_ABF00000_123BC000,  // write data to L1_IC
                `READ,              // read / write signal of tag0
                `READ,              // read / write signal of tag1
                `READ,              // read / write signal of tag2
                `READ,              // read / write signal of tag3
                18'b1_0000_0000_0000_0000_1,  // write data of tag
                `ENABLE,            // ready signal of l2_cache
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
            icache_ctrl_tb(
                32'bx,          // read data of CPU
                `ENABLE,        // the signal of stall caused by cache miss
                `WRITE,          // read / write signal of L1_tag0
                `READ,          // read / write signal of L1_tag1
                21'b1_0000_0000_0000_0000_1110,           // tag_wd
                `WRITE,          // read / write signal of data0
                `READ,          // read / write signal of data1
                8'b0001_0000,   // address of L1_cache
                `ENABLE,        // icache request
                9'b110_0001_00,
                32'b1110_0001_0000_0000
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
        #STEP begin // WRITE_IC  & 2* clk state change to ACCESS_L2 really    
            $display("\n========= Clock 8 ========"); 
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
            icache_ctrl_tb(
                32'bx,          // read data of CPU
                `DISABLE,        // the signal of stall caused by cache miss
                `READ,          // read / write signal of L1_tag0
                `READ,          // read / write signal of L1_tag1
                21'b1_0000_0000_0000_0000_1110,       // write data of L1_tag
                `READ,          // read / write signal of data0
                `READ,          // read / write signal of data1
                8'b0001_0000,   // address of L1_cache
                `DISABLE,         // icache request
                9'b110_0001_00,
                32'b1110_0001_0000_0000
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
        #STEP begin // L1_ACCESS  & l2_IDLE        
            $display("\n========= Clock 9 ========");
            tag_ram_tb(
                21'b1_0000_0000_0000_0000_1110,         // read data of tag0
                21'b0,                                  // read data of tag1
                1'b1,                                   // number of replacing block of tag next time
                1'b0                                    // complete write from L2 to L1
                );
            data_ram_tb(
                128'h0876547A_00000000_ABF00000_123BC000,   // read data of cache_data0
                128'h0                                      // read data of cache_data1
                ); 
            $finish;     // iverilog
        end
        // #10 $stop;       // modelsim       
    end
    /********** output wave **********/
    initial begin
        $dumpfile("icache.vcd");
        $dumpvars(0,icache_ctrl,itag_ram,data_ram,l2_tag_ram,l2_data_ram,l2_cache_ctrl);
    end
endmodule 