////////////////////////////////////////////////////////////////////
// Engineer:       Leway Colin - colin4124@gmail.com              //
//                                                                //
// Additional contributions by:                                   //
//                 Beyond Sky - fan-dave@163.com                  //
//                 Junhao Chen                                    //
//                 Kippy Chen - 799182081@qq.com                  //
//                                                                //
// Design Name:    MEM/WB Pipeline Stage Register                 //
// Project Name:   FMRT Mini Core                                 //
// Language:       Verilog                                        //
//                                                                //
// Description:    MEM/WB Pipeline Stage Register.                //
//                                                                //
////////////////////////////////////////////////////////////////////

`include "common_defines.v"
`include "base_core_defines.v"
`include "hart_ctrl.h"

/********** MEM Stage Register Module**********/
module mem_reg (
    /********** Clock & Reset **********/
    input wire                  clk,            // Clock
    input wire                  reset,          // reset
    /********** Memory Access Result **********/
    input wire [`WORD_DATA_BUS] out,            // Memory access result
    input wire                  miss_align,     // Miss align
    /********** Pipeline Control Signal **********/
    input wire                  stall,          // Stall
    input wire                  flush,          // Flush
    /********** EX/MEM Pipeline Register **********/
    input wire [`EXP_CODE_BUS]  ex_exp_code,    // Exception code
    input wire [`WORD_DATA_BUS] ex_pc,
    input wire                  ex_en,          // If Pipeline data enable
    input wire [`REG_ADDR_BUS]  ex_rd_addr,     // General purpose register write address
    input wire                  ex_gpr_we_,     // General purpose register write enable
    input wire [`HART_STATE_B]  ex_hart_st,     // EX stage hart state
    /********** MEM/WB Pipeline Register **********/
    output reg [`EXP_CODE_BUS]  mem_exp_code,   // Exception code
    output reg [`WORD_DATA_BUS] mem_pc,
    output reg                  mem_en,         // If Pipeline data enables
    output reg [`REG_ADDR_BUS]  mem_rd_addr,    // General purpose register write address
    output reg                  mem_gpr_we_,    // General purpose register write enable
    output reg [`WORD_DATA_BUS] mem_out,        // MEM stage operating result
    output reg [`HART_STATE_B]  mem_hart_st     // MEM stage hart state
);

    /********** Pipeline Register **********/
    always @(posedge clk) begin
        if (reset == `ENABLE) begin
            /* Reset */
            mem_exp_code <= `EXP_NO_EXP;
            mem_pc       <= `WORD_DATA_W'h0;
            mem_en       <= `DISABLE;
            mem_rd_addr  <=  `REG_ADDR_W'h0;
            mem_gpr_we_  <= `DISABLE_;
            mem_out      <= `WORD_DATA_W'h0;
            mem_hart_st  <= `HART_STATE_W'h0;
        end else begin
            if (stall == `DISABLE) begin
                /* Update Pipeline Register */
                if (flush == `ENABLE) begin                // flush
                    mem_exp_code <= `EXP_NO_EXP;
                    mem_pc       <= `WORD_DATA_W'h0;
                    mem_en       <= `DISABLE;
                    mem_rd_addr  <= `REG_ADDR_W'h0;
                    mem_gpr_we_  <= `DISABLE_;
                    mem_out      <= `WORD_DATA_W'h0;
                    mem_hart_st  <= `HART_STATE_W'h0;
                end else if (miss_align == `ENABLE) begin  // Miss align
                    mem_exp_code <= `EXP_MISS_ALIGN;
                    mem_pc       <= ex_pc;
                    mem_en       <= ex_en;
                    mem_rd_addr  <= `REG_ADDR_W'h0;
                    mem_gpr_we_  <= `DISABLE_;
                    mem_out      <= `WORD_DATA_W'h0;
                    mem_hart_st  <= ex_hart_st;
                end else begin                             // Next data
                    mem_exp_code <= ex_exp_code;
                    mem_pc       <= ex_pc;
                    mem_en       <= ex_en;
                    mem_rd_addr  <= ex_rd_addr;
                    mem_gpr_we_  <= ex_gpr_we_;
                    mem_out      <= out;
                    mem_hart_st  <= ex_hart_st;
                end
            end
        end
    end

endmodule
