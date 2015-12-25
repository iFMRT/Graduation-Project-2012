/******** Head files ********/
`include "stddef.h"
`include "cpu.h"
`include "bus.h"

/********** Memory Access Control Module **********/
module mem_ctrl (
    /********** EX/MEM Pipeline Register **********/
    input wire [`MEM_OP_BUS]     ex_mem_op,      // Memory operation
    input wire [`WORD_DATA_BUS]  ex_mem_wr_data, // Memory write data
    input wire [`WORD_DATA_BUS]  ex_out,         // EX stage operating result
    /********** Memory Access Interface **********/
    input wire [`WORD_DATA_BUS]  rd_data,        // Read data
    output wire [`WORD_ADDR_BUS] addr,           // address
    output reg                   as_,            // Address strobe
    output reg                   rw,             // Read/Write
    output wire [`WORD_DATA_BUS] wr_data,        // Write data
    /********** Memory Access  **********/
    output reg [`WORD_DATA_BUS]  out ,           // Memory access result
    output reg                   miss_align      // miss align
);

    /********** Internal Signal **********/
    wire [`BYTE_OFFSET_BUS]      offset;         // Byte offset

    /********** Output Assignment **********/
    assign wr_data = ex_mem_wr_data;
    assign addr    = ex_out[`WORD_ADDR_LOC];
    assign offset  = ex_out[`BYTE_OFFSET_LOC];

    /********** Memory Access Control **********/
    always @(*) begin
        /* Default Value */
        miss_align = `DISABLE;
        out        = `WORD_DATA_W'h0;
        as_        = `DISABLE_;
        rw         = `READ;
        /* Memory Access */
        case (ex_mem_op)
            `MEM_OP_LDW : begin                        // Read a word
                /* Check offset */
                if (offset == `BYTE_OFFSET_WORD) begin // Align
                    out         = rd_data;
                    as_         = `ENABLE_;
                end else begin                        // Miss align
                    miss_align  = `ENABLE;
                end
            end
            `MEM_OP_STW : begin                        // Write a word
                /* Check offset */
                if (offset == `BYTE_OFFSET_WORD) begin // Align
                    rw          = `WRITE;
                    as_         = `ENABLE_;
                end else begin                         // Miss align
                    miss_align  = `ENABLE;
                end
            end
            default     : begin                        // No memory access
                out             = ex_out;
            end
        endcase
    end

endmodule
