/******** Time scale ********/
`timescale 1ns/1ps
/////////////////////////////////////////////////////////////////////
// Engineer:       Leway Colin - colin4124@gmail.com               //
//                                                                 //
// Additional contributions by:                                    //
//                 Beyond Sky - fan-dave@163.com                   //
//                 Kippy Chen - 799182081@qq.com                   //
//                 Junhao Chen                                     //
//                                                                 //
// Design Name:    Main controller                                 //
// Project Name:   FMRT Mini Core                                  //
// Language:       Verilog                                         //
//                                                                 //
// Description:    Including core controller; stall controller;    //
//                 and exception controller.                       //
//                                                                 //
/////////////////////////////////////////////////////////////////////

`include "common_defines.v"
`include "base_core_defines.v"

module ctrl_test; 
    //  State of Pipeline
    reg                  br_taken;    // branch hazard mark

    reg  [1:0]                 src_reg_used;

    // from ID stage
    reg                  is_eret_instr;

    // LOAD Hazard
    reg                  id_en;       // Pipeline Register enable
    reg [`REG_ADDR_BUS]  id_dst_addr; // GPR write address
    reg                  id_gpr_we_;  // GPR write enable
    reg [`MEM_OP_BUS]    id_mem_op;   // Mem operation

    reg [`INS_OP_BUS]    op;
    reg [`REG_ADDR_BUS]  ra_addr;
    reg [`REG_ADDR_BUS]  rb_addr;
    // LOAD STORE Forward
    reg [`REG_ADDR_BUS]  id_rs1_addr;
    reg [`REG_ADDR_BUS]  id_rs2_addr;

    reg                  ex_en;       // Pipeline Register enable
    reg [`REG_ADDR_BUS]  ex_dst_addr; // GPR write address
    reg                  ex_gpr_we_;  // GPR write enable
    reg [`MEM_OP_BUS]    ex_mem_op;   // Mem operation

    // from MEM stage
    reg [`WORD_DATA_BUS] mem_pc;
    reg                  mem_en;
    reg [`EXP_CODE_BUS]  mem_exp_code;

    // from CSR
    reg [`WORD_DATA_BUS] mepc_i;

    // to CSR
    wire[`WORD_DATA_BUS] mepc_o;
    wire[`EXP_CODE_BUS]  exp_code;
    wire                 save_exp;
    wire                 restore_exp;

    // Stall Signal
    wire                if_stall;    // IF stage stall
    wire                id_stall;    // ID stage stall
    wire                ex_stall;    // EX stage stall
    wire                mem_stall;   // MEM stage stall
    // Flush Signal
    wire                if_flush;    // IF stage flush
    wire                id_flush;    // ID stage flush
    wire                ex_flush;    // EX stage Flush
    wire                mem_flush;   // MEM stage flush
    wire[`WORD_DATA_BUS] new_pc;      // New program counter

    // Forward from EX stage

    wire[`FWD_CTRL_BUS]  ra_fwd_ctrl;
    wire[`FWD_CTRL_BUS]  rb_fwd_ctrl;
    wire                 ex_rs1_fwd_en;
    wire                 ex_rs2_fwd_en
;


    /******** Define Simulation Loop********/
    parameter             STEP = 10;

    /******** Generate Clock ********/
    always #(STEP / 2) begin
        clk <= ~clk;
    end

    assign clk_ = ~clk;

    ctrl ctrl (
        .br_taken(br_taken),
        .src_reg_used(src_reg_used),
        .is_eret_instr(is_eret_instr),
        .id_en(id_en),
        .id_dst_addr(id_dst_addr),
        .id_gpr_we_(id_gpr_we_),
        .id_mem_op(id_mem_op),
        .op(op),
        .ra_addr(ra_addr),
        .rb_addr(rb_addr),
        .id_rs1_addr(id_rs1_addr),
        .id_rs2_addr(id_rs2_addr),
        .ex_en(ex_en),
        .ex_dst_addr(ex_dst_addr),
        .ex_gpr_we_(ex_gpr_we_),
        .ex_mem_op(ex_mem_op),
        .mem_pc(mem_pc),
        .mem_en(mem_en),
        .mem_exp_code(mem_exp_code),
        .mepc_i(mepc_i),
        .mepc_o(mepc_o),
        .exp_code(exp_code),
        .save_exp(save_exp),
        .restore_exp(restore_exp),
        .if_stall(if_stall),
        .id_stall(id_stall),
        .ex_stall(ex_stall),
        .mem_stall(mem_stall),
        .if_flush(if_flush),
        .id_flush(id_flush),
        .ex_flush(ex_flush),
        .mem_flush(mem_flush),
        .new_pc(new_pc),
        .ra_fwd_ctrl(ra_fwd_ctrl),
        .rb_fwd_ctrl(rb_fwd_ctrl),
        .ex_rs1_fwd_en(ex_rs1_fwd_en),
        .ex_rs2_fwd_en(ex_rs2_fwd_en)
    );

    task ctrl_tb;
        input [`WORD_DATA_BUS] _mepc_o;
        input [`EXP_CODE_BUS] _exp_code;
        input  _save_exp;
        input  _restore_exp;
        input  _if_stall;
        input  _id_stall;
        input  _ex_stall;
        input  _mem_stall;
        input  _if_flush;
        input  _id_flush;
        input  _ex_flush;
        input  _mem_flush;
        input [`WORD_DATA_BUS] _new_pc;
        input [`FWD_CTRL_BUS] _ra_fwd_ctrl;
        input [`FWD_CTRL_BUS] _rb_fwd_ctrl;
        input  _ex_rs1_fwd_en;
        input  _ex_rs2_fwd_en;

        begin
            if((mepc_o  === _mepc_o)  &&
               (exp_code  === _exp_code)  &&
               (save_exp  === _save_exp)  &&
               (restore_exp  === _restore_exp)  &&
               (if_stall  === _if_stall)  &&
               (id_stall  === _id_stall)  &&
               (ex_stall  === _ex_stall)  &&
               (mem_stall  === _mem_stall)  &&
               (if_flush  === _if_flush)  &&
               (id_flush  === _id_flush)  &&
               (ex_flush  === _ex_flush)  &&
               (mem_flush  === _mem_flush)  &&
               (new_pc  === _new_pc)  &&
               (ra_fwd_ctrl  === _ra_fwd_ctrl)  &&
               (rb_fwd_ctrl  === _rb_fwd_ctrl)  &&
               (ex_rs1_fwd_en  === _ex_rs1_fwd_en)  &&
               (ex_rs2_fwd_en  === _ex_rs2_fwd_en)
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
            is_eret_instr <= placeholder;
            ex_mem_op <= placeholder;
            op <= placeholder;
            ex_gpr_we_ <= placeholder;
            mem_en <= placeholder;
            id_rs1_addr <= placeholder;
            mepc_i <= placeholder;
            rb_addr <= placeholder;
            mem_pc <= placeholder;
            src_reg_used <= placeholder;
            id_gpr_we_ <= placeholder;
            ra_addr <= placeholder;
            id_en <= placeholder;
            id_mem_op <= placeholder;
            id_rs2_addr <= placeholder;
            mem_exp_code <= placeholder;
            ex_dst_addr <= placeholder;
            ex_en <= placeholder;
            br_taken <= placeholder;
            id_dst_addr <= placeholder;
            end
        # (STEP * 3/4)# STEP begin
            $display("something you want to display");
            ctrl_tb(
            	placeholder, // mepc_o
            	placeholder, // exp_code
            	placeholder, // save_exp
            	placeholder, // restore_exp
            	placeholder, // if_stall
            	placeholder, // id_stall
            	placeholder, // ex_stall
            	placeholder, // mem_stall
            	placeholder, // if_flush
            	placeholder, // id_flush
            	placeholder, // ex_flush
            	placeholder, // mem_flush
            	placeholder, // new_pc
            	placeholder, // ra_fwd_ctrl
            	placeholder, // rb_fwd_ctrl
            	placeholder, // ex_rs1_fwd_en
            	placeholder // ex_rs2_fwd_en
            );
            $finish;
        end
    end
	/******** Output Waveform ********/
    initial begin
       $dumpfile("ctrl.vcd");
       $dumpvars(0, ctrl);
    end

endmodule
