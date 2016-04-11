`include "stddef.h"
`include "cpu.h"
`include "mem.h"

module mem_stage (
    /********** Clock & Reset *********/
    input wire                   clk,            // Clock
    input wire                   reset,          // Asynchronous Reset
    /**** Pipeline Control Signal *****/
    input wire                   stall,          // Stall
    input wire                   flush,          // Flush
    /************ Forward *************/
    output wire [`WORD_DATA_BUS] fwd_data,                   
    /*********** Data_cache ***********/
    /* CPU part */
    output                       miss_stall,    // the signal of stall caused by cache miss
    /* L1_cache part */
    input                        lru,           // mark of replacing
    input      [20:0]            tag0_rd,       // read data of tag0
    input      [20:0]            tag1_rd,       // read data of tag1
    input      [127:0]           data0_rd,      // read data of data0
    input      [127:0]           data1_rd,      // read data of data1
    input                        dirty0,
    input                        dirty1,
    output                       dirty_wd,
    output                       dirty0_rw,
    output                       dirty1_rw,
    output     [127:0]           data_wd_dc,
    output                       tag0_rw,       // read / write signal of L1_tag0
    output                       tag1_rw,       // read / write signal of L1_tag1
    output     [20:0]            tag_wd,        // write data of L1_tag
    output                       data_wd_dc_en, // choose signal of data_wd           
    output                       data0_rw,      // read / write signal of data0
    output                       data1_rw,      // read / write signal of data1
    output     [7:0]             index,         // address of L1_cache
    output     [127:0]           data_rd,       // read data of L1_cache's data
    /* L2_cache part */
    input                        l2_busy,       // busy signal of L2_cache
    input                        l2_rdy,        // ready signal of L2_cache
    input                        complete,      // complete op writing to L1
    input                        l2_complete,
    output                       drq,           // icache request
    output                       dc_rw_en, 
    output     [`WORD_DATA_BUS]  l2_addr, 
    // output     [8:0]             l2_index,
    output                       l2_cache_rw,   // l2_cache read/write signal

    // /********** SPM Interface **********/
    // input wire [`WORD_DATA_BUS]  spm_rd_data,    // SPM: Read data
    // output wire [`WORD_ADDR_BUS] spm_addr,       // SPM: Address
    // output wire                  spm_as_,        // SPM: Address Strobe
    // output wire                  spm_rw,         // SPM: Read/Write
    // output wire [`WORD_DATA_BUS] spm_wr_data,    // SPM: Write data
    /********** EX/MEM Pipeline Register **********/
    input wire                   ex_en,          // If Pipeline data enable
    input wire [`MEM_OP_BUS]     ex_mem_op,      // Memory operation
    input wire [`MEM_OP_BUS]     id_mem_op,
    input wire [`WORD_DATA_BUS]  ex_mem_wr_data, // Memory write data
    input wire [`REG_ADDR_BUS]   ex_dst_addr,    // General purpose register write address
    input wire                   ex_gpr_we_,     // General purpose register enable
    input wire [`WORD_DATA_BUS]  ex_out,         // EX Stage operating reslut
    /********** MEM/WB Pipeline Register **********/
    output wire                  mem_en,         // If Pipeline data enables
    output wire [`REG_ADDR_BUS]  mem_dst_addr,   // General purpose register write address
    output wire                  mem_gpr_we_,    // General purpose register enable
    output wire [`WORD_DATA_BUS] mem_out
);
        
    /********** Internal signals **********/
    wire [`WORD_DATA_BUS]        read_data_m;         // Read data
    wire [`WORD_DATA_BUS]        addr;            // Address
    // wire                         as_;             // Address Strobe
    wire                         memwrite_m;      // Read/Write
    wire [`WORD_DATA_BUS]        wr_data_m;         // Write data
    wire [`WORD_DATA_BUS]        out;             // Memory Access Result
    wire                         miss_align;
    reg                          access_mem;
    reg                          access_mem_ex;
    wire                         hitway;
    assign fwd_data  = out;

    always @(*) begin
        if (ex_mem_op[3:2] == 2'b00) begin
            access_mem = `DISABLE;
        end else begin
            access_mem = `ENABLE;
        end
        if (id_mem_op[3:2] == 2'b00) begin
            access_mem_ex = `DISABLE;
        end else begin
            access_mem_ex = `ENABLE;
        end
    end
    // /********** Memory Access Control Module **********/
    mem_ctrl mem_ctrl (
        /********** EX/MEM Pipeline Register **********/
        .ex_en            (ex_en),
        .ex_mem_op        (ex_mem_op),       // Memory operation
        .ex_mem_wr_data   (ex_mem_wr_data),  // Memory write data
        .ex_out           (ex_out),          // EX Stage operating reslut
        /********** Memory Access Interface **********/
        .read_data_m      (read_data_m),         // Read data
        .addr             (addr),            // Address
        // .as_              (as_),             // Address Strobe
        .rw               (memwrite_m),     // Read/Write               +++
        .wr_data          (wr_data_m),         // Write data
        .hitway           (hitway),             // Address Strobe
        .data0_rd         (data0_rd),              // Read/Write
        .data1_rd         (data1_rd),         // Write data
        /********** Memory Access Result **********/
        .out              (out),             // Memory Access Result
        .miss_align       (miss_align)
    );
    
    // /********** Bus Interface **********/
    // bus_if bus_if (
    //      /********** Pipeline Control Signal **********/
    //     .stall            (stall),                       // Stall
    //     .flush            (flush),                       // Flush signal
    //     /********** CPU  Interface **********/
    //     .addr             (addr),            // CPU: Address
    //     .as_              (as_),             // CPU: Address Strobe
    //     .rw               (rw),              // CPU: Read/Write
    //     .wr_data          (wr_data),         // CPU: Write data
    //     .rd_data          (rd_data),         // CPU: Read data
    //     /********** SPM Interface **********/
    //     .spm_rd_data      (spm_rd_data),     // SPM: Read data
    //     .spm_addr         (spm_addr),        // SPM: Address
    //     .spm_as_          (spm_as_),         // SPM: Address Strobe
    //     .spm_rw           (spm_rw),          // SPM: Read/Write
    //     .spm_wr_data      (spm_wr_data)      // SPM: Write data
    // );

    /********** Dcache Interface **********/
    dcache_ctrl dcache_ctrl(
        .clk            (clk),           // clock
        .rst            (reset),           // reset
        /* CPU part */
        .addr           (addr),       // address of fetching instruction
        .wr_data_m      (wr_data_m),
        .memwrite_m     (memwrite_m),            // read / write signal of CPU
        .access_mem     (access_mem), 
        .access_mem_ex  (access_mem_ex), 
        .read_data_m    (read_data_m),      // read data of CPU
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
        .hitway         (hitway),
        .data0_rw       (data0_rw),      // read / write signal of data0
        .data1_rw       (data1_rw),      // read / write signal of data1
        .index          (index),         // address of L1_cache
        .data_rd        (data_rd),
        /* l2_cache part */
        .l2_complete    (l2_complete),
        .l2_busy        (l2_busy),       // busy signal of l2_cache
        .l2_rdy         (l2_rdy),        // ready signal of l2_cache
        .complete       (complete),      // complete op writing to L1
        .drq            (drq),  
        .dc_rw_en       (dc_rw_en),     
        .l2_addr        (l2_addr), 
        // .l2_index       (l2_index),       
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
