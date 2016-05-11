/******** Time scale ********/
`timescale 1ns/1ps
////////////////////////////////////////////////////////////////////
// Engineer:       Beyond Sky - fan-dave@163.com                  //
//                                                                //
// Additional contributions by:                                   //
//                 Leway Colin - colin4124@gmail.com              //
//                 Junhao Chen                                    //
//                 Kippy Chen - 799182081@qq.com                  //
//                                                                //
// Design Name:    EX Pipeline Stage                              //
// Project Name:   FMRT Mini Core                                 //
// Language:       Verilog                                        //
//                                                                //
// Description:    EX Pipeline Stage.                             //
//                                                                //
////////////////////////////////////////////////////////////////////

`include "common_defines.v"
`include "base_core_defines.v"

module ex_stage_test; 
    reg                    clk;
    reg                    reset;
    reg                    stall;
    reg                    flush;
    reg                    id_is_jalr;  // is JALR instruction
    reg  [`EXP_CODE_BUS]   id_exp_code; // Exception code
    reg  [`WORD_DATA_BUS]  id_pc;
    reg                    id_en;       // Pipeline data enable
    reg  [`ALU_OP_BUS]     id_alu_op;
    reg  [`WORD_DATA_BUS]  id_alu_in_0;
    reg  [`WORD_DATA_BUS]  id_alu_in_1;
    reg  [`CMP_OP_BUS]     id_cmp_op;
    reg  [`WORD_DATA_BUS]  id_cmp_in_0;
    reg  [`WORD_DATA_BUS]  id_cmp_in_1;
    reg                    id_jump_taken; // true - jump to target pc
    reg  [`MEM_OP_BUS]     id_mem_op;
    reg  [`WORD_DATA_BUS]  id_mem_wr_data;
    reg  [`REG_ADDR_BUS]   id_rd_addr;    // bypass reg 
    reg                    id_gpr_we_;
    reg  [`EX_OUT_SEL_BUS] id_ex_out_sel;
    reg  [`WORD_DATA_BUS]  id_gpr_wr_data;
    reg                    ex_rs1_fwd_en;
    reg                    ex_rs2_fwd_en;
    reg  [`WORD_DATA_BUS]  mem_fwd_data;   // MEM Stage
    wire [`WORD_DATA_BUS] fwd_data;
    wire [`EXP_CODE_BUS]  ex_exp_code;    // Exception code
    wire [`WORD_DATA_BUS] ex_pc;
    wire                  ex_en;
    wire [`MEM_OP_BUS]    ex_mem_op;
    wire [`WORD_DATA_BUS] ex_mem_wr_data;
    wire [`REG_ADDR_BUS]  ex_rd_addr;     // bypass wire
    wire                  ex_gpr_we_;
    wire [`WORD_DATA_BUS] ex_out;
    // wire to IF Stage
    wire [`WORD_DATA_BUS] br_addr;        // target pc value of branch or jump
    wire                  br_taken        // ture - take branch or jump
;


    /******** Define Simulation Loop********/
    parameter             STEP = 10;

    /******** Generate Clock ********/
    always #(STEP / 2) begin
        clk <= ~clk;
    end

    assign clk_ = ~clk;

    ex_stage ex_stage (
        .clk(clk),
        .reset(reset),
        .stall(stall),
        .flush(flush),
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
        .ex_rs1_fwd_en(ex_rs1_fwd_en),
        .ex_rs2_fwd_en(ex_rs2_fwd_en),
        .mem_fwd_data(mem_fwd_data),
        .fwd_data(fwd_data),
        .ex_exp_code(ex_exp_code),
        .ex_pc(ex_pc),
        .ex_en(ex_en),
        .ex_mem_op(ex_mem_op),
        .ex_mem_wr_data(ex_mem_wr_data),
        .ex_rd_addr(ex_rd_addr),
        .ex_gpr_we_(ex_gpr_we_),
        .ex_out(ex_out),
        .br_addr(br_addr),
        .br_taken(br_taken)
    );

    task ex_stage_tb;
        input [`WORD_DATA_BUS] _fwd_data;
        input [`EXP_CODE_BUS] _ex_exp_code;
        input [`WORD_DATA_BUS] _ex_pc;
        input  _ex_en;
        input [`MEM_OP_BUS] _ex_mem_op;
        input [`WORD_DATA_BUS] _ex_mem_wr_data;
        input [`REG_ADDR_BUS] _ex_rd_addr;
        input  _ex_gpr_we_;
        input [`WORD_DATA_BUS] _ex_out;
        input [`WORD_DATA_BUS] _br_addr;
        input  _br_taken;

        begin
            if((fwd_data  === _fwd_data)  &&
               (ex_exp_code  === _ex_exp_code)  &&
               (ex_pc  === _ex_pc)  &&
               (ex_en  === _ex_en)  &&
               (ex_mem_op  === _ex_mem_op)  &&
               (ex_mem_wr_data  === _ex_mem_wr_data)  &&
               (ex_rd_addr  === _ex_rd_addr)  &&
               (ex_gpr_we_  === _ex_gpr_we_)  &&
               (ex_out  === _ex_out)  &&
               (br_addr  === _br_addr)  &&
               (br_taken  === _br_taken)
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
            reset <= placeholder;
            mem_fwd_data <= placeholder;
            id_cmp_op <= placeholder;
            id_alu_in_1 <= placeholder;
            id_gpr_wr_data <= placeholder;
            id_is_jalr <= placeholder;
            id_mem_wr_data <= placeholder;
            id_alu_in_0 <= placeholder;
            id_ex_out_sel <= placeholder;
            id_mem_op <= placeholder;
            id_alu_op <= placeholder;
            id_en <= placeholder;
            id_exp_code <= placeholder;
            stall <= placeholder;
            ex_rs1_fwd_en <= placeholder;
            id_pc <= placeholder;
            id_cmp_in_1 <= placeholder;
            ex_rs2_fwd_en <= placeholder;
            clk <= placeholder;
            id_cmp_in_0 <= placeholder;
            id_rd_addr <= placeholder;
            flush <= placeholder;
            id_gpr_we_ <= placeholder;
            id_jump_taken <= placeholder;
            end
        # (STEP * 3/4)# STEP begin
            $display("something you want to display");
            ex_stage_tb(
            	placeholder, // fwd_data
            	placeholder, // ex_exp_code
            	placeholder, // ex_pc
            	placeholder, // ex_en
            	placeholder, // ex_mem_op
            	placeholder, // ex_mem_wr_data
            	placeholder, // ex_rd_addr
            	placeholder, // ex_gpr_we_
            	placeholder, // ex_out
            	placeholder, // br_addr
            	placeholder // br_taken
            );
            $finish;
        end
    end
	/******** Output Waveform ********/
    initial begin
       $dumpfile("ex_stage.vcd");
       $dumpvars(0, ex_stage);
    end

endmodule
