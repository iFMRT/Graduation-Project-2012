`include "stddef.h"
`include "cpu.h"

module bus_if (
    /********** 流水线控制信号 **********/
    input  wire       stall,       // 延迟
    input  wire       flush,       // 刷新信号
    /************* CPU Interface *************/
    input [29:0]      addr,        // Address
    input             as_,         // Address strobe
    input             rw,          // Read/Write
    input [31:0]      wr_data,     // Write data
    output reg [31:0] rd_data,     // Read data
    /************* SPM Interface *************/
    input [31:0]      spm_rd_data,
    output [29:0]     spm_addr,
    output reg        spm_as_,
    output            spm_rw,
    output [31:0]     spm_wr_data
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
            spm_as_  = `ENABLE_;
            if (rw == `READ) begin  // Read Access
                rd_data    = spm_rd_data;
            end
        end else begin
            /* Default Value */
            rd_data    = 32'h0;
            spm_as_    = `DISABLE_;
        end
    end
endmodule
