/******** Time scale ********/
`timescale 1ns/1ps
////////////////////////////////////////////////////////////////////
// Engineer:       Leway Colin - colin4124@gmail.com              //
//                                                                //
// Additional contributions by:                                   //
//                 Beyond Sky - fan-dave@163.com                  //
//                 Junhao Chen                                    //
//                 Kippy Chen - 799182081@qq.com                  //
//                                                                //
// Design Name:    ID Pipeline Stage                              //
// Project Name:   FMRT Mini Core                                 //
// Language:       Verilog                                        //
//                                                                //
// Description:    ID Pipeline Stage.                             //
//                                                                //
////////////////////////////////////////////////////////////////////

`include "common_defines.v"
`include "base_core_defines.v"

module id_stage_test; 
    /********** Clock & Reset **********/
    reg                     clk;           // Clock
    reg                     reset;         // Reset
    /********** GPR Interface **********/
    reg   [`WORD_DATA_BUS]  gpr_rs1_data;  // Read rs1 data
    reg   [`WORD_DATA_BUS]  gpr_rs2_data;  // Read rs2 data
    wire [`REG_ADDR_BUS]   gpr_rs1_addr;  // Read rs1 address
    wire [`REG_ADDR_BUS]   gpr_rs2_addr;  // Read rs2 address
    /********** Forward **********/
    reg   [`WORD_DATA_BUS]  ex_fwd_data;   // Forward data from EX Stage
    reg   [`WORD_DATA_BUS]  mem_fwd_data;  // Forward data from MEM Stage
    /********** CSRs Interface **********/
    reg   [`WORD_DATA_BUS]  csr_rd_data;   // Read from CSRs
    wire [`CSR_OP_BUS]     csr_op;        // CSRs operation
    wire [`CSR_ADDR_BUS]   csr_addr;      // Access CSRs address
    wire [`WORD_DATA_BUS]  csr_wr_data;   // Write to CSRs
    /********** Pipeline Control Signal **********/
    reg                     stall;         // Stall
    reg                     flush;         // Flush
    /********** Forward Signal **********/
    reg  [`FWD_CTRL_BUS]    rs1_fwd_ctrl;
    reg  [`FWD_CTRL_BUS]    rs2_fwd_ctrl;
    /********** IF/ID Pipeline Register **********/
    reg  [`WORD_DATA_BUS]   pc;            // Current PC
    reg  [`WORD_DATA_BUS]   if_pc;         // Next PC
    reg  [`WORD_DATA_BUS]   if_insn;       // Instruction
    reg                     if_en;         // Pipeline data enable
    /********** ID/EX Pipeline Register  **********/
    wire                   id_is_jalr;    // is JALR instruction
    wire [`EXP_CODE_BUS]   id_exp_code;   // Exception code
    wire [`WORD_DATA_BUS]  id_pc;
    wire                   id_en;         // Pipeline data enable
    wire [`ALU_OP_BUS]     id_alu_op;     // ALU Operation
    wire [`WORD_DATA_BUS]  id_alu_in_0;   // ALU reg  0
    wire [`WORD_DATA_BUS]  id_alu_in_1;   // ALU reg  1
    wire [`CMP_OP_BUS]     id_cmp_op;     // CMP Operation
    wire [`WORD_DATA_BUS]  id_cmp_in_0;   // CMP reg  0
    wire [`WORD_DATA_BUS]  id_cmp_in_1;   // CMP reg  1
    wire                   id_jump_taken;
    wire [`MEM_OP_BUS]     id_mem_op;     // Memory Operation
    wire [`WORD_DATA_BUS]  id_mem_wr_data;// Memory write data
    wire [`REG_ADDR_BUS]   id_rd_addr;    // GPR write address
    wire                   id_gpr_we_;    // GPR write enable
    wire [`EX_OUT_SEL_BUS] id_ex_out_sel;
    wire [`WORD_DATA_BUS]  id_gpr_wr_data;
    // wire to Control Unit
    wire                   is_eret;       // is ERET instruction
    wire [`INSN_OP_BUS]    op;
    wire [`REG_ADDR_BUS]   id_rs1_addr;
    wire [`REG_ADDR_BUS]   id_rs2_addr;
    wire [`REG_ADDR_BUS]   rs1_addr;
    wire [`REG_ADDR_BUS]   rs2_addr;
    wire [1:0]             src_reg_used   // How many source registers instruction used
;


    /******** Define Simulation Loop********/
    parameter             STEP = 10;

    /******** Generate Clock ********/
    always #(STEP / 2) begin
        clk <= ~clk;
    end

    assign clk_ = ~clk;

    id_stage id_stage (
        .clk(clk),
        .reset(reset),
        .gpr_rs1_data(gpr_rs1_data),
        .gpr_rs2_data(gpr_rs2_data),
        .gpr_rs1_addr(gpr_rs1_addr),
        .gpr_rs2_addr(gpr_rs2_addr),
        .ex_fwd_data(ex_fwd_data),
        .mem_fwd_data(mem_fwd_data),
        .csr_rd_data(csr_rd_data),
        .csr_op(csr_op),
        .csr_addr(csr_addr),
        .csr_wr_data(csr_wr_data),
        .stall(stall),
        .flush(flush),
        .rs1_fwd_ctrl(rs1_fwd_ctrl),
        .rs2_fwd_ctrl(rs2_fwd_ctrl),
        .pc(pc),
        .if_pc(if_pc),
        .if_insn(if_insn),
        .if_en(if_en),
        .id_is_jalr(id_is_jalr),
        .id_exp_code(id_exp_code),
        .id_pc(id_pc),
        .id_en(id_en),
        .id_alu_op(id_alu_op),
        .id_alu_in_0(id_alu_in_0),
        .id_alu_in_1(id_alu_in_1),
        .id_cmp_op(id_cmp_op),
        .id_cmp_in_0(id_cmp_in_0),
        .id_cmp_in_1(id_cmp_in_1),
        .id_jump_taken(id_jump_taken),
        .id_mem_op(id_mem_op),
        .id_mem_wr_data(id_mem_wr_data),
        .id_rd_addr(id_rd_addr),
        .id_gpr_we_(id_gpr_we_),
        .id_ex_out_sel(id_ex_out_sel),
        .id_gpr_wr_data(id_gpr_wr_data),
        .is_eret(is_eret),
        .op(op),
        .id_rs1_addr(id_rs1_addr),
        .id_rs2_addr(id_rs2_addr),
        .rs1_addr(rs1_addr),
        .rs2_addr(rs2_addr),
        .src_reg_used(src_reg_used)
    );

    task id_stage_tb;
        input [`REG_ADDR_BUS] _gpr_rs1_addr;
        input [`REG_ADDR_BUS] _gpr_rs2_addr;
        input [`CSR_OP_BUS] _csr_op;
        input [`CSR_ADDR_BUS] _csr_addr;
        input [`WORD_DATA_BUS] _csr_wr_data;
        input  _id_is_jalr;
        input [`EXP_CODE_BUS] _id_exp_code;
        input [`WORD_DATA_BUS] _id_pc;
        input  _id_en;
        input [`ALU_OP_BUS] _id_alu_op;
        input [`WORD_DATA_BUS] _id_alu_in_0;
        input [`WORD_DATA_BUS] _id_alu_in_1;
        input [`CMP_OP_BUS] _id_cmp_op;
        input [`WORD_DATA_BUS] _id_cmp_in_0;
        input [`WORD_DATA_BUS] _id_cmp_in_1;
        input  _id_jump_taken;
        input [`MEM_OP_BUS] _id_mem_op;
        input [`WORD_DATA_BUS] _id_mem_wr_data;
        input [`REG_ADDR_BUS] _id_rd_addr;
        input  _id_gpr_we_;
        input [`EX_OUT_SEL_BUS] _id_ex_out_sel;
        input [`WORD_DATA_BUS] _id_gpr_wr_data;
        input  _is_eret;
        input [`INSN_OP_BUS] _op;
        input [`REG_ADDR_BUS] _id_rs1_addr;
        input [`REG_ADDR_BUS] _id_rs2_addr;
        input [`REG_ADDR_BUS] _rs1_addr;
        input [`REG_ADDR_BUS] _rs2_addr;
        input [1:0] _src_reg_used;

        begin
            if((gpr_rs1_addr  === _gpr_rs1_addr)  &&
               (gpr_rs2_addr  === _gpr_rs2_addr)  &&
               (csr_op  === _csr_op)  &&
               (csr_addr  === _csr_addr)  &&
               (csr_wr_data  === _csr_wr_data)  &&
               (id_is_jalr  === _id_is_jalr)  &&
               (id_exp_code  === _id_exp_code)  &&
               (id_pc  === _id_pc)  &&
               (id_en  === _id_en)  &&
               (id_alu_op  === _id_alu_op)  &&
               (id_alu_in_0  === _id_alu_in_0)  &&
               (id_alu_in_1  === _id_alu_in_1)  &&
               (id_cmp_op  === _id_cmp_op)  &&
               (id_cmp_in_0  === _id_cmp_in_0)  &&
               (id_cmp_in_1  === _id_cmp_in_1)  &&
               (id_jump_taken  === _id_jump_taken)  &&
               (id_mem_op  === _id_mem_op)  &&
               (id_mem_wr_data  === _id_mem_wr_data)  &&
               (id_rd_addr  === _id_rd_addr)  &&
               (id_gpr_we_  === _id_gpr_we_)  &&
               (id_ex_out_sel  === _id_ex_out_sel)  &&
               (id_gpr_wr_data  === _id_gpr_wr_data)  &&
               (is_eret  === _is_eret)  &&
               (op  === _op)  &&
               (id_rs1_addr  === _id_rs1_addr)  &&
               (id_rs2_addr  === _id_rs2_addr)  &&
               (rs1_addr  === _rs1_addr)  &&
               (rs2_addr  === _rs2_addr)  &&
               (src_reg_used  === _src_reg_used)
              ) begin
                $display("Test Succeeded !");
            end else begin
                $display("Test Failed !");
            end
        end

    endtask

    /******** Test Case ********/
    initial begin
        # 0 begin
            flush <= placeholder;
            mem_fwd_data <= placeholder;
            if_insn <= placeholder;
            rs2_fwd_ctrl <= placeholder;
            if_en <= placeholder;
            gpr_rs2_data <= placeholder;
            gpr_rs1_data <= placeholder;
            ex_fwd_data <= placeholder;
            stall <= placeholder;
            pc <= placeholder;
            csr_rd_data <= placeholder;
            rs1_fwd_ctrl <= placeholder;
            reset <= placeholder;
            clk <= placeholder;
            if_pc <= placeholder;
            end
        # (STEP * 3/4)# STEP begin
            $display("something you want to display");
            id_stage_tb(
            	placeholder, // gpr_rs1_addr
            	placeholder, // gpr_rs2_addr
            	placeholder, // csr_op
            	placeholder, // csr_addr
            	placeholder, // csr_wr_data
            	placeholder, // id_is_jalr
            	placeholder, // id_exp_code
            	placeholder, // id_pc
            	placeholder, // id_en
            	placeholder, // id_alu_op
            	placeholder, // id_alu_in_0
            	placeholder, // id_alu_in_1
            	placeholder, // id_cmp_op
            	placeholder, // id_cmp_in_0
            	placeholder, // id_cmp_in_1
            	placeholder, // id_jump_taken
            	placeholder, // id_mem_op
            	placeholder, // id_mem_wr_data
            	placeholder, // id_rd_addr
            	placeholder, // id_gpr_we_
            	placeholder, // id_ex_out_sel
            	placeholder, // id_gpr_wr_data
            	placeholder, // is_eret
            	placeholder, // op
            	placeholder, // id_rs1_addr
            	placeholder, // id_rs2_addr
            	placeholder, // rs1_addr
            	placeholder, // rs2_addr
            	placeholder // src_reg_used
            );
            $finish;
        end
    end
	/******** Output Waveform ********/
    initial begin
       $dumpfile("id_stage.vcd");
       $dumpvars(0, id_stage);
    end

endmodule
