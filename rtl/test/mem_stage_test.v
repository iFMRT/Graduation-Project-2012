`timescale 1ns/1ps

`include "stddef.h"
`include "cpu.h"

module mem_stage_test;
    /******** Clock & Reset ********/
    reg clk;                              // Clock
    reg reset;                            // Asynchronous reset
    /******** SPM Interface ********/
    reg [`WORD_DATA_BUS] spm_rd_data;     // SPM: Read data
    wire [`WORD_ADDR_BUS] spm_addr;       // SPM: Address
    wire                  spm_as_;        // SPM: Address Strobe
    wire                  spm_rw;         // SPM: Read/Write
    wire [`WORD_DATA_BUS] spm_wr_data;    // SPM: Write data
    /********** EX/MEM Pipeline Register **********/
    reg [`MEM_OP_BUS]     ex_mem_op;      // Memory operation
    reg [`WORD_DATA_BUS]  ex_mem_wr_data; // Memory write data
    reg [`REG_ADDR_BUS]   ex_dst_addr;    // General purpose register write address
    reg                   ex_gpr_we_;     // General purpose register enable
    reg [`WORD_DATA_BUS]  ex_out;         // EX stage operating result
    /********** MEM/WB Pipeline Register **********/
    wire [`REG_ADDR_BUS]  mem_dst_addr;
    wire                  mem_gpr_we_;
    wire [`WORD_DATA_BUS] mem_out;        // MEM stage operating result

    /******** Define Simulation Loop********/
    parameter             STEP = 10;

    /******** Generate Clock ********/
    always #(STEP / 2) begin
        clk <= ~clk;
    end

    /******** Instantiate Test Module ********/
    mem_stage mem_stage(
        // Clock & Reset
        .clk(clk),                      // Clock
        .reset(reset),                  // Reset
        // SPM Interface
        .spm_rd_data(spm_rd_data),
        .spm_addr(spm_addr),
        .spm_as_(spm_as_),
        .spm_rw(spm_rw),
        .spm_wr_data(spm_wr_data),
        /********* EX/MEM Pipeline Register *********/
        .ex_mem_op(ex_mem_op),
        .ex_mem_wr_data(ex_mem_wr_data),
        .ex_dst_addr(ex_dst_addr),
        .ex_gpr_we_(ex_gpr_we_),
        .ex_out(ex_out),
        /********** MEM/WB Pipeline Register **********/
        .mem_dst_addr(mem_dst_addr),
        .mem_gpr_we_(mem_gpr_we_),
        .mem_out(mem_out)
    );

    /******** Test Case ********/
    initial begin
        # 0 begin
            // Case: read the value 0x24 from address 0x154
            /******** Initialize Test Input********/
            clk            <= 1'h1;
            reset          <= `ENABLE;
            spm_rd_data    <= `WORD_DATA_W'h24;
            ex_mem_op      <= `MEM_OP_LDW;       // when `MEM_OP_LDW, vvp will be infinite loop!
            ex_mem_wr_data <= `WORD_DATA_W'h999; // don't care, e.g: 0x999
            ex_dst_addr    <= `REG_ADDR_W'h7;    // don't care, e.g: 0x7
            ex_gpr_we_     <= `DISABLE_;
            ex_out         <= `WORD_DATA_W'h154;
        end
        # (STEP * 3/4)
        # STEP begin
            /******** Initialize Test Output ********/
            if ( (spm_addr     == `WORD_ADDR_W'h55)     &&
                 (spm_as_      == `ENABLE_)             &&
                 (spm_rw       == `READ)                &&
                 (spm_wr_data  == `WORD_DATA_W'h999)    &&
                 (mem_dst_addr == `REG_ADDR_W'h0)       &&
                 (mem_gpr_we_  == `DISABLE_)            &&
                 (mem_out      == `WORD_DATA_W'h0)
               ) begin
                $display("MEM Stage Initialize Test Succeeded !");
            end else begin
                $display("MEM Stage Initialize Test Failed !");
            end
            // Case: read the value 0x24 from address 0x154
            /******** Read Data(align) Test Input ********/
            reset          <= `DISABLE;
        end
        # STEP begin
            /******** Read Data(align) Test Output ********/
            if ( (spm_addr     == `WORD_ADDR_W'h55)     &&
                 (spm_as_      == `ENABLE_)             &&
                 (spm_rw       == `READ)                &&
                 (spm_wr_data  == `WORD_DATA_W'h999)    &&
                 (mem_dst_addr == `REG_ADDR_W'h7)       &&
                 (mem_gpr_we_  == `DISABLE_)            &&
                 (mem_out      == `WORD_DATA_W'h24)
               ) begin
                $display("MEM Stage Read Data(align) Test Succeeded !");
            end else begin
                $display("MEM Stage Read Data(align) Test Failed !");
            end
            // Case: read the value 0x24 from address 0x59
            /******** Read Data(miss align) Test Input ********/
            ex_out         <= `WORD_DATA_W'h59;
        end
        # STEP begin
            /******** Read Data(miss align) Test Output ********/
            if ( (spm_addr     == `WORD_ADDR_W'h16)     &&
                 (spm_as_      == `DISABLE_)            &&
                 (spm_rw       == `READ)                &&
                 (spm_wr_data  == `WORD_DATA_W'h999)    &&
                 (mem_dst_addr == `REG_ADDR_W'h0)       &&
                 (mem_gpr_we_  == `DISABLE_)            &&
                 (mem_out      == `WORD_DATA_W'h0)
               ) begin
                $display("MEM Stage Read Data(miss align) Test Succeeded !");
            end else begin
                $display("MEM Stage Read Data(miss align) Test Failed !");
            end   ex_out       <= `WORD_DATA_W'h59;
            // Case: write the value 0x13 to address 0x154 which hold value 0x24
            /******** Write Data(align) Test Input ********/
            ex_mem_op      <= `MEM_OP_STW;       // when `MEM_OP_LDW, vvp can't finish! 
            ex_out         <= `WORD_DATA_W'h154;
            ex_mem_wr_data <= `WORD_DATA_W'h13;
        end
        # STEP begin
            /******** Write Data(align) Test Output ********/
            if ( (spm_addr     == `WORD_ADDR_W'h55)     &&
                 (spm_as_      == `ENABLE_)             &&
                 (spm_rw       == `WRITE)               &&
                 (spm_wr_data  == `WORD_DATA_W'h13)     &&
                 (mem_dst_addr == `REG_ADDR_W'h7)       &&
                 (mem_gpr_we_  == `DISABLE_)            &&
                 (mem_out      == `WORD_DATA_W'h0)
               ) begin
                $display("MEM Stage Write Data(align) Test Succeeded !");
            end else begin
                $display("MEM Stage Write Data(align) Test Failed !");
            end
            // Case: write the value 0x13 to address 0x59 which hold value 0x24
            /******** Write Data(miss align) Test Input ********/
            ex_out         <= `WORD_DATA_W'h59;
        end
        # STEP begin
            /******** Write Data(miss align) Test Output ********/
            if ( (spm_addr     == `WORD_ADDR_W'h16)     &&
                 (spm_as_      == `DISABLE_)            &&
                 (spm_rw       == `READ)                &&
                 (spm_wr_data  == `WORD_DATA_W'h13)     &&
                 (mem_dst_addr == `REG_ADDR_W'h0)       &&
                 (mem_gpr_we_  == `DISABLE_)            &&
                 (mem_out      == `WORD_DATA_W'h0)
               ) begin
                $display("MEM Stage Write Data(miss align) Test Succeeded !");
            end else begin
                $display("MEM Stage Write Data(miss align) Test Failed !");
            end
            // Case: EX Stage out is 0x59, and the address 0x59 hold value 0x24
            /******** No Access Test Input ********/
            ex_mem_op      <= `MEM_OP_NOP;       // when `MEM_OP_LDW, vvp can't finish! 
            ex_mem_wr_data <= `WORD_DATA_W'h999; // don't care, e.g: 0x999
            ex_gpr_we_     <= `ENABLE_;
        end
        # STEP begin
            /******** No Access Test Output ********/
            if ((spm_addr     == `WORD_ADDR_W'h16)      &&
                (spm_as_      == `DISABLE_)             &&
                (spm_rw       == `READ)                 &&
                (spm_wr_data  == `WORD_DATA_W'h999)     &&
                (mem_dst_addr == `REG_ADDR_W'h7)        &&
                (mem_gpr_we_  == `ENABLE_)              &&
                (mem_out  == `WORD_DATA_W'h59)
                ) begin
                $display("MEM Stage No Access Test Succeeded !");
            end else begin
                $display("MEM Stage No Access Test Failed !");
            end
            $finish;
        end
    end // initial begin

    /******** Output Waveform ********/
    initial begin
       $dumpfile("mem_stage.vcd");
       $dumpvars(0,mem_stage);
    end
endmodule // mem_stage_test
