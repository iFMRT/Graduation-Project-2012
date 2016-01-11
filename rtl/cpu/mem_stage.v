`include "stddef.h"
`include "cpu.h"
`include "mem.h"

module mem_stage (
    /********** Clock & Reset **********/
    input wire                   clk,            // Clock
    input wire                   reset,          // Asynchronous Reset
    /********** Pipeline Control Signal **********/
    input wire                   stall,          // Stall
    input wire                   flush,          // Flush
    /********** Forward **********/
    output wire [`WORD_DATA_BUS] fwd_data,       
    /********** SPM Interface **********/
    input wire [`WORD_DATA_BUS]  spm_rd_data,    // SPM: Read data
    output wire [`WORD_ADDR_BUS] spm_addr,       // SPM: Address
    output wire                  spm_as_,        // SPM: Address Strobe
    output wire                  spm_rw,         // SPM: Read/Write
    output wire [`WORD_DATA_BUS] spm_wr_data,    // SPM: Write data
    /********** EX/MEM Pipeline Register **********/
    input wire                   ex_en,          // If Pipeline data enable
    input wire [`MEM_OP_BUS]     ex_mem_op,      // Memory operation
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
    wire [`WORD_DATA_BUS]        rd_data;         // Read data
    wire [`WORD_ADDR_BUS]        addr;            // Address
    wire                         as_;             // Address Strobe
    wire                         rw;              // Read/Write
    wire [`WORD_DATA_BUS]        wr_data;         // Write data
    wire [`WORD_DATA_BUS]        out;             // Memory Access Result
    wire                         miss_align;

    assign fwd_data  = out;

    // /********** Memory Access Control Module **********/
    mem_ctrl mem_ctrl (
        /********** EX/MEM Pipeline Register **********/
        .ex_en            (ex_en),
        .ex_mem_op        (ex_mem_op),       // Memory operation
        .ex_mem_wr_data   (ex_mem_wr_data),  // Memory write data
        .ex_out           (ex_out),          // EX Stage operating reslut
        /********** Memory Access Interface **********/
        .rd_data          (rd_data),         // Read data
        .addr             (addr),            // Address
        .as_              (as_),             // Address Strobe
        .rw               (rw),              // Read/Write
        .wr_data          (wr_data),         // Write data
        /********** Memory Access Result **********/
        .out              (out),             // Memory Access Result
        .miss_align       (miss_align)
    );

    // /********** Bus Interface **********/
    bus_if bus_if (
         /********** Pipeline Control Signal **********/
        .stall            (stall),                       // Stall
        .flush            (flush),                       // Flush signal
        /********** CPU  Interface **********/
        .addr             (addr),            // CPU: Address
        .as_              (as_),             // CPU: Address Strobe
        .rw               (rw),              // CPU: Read/Write
        .wr_data          (wr_data),         // CPU: Write data
        .rd_data          (rd_data),         // CPU: Read data
        /********** SPM Interface **********/
        .spm_rd_data      (spm_rd_data),     // SPM: Read data
        .spm_addr         (spm_addr),        // SPM: Address
        .spm_as_          (spm_as_),         // SPM: Address Strobe
        .spm_rw           (spm_rw),          // SPM: Read/Write
        .spm_wr_data      (spm_wr_data)      // SPM: Write data
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
