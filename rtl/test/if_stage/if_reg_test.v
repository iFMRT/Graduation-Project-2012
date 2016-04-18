/******** Time scale ********/
`timescale 1ns/1ps
////////////////////////////////////////////////////////////////////////
// Engineer:       Kippy Chen - 799182081@qq.com                      //
//                                                                    //
// Additional contributions by:                                       //
//                 Beyond Sky - fan-dave@163.com                      //
//                 Leway Colin - colin4124@gmail.com                  //
//                 Junhao Chen                                        //
//                                                                    //
// Design Name:    IF/ID Pipeline Register                            //
// Project Name:   FMRT Mini Core                                     //
// Language:       Verilog                                            //
//                                                                    //
// Description:    IF/ID Pipeline Register.                           //
//                                                                    //
////////////////////////////////////////////////////////////////////////

`include "stddef.h"
`include "base_core_defines.v"

module if_reg_test; 
    /******** Clock & Rest ********/
    reg                        clk;      // Clk
    reg                        reset;    // Reset
    /******** Read Instruction ********/
    reg  [`WORD_DATA_BUS]      insn;     // Reading instruction

    reg                        stall;    // Stall
    reg                        flush;    // Flush
    reg  [`WORD_DATA_BUS]      new_pc;   // New value of program counter
    reg                        br_taken; // Branch taken
    reg  [`WORD_DATA_BUS]      br_addr;  // Branch target

    wire[`WORD_DATA_BUS] pc;       // Current Program counter
    wire[`WORD_DATA_BUS] if_pc;    // Next Program counter
    wire[`WORD_DATA_BUS] if_insn;  // Instruction
    wire                 if_en     // Effective mark of pipeline
;


    /******** Define Simulation Loop********/
    parameter             STEP = 10;

    /******** Generate Clock ********/
    always #(STEP / 2) begin
        clk <= ~clk;
    end

    assign clk_ = ~clk;

    if_reg if_reg (
        .clk(clk),
        .reset(reset),
        .insn(insn),
        .stall(stall),
        .flush(flush),
        .new_pc(new_pc),
        .br_taken(br_taken),
        .br_addr(br_addr),
        .pc(pc),
        .if_pc(if_pc),
        .if_insn(if_insn),
        .if_en(if_en)
    );

    task if_reg_tb;
        input [`WORD_DATA_BUS] _pc;
        input [`WORD_DATA_BUS] _if_pc;
        input [`WORD_DATA_BUS] _if_insn;
        input  _if_en;

        begin
            if((pc  === _pc)  &&
               (if_pc  === _if_pc)  &&
               (if_insn  === _if_insn)  &&
               (if_en  === _if_en)
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
            reset <= `ENABLE;
            insn <= `WORD_DATA_W'h124;
            br_taken <= `DISABLE;
            stall <= `DISABLE;
            clk <= `ENABLE;
            flush <= `DISABLE;
            br_addr <= `WORD_DATA_W'h100;
            new_pc <= `WORD_DATA_W'h154;
            end
        # (STEP * 3/4)
        # STEP begin
            $display("\n=== Initialize ===");
           if_reg_tb(
           	`WORD_DATA_W'h0, // pc
           	`WORD_DATA_W'h0, // if_pc
           	`ISA_NOP, // if_insn
           	`DISABLE // if_en
           );
           
            reset <= `DISABLE;
           end
        
        # STEP begin
            $display("\n=== Clock 1 ===");
           if_reg_tb(
           	`WORD_DATA_W'h0, // pc
           	`WORD_DATA_W'h4, // if_pc
           	`WORD_DATA_W'h124, // if_insn
           	`ENABLE // if_en
           );
           
            flush <= `ENABLE;
           end
        
        # STEP begin
            $display("\n=== Clock 2: Flush ===");
           if_reg_tb(
           	`WORD_DATA_W'h0, // pc
           	`WORD_DATA_W'h154, // if_pc
           	`ISA_NOP, // if_insn
           	`DISABLE // if_en
           );
           
            br_taken <= `ENABLE;
           flush <= `DISABLE;
           end
        # STEP begin
            $display("\n=== Clock 3: Branch ===");
            if_reg_tb(
            	`WORD_DATA_W'h0, // pc
            	`WORD_DATA_W'h100, // if_pc
            	`ISA_NOP, // if_insn
            	`DISABLE // if_en
            );
            $finish;
        end
    end
	/******** Output Waveform ********/
    initial begin
       $dumpfile("if_reg.vcd");
       $dumpvars(0, if_reg);
    end

endmodule
