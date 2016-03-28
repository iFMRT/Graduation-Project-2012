/******** Head files ********/
`include "stddef.h"
`include "cpu.h"
`include "mem.h"

/********** Memory Access Control Module **********/
module mem_ctrl (
    /********** EX/MEM Pipeline Register **********/
    input wire                   ex_en,          // If Pipeline data enable
    input wire  [`MEM_OP_BUS]    ex_mem_op,      // Memory operation
    input wire  [`WORD_DATA_BUS] ex_mem_wr_data, // Memory write data
    input wire  [`WORD_DATA_BUS] ex_out,         // EX stage operating result
    /********** Memory Access Interface **********/
    // input wire [`WORD_DATA_BUS]  rd_data,        // Read data
    input wire  [`WORD_DATA_BUS] read_data_m,        // Read data
    output wire [`WORD_DATA_BUS] addr,           // address
    // output reg                   as_,            // Address strobe
    output reg                   rw,             // Read/Write
    output reg  [`WORD_DATA_BUS] wr_data,        // Write data
    input wire                   hitway,         // path hit mark           
    input wire  [127:0]          data0_rd,       // read data of data cache'path0     
    input wire  [127:0]          data1_rd,       // read data of data cache'path1     
    /********** Memory Access  **********/
    output reg [`WORD_DATA_BUS]  out ,           // Memory access result
    output reg                   miss_align      // miss align
);

    /********** Internal Signal **********/
    wire [`BYTE_OFFSET_BUS]      offset;         // Byte offset

    /********** Output Assignment **********/
    assign addr    = ex_out;
    assign offset  = ex_out[`BYTE_OFFSET_LOC];

    /********** Memory Access Control **********/
    always @(*) begin
        /* Default Value */
        miss_align = `DISABLE;
        wr_data    = ex_mem_wr_data;
        out        = `WORD_DATA_W'h0;
        // as_        = `DISABLE_;
        rw         = `READ;
        /* Memory Access */
        if (ex_en == `ENABLE) begin
            case (ex_mem_op)
                `MEM_OP_LW : begin                              // Read a word
                    /* Check offset */
                    if (offset == `BYTE_OFFSET_WORD) begin      // Align
                        out         = read_data_m;
                        // as_         = `ENABLE_;
                    end else begin                              // Miss align
                        miss_align  = `ENABLE;
                    end
                end
                `MEM_OP_LH : begin                              // Read a half word
                    /* Check offset */
                    if (offset[0] == 1'b0) begin // Align
                        out         = { {16{read_data_m[15]}}, read_data_m[15:0]};
                        // as_         = `ENABLE_;
                    end else begin                              // Miss align
                        miss_align  = `ENABLE;
                    end
                end
                `MEM_OP_LB : begin                              // Read a byte
                    out         = { {24{read_data_m[7]}}, read_data_m[7:0]};
                    // as_         = `ENABLE_;
                end
                `MEM_OP_LBU : begin                             // Read a unsigned byte
                    out         = { {24{1'b0}}, read_data_m[7:0]};
                    // as_         = `ENABLE_;
                end
                `MEM_OP_LHU : begin                             // Read a half unsigned word
                    /* Check offset */
                    if (offset[0] == 1'b0) begin // Align
                        out         = { {16{1'b0}}, read_data_m[15:0]};
                        // as_         = `ENABLE_;
                    end else begin                              // Miss align
                        miss_align  = `ENABLE;
                    end
                end
                `MEM_OP_SW : begin                              // Write a word
                    /* Check offset */
                    if (offset == `BYTE_OFFSET_WORD) begin      // Align
                        rw          = `WRITE;
                        // as_         = `ENABLE_;
                    end else begin                              // Miss align
                        miss_align  = `ENABLE;
                    end
                end
                `MEM_OP_SH : begin                              // Write a half word
                    /* Check offset */
                    if (offset[0] == 1'b0) begin // Align
                        // wr_data     = { rd_data[31:16], ex_mem_wr_data[15:0]};
                        case (hitway)
                            `WAY0:begin
                                wr_data     = { data0_rd[31:16], ex_mem_wr_data[15:0]};  
                            end // hitway == 0
                            `WAY1:begin 
                                wr_data     = { data1_rd[31:16], ex_mem_wr_data[15:0]};  
                            end // hitway == 1
                        endcase
                        rw          = `WRITE;
                        // as_         = `ENABLE_;
                    end else begin                              // Miss align
                        miss_align  = `ENABLE;
                    end
                end
                `MEM_OP_SB : begin                              // Write a byte
                    // wr_data    = { rd_data[31:8], ex_mem_wr_data[7:0]};
                    case (hitway)
                        `WAY0:begin
                            wr_data     = { data0_rd[31:8], ex_mem_wr_data[7:0]};  
                        end // hitway == 0
                        `WAY1:begin 
                            wr_data     = { data1_rd[31:8], ex_mem_wr_data[7:0]};  
                        end // hitway == 1
                    endcase
                    rw         = `WRITE;
                    // as_        = `ENABLE_;
                end
                default     : begin                             // No memory accessS
                    out        = ex_out;
                end
            endcase
        end
    end

endmodule
