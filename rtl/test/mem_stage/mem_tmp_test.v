`timescale 1ns/1ps

`include "stddef.h"
`include "cpu.h"
`include "mem.h"

module mem_tmp_test;
    /******** Clock & Reset ********/
    reg                   clk;
    reg                   reset;
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

    wire [`WORD_DATA_BUS] rd_data;
    wire [`WORD_ADDR_BUS] addr;
    wire                  as_;
    wire                  rw;
    wire [`WORD_DATA_BUS] wr_data;
    wire [`WORD_DATA_BUS] out;
    wire                  miss_align;

    /******** Define Simulation Loop********/
    parameter             STEP = 10;

    assign tmp_as_ = `ENABLE_;

    /******** Define Simulation Loop********/
    always #(STEP / 2) begin
        clk <= ~clk;
    end

    /******** Instantiate Test Module ********/
    /********** Memory Access Control Module **********/
    mem_ctrl mem_ctrl (
        /********** EX/MEM Pipeline Register **********/
        .ex_mem_op        (ex_mem_op),       // Memory operation
        .ex_mem_wr_data   (ex_mem_wr_data),  // Memory write data
        .ex_out           (ex_out),          // EX Stage operating reslut
        /********** Memory Access Interface **********/
        .rd_data          (rd_data),         // Read data
        .addr             (addr),            // Address
        .as_              (as_),             // Address Strobe
        .rw               (rw),              // Read/Write
        .wr_data          (wr_data),         // Write data
        /********** Memory Access Result **********/
        .out              (out),             // Memory Access Result
        .miss_align       (miss_align)
    );

    /********** Bus Interface **********/
    bus_if bus_if (
        /********** CPU  Interface **********/
        .addr             (addr),            // CPU: Address
        .as_              (as_),             // CPU: Address Strobe
        .rw               (rw),              // CPU: Read/Write
        .wr_data          (wr_data),         // CPU: Write data
        .rd_data          (rd_data),         // CPU: Read data
        /********** SPM Interface **********/
        .spm_rd_data      (spm_rd_data),     // SPM: Read data
        .spm_addr         (spm_addr),        // SPM: Address
        .spm_as_          (spm_as_),         // SPM: Address Strobe
        .spm_rw           (spm_rw),          // SPM: Read/Write
        .spm_wr_data      (spm_wr_data)      // SPM: Write data
    );

    /******** Test Case ********/
    initial begin
        # 0 begin
            // Case: read the value 0x24 from address 0x154
            /******** Read Data(align) Test Input ********/
            ex_mem_op      <= `MEM_OP_LDW;
            ex_mem_wr_data <= `WORD_DATA_W'h999;        // don't care, e.g: 0x999
            ex_out         <= `WORD_DATA_W'h154;
            spm_rd_data    <= `WORD_DATA_W'h24;
        end
        # STEP begin
            /******** Read Data(align) Test Output ********/
            if ( (out == 32'h24)                     &&
                 (miss_align   == `DISABLE)          &&
                 (spm_addr     == `WORD_ADDR_W'h55)  &&
                 (spm_as_      == `ENABLE_)          &&
                 (spm_rw       == `READ)             &&
                 (as_          == `ENABLE_)          &&
                 (spm_wr_data  == `WORD_DATA_W'h999)    // don't care, e.g: 0x999

               ) begin
                $display("MEM Stage Read Data(align) Test Succeeded !");
            end else begin
                $display("MEM Stage Read Data(align) Test Failed !");
            end
        end
        # STEP begin
            $finish;
        end
    end // initial begin

    /******** Output Waveform ********/
    initial begin
       $dumpfile("mem_tmp.vcd");
       $dumpvars(0,mem_ctrl, bus_if);
    end

endmodule // mem_stage_test
