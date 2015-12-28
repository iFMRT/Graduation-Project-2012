`include "stddef.h"
`include "cpu.h"

/********** MEM Stage Register Module**********/
module mem_reg (
    /********** Clock & Reset **********/
    input wire                  clk,            // Clock
    input wire                  reset,          // Asynchronous reset
    /********** Memory Access Result **********/
    input wire [`WORD_DATA_BUS] out,            // Memory access result
    input wire                  miss_align,     // Miss align
    /********** Pipeline Control Signal **********/
    input wire                  stall,          // Stall
    input wire                  flush,          // Flush
    /********** EX/MEM Pipeline Register **********/
    // input wire [`WordAddrBus]   ex_pc,          // Program counter
    input wire                  ex_en,          // If Pipeline data enable
    // input wire                  ex_br_flag,     // Branch flag
    // input wire [`CtrlOpBus]     ex_ctrl_op,     // Control register operation
    input wire [`REG_ADDR_BUS]  ex_dst_addr,    // General purpose register write address
    input wire                  ex_gpr_we_,     // General purpose register write enable
    // input wire [`IsaExpBus]     ex_exp_code,    // Exception code
    /********** MEM/WB Pipeline Register **********/
    // output reg [`WordAddrBus]   mem_pc,         // Program counter
    output reg                  mem_en,         // If Pipeline data enables
    // output reg                  mem_br_flag,    // Branch flag
    // output reg [`CtrlOpBus]     mem_ctrl_op,    // Control register operation
    output reg [`REG_ADDR_BUS]  mem_dst_addr,   // General purpose register write address
    output reg                  mem_gpr_we_,    // General purpose register write enable
    // output reg [`IsaExpBus]     mem_exp_code,   // Exception code
    output reg [`WORD_DATA_BUS] mem_out         // MEM stage operating result
);

    /********** Pipeline Register **********/
    always @(posedge clk or negedge reset) begin
        if (reset == `ENABLE) begin
            /* Asynchronous Reset */
            // mem_pc         <= #1 `WORD_ADDR_W'h0;
            mem_en       <= #1 `DISABLE;
            // mem_br_flag  <= #1 `DISABLE;
            // mem_ctrl_op  <= #1 `CTRL_OP_NOP;
            mem_dst_addr <= #1 `REG_ADDR_W'h0;
            mem_gpr_we_  <= #1 `DISABLE_;
            // mem_exp_code <= #1 `ISA_EXP_NO_EXP;
            mem_out      <= #1 `WORD_DATA_W'h0;
        end else begin
            if (stall == `DISABLE) begin
                /* Update Pipeline Register */
                if (flush == `ENABLE) begin                // flush
                    // mem_pc         <= #1 `WORD_ADDR_W'h0;
                    mem_en       <= #1 `DISABLE;
                    // mem_br_flag  <= #1 `DISABLE;
                    // mem_ctrl_op  <= #1 `CTRL_OP_NOP;
                    mem_dst_addr <= #1 `REG_ADDR_W'h0;
                    mem_gpr_we_  <= #1 `DISABLE_;
                    // mem_exp_code <= #1 `ISA_EXP_NO_EXP;
                    mem_out      <= #1 `WORD_DATA_W'h0;
                end else if (miss_align == `ENABLE) begin  // Miss align
                    // mem_pc         <= #1 ex_pc;
                    mem_en       <= #1 ex_en;
                    // mem_br_flag  <= #1 ex_br_flag;
                    // mem_ctrl_op  <= #1 `CTRL_OP_NOP;
                    mem_dst_addr <= #1 `REG_ADDR_W'h0;
                    mem_gpr_we_  <= #1 `DISABLE_;
                    // mem_exp_code <= #1 `ISA_EXP_MISS_ALIGN;
                    mem_out      <= #1 `WORD_DATA_W'h0;
                end else begin                             // Next data
                    // mem_pc       <= #1 ex_pc;
                    mem_en       <= #1 ex_en;
                    // mem_br_flag  <= #1 ex_br_flag;
                    // mem_ctrl_op  <= #1 ex_ctrl_op;
                    mem_dst_addr <= #1 ex_dst_addr;
                    mem_gpr_we_  <= #1 ex_gpr_we_;
                    // mem_exp_code <= #1 ex_exp_code;
                    mem_out      <= #1 out;
                end
            end
        end
    end

endmodule
