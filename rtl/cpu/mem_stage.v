////////////////////////////////////////////////////////////////////
// Engineer:       Leway Colin - colin4124@gmail.com              //
//                                                                //
// Additional contributions by:                                   //
//                 Beyond Sky - fan-dave@163.com                  //
//                 Junhao Chen                                    //
//                 Kippy Chen - 799182081@qq.com                  //
//                                                                //
// Design Name:    MEM Pipeline Stage                             //
// Project Name:   FMRT Mini Core                                 //
// Language:       Verilog                                        //
//                                                                //
// Description:    MEM Pipeline Stage.                            //
//                                                                //
////////////////////////////////////////////////////////////////////

`include "common_defines.v"
`include "base_core_defines.v"
`include "hart_ctrl.h"

module mem_stage (
    /********** Clock & Reset *********/
    input wire                   clk,            // Clock
    input wire                   reset,          // Asynchronous Reset
    /**** Pipeline Control Signal *****/
    input wire                   stall,          // Stall
    input wire                   flush,          // Flush
    /************ Forward *************/
    output wire [`WORD_DATA_BUS] fwd_data,
    /********** SPM Interface **********/
    input wire [`WORD_DATA_BUS]  spm_rd_data,    // SPM: Read data
    output wire [`WORD_ADDR_BUS] spm_addr,       // SPM: Address
    output wire                  spm_as_,        // SPM: Address Strobe
    output wire                  spm_rw,         // SPM: Read/Write
    output wire [`WORD_DATA_BUS] spm_wr_data,    // SPM: Write data
    /********** EX/MEM Pipeline Register **********/
    input wire [`EXP_CODE_BUS]   ex_exp_code,    // Exception code
    input wire [`WORD_DATA_BUS]  ex_pc,
    input wire                   ex_en,          // If Pipeline data enable
    input wire [`MEM_OP_BUS]     ex_mem_op,      // Memory operation
    input wire [`WORD_DATA_BUS]  ex_mem_wr_data, // Memory write data
    input wire [`REG_ADDR_BUS]   ex_rd_addr,     // General purpose register write address
    input wire                   ex_gpr_we_,     // General purpose register enable
    input wire [`WORD_DATA_BUS]  ex_out,         // EX Stage operating reslut
    input wire [`HART_STATE_B]   ex_hart_st,     // EX stage hart state
    /********** MEM/WB Pipeline Register **********/
    output wire [`EXP_CODE_BUS]  mem_exp_code,   // Exception code
    output wire [`WORD_DATA_BUS] mem_pc,
    output wire                  mem_en,         // If Pipeline data enables
    output wire [`REG_ADDR_BUS]  mem_rd_addr,    // General purpose register write address
    output wire                  mem_gpr_we_,    // General purpose register enable
    output wire [`WORD_DATA_BUS] mem_out,
    output wire [`HART_STATE_B]  mem_hart_st     // MEM stage hart state
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

    /********** Memory Access Control Module **********/
    mem_ctrl mem_ctrl (
        /********** EX/MEM Pipeline Register **********/
        .ex_en            (ex_en),
        .ex_mem_op        (ex_mem_op),      // Memory operation
        .ex_mem_wr_data   (ex_mem_wr_data), // Memory write data
        .ex_out           (ex_out),         // EX Stage operating reslut
        /********** Memory Access Interface **********/
        .rd_data          (rd_data),        // Read data
        .addr             (addr),           // Address
        .as_              (as_),            // Address strobe
        .rw               (rw),             // Read/Write
        .wr_data          (wr_data),        // Write data
        /********** Memory Access Result **********/
        .out              (out),            // Memory Access Result
        .miss_align       (miss_align)
    );

    /********** Bus Interface **********/
    bus_if bus_if (
        /********** Pipeline Control Signal **********/
        .stall            (stall),           // Stall
        .flush            (flush),           // Flush signal
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

    /********** MEM Stage Pipeline Register **********/
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
        .ex_exp_code      (ex_exp_code),
        .ex_pc            (ex_pc),
        .ex_en            (ex_en),
        .ex_rd_addr       (ex_rd_addr),      // General purpose register write address
        .ex_gpr_we_       (ex_gpr_we_),      // General purpose register enable
        .ex_hart_st       (ex_hart_st),
        /********** MEM/WB Pipeline Register **********/
        .mem_exp_code     (mem_exp_code),    // Exception code
        .mem_pc           (mem_pc),
        .mem_en           (mem_en),
        .mem_rd_addr      (mem_rd_addr),     // General purpose register write address
        .mem_gpr_we_      (mem_gpr_we_),     // General purpose register enable
        .mem_out          (mem_out),
        .mem_hart_st      (mem_hart_st)
    );

endmodule
