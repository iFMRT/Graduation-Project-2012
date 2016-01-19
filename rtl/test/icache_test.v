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
    wire     [19:0]  tag_wd;        // write data of L1_tag
    wire             data0_rw;      // read / write signal of cache_data0
    wire             data1_rw;      // read / write signal of cache_data1
    wire     [7:0]   index;         // address of L1_cache
    /* L2_cache part */
    wire             irq;           // icache request
    // reg              L2_busy;    // L2C busy mark
    // reg              L2_rdy;     // L2C ready mark
    // reg      [127:0] data_wd;    // write data to L1_IC
    // L2_icache
    /* CPU part */
    wire             L2_miss_stall; // stall caused by L2_miss
    /*cache part*/
    wire             L2_busy;       // busy mark of L2C
    wire     [127:0] data_wd;       // write data to L1_IC
    wire             L2_tag0_rw;    // read / write signal of tag0
    wire             L2_tag1_rw;    // read / write signal of tag1
    wire             L2_tag2_rw;    // read / write signal of tag0
    wire             L2_tag3_rw;    // read / write signal of tag1
    wire     [16:0]  L2_tag_wd;     // write data of tag0
    wire             L2_rdy;        // ready mark of L2C
    wire             L2_data0_rw;   // the mark of cache_data0 write signal 
    wire             L2_data1_rw;   // the mark of cache_data1 write signal 
    wire             L2_data2_rw;   // the mark of cache_data2 write signal 
    wire             L2_data3_rw;   // the mark of cache_data3 write signal 
    wire     [8:0]   L2_index;      // address of cache
    /*memory part*/
    wire     [25:0]  mem_addr;      // address of memory
    wire             mem_rw;        // read / write signal of memory

    // tag_ram part
    wire     [20:0]  tag0_rd;       // read data of tag0
    wire     [20:0]  tag1_rd;       // read data of tag1
    wire             LUR;           // read data of tag
    wire             complete;      // complete write from L2 to L1
    // data_ram part
    wire     [127:0] data0_rd;      // read data of cache_data0
    wire     [127:0] data1_rd;      // read data of cache_data1
    // L2_tag_ram part
    wire     [18:0]  L2_tag0_rd;    // read data of tag0
    wire     [18:0]  L2_tag1_rd;    // read data of tag1
    wire     [18:0]  L2_tag2_rd;    // read data of tag2
    wire     [18:0]  L2_tag3_rd;    // read data of tag3
    wire     [2:0]   PLUR;          // read data of tag
    wire             L2_complete;   // complete write from MEM to L2
    // L2_data_ram
    reg      [511:0] L2_data_wd;     // write data of L2_cache
    wire     [511:0] L2_data0_rd;    // read data of cache_data0
    wire     [511:0] L2_data1_rd;    // read data of cache_data1
    wire     [511:0] L2_data2_rd;    // read data of cache_data2
    wire     [511:0] L2_data3_rd;    // read data of cache_data3 
    reg              clk_tmp;        // temporary clock of L2C
    icache icache(
        .clk            (clk),           // clock
        .rst            (rst),           // reset
        /* CPU part */
        .if_addr        (if_addr),       // address of fetching instruction
        .rw             (rw),            // read / write signal of CPU
        .cpu_data       (cpu_data),      // read data of CPU
        .miss_stall     (miss_stall),    // the signal of stall caused by cache miss
        /* L1_cache part */
        .LRU            (LRU),           // mark of replacing
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
        /* L2_cache part */
        .L2_busy        (L2_busy),       // busy signal of L2_cache
        .L2_rdy         (L2_rdy),        // ready signal of L2_cache
        .complete       (complete),      // complete op writing to L1
        .irq            (irq)            // icache request
        );
    L2_icache L2_icache(
        .clk            (clk_tmp),       // clock of L2C
        .rst            (rst),           // reset
        /* CPU part */
        .if_addr        (if_addr),       // address of fetching instruction
        .rw             (rw),            // read / write signal of CPU
        .L2_miss_stall  (L2_miss_stall), // stall caused by L2_miss
        /*cache part*/
        .irq            (irq),           // icache request
        .complete       (complete),      // complete write from L2 to L1
        .L2_complete    (L2_complete),   // complete write from MEM to L2
        .PLUR           (PLUR),          // replace mark
        .L2_tag0_rd     (L2_tag0_rd),    // read data of tag0
        .L2_tag1_rd     (L2_tag1_rd),    // read data of tag1
        .L2_tag2_rd     (L2_tag2_rd),    // read data of tag2
        .L2_tag3_rd     (L2_tag3_rd),    // read data of tag3
        .L2_busy        (L2_busy),
        .L2_data0_rd    (L2_data0_rd),   // read data of cache_data0
        .L2_data1_rd    (L2_data1_rd),   // read data of cache_data1
        .L2_data2_rd    (L2_data2_rd),   // read data of cache_data2
        .L2_data3_rd    (L2_data3_rd),   // read data of cache_data3
        .data_wd        (data_wd),       // write data to L1_IC
        .L2_tag0_rw     (L2_tag0_rw),    // read / write signal of tag0
        .L2_tag1_rw     (L2_tag1_rw),    // read / write signal of tag1
        .L2_tag2_rw     (L2_tag2_rw),    // read / write signal of tag0
        .L2_tag3_rw     (L2_tag3_rw),    // read / write signal of tag1
        .L2_tag_wd      (L2_tag_wd),     // write data of tag0
        .L2_rdy         (L2_rdy),
        .L2_data0_rw    (L2_data0_rw),   // the mark of cache_data0 write signal 
        .L2_data1_rw    (L2_data1_rw),   // the mark of cache_data1 write signal 
        .L2_data2_rw    (L2_data2_rw),   // the mark of cache_data2 write signal 
        .L2_data3_rw    (L2_data3_rw),   // the mark of cache_data3 write signal 
        .L2_index       (L2_index),      // address of cache
        /*memory part*/
        .mem_addr        (mem_addr),     // address of memory
        .mem_rw          (mem_rw)        // read / write signal of memory
    );
    tag_ram tag_ram(
        .clk            (clk),           // clock
        .tag0_rw        (tag0_rw),       // read / write signal of tag0
        .tag1_rw        (tag1_rw),       // read / write signal of tag1
        .index          (index),         // address of cache
        .tag_wd         (tag_wd),        // write data of tag
        .tag0_rd        (tag0_rd),       // read data of tag0
        .tag1_rd        (tag1_rd),       // read data of tag1
        .LUR            (LUR),           // read data of tag
        .complete       (complete)       // complete write from L2 to L1
        );
    data_ram data_ram(
        .clk            (clk),           // clock
        .data0_rw       (data0_rw),      // the mark of cache_data0 write signal 
        .data1_rw       (data1_rw),      // the mark of cache_data1 write signal 
        .index          (index),         // address of cache__
        .data_wd        (data_wd),       // write data of L2_cache
        .data0_rd       (data0_rd),      // read data of cache_data0
        .data1_rd       (data1_rd)       // read data of cache_data1
    );
    L2_data_ram L2_data_ram(
        .clk            (clk_tmp),       // clock of L2C
        .L2_data0_rw    (L2_data0_rw),   // the mark of cache_data0 write signal 
        .L2_data1_rw    (L2_data1_rw),   // the mark of cache_data1 write signal 
        .L2_data2_rw    (L2_data2_rw),   // the mark of cache_data2 write signal 
        .L2_data3_rw    (L2_data3_rw),   // the mark of cache_data3 write signal 
        .L2_index       (L2_index),      // address of cache
        .L2_data_wd     (L2_data_wd),    // write data of L2_cache
        .L2_data0_rd    (L2_data0_rd),   // read data of cache_data0
        .L2_data1_rd    (L2_data1_rd),   // read data of cache_data1
        .L2_data2_rd    (L2_data2_rd),   // read data of cache_data2
        .L2_data3_rd    (L2_data3_rd)    // read data of cache_data3
    );
    L2_tag_ram L2_tag_ram(    
        .clk            (clk_tmp),       // clock of L2C
        .L2_tag0_rw     (L2_tag0_rw),    // read / write signal of tag0
        .L2_tag1_rw     (L2_tag1_rw),    // read / write signal of tag1
        .L2_tag2_rw     (L2_tag2_rw),    // read / write signal of tag2
        .L2_tag3_rw     (L2_tag3_rw),    // read / write signal of tag3
        .L2_index       (L2_index),      // address of cache
        .L2_tag_wd      (L2_tag_wd),     // write data of tag
        .L2_tag0_rd     (L2_tag0_rd),    // read data of tag0
        .L2_tag1_rd     (L2_tag1_rd),    // read data of tag1
        .L2_tag2_rd     (L2_tag2_rd),    // read data of tag2
        .L2_tag3_rd     (L2_tag3_rd),    // read data of tag3
        .PLUR           (PLUR),          // read data of tag
        .L2_complete    (L2_complete)    // complete write from L2 to L1
    );

    task icache_tb;
        input  [31:0]  _cpu_data;        // read data of CPU
        input          _miss_stall;      // the signal of stall caused by cache miss
        /* L1_cache part */
        input          _tag0_rw;         // read / write signal of L1_tag0
        input          _tag1_rw;         // read / write signal of L1_tag1
        input  [19:0]  _tag_wd;          // write data of L1_tag
        input          _data0_rw;        // read / write signal of data0
        input          _data1_rw;        // read / write signal of data1
        input  [7:0]   _index;           // address of L1_cache
        /* L2_cache part */
        input          _irq;             // icache request
        begin 
            if( (cpu_data   === _cpu_data)          && 
                (miss_stall === _miss_stall)        && 
                (tag0_rw    === _tag0_rw)           && 
                (tag1_rw    === _tag1_rw)           && 
                (tag_wd     === _tag_wd)            && 
                (data0_rw   === _data0_rw)          && 
                (data1_rw   === _data1_rw)          && 
                (index      === _index)             && 
                (irq        === _irq)    
               ) begin 
                 $display("Icache Test Succeeded !"); 
            end else begin 
                 $display("Icache Test Failed !"); 
            end 
        end
    endtask
    task L2_icache_tb;
        input           _L2_miss_stall;      // miss caused by L2C
        input           _L2_busy;            // L2C busy mark
        input   [127:0] _data_wd;            // write data to L1_IC
        input           _L2_tag0_rw;         // read / write signal of tag0
        input           _L2_tag1_rw;         // read / write signal of tag1
        input           _L2_tag2_rw;         // read / write signal of tag0
        input           _L2_tag3_rw;         // read / write signal of tag1
        input   [16:0]  _L2_tag_wd;          // write data of tag0
        input           _L2_rdy;             // ready signal of L2_cache
        input           _L2_data0_rw;        // the mark of cache_data0 write signal 
        input           _L2_data1_rw;        // the mark of cache_data1 write signal 
        input           _L2_data2_rw;        // the mark of cache_data2 write signal 
        input           _L2_data3_rw;        // the mark of cache_data3 write signal 
        input   [8:0]   _L2_index;           // address of cache
        input   [25:0]  _mem_addr;           // address of memory
        input           _mem_rw;             // read / write signal of memory
        begin 
            if( (L2_miss_stall === _L2_miss_stall)  && 
                (L2_busy       === _L2_busy)        && 
                (data_wd       === _data_wd)        && 
                (L2_tag0_rw    === _L2_tag0_rw)     && 
                (L2_tag1_rw    === _L2_tag1_rw)     && 
                (L2_tag2_rw    === _L2_tag2_rw)     && 
                (L2_tag3_rw    === _L2_tag3_rw)     && 
                (L2_tag_wd     === _L2_tag_wd)      && 
                (L2_rdy        === _L2_rdy)         && 
                (L2_data0_rw   === _L2_data0_rw)    && 
                (L2_data1_rw   === _L2_data1_rw)    && 
                (L2_data2_rw   === _L2_data2_rw)    && 
                (L2_data3_rw   === _L2_data3_rw)    && 
                (L2_index      === _L2_index)       && 
                (mem_addr      === _mem_addr)       && 
                (mem_rw        === _mem_rw)  
               ) begin 
                 $display("L2_icache Test Succeeded !"); 
            end else begin 
                 $display("L2_icache Test Failed !"); 
            end 
        end
    endtask
    task tag_ram_tb;
        input      [20:0]  _tag0_rd;        // read data of tag0
        input      [20:0]  _tag1_rd;        // read data of tag1
        input              _LUR;            // read block of tag
        input              _complete;       // complete write from L2 to L1
        begin 
            if( (tag0_rd  === _tag0_rd)     && 
                (tag1_rd  === _tag1_rd)     && 
                (LUR      === _LUR)         && 
                (complete === _complete)              
               ) begin 
                 $display("Tag_ram Test Succeeded !"); 
            end else begin 
                 $display("Tag_ram Test Failed !"); 
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
    task L2_tag_ram_tb;    
        input      [18:0]  _L2_tag0_rd;        // read data of tag0
        input      [18:0]  _L2_tag1_rd;        // read data of tag1
        input      [18:0]  _L2_tag2_rd;        // read data of tag2
        input      [18:0]  _L2_tag3_rd;        // read data of tag3
        input      [2:0]   _PLUR;              // read data of tag
        input              _L2_complete;       // complete write from L2 to L1
        begin 
            if( (L2_tag0_rd  === _L2_tag0_rd)   && 
                (L2_tag1_rd  === _L2_tag1_rd)   && 
                (L2_tag2_rd  === _L2_tag2_rd)   && 
                (L2_tag3_rd  === _L2_tag3_rd)   && 
                (PLUR        === _PLUR)         && 
                (L2_complete === _L2_complete)
               ) begin 
                 $display("L2_tag_ram Test Succeeded !"); 
            end else begin 
                 $display("L2_tag_ram Test Failed !"); 
            end 
        end
    endtask
    task L2_data_ram_tb;
        input  [511:0] _L2_data0_rd;         // read data of cache_data0
        input  [511:0] _L2_data1_rd;         // read data of cache_data1
        input  [511:0] _L2_data2_rd;         // read data of cache_data2
        input  [511:0] _L2_data3_rd;         // read data of cache_data3
        begin 
            if( (L2_data0_rd  === _L2_data0_rd)   && 
                (L2_data1_rd  === _L2_data1_rd)   && 
                (L2_data2_rd  === _L2_data2_rd)   && 
                (L2_data3_rd  === _L2_data3_rd)                 
               ) begin 
                 $display("L2_data_ram Test Succeeded !"); 
            end else begin 
                 $display("L2_data_ram Test Failed !"); 
            end 
        end
    endtask

    /******** Define Simulation Loop********/ 
    parameter  STEP = 10; 

    /******* Generated Clocks *******/
    always #(STEP / 2)
        begin
            clk     <= ~clk;  
        end
    always #STEP
        begin
            clk_tmp <= ~clk_tmp;  
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
            rst     <= `DISABLE;      
            if_addr <= 32'b1110_0001_0000_0000;
            rw      <= `READ;
            L2_data_wd <= 512'h123BC000_0876547A_00000000_ABF00000_123BC000_00000000_0876547A_00000000_ABF00000_123BC000;      // write data of L2_cache
            // L2_busy <= `DISABLE;                                      // busy signal of L2_cache
            // L2_rdy  <= `ENABLE;                                       // ready signal of L2_cache
            // data_wd <= 128'h0876547A_00000000_ABF00000_123BC000;      // write data of L1_cache
        end
        #STEP begin // L1_IDLE & L2_IDLE 
            $display("\n========= Clock 1 ========");
        end
        #STEP begin // L1_ACCESS & L2_IDLE 
            $display("\n========= Clock 2 ========");
        end
        #STEP begin // L2_ACCESS & L2_IDLE  
            $display("\n========= Clock 3 ========");
        end
        // #STEP begin // WRITE_IC & access ic_ram
        //     $display("\n========= Clock 4 ========"); 
        //     tag_ram_tb(
        //         21'b1_0000_0000_0000_0000_1110,         // read data of tag0
        //         21'b0,                                  // read data of tag1
        //         1'b1,                                   // read block of tag
        //         1'b1                                    // complete write from L2 to L1
        //         );
        //     data_ram_tb(
        //         128'h0876547A_00000000_ABF00000_123BC000,   // read data of cache_data0
        //         128'h0                                      // read data of cache_data1
        //         );
        // end
        // #STEP begin // L1_ACCESS
        //     $display("\n========= Clock 5 ========");
        //     icache_tb(
        //         32'h123BC000,       // read data of CPU
        //         `DISABLE,           // the signal of stall caused by cache miss
        //         `READ,              // read / write signal of L1_tag0
        //         `READ,              // read / write signal of L1_tag1
        //         20'b1110,           // write data of L1_tag
        //         `READ,              // read / write signal of data0
        //         `READ,              // read / write signal of data1
        //         8'b0001_0000,       // address of L1_cache
        //         `DISABLE            // icache request
        //         );
        // end        
        #STEP begin // L2_ACCESS & 2* clk state change to ACCESS_L2 really 
            $display("\n========= Clock 4 ========");
        end
        #STEP begin // L2_ACCESS & ACCESS_L2
            $display("\n========= Clock 5 ========");
            L2_icache_tb(
                `ENABLE,            // miss caused by L2C
                `ENABLE,            // L2C busy mark
                128'bx,             // write data to L1_IC
                `WRITE,             // read / write signal of tag0
                `READ,              // read / write signal of tag1
                `READ,              // read / write signal of tag0
                `READ,              // read / write signal of tag1
                17'b0000_1,         // write data of tag
                `DISABLE,           // ready signal of L2_cache
                `WRITE,             // the mark of cache_data0 write signal 
                `READ,              // the mark of cache_data1 write signal 
                `READ,              // the mark of cache_data2 write signal 
                `READ,              // the mark of cache_data3 write signal 
                9'b110_0001_00,     // address of cache
                26'b1110_0001_00,   // address of memory
                `READ               // read / write signal of memory
                );
        end
        #STEP begin // L2_ACCESS & 2* clk state change to WRITE_L2 really 
            $display("\n========= Clock 6 ========");
        end        
        #STEP begin // L2_ACCESS & WRITE_L2 & access L2_ram
            $display("\n========= Clock 7 ========");
            L2_tag_ram_tb(   
                19'b10_0000_0000_0000_0000_1,   // read data of tag0
                19'b0,                          // read data of tag1
                19'b0,                          // read data of tag2
                19'b0,                          // read data of tag3
                3'b011,                         // read data of tag
                `ENABLE                         // complete write from L2 to L1
            );
            L2_data_ram_tb(
                512'h123BC000_0876547A_00000000_ABF00000_123BC000_00000000_0876547A_00000000_ABF00000_123BC000,         // read data of cache_data0
                512'b0,             // read data of cache_data1
                512'b0,             // read data of cache_data2
                512'b0              // read data of cache_data3
             );
            L2_icache_tb(
                `ENABLE,            // miss caused by L2C
                `ENABLE,            // L2C busy mark
                128'bx,             // write data to L1_IC
                `READ,              // read / write signal of tag0
                `READ,              // read / write signal of tag1
                `READ,              // read / write signal of tag0
                `READ,              // read / write signal of tag1
                17'b0000_1,         // write data of tag0
                `DISABLE,           // ready signal of L2_cache
                `READ,              // the mark of cache_data0 write signal 
                `READ,              // the mark of cache_data1 write signal 
                `READ,              // the mark of cache_data2 write signal 
                `READ,              // the mark of cache_data3 write signal 
                9'b110_0001_00,     // address of cache
                26'b1110_0001_00,   // address of memory
                `READ               // read / write signal of memory
                );
        end
        #STEP begin // L2_ACCESS  & 2* clk state change to ACCESS_L2 really  
            $display("\n========= Clock 8 ========"); 
        end
        #STEP begin // L2_ACCESS  & ACCESS_L2 
            $display("\n========= Clock 9 ========");        
            icache_tb(
                32'bx,          // read data of CPU
                `ENABLE,        // the signal of stall caused by cache miss
                `READ,          // read / write signal of L1_tag0
                `READ,          // read / write signal of L1_tag1
                20'b1110,       // write data of L1_tag
                `READ,          // read / write signal of data0
                `READ,          // read / write signal of data1
                8'b0001_0000,   // address of L1_cache
                `ENABLE         // icache request
                );
            L2_icache_tb(
                `DISABLE,                                  // miss caused by L2C
                `ENABLE,                                   // L2C busy mark
                128'h0876547A_00000000_ABF00000_123BC000,  // write data to L1_IC
                `READ,                                     // read / write signal of tag0
                `READ,                                     // read / write signal of tag1
                `READ,                                     // read / write signal of tag0
                `READ,                                     // read / write signal of tag1
                17'b0000_1,                                // write data of tag0
                `ENABLE,                                  // ready signal of L2_cache
                `READ,                                     // the mark of cache_data0 write signal 
                `READ,                                     // the mark of cache_data1 write signal 
                `READ,                                     // the mark of cache_data2 write signal 
                `READ,                                     // the mark of cache_data3 write signal 
                9'b110_0001_00,                            // address of cache
                26'b1110_0001_00,                          // address of memory
                `READ                                      // read / write signal of memory
                );        
        end
        #STEP begin // L2_ACCESS  & 2* clk state change to WRITE_L1 really  
            $display("\n========= Clock 10 ========"); 
            icache_tb(
                32'bx,          // read data of CPU
                `ENABLE,        // the signal of stall caused by cache miss
                `WRITE,         // read / write signal of L1_tag0
                `READ,          // read / write signal of L1_tag1
                20'b1110,       // write data of L1_tag
                `WRITE,         // read / write signal of data0
                `READ,          // read / write signal of data1
                8'b0001_0000,   // address of L1_cache
                `ENABLE         // icache request
                );
            L2_icache_tb(
                `DISABLE,                                  // miss caused by L2C
                `ENABLE,                                   // L2C busy mark
                128'h0876547A_00000000_ABF00000_123BC000,  // write data to L1_IC
                `READ,                                     // read / write signal of tag0
                `READ,                                     // read / write signal of tag1
                `READ,                                     // read / write signal of tag0
                `READ,                                     // read / write signal of tag1
                17'b0000_1,                                // write data of tag0
                `ENABLE,                                   // ready signal of L2_cache
                `READ,                                     // the mark of cache_data0 write signal 
                `READ,                                     // the mark of cache_data1 write signal 
                `READ,                                     // the mark of cache_data2 write signal 
                `READ,                                     // the mark of cache_data3 write signal 
                9'b110_0001_00,                            // address of cache
                26'b1110_0001_00,                          // address of memory
                `READ                                      // read / write signal of memory
                ); 
        end
        #STEP begin // WRITE_IC  & WRITE_L1 
            $display("\n========= Clock 11 ========"); 
            icache_tb(
                32'bx,          // read data of CPU
                `ENABLE,        // the signal of stall caused by cache miss
                `READ,          // read / write signal of L1_tag0
                `READ,          // read / write signal of L1_tag1
                20'b1110,       // write data of L1_tag
                `READ,          // read / write signal of data0
                `READ,          // read / write signal of data1
                8'b0001_0000,   // address of L1_cache
                `DISABLE        // icache request
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
        #STEP begin // L1_ACCESS  & 2* clk state change to L2_IDLE really    
            $display("\n========= Clock 12 ========"); 
            icache_tb(
                32'h123BC000,           // read data of CPU
                `DISABLE,               // the signal of stall caused by cache miss
                `READ,                  // read / write signal of L1_tag0
                `READ,                  // read / write signal of L1_tag1
                20'b1110,               // write data of L1_tag
                `READ,                  // read / write signal of data0
                `READ,                  // read / write signal of data1
                8'b0001_0000,           // address of L1_cache
                `DISABLE                // icache request
                );
        end        
        #STEP begin // L1_ACCESS  & L2_IDLE        
            $display("\n========= Clock 13 ========");
            $finish;
        end
    end
    /********** output wave **********/
    initial begin
        $dumpfile("icache.vcd");
        $dumpvars(0,icache,tag_ram,data_ram,L2_tag_ram,L2_data_ram,L2_icache);
    end
endmodule 