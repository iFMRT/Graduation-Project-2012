/******** Head files ********/
`include "stddef.h"
`include "cpu.h"
`include "mem.h"
`include "bus.h"

/********** Memory Access Control Module **********/
module mem_ctrl (
    /********** EX/MEM Pipeline Register **********/
    input wire                   ex_en,          // If Pipeline data enable
    input wire [`MEM_OP_BUS]     ex_mem_op,      // Memory operation
    input wire [`WORD_DATA_BUS]  ex_mem_wr_data, // Memory write data
    input wire [`WORD_DATA_BUS]  ex_out,         // EX stage operating result
    /********** Memory Access Interface **********/
    input wire [`WORD_DATA_BUS]  rd_data,        // Read data
    output wire [`WORD_ADDR_BUS] addr,           // address
    output reg                   as_,            // Address strobe
    output reg                   rw,             // Read/Write
    output reg [`WORD_DATA_BUS]  wr_data,        // Write data
    /********** Memory Access  **********/
    output reg [`WORD_DATA_BUS]  out ,           // Memory access result
    output reg                   miss_align      // miss align
);

    /********** Internal Signal **********/
    wire [`BYTE_OFFSET_BUS]      offset;         // Byte offset

    /********** Output Assignment **********/
    assign addr    = ex_out[`WORD_ADDR_LOC];
    assign offset  = ex_out[`BYTE_OFFSET_LOC];

    /********** Memory Access Control **********/
    always @(*) begin
        /* Default Value */
        miss_align = `DISABLE;
        wr_data    = ex_mem_wr_data;
        out        = `WORD_DATA_W'h0;
        as_        = `DISABLE_;
        rw         = `READ;
        /* Memory Access */
        if (ex_en == `ENABLE) begin
            case (ex_mem_op)
                `MEM_OP_LW : begin                              // Read a word
                    /* Check offset */
                    if (offset == `BYTE_OFFSET_WORD) begin      // Align
                        out         = rd_data;
                        as_         = `ENABLE_;
                    end else begin                              // Miss align
                        miss_align  = `ENABLE;
                    end
                end
                `MEM_OP_LH : begin                              // Read a half word
                    /* Check offset */
                    if (offset[0] == `BYTE_OFFSET_HALF_WORD) begin // Align
                        out         = { {16{rd_data[15]}}, rd_data[15:0]};
                        as_         = `ENABLE_;
                    end else begin                              // Miss align
                        miss_align  = `ENABLE;
                    end
                end
                `MEM_OP_LB : begin                              // Read a byte
                    out         = { {24{rd_data[7]}}, rd_data[7:0]};
                    as_         = `ENABLE_;
                end
                `MEM_OP_LBU : begin                             // Read a unsigned byte
                    out         = { {24{1'b0}}, rd_data[7:0]};
                    as_         = `ENABLE_;
                end
                `MEM_OP_LHU : begin                             // Read a half unsigned word
                    /* Check offset */
                    if (offset == `BYTE_OFFSET_HALF_WORD) begin // Align
                        out         = { {16{1'b0}}, rd_data[15:0]};
                        as_         = `ENABLE_;
                    end else begin                              // Miss align
                        miss_align  = `ENABLE;
                    end
                end
                `MEM_OP_SW : begin                              // Write a word
                    /* Check offset */
                    if (offset == `BYTE_OFFSET_WORD) begin      // Align
                        rw          = `WRITE;
                        as_         = `ENABLE_;
                    end else begin                              // Miss align
                        miss_align  = `ENABLE;
                    end
                end
                `MEM_OP_SH : begin                              // Write a half word
                    /* Check offset */
                    if (offset == `BYTE_OFFSET_HALF_WORD) begin // Align
                        wr_data     = { rd_data[31:16], ex_mem_wr_data[15:0]};
                        rw          = `WRITE;
                        as_         = `ENABLE_;
                    end else begin                              // Miss align
                        miss_align  = `ENABLE;
                    end
                end
                `MEM_OP_SB : begin                              // Write a byte
                    wr_data     = { rd_data[31:8], ex_mem_wr_data[7:0]};
                    rw          = `WRITE;
                    as_         = `ENABLE_;
                end
                default     : begin                             // No memory access
                    out             = ex_out;
                end
            endcase
        end
    end

endmodule
