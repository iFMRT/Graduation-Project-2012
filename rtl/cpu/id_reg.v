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

module id_reg (
    /********** Clock & Rest **********/
    input                        clk,           // Clock
    input                        reset,         // Asynchronous rest
    /********** Decode result **********/
    input [`ALU_OP_BUS]          alu_op,        // ALU operation
    input [`WORD_DATA_BUS]       alu_in_0,      // ALU input 0
    input [`WORD_DATA_BUS]       alu_in_1,      // ALU input 1
    input [`CMP_OP_BUS]          cmp_op,        // CMP operation
    input [`WORD_DATA_BUS]       cmp_in_0,      // CMP input 0
    input [`WORD_DATA_BUS]       cmp_in_1,      // CMP input 1
    input [`REG_ADDR_BUS]        rs1_addr,      // Read register source one
    input [`REG_ADDR_BUS]        rs2_addr,      // Read register source two
    input                        jump_taken,    // Jump taken
    input [`MEM_OP_BUS]          mem_op,        // Memory operation
    input [`WORD_DATA_BUS]       mem_wr_data,   // Memory write data
    input [`REG_ADDR_BUS]        rd_addr,      // destination register address
    input                        gpr_we_,       // GPR write eanble
    input [`EX_OUT_SEL_BUS]      ex_out_sel,    // Select ex stage outputs
    input [`WORD_DATA_BUS]       gpr_wr_data,   // the data which write to GPR
    input                        is_jalr,       // is JALR instruction
    input [`EXP_CODE_BUS]        exp_code,      // Exception code
    /********** Control Signal **********/
    input                        stall,
    input                        flush,
    /********** IF/ID Pipeline  Register  **********/
    input [`WORD_DATA_BUS]       pc,            // Current program counter
    input                        if_en,         // IF stage register enable
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
    output reg [`WORD_DATA_BUS]  id_gpr_wr_data
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
                end
            end
        end
    end
endmodule
