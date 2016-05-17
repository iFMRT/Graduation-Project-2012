`timescale 1ns/1ps

`include "stddef.h"
`include "cpu.h"
`include "mem.h"

module mem_stage (
    /********** Clock & Reset *********/
    input                        clk,            // Clock
    input                        reset,          // Asynchronous Reset
    /**** Pipeline Control Signal *****/
    input                        stall,          // Stall
    input                        flush,          // Flush
    /************ Forward *************/
    output     [`WORD_DATA_BUS]  fwd_data,                   
    /*********** Data_cache ***********/
    /* CPU part */
    output                       miss_stall,    // the signal of stall caused by cache miss
    /* L1_cache part */
    input                        lru,           // mark of replacing
    input      [20:0]            tag0_rd,       // read data of tag0
    input      [20:0]            tag1_rd,       // read data of tag1
    input      [127:0]           data0_rd,      // read data of data0
    input      [127:0]           data1_rd,      // read data of data1
    input      [127:0]           data_wd_l2,
    input                        dirty0,
    input                        dirty1,
    output                       dirty_wd,
    output                       block0_we,     // write signal of block0
    output                       block1_we,     // write signal of block1
    output                       block0_re,     // read signal of block0
    output                       block1_re,     // read signal of block1
    output                       tagcomp_hit,
    output     [1:0]             offset, 
    output     [127:0]           rd_to_l2,
    output     [20:0]            tag_wd,        // write data of L1_tag
    output                       data_wd_dc_en, // choose signal of data_wd           
    input                        mem_wr_dc_en,
    output     [7:0]             index,         // address of L1_cache
    output     [`WORD_DATA_BUS]  dc_wd,         // Write data
    /* L2_cache part */
    input                        dc_en,         // busy signal of L2_cache
    input                        l2_rdy,        // ready signal of L2_cache
    input                        w_complete_dc, // complete op writing to L1
    input                        r_complete_dc,      
    input                        l2_complete_w,
    output                       drq,           // icache request
    output                       dc_rw_en, 
    output     [27:0]            l2_addr,
    output                       l2_cache_rw,   // l2_cache read/write signal
   /********** EX/MEM Pipeline Register **********/
    input                        ex_en,          // If Pipeline data enable
    input      [`MEM_OP_BUS]     ex_mem_op,      // Memory operation
    // input      [`MEM_OP_BUS]     id_mem_op,
    input      [`WORD_DATA_BUS]  ex_mem_wr_data, // Memory write data
    input      [`REG_ADDR_BUS]   ex_dst_addr,    // General purpose register write address
    input                        ex_gpr_we_,     // General purpose register enable
    input      [`WORD_DATA_BUS]  ex_out,         // EX Stage operating reslut
    /********** MEM/WB Pipeline Register **********/
    output                       mem_en,         // If Pipeline data enables
    output      [`REG_ADDR_BUS]  mem_dst_addr,   // General purpose register write address
    output                       mem_gpr_we_,    // General purpose register enable
    output      [`WORD_DATA_BUS] mem_out
);
        
    /********** Internal signals **********/
    wire [`WORD_DATA_BUS]        wr_data;         // Write data
    wire [`WORD_DATA_BUS]        read_data_m;     // Read data
    wire [`WORD_DATA_BUS]        addr;            // Address
    wire                         memwrite_m;      // Read/Write
    wire [`WORD_DATA_BUS]        out;             // Memory Access Result
    wire                         miss_align;
    reg                          access_mem;
    // reg                          access_mem_ex;
    wire                         hitway;
    assign fwd_data  = out;

    always @(*) begin
        if (ex_mem_op[3:2] == 2'b00) begin
            access_mem = `DISABLE;
        end else begin
            access_mem = `ENABLE;
        end
    end
    // /********** Memory Access Control Module **********/
    mem_ctrl mem_ctrl (
        /********** EX/MEM Pipeline Register **********/
        .ex_en            (ex_en),
        .ex_mem_op        (ex_mem_op),      // Memory operation
        .ex_mem_wr_data   (ex_mem_wr_data), // Memory write data
        .ex_out           (ex_out),         // EX Stage operating reslut
        /********** Memory Access Interface **********/
        .read_data_m      (read_data_m),    // Read data
        .addr             (addr),           // Address
        .rw               (memwrite_m),     // Read/Write                
        .wr_data          (wr_data),        // Write data
        .hitway           (hitway),         // Address Strobe
        .data0_rd         (data0_rd),       // Read/Write
        .data1_rd         (data1_rd),       // Write data
        /********** Memory Access Result **********/
        .out              (out),            // Memory Access Result
        .miss_align       (miss_align)
    );

    /********** Dcache Interface **********/
    dcache_ctrl dcache_ctrl(
        .clk            (clk),           // clock
        .rst            (reset),         // reset
        /* CPU part */
        .addr           (addr[31:2]),    // address of fetching instruction
        .memwrite_m     (memwrite_m),    // Read/Write 
        .wr_data        (wr_data),       // read / write signal of CPU
        .dc_wd          (dc_wd),
        .access_mem     (access_mem), 
        .read_data_m    (read_data_m),   // read data of CPU
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
        .block0_we      (block0_we),     // write signal of block0
        .block1_we      (block1_we),     // write signal of block1
        .block0_re      (block0_re),     // read signal of block0
        .block1_re      (block1_re),     // read signal of block1      
        .offset         (offset),      
        .tagcomp_hit    (tagcomp_hit),  
        .tag_wd         (tag_wd),        // write data of L1_tag
        .data_wd_dc_en  (data_wd_dc_en),
        .hitway         (hitway),
        .index          (index),         // address of L1_cache
        .rd_to_l2       (rd_to_l2),
        /* l2_cache part */
        .l2_complete_w  (l2_complete_w), // complete signal of l2_cache
        .dc_en          (dc_en),         // busy signal of l2_cache
        .l2_rdy         (l2_rdy),        // ready signal of l2_cache
        .mem_wr_dc_en   (mem_wr_dc_en), 
        .w_complete     (w_complete_dc), // complete write to L1
        .r_complete     (r_complete_dc), // complete write from L1
        .data_wd_l2     (data_wd_l2), 
        .drq            (drq),      
        .dc_rw_en       (dc_rw_en), 
        .l2_addr        (l2_addr),      
        .l2_cache_rw    (l2_cache_rw)        
        );
    // /********** MEM Stage Pipeline Register **********/
    mem_reg mem_reg (
        /********** Clock & Reset **********/
        .clk              (clk),             // Clock
        .reset            (reset),           // Asynchronous Reset
        /********** Memory Access Result **********/
        .out              (out),
        .miss_align       (miss_align),
        /********** Pipeline Control Signal **********/
        .stall            (stall),           // Stall
        .flush            (flush),           // Flush
        /********** EX/MEM Pipeline Register **********/
        .ex_en            (ex_en),
        .ex_dst_addr      (ex_dst_addr),     // General purpose register write address
        .ex_gpr_we_       (ex_gpr_we_),      // General purpose register enable
        /********** MEM/WB Pipeline Register **********/
        .mem_en           (mem_en),          
        .mem_dst_addr     (mem_dst_addr),    // General purpose register write address
        .mem_gpr_we_      (mem_gpr_we_),     // General purpose register enable
        .mem_out          (mem_out)
        );

endmodule
