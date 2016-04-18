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
// Description:    Bus interface used to control bus access, used for //
//                 IF Stage and MEM Stage                             //
//                                                                    //
////////////////////////////////////////////////////////////////////////

`include "common_defines.v"

module bus_if (
    /********** Pipeline Control Signal **********/
    input                       stall,     // Stall
    input                       flush,     // Flush signal
    /************* CPU Interface *************/
    input [`WORD_ADDR_BUS]      addr,      // Address
    input                       as_,       // Address strobe
    input                       rw,        // Read/Write
    input [`WORD_DATA_BUS]      wr_data,   // Write data
    output reg [`WORD_DATA_BUS] rd_data,   // Read data
    /************* SPM Interface *************/
    input [`WORD_DATA_BUS]      spm_rd_data,
    output [`WORD_ADDR_BUS]     spm_addr,
    output reg                  spm_as_,
    output                      spm_rw,
    output [`WORD_DATA_BUS]     spm_wr_data
);

    /********** Output Assignment **********/
    assign spm_addr    = addr;
    assign spm_rw      = rw;
    assign spm_wr_data = wr_data;

    /********* Memory Access Control *********/
    always @(*) begin
        /* Memory Access */
        if ((flush == `DISABLE) &&
            (stall == `DISABLE) &&
            (as_ == `ENABLE_)
           ) begin
            spm_as_ = `ENABLE_;
            // write a half word or a byte need spm_rd_data
            rd_data    = spm_rd_data;
        end else begin
            /* Default Value */
            rd_data = 32'h0;
            spm_as_ = `DISABLE_;
        end
    end

endmodule
