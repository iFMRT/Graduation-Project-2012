/******** Time scale ********/
`timescale 1ns/1ps

`include "stddef.h"
`include "cpu.h"

module bus_if_test;
    /************* Pipeline Control Signals *************/
    reg             stall;
    reg             flush;
    /************* CPU Interface *************/
    reg [29:0]      addr;        // Address
    reg             as_;         // Address strobe
    reg             rw;          // Read/Write
    reg [31:0]      wr_data;     // Write data
    wire [31:0]     rd_data;     // Read data
    /************* SPM Interface *************/
    reg [31:0]      spm_rd_data; // Read data
    wire [29:0]     spm_addr;    // Address
    wire            spm_as_;     // Address strobe
    wire            spm_rw;      // Read/Write
    wire [31:0]     spm_wr_data; // Read data

    /******** Define Simulation Loop ********/
    parameter             STEP = 10;

    /******** Instantiate Test Module  ********/
    bus_if bus_if (
        /************* Pipeline Control Signals *************/
        .stall(stall),
        .flush(flush),
        /************* CPU Interface *************/
        .addr(addr),               // Address
        .as_(as_),                 // Address strobe
        .rw(rw),                   // Read/Write
        .wr_data(wr_data),         // Write data
        .rd_data(rd_data),         // Read data
        /************* SPM Interface *************/
        .spm_rd_data(spm_rd_data), // Read data
        .spm_addr(spm_addr),       // Address
        .spm_as_(spm_as_),         // Address strobe
        .spm_rw(spm_rw),           // Read/Write
        .spm_wr_data(spm_wr_data)  // Read data
    );

    //******** Test Case ********/
    initial begin
        # 0 begin
            /******** Read Data Input Test ********/
            stall       <= `DISABLE;
            flush       <= `DISABLE;
            addr        <= `WORD_ADDR_W'h55;
            as_         <= `ENABLE_;
            rw          <= `READ;
            wr_data     <= `WORD_DATA_W'h999;        // don't care, e.g: 0x999
            spm_rd_data <= `WORD_DATA_W'h24;
        end
        # STEP begin
            /******** Read Data Output Test ********/
            if ( (rd_data      == `WORD_DATA_W'h24)  &&
                 (spm_addr     == `WORD_ADDR_W'h55)  &&
                 (spm_as_      == `ENABLE_)          &&
                 (spm_rw       == `READ)             &&
                 (spm_wr_data  == `WORD_DATA_W'h999)        // don't care, e.g: 0x999
               ) begin
                $display("Bus If module read data Test Succeeded !");
            end else begin
                $display("Bus If module read data Test Failed !");
            end
            /******** No Memory Access Input Test ********/
            addr        <= `WORD_ADDR_W'h55;
            as_         <= `DISABLE_;
            rw          <= `READ;
            wr_data     <= `WORD_DATA_W'h999;        // don't care, e.g: 0x999
            spm_rd_data <= `WORD_DATA_W'h24;
        end
        # STEP begin
            /******** No Memory Access Output Test ********/
            if ( (rd_data      == `WORD_DATA_W'h0)   &&
                 (spm_addr     == `WORD_ADDR_W'h55)  &&
                 (spm_as_      == `DISABLE_)         &&
                 (spm_rw       == `READ)             &&
                 (spm_wr_data  == `WORD_DATA_W'h999)        // don't care, e.g: 0x999
               ) begin
                $display("Bus If module no access Test Succeeded !");
            end else begin
                $display("Bus If module no access Test Failed !");
            end
            /******** Write Data Input Test ********/
            addr        <= `WORD_ADDR_W'h55;
            as_         <= `ENABLE_;
            rw          <= `WRITE;
            wr_data     <= `WORD_DATA_W'h59;
            spm_rd_data <= `WORD_DATA_W'h24;
        end
        # STEP begin
            /******** Write Data Output Test ********/
            if ( (rd_data      == `WORD_DATA_W'h0)   &&
                 (spm_addr     == `WORD_ADDR_W'h55)  &&
                 (spm_as_      == `ENABLE_)          &&
                 (spm_rw       == `WRITE)            &&
                 (spm_wr_data  == `WORD_DATA_W'h59)
                 ) begin
                $display("Bus If module write data Test Succeeded !");
            end else begin
                $display("Bus If module write data Test Failed !");
            end
            /******** Pipeline flush or stall Input Test ********/
            stall       <= `ENABLE;
            flush       <= `ENABLE;
            as_         <= `DISABLE_;
            rw          <= `READ;
            wr_data     <= `WORD_DATA_W'h999;        // don't care, e.g: 0x999
        end
        # STEP begin
            /******** Write Data Output Test ********/
            if ( (rd_data      == `WORD_DATA_W'h0)   &&
                 (spm_addr     == `WORD_ADDR_W'h55)  &&
                 (spm_as_      == `DISABLE_)          &&
                 (spm_rw       == `READ)            &&
                 (spm_wr_data  == `WORD_DATA_W'h999)
                 ) begin
                $display("Bus If module Pipeline flush or stall Test Succeeded !");
            end else begin
                $display("Bus If module Pipeline flush or stall Test Failed !");
            end
            $finish;
        end
    end // initial begin

    /******** Output Waveform ********/
    initial begin
       $dumpfile("bus_if.vcd");
       $dumpvars(0,bus_if);
    end
endmodule // mem_stage_test
