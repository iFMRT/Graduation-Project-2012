////////////////////////////////////////////////////////////////////
// Engineer:       Junhao Chen                                    //
//                                                                //
// Additional contributions by:                                   //
//                 Beyond Sky - fan-dave@163.com                  //
//                 Leway Colin - colin4124@gmail.com              //
//                 Kippy Chen - 799182081@qq.com                  //
//                                                                //
// Design Name:    ID/EX Pipeline Register                        //
// Project Name:   FMRT Mini Core                                 //
// Language:       Verilog                                        //
//                                                                //
// Description:    ID/EX Pipeline Register.                       //
//                                                                //
////////////////////////////////////////////////////////////////////

`include "common_defines.v"
`include "base_core_defines.v"
`include "hart_ctrl.h"

module id_reg (
    /********** Clock & Rest **********/
    input wire                   clk,           // Clock
    input wire                   reset,         // Asynchronous rest
    /********** Decode result **********/
    input wire [`ALU_OP_BUS]     alu_op,        // ALU operation
    input wire [`WORD_DATA_BUS]  alu_in_0,      // ALU input 0
    input wire [`WORD_DATA_BUS]  alu_in_1,      // ALU input 1
    input wire [`CMP_OP_BUS]     cmp_op,        // CMP operation
    input wire [`WORD_DATA_BUS]  cmp_in_0,      // CMP input 0
    input wire [`WORD_DATA_BUS]  cmp_in_1,      // CMP input 1
    input wire [`REG_ADDR_BUS]   rs1_addr,      // Read register source one
    input wire [`REG_ADDR_BUS]   rs2_addr,      // Read register source two
    input wire                   jump_taken,    // Jump taken
    input wire [`MEM_OP_BUS]     mem_op,        // Memory operation
    input wire [`WORD_DATA_BUS]  mem_wr_data,   // Memory write data
    input wire [`REG_ADDR_BUS]   rd_addr,      // destination register address
    input wire                   gpr_we_,       // GPR write eanble
    input wire [`EX_OUT_SEL_BUS] ex_out_sel,    // Select ex stage outputs
    input wire [`WORD_DATA_BUS]  gpr_wr_data,   // the data which write to GPR
    input wire                   is_jalr,       // is JALR instruction
    input wire [`EXP_CODE_BUS]   exp_code,      // Exception code
    /********** Control Signal **********/
    input wire                   stall,
    input wire                   flush,
    /********** IF/ID Pipeline  Register  **********/
    input wire [`WORD_DATA_BUS]  pc,            // Current program counter
    input wire                   if_en,         // IF stage register enable
    input wire [`HART_ID_B]      if_hart_id,    // Hart state
    /********** ID/EX Register Output **********/
    output reg                   id_is_jalr,
    output reg [`EXP_CODE_BUS]   id_exp_code,   // Exception code
    output reg [`WORD_DATA_BUS]  id_pc,
    output reg                   id_en,         // ID stage register enable
    output reg [`ALU_OP_BUS]     id_alu_op,
    output reg [`WORD_DATA_BUS]  id_alu_in_0,
    output reg [`WORD_DATA_BUS]  id_alu_in_1,
    output reg [`CMP_OP_BUS]     id_cmp_op,
    output reg [`WORD_DATA_BUS]  id_cmp_in_0,
    output reg [`WORD_DATA_BUS]  id_cmp_in_1,
    output reg [`EX_OUT_SEL_BUS] id_ex_out_sel,
    output reg [`REG_ADDR_BUS]   id_rs1_addr,
    output reg [`REG_ADDR_BUS]   id_rs2_addr,
    output reg                   id_jump_taken,

    output reg [`MEM_OP_BUS]     id_mem_op,
    output reg [`WORD_DATA_BUS]  id_mem_wr_data,
    output reg [`REG_ADDR_BUS]   id_rd_addr,
    output reg                   id_gpr_we_,
    output reg [`WORD_DATA_BUS]  id_gpr_wr_data,

    output reg [`HART_ID_B]      id_hart_id,   // ID stage hart id

    //from Hart Control Unit
    input  wire                  hkill,
    input  wire                  hstart,
    input  wire [`HART_ID_B]     spec_hid,
    input  wire                  hidle,
    input  wire [`HART_ID_B]     hs_id,
    input  wire [`WORD_DATA_BUS] hs_pc,
    //to IF stage
    output reg                   id_hkill,
    output reg                   id_hstart,
    output reg                   id_hidle,
    output reg  [`HART_ID_B]     id_set_hid,        // ID_reg set hart id
    output reg  [`HART_ID_B]     id_hs_id,
    output reg  [`WORD_DATA_BUS] id_hs_pc
);

    always @(posedge clk) begin
        /******** Reset ********/
        if (reset == `ENABLE) begin
            /* Asynchronous Rest */
            id_is_jalr     <= #1 `DISABLE;
            id_exp_code    <= #1 `EXP_NO_EXP;
            id_pc          <= #1 `WORD_DATA_W'h0;
            id_en          <= #1 `DISABLE;
            id_alu_op      <= #1 `ALU_OP_NOP;
            id_alu_in_0    <= #1 `WORD_DATA_W'h0;
            id_alu_in_1    <= #1 `WORD_DATA_W'h0;
            id_cmp_op      <= #1 `CMP_OP_NOP;
            id_cmp_in_0    <= #1 `WORD_DATA_W'h0;
            id_cmp_in_1    <= #1 `WORD_DATA_W'h0;
            id_ex_out_sel  <= #1 `EX_OUT_SEL_W'h0;
            id_rs1_addr    <= #1 `REG_ADDR_W'h0;
            id_rs2_addr    <= #1 `REG_ADDR_W'h0;
            id_jump_taken  <= #1 `DISABLE;
            id_mem_op      <= #1 `MEM_OP_NOP;
            id_mem_wr_data <= #1 `WORD_DATA_W'h0;
            id_rd_addr     <= #1 5'h0;
            id_gpr_we_     <= #1 `DISABLE_;
            id_gpr_wr_data <= #1 `WORD_DATA_W'h0;
            id_hart_id     <= #1 `HART_ID_W'h0;
            id_hkill       <= #1 `DISABLE;
            id_hstart      <= #1 `DISABLE;
            id_hidle       <= #1 `DISABLE; 
            id_set_hid     <= #1 `HART_ID_W'h0;
            id_hs_id       <= #1 `HART_ID_W'h0; 
            id_hs_pc       <= #1 `WORD_DATA_W'h0; 
        end else begin
            /* Update Register's Data */
            if (stall == `DISABLE) begin
                if (flush == `ENABLE) begin // Flush register
                    id_is_jalr     <= #1 `DISABLE;
                    id_exp_code    <= #1 `EXP_NO_EXP;
                    id_pc          <= #1 `WORD_DATA_W'h0;
                    id_en          <= #1 `DISABLE;
                    id_alu_op      <= #1 `ALU_OP_NOP;
                    id_alu_in_0    <= #1 `WORD_DATA_W'h0;
                    id_alu_in_1    <= #1 `WORD_DATA_W'h0;
                    id_cmp_op      <= #1 `CMP_OP_NOP;
                    id_cmp_in_0    <= #1 `WORD_DATA_W'h0;
                    id_cmp_in_1    <= #1 `WORD_DATA_W'h0;
                    id_ex_out_sel  <= #1 `EX_OUT_SEL_W'h0;
                    id_rs1_addr    <= #1 `REG_ADDR_W'h0;
                    id_rs2_addr    <= #1 `REG_ADDR_W'h0;
                    id_jump_taken  <= #1 `DISABLE;
                    id_mem_op      <= #1 `MEM_OP_NOP;
                    id_mem_wr_data <= #1 `WORD_DATA_W'h0;
                    id_rd_addr     <= #1 5'h0;
                    id_gpr_we_     <= #1 `DISABLE_;
                    id_gpr_wr_data <= #1 `WORD_DATA_W'h0;
                    id_hart_id     <= #1 `HART_ID_W'h0;
                    id_hkill       <= #1 `DISABLE;
                    id_hstart      <= #1 `DISABLE;
                    id_hidle       <= #1 `DISABLE; 
                    id_set_hid     <= #1 `HART_ID_W'h0;
                    id_hs_id       <= #1 `HART_ID_W'h0; 
                    id_hs_pc       <= #1 `WORD_DATA_W'h0; 
                end else begin              // Assign to register
                    id_is_jalr     <= #1 is_jalr;
                    id_exp_code    <= #1 exp_code;
                    id_pc          <= #1 pc;
                    id_en          <= #1 if_en;
                    id_alu_op      <= #1 alu_op;
                    id_alu_in_0    <= #1 alu_in_0;
                    id_alu_in_1    <= #1 alu_in_1;
                    id_cmp_op      <= #1 cmp_op;
                    id_cmp_in_0    <= #1 cmp_in_0;
                    id_cmp_in_1    <= #1 cmp_in_1;
                    id_ex_out_sel  <= #1 ex_out_sel;
                    id_rs1_addr    <= #1 rs1_addr;
                    id_rs2_addr    <= #1 rs2_addr;
                    id_jump_taken  <= #1 jump_taken;
                    id_mem_op      <= #1 mem_op;
                    id_mem_wr_data <= #1 mem_wr_data;
                    id_rd_addr     <= #1 rd_addr;
                    id_gpr_we_     <= #1 gpr_we_;
                    id_gpr_wr_data <= #1 gpr_wr_data;
                    id_hart_id     <= #1 if_hart_id;
                    id_hkill       <= #1 hkill;
                    id_hstart      <= #1 hstart;
                    id_hidle       <= #1 hidle; 
                    id_set_hid     <= #1 spec_hid;
                    id_hs_id       <= #1 hs_id; 
                    id_hs_pc       <= #1 hs_pc; 
                end
            end
        end
    end
endmodule
