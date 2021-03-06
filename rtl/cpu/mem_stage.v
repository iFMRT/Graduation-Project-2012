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
    /********** EX/MEM Pipeline Register **********/
    input wire [`EXP_CODE_BUS]   ex_exp_code,    // Exception code
    input wire [`WORD_DATA_BUS]  ex_pc,
    input wire                   ex_en,          // If Pipeline data enable
    input wire [`MEM_OP_BUS]     ex_mem_op,      // Memory operation
    input wire [`WORD_DATA_BUS]  ex_mem_wr_data, // Memory write data
    input wire [`OFFSET_BUS]     ex_offset,
    input wire [`REG_ADDR_BUS]   ex_rd_addr,     // General purpose register write address
    input wire                   ex_gpr_we_,     // General purpose register enable
    input wire [`WORD_DATA_BUS]  ex_out,         // EX Stage operating reslut
    input wire [`HART_ID_B]      ex_hart_id,     // EX stage hart state
    /********** D Cache **********/
    input  wire [`WORD_DATA_BUS] rd_data,        // Read data
    input  wire [`WORD_DATA_BUS] rd_to_write_m,         
    output wire                  rw,             // Read/Write
    output wire [`WORD_DATA_BUS] wr_data,        // Write data
    output wire                  out_rdy,
    /********** MEM/WB Pipeline Register **********/
    output wire [`EXP_CODE_BUS]  mem_exp_code,   // Exception code
    output wire [`WORD_DATA_BUS] mem_pc,
    output wire                  mem_en,         // If Pipeline data enables
    output wire [`REG_ADDR_BUS]  mem_rd_addr,    // General purpose register write address
    output wire                  mem_gpr_we_,    // General purpose register enable
    output wire [`WORD_DATA_BUS] mem_out,
    output wire [`HART_ID_B]     mem_hart_id     // MEM stage hart state
);

    /********** Internal signals **********/
    wire [`WORD_DATA_BUS]        out;             // Memory Access Result
    wire                         miss_align;
    wire                         load_rdy;

    assign fwd_data  = out;

    /********** Memory Access Control Module **********/
    mem_ctrl mem_ctrl (
        /********** EX/MEM Pipeline Register **********/
        .ex_en            (ex_en),
        .ex_mem_op        (ex_mem_op),      // Memory operation
        .ex_mem_wr_data   (ex_mem_wr_data), // Memory write data
        .offset           (ex_offset),      // EX stage operating result
        .ex_out           (ex_out),         // EX Stage operating reslut
        /********** Memory Access Interface **********/
        .read_data_m      (rd_data),        // Read data
        .rw               (rw),             // Read/Write
        .wr_data          (wr_data),        // Write data
        .rd_to_write_m    (rd_to_write_m),
        /********** Memory Access Result **********/
        .out              (out),            // Memory Access Result
        .load_rdy         (load_rdy),
        .miss_align       (miss_align)
    );

    /********** MEM Stage Pipeline Register **********/
    mem_reg mem_reg (
        /********** Clock & Reset **********/
        .clk              (clk),             // Clock
        .reset            (reset),           // Asynchronous Reset
        /********** Memory Access Result **********/
        .out              (out),
        .miss_align       (miss_align),
        .load_rdy         (load_rdy),
        .out_rdy          (out_rdy),
        /********** Pipeline Control Signal **********/
        .stall            (stall),           // Stall
        .flush            (flush),           // Flush
        /********** EX/MEM Pipeline Register **********/
        .ex_exp_code      (ex_exp_code),
        .ex_pc            (ex_pc),
        .ex_en            (ex_en),
        .ex_rd_addr       (ex_rd_addr),      // General purpose register write address
        .ex_gpr_we_       (ex_gpr_we_),      // General purpose register enable
        .ex_hart_id       (ex_hart_id),
        /********** MEM/WB Pipeline Register **********/
        .mem_exp_code     (mem_exp_code),    // Exception code
        .mem_pc           (mem_pc),
        .mem_en           (mem_en),
        .mem_rd_addr      (mem_rd_addr),     // General purpose register write address
        .mem_gpr_we_      (mem_gpr_we_),     // General purpose register enable
        .mem_out          (mem_out),
        .mem_hart_id      (mem_hart_id)
    );

endmodule
