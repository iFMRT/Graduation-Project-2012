/* 
 -- ============================================================================
 -- FILE NAME : if_reg_test.v
 -- DESCRIPTION : 测试 if_reg 模块的正确性
 -- ----------------------------------------------------------------------------
 -- Date : 2015/12/21                       Coding_by : kippy
 -- ============================================================================
*/

/************** Time scale ***************/
`timescale 1ns/1ps

/********** General header file **********/
`include "stddef.h"

/********** module header file ***********/
`include "isa.h"

module if_reg_test;

    /***** clock & reset ******/ 
    reg clk;                                    // Clk
    reg reset;                                  // Reset
    /********* input *********/
    reg stall;                                  // Stall
    reg flush;                                  // Flush
    reg br_taken;                               // Branch taken
    reg [`WORD_DATA_BUS] new_pc;                // New value of program counter
    reg [`WORD_DATA_BUS] br_addr;               // Branch target
    reg [`WORD_DATA_BUS] insn;                  // Reading instruction
    /******** output ********/
    wire[`WORD_DATA_BUS] if_pc;                 // Program counter
    wire[`WORD_DATA_BUS] if_pc_plus4;           // Next PC
    wire[`WORD_DATA_BUS] if_insn;               // Instruction
    wire if_en;                                 // Effective mark of pipeline

    /* Define the simulation loop */  
    parameter     STEP = 10; 

    /* Instantiate the test module */
    if_reg if_reg(.clk      (clk),               // Clk
                  .reset    (reset),             // Reset
                  .stall    (stall),             // Stall
                  .flush    (flush),             // Flush
                  .br_taken (br_taken),          // Branch taken
                  .new_pc   (new_pc),            // New value of program counter
                  .br_addr  (br_addr),           // Branch target
                  .insn     (insn),              // Reading instruction
                  .if_pc    (if_pc),             // Program counter
                  .if_pc_plus4    (if_pc_plus4), // Next PC
                  .if_insn  (if_insn),           // Instruction
                  .if_en    (if_en)              // Effective mark of pipeline
                  ); 

    /******* Generated Clocks *******/
    always #(STEP / 2)
        begin
            clk <= ~clk;  
        end

    /********** Testbench **********/
    initial
    begin
        /************* Flush ***************/
        #0  
        begin
            clk <= `ENABLE;
            reset <= `ENABLE;
            insn <= `WORD_DATA_W'h124;
            stall <= `DISABLE;
            flush <= `ENABLE;
            new_pc <= `WORD_DATA_W'h154;
            br_taken <= `DISABLE;
            br_addr <= `WORD_DATA_W'h100;
        end
        #(STEP * 3 / 4)
        #STEP 
        begin
            reset <= `DISABLE;
        end
        #STEP 
        begin
            if (if_pc == 32'h154 && if_insn == `ISA_NOP && if_en == `DISABLE && if_pc_plus4 == 32'h158) 
                begin
                    $display ("Simulation of flush succeeded");      
                end
            else 
                begin
                    $display ("Simulation of flush failed");
                end
        end
        /************* Branch taken ***************/
        #STEP
        begin
            flush <= `DISABLE;
            br_taken <= `ENABLE;
        end
        #STEP
        begin
            if (if_pc == `WORD_DATA_W'h100 && if_insn == `WORD_DATA_W'h124 && if_en == `ENABLE && if_pc_plus4 == 32'h104) 
                begin
                    $display ("Simulation of branch succeeded");        
                end
            else 
                begin
                    $display ("Simulation of branch failed");
                end
        end
        /************* Next PC ***************/
        #STEP
        begin
            br_taken <= `DISABLE;
        end
        #STEP
        begin
            if (if_pc == `WORD_DATA_W'h104 && if_insn == `WORD_DATA_W'h124 && if_en == `ENABLE && if_pc_plus4 == 32'h108) 
                begin
                    $display ("Simulation of next pc succeeded");        
                end
            else 
                begin
                    $display ("Simulation of next pc failed");
                end
        end
        #STEP
        begin
            $finish;
        end
    end     

    /********** output wave **********/
    initial
        begin
            $dumpfile("if_reg.vcd");
            $dumpvars(0,if_reg);
        end
endmodule