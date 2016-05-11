/******** Time scale ********/
`timescale 1ns/1ps

`include "stddef.h"
`include "cpu.h"

module mem_ctrl_test;
    /********** EX/MEM Pipeline Register **********/
    reg                   ex_en;          // If Pipeline data enable
    reg [`MEM_OP_BUS]     ex_mem_op;      // Memory operation
    reg [`WORD_DATA_BUS]  ex_mem_wr_data; // Memory write data
    reg [`WORD_DATA_BUS]  ex_out;         // EX stage operating result
    /********** Memory Access Interface **********/
    reg [`WORD_DATA_BUS]  rd_data;        // Read data
    wire [`WORD_ADDR_BUS] addr;           // address
    wire                  as_;            // Address strobe
    wire                  rw;             // Read/Write
    wire [`WORD_DATA_BUS] wr_data;        // Write data
    /********** Memory Access  **********/
    wire [`WORD_DATA_BUS] out;            // Memory access result
    wire                  miss_align;     // miss align


    /******** Define Simulation Loop********/
    parameter             STEP = 10;


    /******** Instantiate Test Module ********/
    /********** Memory Access Control Module **********/
    mem_ctrl mem_ctrl (
        /********** EX/MEM Pipeline Register **********/
        .ex_en            (ex_en),           // If Pipeline data enable
        .ex_mem_op        (ex_mem_op),       // Memory operation
        .ex_mem_wr_data   (ex_mem_wr_data),  // Memory write data
        .ex_out           (ex_out),          // EX stage operating result
        /********** Memory Access Interface **********/
        .rd_data          (rd_data),
        .addr             (addr),
        .as_              (as_),
        .rw               (rw),
        .wr_data          (wr_data),
        /********** Memory Access  **********/
        .out              (out),
        .miss_align       (miss_align)
    );

    /******** Test Case ********/
    initial begin
        # 0 begin
            /******** Read a Word(align) Input Test ********/
            ex_en          <= `ENABLE;
            ex_mem_op      <= `MEM_OP_LDW;
            ex_mem_wr_data <= `WORD_DATA_W'h999;        // don't care, e.g: 0x999
            ex_out         <= `WORD_DATA_W'h154;
            rd_data        <= `WORD_DATA_W'h24;
        end
        # STEP begin
            /******** Read a Word(align)Output Test ********/
            if ( (addr     == `WORD_ADDR_W'h55) &&
                 (as_      == `ENABLE_)         &&
                 (rw       == `READ)            &&
                 (wr_data  == `WORD_DATA_W'h999)&&
                 (out == 32'h24)                &&
                 (miss_align  == `DISABLE)
               ) begin

                $display("MEM CTRL Module Read a Word(align) Test Succeeded! ");
            end else begin

                $display("MEM CTRL Module Read a Word(align) Test Failed! ");
            end
            /******** Read a Word(miss align) Input Test ********/
            ex_mem_op      <= `MEM_OP_LDW;
            ex_mem_wr_data <= `WORD_ADDR_W'h999;        // don't care, e.g: 0x999
            ex_out         <= `WORD_DATA_W'h59;
            rd_data        <= `WORD_DATA_W'h24;
        end
        # STEP begin
            /******** Read a Word(miss align)Output Test ********/
            if ( (addr  == `WORD_ADDR_W'h16)       &&
                 (as_         == `DISABLE_)        &&
                 (rw          == `READ)            &&
                 (wr_data     == `WORD_DATA_W'h999)&&
                 (out         == `WORD_DATA_W'h0)  &&
                 (miss_align  == `ENABLE)
               ) begin

                $display("MEM CTRL Module Read a Word(miss align) Test Succeeded! ");
            end else begin

                $display("MEM CTRL Module Read a Word(miss align) Test Failed! ");
            end
        end
        # STEP begin
            /******** Read a Word(miss align) Output Test ********/
            if ( (addr        == `WORD_ADDR_W'h16) &&
                 (as_         == `DISABLE_)        &&
                 (rw          == `READ)            &&
                 (wr_data     == `WORD_DATA_W'h999)&&
                 (out         == `WORD_DATA_W'h0)  &&
                 (miss_align  == `ENABLE)
               ) begin

                $display("MEM CTRL Module Read a Word(miss align) Test Succeeded! ");
            end else begin

                $display("MEM CTRL Module Read a Word(miss align) Test Failed! ");
            end
            /******** Write a Word(align) Input Test ********/
            // Case: write the value 0x13 to address 0x154 which hold value 0x24
            ex_mem_op      <= `MEM_OP_STW;
            ex_mem_wr_data <= `WORD_DATA_W'h13;
            ex_out         <= `WORD_DATA_W'h154;
            rd_data        <= `WORD_DATA_W'h24;
        end
        # STEP begin
            /******** Write a Word(align)Output Test ********/
            if ( (addr        == `WORD_ADDR_W'h55)  &&
                 (as_         == `ENABLE_)          &&
                 (rw          == `WRITE)            &&
                 (wr_data     == `WORD_DATA_W'h13)  &&
                 (out         == `WORD_DATA_W'h0)   &&
                 (miss_align  == `DISABLE)
               ) begin

                $display("MEM CTRL Module Write a Word(align) Test Succeeded! ");
            end else begin

                $display("MEM CTRL Module Write a Word(align) Test Failed! ");
            end
            /******** Write a Word(miss align) Input Test ********/
            // Case: write the value 0x13 to address 0x59 which hold value 0x24
            ex_mem_op      <= `MEM_OP_STW;
            ex_mem_wr_data <= `WORD_DATA_W'h13;
            ex_out         <= `WORD_DATA_W'h59;
            rd_data        <= `WORD_DATA_W'h24;
        end
        # STEP begin
            /******** Write a Word(miss align)Output Test ********/
            if ( (addr        == `WORD_ADDR_W'h16)            &&
                 (as_         == `DISABLE_)         &&
                 (rw          == `READ)             &&
                 (wr_data     == `WORD_DATA_W'h13)  &&
                 (out         == `WORD_DATA_W'h0)   &&
                 (miss_align  == `ENABLE)
                 ) begin
                $display("MEM CTRL Module Write a Word(miss align) Test Succeeded! ");
            end else begin
                $display("MEM CTRL Module Write a Word(miss align) Test Failed! ");
            end
            /******** No Memory Access Input Test ********/
            // Case: EX Stage out is 0x59, and the address 0x59 hold value 0x24
            ex_mem_op      <= `MEM_OP_NOP;
            ex_mem_wr_data <= `WORD_DATA_W'h999;
            ex_out         <= `WORD_DATA_W'h59;
            rd_data        <= `WORD_DATA_W'h24;
        end
        # STEP begin
            /******** No Memory Access Output Test ********/
            if ( (addr        == `WORD_ADDR_W'h16)  &&
                 (as_         == `DISABLE_)         &&
                 (rw          == `READ)             &&
                 (wr_data     == `WORD_DATA_W'h999) &&
                 (out         == `WORD_DATA_W'h59)  &&
                 (miss_align  == `DISABLE)
               ) begin

                $display("MEM CTRL Module No Memory Access Test Succeeded! ");
            end else begin

                $display("MEM CTRL Module No Memory Access Test Failed! ");
            end
            /******** EX Pipeline Data Disable Input Test ********/
            ex_en          <= `DISABLE;
        end
        # STEP begin
            /******** EX Pipeline Data Disable Output Test ********/
            if ( (addr        == `WORD_ADDR_W'h16)  &&
                 (as_         == `DISABLE_)         &&
                 (rw          == `READ)             &&
                 (wr_data     == `WORD_DATA_W'h999) &&
                 (out         == `WORD_DATA_W'h0)   &&
                 (miss_align  == `DISABLE)
               ) begin

                $display("MEM CTRL Module EX Pipeline Data Disable Test Succeeded! ");
            end else begin

                $display("MEM CTRL Module EX Pipeline Data Disable Test Failed! ");
            end

            $finish;
        end
    end // initial begin

    /******** Output Waveform ********/
    initial begin
       $dumpfile("mem_ctrl.vcd");
       $dumpvars(0,mem_ctrl);
    end
endmodule // mem_stage_test
