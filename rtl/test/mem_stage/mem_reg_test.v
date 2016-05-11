/******** Time scale ********/
`timescale 1ns/1ps

`include "stddef.h"
`include "cpu.h"

module mem_reg_test;
    /********** Clock & Reset **********/
    reg                  clk;          // Clock 
    reg                  reset;        // Asynchronous Reset
    /********** Memory Access Result **********/
    reg [`WORD_DATA_BUS] out;          // Memory Access Result
    reg                  miss_align;   // Miss align 
    /********** Pipeline Control Signal **********/
    reg                  stall;          // Stall
    reg                  flush;          // Flush
    /********** EX/MEM Pipeline Register **********/
    reg                  ex_en;          // If Pipeline data enable
    reg [`REG_ADDR_BUS]  ex_dst_addr;  // General purpose register write address
    reg                  ex_gpr_we_;   // General purpose register write enable
    /********** MEM/WB Pipeline Register **********/
    wire                  mem_en;      // If Pipeline data enables
    wire [`REG_ADDR_BUS]  mem_dst_addr;// General purpose register write address
    wire                  mem_gpr_we_; // General purpose register write enable
    wire [`WORD_DATA_BUS] mem_out;     // MEM stage operating result

    /******** Define Simulation Loop********/
    parameter             STEP = 10;

    /******** Generate Clock ********/
    always #(STEP / 2) begin
        clk <= ~clk;
    end

    /******** Instantiate Test Module ********/
    /********** MEM Stage Pipeline Register Module **********/
    mem_reg mem_reg (
        .clk(clk),                   // Clock 
        .reset(reset),               // Asynchronous Reset
        /********** Memory Access Result **********/
        .out(out),                   // Memory Access Result
        .miss_align(miss_align),     // Miss align 
        /********** Pipeline Control Signal **********/
        .stall(stall),               // Stall
        .flush(flush),               // Flush
    /********** EX/MEM Pipeline Register **********/
        .ex_en(ex_en),               // If Pipeline data enable
        /********** EX/MEM Pipeline Register **********/
        .ex_dst_addr(ex_dst_addr),   // General purpose register write address
        .ex_gpr_we_(ex_gpr_we_),     // General purpose register write enable
        /********** MEM/WB Pipeline Register **********/
        .mem_en(mem_en),             // If Pipeline data enables
        .mem_dst_addr(mem_dst_addr), // General purpose register write address
        .mem_gpr_we_(mem_gpr_we_),   // General purpose register write enable
        .mem_out(mem_out)            // MEM stage operating result
    );

    /******** Test Case ********/
    initial begin
        # 0 begin
            /******** Initialize Input Test ********/
            clk            <= 1'h1;
            reset          <= `ENABLE;
            out            <= `WORD_DATA_W'h999; // don't care, e.g: 0x999
            miss_align     <= 1'h0;              // don't care, e.g: 0x1
            stall          <= `DISABLE;
            flush          <= `DISABLE;
            ex_en          <= `ENABLE;           // don't care, e.g: `ENABLE
            ex_dst_addr    <= `REG_ADDR_W'h7;    // don't care, e.g: 0x7
            ex_gpr_we_     <= `ENABLE_;          // don't care, e.g: 0x0
        end
        # (STEP * 3/4)
        # STEP begin
            /******** Initialize Output Test ********/
            if ( (mem_en           == `DISABLE)          &&
                 (mem_dst_addr     == `WORD_ADDR_W'h0)   &&
                 (mem_gpr_we_      == `DISABLE_)         &&
                 (mem_out          == `WORD_DATA_W'h0)   
               ) begin
                $display("MEM Stage Reg module Initialize Test Succeeded!");
            end else begin
                $display("MEM Stage Reg module Initialize Test Failed !");
            end

            reset <= `DISABLE;
        end
        # STEP begin
             /******** Updata Pipeline Output Test ********/
            if ( (mem_en           == ex_en)             &&
                 (mem_dst_addr     == `WORD_ADDR_W'h7)   &&
                 (mem_gpr_we_      == `ENABLE_)          &&
                 (mem_out          == `WORD_DATA_W'h999)  
               ) begin
                $display("MEM Stage Reg module Update Test Succeed !");
            end else begin
                $display("MEM Stage Reg module Update Test Failure !");
            end
            /******** Miss align Input Test ********/
            miss_align <= 1'h1;
        end
        # STEP begin
            /******** Miss align Output Test ********/
            if ( (mem_en           == ex_en)             &&
                 (mem_dst_addr     == `WORD_ADDR_W'h0)   &&
                 (mem_gpr_we_      == `DISABLE_)         &&
                 (mem_out          == `WORD_DATA_W'h0)  
               ) begin
                $display("MEM Stage Reg module Miss Align Test Succeed !");
            end else begin
                $display("MEM Stage Reg module Miss Align Test Failure !");
            end

            /******** Flush Input Test ********/
            miss_align <= `DISABLE;
            flush      <= `ENABLE;
        end
        # STEP begin
            /******** Flush Output Test ********/
            if ( (mem_en           == `DISABLE)          &&
                 (mem_dst_addr     == `WORD_ADDR_W'h0)   &&
                 (mem_gpr_we_      == `DISABLE_)         &&
                 (mem_out          == `WORD_DATA_W'h0)  
               ) begin
                $display("MEM Stage Reg module Flush Test Succeed !");
            end else begin
                $display("MEM Stage Reg module Flush Test Failure !");
            end

            /******** Stall Input Test ********/
            flush <= `DISABLE;
            stall <= `ENABLE;
        end
        # STEP begin
            /******** Stall Output Test ********/
            if ( (mem_en           == `DISABLE)          &&
                 (mem_dst_addr     == `WORD_ADDR_W'h0)   &&
                 (mem_gpr_we_      == `DISABLE_)         &&
                 (mem_out          == `WORD_DATA_W'h0)  
               ) begin
                $display("MEM Stage Reg module Stall Test Succeed !");
            end else begin
                $display("MEM Stage Reg module Stall Test Failure !");
            end

            $finish;
        end
    end // initial begin

    /******** Output Waveform ********/
    initial begin
       $dumpfile("mem_reg.vcd");
       $dumpvars(0,mem_reg);
    end
endmodule // mem_stage_test
