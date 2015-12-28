/* 
 -- ============================================================================
 -- FILE NAME : if_stage_test.v
 -- DESCRIPTION : 测试 if_stage 模块的正确性
 -- ----------------------------------------------------------------------------
 -- Date : 2015/12/25                       Coding_by : kippy
 -- ============================================================================
*/

/********** 时间规格 **********/
`timescale 1ns/1ps

/********** General header file **********/
`include "stddef.h"

/********** module header file **********/
`include "isa.h"

module if_stage_test;

    /********** input & output **********/
    /********** clock & reset **********/ 
                reg  clk;                           // Clk
                reg  reset;                         // Reset
                reg  br_taken;                      // Branch taken
                reg  [`WORD_DATA_BUS] new_pc;       // New value of program counter
                reg  [`WORD_DATA_BUS] br_addr;      // Branch target
                wire [`WORD_DATA_BUS] if_pc;        // Program counter
                wire [`WORD_DATA_BUS] if_insn;      // Instruction
                wire  if_en;                            // Effective mark of pipeline
                /********** Pipeline control **********/ 
                reg  stall;                         // Stall 
                reg  flush;                         // Flush  
                /************ SPM Interface ***********/
                reg  [`WORD_DATA_BUS] spm_rd_data;  // Address of reading SPM
                wire [`WORD_ADDR_BUS] spm_addr;     // Address of SPM
                wire spm_as_;                       // SPM strobe
                wire spm_rw;                        // Read/Write SPM
                wire [`WORD_DATA_BUS] spm_wr_data;  // Write data of SPM

    /******** Define the simulation loop ********/ 
    parameter     STEP = 10; 

    if_stage if_stage(/********** clock & reset **********/ 
                        .clk        (clk),          // Clk
                        .reset      (reset),        // Reset
                        .br_taken   (br_taken),     // Branch taken
                        .new_pc     (new_pc),       // New value of program counter
                        .br_addr    (br_addr),      // Branch target
                        .if_pc      (if_pc),        // Program counter
                        .if_insn    (if_insn),      // Instruction
                        .if_en      (if_en),        // Effective mark of pipeline
                        /********** Pipeline control **********/ 
                        .stall      (stall),        // Stall 
                        .flush      (flush),        // Flush  
                        /************* SPM Interface *************/
                        .spm_rd_data(spm_rd_data),  // Address of reading SPM
                        .spm_addr   (spm_addr),     // Address of SPM
                        .spm_as_    (spm_as_),      // SPM strobe
                        .spm_rw     (spm_rw),       // Read/Write SPM
                        .spm_wr_data(spm_wr_data)   // Write data of SPM
                        );

    /********** Generated Clocks **********/
    always #(STEP / 2)
        begin
            clk <= ~clk;  
        end

    /********** Testbench **********/
    initial
    begin
        /************* next pc ***************/
        #0  
        begin
            clk <= `ENABLE;
            reset <= `ENABLE;
            br_taken <= `DISABLE; 
            new_pc <= `WORD_DATA_W'h154;
            br_addr <= `WORD_DATA_W'h100; 
            stall <= `DISABLE;
            flush <= `DISABLE;
            spm_rd_data <=  `WORD_DATA_W'd128;        
        end
        #(STEP * 3 / 4)
        #STEP 
        begin
            reset <= `DISABLE;
        end
        #STEP 
        begin
            if (if_pc === `WORD_DATA_W'h4 & if_insn === `WORD_DATA_W'd128 & if_en === `ENABLE) 
                begin
                    $display ("Simulation of next pc succeeded");      
                end
            else 
                begin
                    $display ("Simulation of next pc failed");
                end
        end
        /************* flush ***************/
        #STEP 
        begin
            flush <= `ENABLE;
        end
        #STEP 
        begin
            if (if_pc === 32'h154 & if_insn === `ISA_NOP & if_en === `DISABLE) 
                begin
                    $display ("Simulation of flush succeeded");      
                end
            else 
                begin
                    $display ("Simulation of flush failed");
                end
        end
        /************* branch taken ***************/
        #STEP
        begin
            flush <= `DISABLE;
            br_taken <= `ENABLE;
        end
        #STEP
        begin
            if (if_pc === `WORD_DATA_W'h100 & if_insn === `WORD_DATA_W'd128 & if_en === `ENABLE) 
                begin
                    $display ("Simulation of branch succeeded");        
                end
            else 
                begin
                    $display ("Simulation of branch failed");
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
            $dumpfile("if_stage.vcd");
            $dumpvars(0,if_stage);
        end
endmodule