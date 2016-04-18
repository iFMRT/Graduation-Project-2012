/******** Time scale ********/
`timescale 1ns/1ps
////////////////////////////////////////////////////////////////////////
// Engineer:       Leway Colin - colin4124@gmail.com                  //
//                                                                    //
// Additional contributions by:                                       //
//                 Beyond Sky - fan-dave@163.com                      //
//                 Kippy Chen - 799182081@qq.com                      //
//                 Junhao Chang                                       //
//                                                                    //
// Design Name:    Bus Interface                                      //
// Project Name:   FMRT Mini Core                                     //
// Language:       Verilog                                            //
//                                                                    //
// Description:    Bus interface used to control bus access; used for //
//                 IF Stage and MEM Stage                             //
//                                                                    //
////////////////////////////////////////////////////////////////////////

`include "common_defines.v"

module bus_if_test; 
    /********** Pipeline Control Signal **********/
    reg                        stall;     // Stall
    reg                        flush;     // Flush signal
    /************* CPU Interface *************/
    reg  [`WORD_ADDR_BUS]      addr;      // Address
    reg                        as_;       // Address strobe
    reg                        rw;        // Read/Write
    reg  [`WORD_DATA_BUS]      wr_data;   // Write data
    wire[`WORD_DATA_BUS] rd_data;   // Read data
    /************* SPM Interface *************/
    reg  [`WORD_DATA_BUS]      spm_rd_data;
    wire [`WORD_ADDR_BUS]     spm_addr;
    wire                 spm_as_;
    wire                      spm_rw;
    wire [`WORD_DATA_BUS]     spm_wr_data
;


    /******** Define Simulation Loop********/
    parameter             STEP = 10;

    bus_if bus_if (
        .stall(stall),
        .flush(flush),
        .addr(addr),
        .as_(as_),
        .rw(rw),
        .wr_data(wr_data),
        .rd_data(rd_data),
        .spm_rd_data(spm_rd_data),
        .spm_addr(spm_addr),
        .spm_as_(spm_as_),
        .spm_rw(spm_rw),
        .spm_wr_data(spm_wr_data)
    );

    task bus_if_tb;
        input [`WORD_DATA_BUS] _rd_data;
        input [`WORD_ADDR_BUS] _spm_addr;
        input  _spm_as_;
        input  _spm_rw;
        input [`WORD_DATA_BUS] _spm_wr_data;

        begin
            if((rd_data  === _rd_data)  &&
               (spm_addr  === _spm_addr)  &&
               (spm_as_  === _spm_as_)  &&
               (spm_rw  === _spm_rw)  &&
               (spm_wr_data  === _spm_wr_data)
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
            stall <= `DISABLE;
            as_ <= `ENABLE_;
            flush <= `DISABLE;
            rw <= `READ;
            spm_rd_data <= `WORD_DATA_W'h24;
            addr <= `WORD_ADDR_W'h55;
            wr_data <= `WORD_DATA_W'h999;
            end
        # (STEP * 3/4)
        # STEP begin
            $display("\n== Read Data Test ==");
           bus_if_tb(
           	`WORD_DATA_W'h24, // rd_data
           	`WORD_ADDR_W'h55, // spm_addr
           	`ENABLE_, // spm_as_
           	`READ, // spm_rw
           	`WORD_DATA_W'h999 // spm_wr_data
           );
           
            as_ <= `DISABLE_;
           end
        
        # STEP begin
            $display("\n== No Memory Access Test ==");
           bus_if_tb(
           	`WORD_DATA_W'h0, // rd_data
           	`WORD_ADDR_W'h55, // spm_addr
           	`DISABLE_, // spm_as_
           	`READ, // spm_rw
           	`WORD_DATA_W'h999 // spm_wr_data
           );
           
            as_ <= `ENABLE_;
           wr_data <= `WORD_DATA_W'h59;
           rw <= `WRITE;
           end
        
        # STEP begin
            $display("\n== Write Data Test ==");
           bus_if_tb(
           	`WORD_DATA_W'h24, // rd_data
           	`WORD_ADDR_W'h55, // spm_addr
           	`ENABLE_, // spm_as_
           	`WRITE, // spm_rw
           	`WORD_DATA_W'h59 // spm_wr_data
           );
           
            stall <= `ENABLE;
           as_ <= `DISABLE_;
           wr_data <= `WORD_DATA_W'h999;
           rw <= `READ;
           flush <= `ENABLE;
           end
        # STEP begin
            $display("\n== Pipeline flush or stall Test ==");
            bus_if_tb(
            	`WORD_DATA_W'h0, // rd_data
            	`WORD_ADDR_W'h55, // spm_addr
            	`DISABLE_, // spm_as_
            	`READ, // spm_rw
            	`WORD_DATA_W'h999 // spm_wr_data
            );
            $finish;
        end
    end
	/******** Output Waveform ********/
    initial begin
       $dumpfile("bus_if.vcd");
       $dumpvars(0, bus_if);
    end

endmodule
