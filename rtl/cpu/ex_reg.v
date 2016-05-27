////////////////////////////////////////////////////////////////////
// Engineer:       Beyond Sky - fan-dave@163.com                  //
//                                                                //
// Additional contributions by:                                   //
//                 Leway Colin - colin4124@gmail.com              //
//                 Junhao Chen                                    //
//                 Kippy Chen - 799182081@qq.com                  //
//                                                                //
// Design Name:    EX Pipeline Register                           //
// Project Name:   FMRT Mini Core                                 //
// Language:       Verilog                                        //
//                                                                //
// Description:    EX Pipeline Register.                          //
//                                                                //
////////////////////////////////////////////////////////////////////

`include "common_defines.v"
`include "base_core_defines.v"
`include "hart_ctrl.h"

module ex_reg (
    input  wire                  clk,
    input  wire                  reset,

    // Inner Output
    input  wire [`WORD_DATA_BUS] ex_out_inner,

    // Pipeline Control Signal
    input  wire                  stall,
    input  wire                  flush,

    // ID/EX Pipeline Register
    input  wire [`EXP_CODE_BUS]  id_exp_code,     // Exception code
    input  wire [`WORD_DATA_BUS] id_pc,
    input  wire                  id_en,
    input  wire [`MEM_OP_BUS]    id_mem_op,
    input  wire [`WORD_DATA_BUS] id_mem_wr_data,
    input  wire [`REG_ADDR_BUS]  id_rd_addr,      // bypass input 
    input  wire                  id_gpr_we_,
    input  wire [`HART_ID_B]     id_hart_id,      // ID stage hart id

    // EX/MEM Pipeline Register
    output reg  [`EXP_CODE_BUS]  ex_exp_code,     // Exception code
    output reg  [`WORD_DATA_BUS] ex_pc,
    output reg                   ex_en,
    output reg  [`MEM_OP_BUS]    ex_mem_op,
    output reg  [`WORD_DATA_BUS] ex_mem_wr_data,
    output reg  [`REG_ADDR_BUS]  ex_rd_addr,      // bypass output
    output reg                   ex_gpr_we_,
    output reg  [`WORD_DATA_BUS] ex_out,
    output reg  [`HART_ID_B]     ex_hart_id       // EX stage hart id
);

    always @(posedge clk) begin
        if(reset == `ENABLE) begin
            ex_exp_code    <= #1 `EXP_NO_EXP;
            ex_pc          <= #1 `WORD_DATA_W'h0;
            ex_en          <= #1 `DISABLE;
            ex_mem_op      <= #1 `MEM_OP_NOP;
            ex_mem_wr_data <= #1 `WORD_DATA_W'h0;
            ex_rd_addr     <= #1 `REG_ADDR_W'd0;
            ex_gpr_we_     <= #1 `DISABLE_;
            ex_out         <= #1 `WORD_DATA_W'b0;
            ex_hart_id     <= #1 `HART_ID_W'h0;
        end else begin
            if (stall == `DISABLE) begin
                if (flush == `ENABLE) begin
                    ex_exp_code    <= #1 `EXP_NO_EXP;
                    ex_pc          <= #1 `WORD_DATA_W'h0;
                    ex_en          <= #1 `DISABLE;
                    ex_mem_op      <= #1 `MEM_OP_NOP;
                    ex_mem_wr_data <= #1 `WORD_DATA_W'h0;
                    ex_rd_addr     <= #1 `REG_ADDR_W'd0;
                    ex_gpr_we_     <= #1 `DISABLE_;
                    ex_out         <= #1 `WORD_DATA_W'b0;
                    ex_hart_id     <= #1 `HART_ID_W'h0;
                end else begin
                    ex_en          <= #1 id_en;
                    ex_exp_code    <= #1 id_exp_code;
                    ex_pc          <= #1 id_pc;
                    ex_out         <= #1 ex_out_inner;
                    ex_rd_addr     <= #1 id_rd_addr;
                    ex_gpr_we_     <= #1 id_gpr_we_;
                    ex_mem_op      <= #1 id_mem_op;
                    ex_mem_wr_data <= #1 id_mem_wr_data;
                    ex_hart_id     <= #1 id_hart_id;
                end
            end
        end
    end

endmodule
