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
// Design Name:    MEM Pipeline Stage                             //
// Project Name:   FMRT Mini Core                                 //
// Language:       Verilog                                        //
//                                                                //
// Description:    MEM Pipeline Stage.                            //
//                                                                //
////////////////////////////////////////////////////////////////////

`include "common_defines.v"
`include "base_core_defines.v"

module mem_stage_test; 
    /********** Clock & Reset *********/
    reg                   clk;            // Clock
    reg                   reset;          // Asynchronous Reset
    /**** Pipeline Control Signal *****/
    reg                   stall;          // Stall
    reg                   flush;          // Flush
    /************ Forward *************/
    wire[`WORD_DATA_BUS] fwd_data;
    /********** SPM Interface **********/
    reg [`WORD_DATA_BUS]  spm_rd_data;    // SPM: Read data
    wire[`WORD_ADDR_BUS] spm_addr;       // SPM: Address
    wire                 spm_as_;        // SPM: Address Strobe
    wire                 spm_rw;         // SPM: Read/Write
    wire[`WORD_DATA_BUS] spm_wr_data;    // SPM: Write data
    /********** EX/MEM Pipeline Register **********/
    reg  [`EXP_CODE_BUS]        ex_exp_code;    // Exception code
    reg  [`WORD_DATA_BUS]       ex_pc;
    reg                   ex_en;          // If Pipeline data enable
    reg [`MEM_OP_BUS]     ex_mem_op;      // Memory operation
    reg [`WORD_DATA_BUS]  ex_mem_wr_data; // Memory write data
    reg [`REG_ADDR_BUS]   ex_rd_addr;     // General purpose register write address
    reg                   ex_gpr_we_;     // General purpose register enable
    reg [`WORD_DATA_BUS]  ex_out;         // EX Stage operating reslut
    /********** MEM/WB Pipeline Register **********/
    wire[`EXP_CODE_BUS]  mem_exp_code;   // Exception code
    wire[`WORD_DATA_BUS] mem_pc;
    wire                 mem_en;         // If Pipeline data enables
    wire[`REG_ADDR_BUS]  mem_rd_addr;    // General purpose register write address
    wire                 mem_gpr_we_;    // General purpose register enable
    wire[`WORD_DATA_BUS] mem_out
;


    /******** Define Simulation Loop********/
    parameter             STEP = 10;

    /******** Generate Clock ********/
    always #(STEP / 2) begin
        clk <= ~clk;
    end

    assign clk_ = ~clk;

    mem_stage mem_stage (
        .clk(clk),
        .reset(reset),
        .stall(stall),
        .flush(flush),
        .fwd_data(fwd_data),
        .spm_rd_data(spm_rd_data),
        .spm_addr(spm_addr),
        .spm_as_(spm_as_),
        .spm_rw(spm_rw),
        .spm_wr_data(spm_wr_data),
        .ex_exp_code(ex_exp_code),
        .ex_pc(ex_pc),
        .ex_en(ex_en),
        .ex_mem_op(ex_mem_op),
        .ex_mem_wr_data(ex_mem_wr_data),
        .ex_rd_addr(ex_rd_addr),
        .ex_gpr_we_(ex_gpr_we_),
        .ex_out(ex_out),
        .mem_exp_code(mem_exp_code),
        .mem_pc(mem_pc),
        .mem_en(mem_en),
        .mem_rd_addr(mem_rd_addr),
        .mem_gpr_we_(mem_gpr_we_),
        .mem_out(mem_out)
    );

    task mem_stage_tb;
        input [`WORD_DATA_BUS] _fwd_data;
        input [`WORD_ADDR_BUS] _spm_addr;
        input  _spm_as_;
        input  _spm_rw;
        input [`WORD_DATA_BUS] _spm_wr_data;
        input [`EXP_CODE_BUS] _mem_exp_code;
        input [`WORD_DATA_BUS] _mem_pc;
        input  _mem_en;
        input [`REG_ADDR_BUS] _mem_rd_addr;
        input  _mem_gpr_we_;
        input [`WORD_DATA_BUS] _mem_out;

        begin
            if((fwd_data  === _fwd_data)  &&
               (spm_addr  === _spm_addr)  &&
               (spm_as_  === _spm_as_)  &&
               (spm_rw  === _spm_rw)  &&
               (spm_wr_data  === _spm_wr_data)  &&
               (mem_exp_code  === _mem_exp_code)  &&
               (mem_pc  === _mem_pc)  &&
               (mem_en  === _mem_en)  &&
               (mem_rd_addr  === _mem_rd_addr)  &&
               (mem_gpr_we_  === _mem_gpr_we_)  &&
               (mem_out  === _mem_out)
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
            stall <= placeholder;
            ex_gpr_we_ <= placeholder;
            ex_mem_op <= placeholder;
            ex_mem_wr_data <= placeholder;
            reset <= placeholder;
            ex_rd_addr <= placeholder;
            ex_pc <= placeholder;
            ex_en <= placeholder;
            spm_rd_data <= placeholder;
            flush <= placeholder;
            ex_out <= placeholder;
            ex_exp_code <= placeholder;
            clk <= placeholder;
            end
        # (STEP * 3/4)# STEP begin
            $display("something you want to display");
            mem_stage_tb(
            	placeholder, // fwd_data
            	placeholder, // spm_addr
            	placeholder, // spm_as_
            	placeholder, // spm_rw
            	placeholder, // spm_wr_data
            	placeholder, // mem_exp_code
            	placeholder, // mem_pc
            	placeholder, // mem_en
            	placeholder, // mem_rd_addr
            	placeholder, // mem_gpr_we_
            	placeholder // mem_out
            );
            $finish;
        end
    end
	/******** Output Waveform ********/
    initial begin
       $dumpfile("mem_stage.vcd");
       $dumpvars(0, mem_stage);
    end

endmodule
