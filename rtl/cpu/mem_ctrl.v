`timescale 1ns/1ps

/******** Head files ********/
`include "common_defines.v"
`include "cpu.h"
`include "mem.h"
`include "l1_cache.h"

/********** Memory Access Control Module **********/
module mem_ctrl (
    /***** EX/MEM Pipeline Register *****/
    input  wire                   ex_en,          // If Pipeline data enable
    input  wire  [`MEM_OP_BUS]    ex_mem_op,      // Memory operation
    input  wire  [`WORD_DATA_BUS] ex_mem_wr_data, // Memory write data
    input  wire  [`OFFSET_BUS]    offset,         // EX stage operating result
    input  wire  [`WORD_DATA_BUS] ex_out,
    /***** Memory Access Interface ******/
    input  wire  [`WORD_DATA_BUS] read_data_m,    // Read data
    output reg                    rw,             // Read/Write
    output reg   [`WORD_DATA_BUS] wr_data,        // Write data
    input  wire  [`WORD_DATA_BUS] rd_to_write_m,         
    /********** Memory Access  **********/
    output reg   [`WORD_DATA_BUS] out,            // Memory access result
    output reg                    load_rdy,
    output reg                    miss_align      // miss align
);
    /****** Memory Access Control *******/
    always @(*) begin
        /* Default Value */
        miss_align = `DISABLE;
        wr_data    = ex_mem_wr_data;
        out        = `WORD_DATA_W'h0;
        rw         = `READ;
        load_rdy   = `DISABLE;
        /* Memory Access */
        if (ex_en == `ENABLE) begin
            case (ex_mem_op)
                `MEM_OP_LW : begin                              // Read a word
                    /* Check offset */
                    if (offset == `BYTE_OFFSET_WORD) begin      // Align
                        out         = read_data_m;
                        load_rdy     = `ENABLE;
                    end else begin                              // Miss align
                        miss_align  = `ENABLE;
                    end
                end
                `MEM_OP_LH : begin                              // Read a half word
                    /* Check offset */
                    if (offset[0] == 1'b0) begin // Align
                        load_rdy     = `ENABLE;
                        if (offset[1] == 1'b0) begin
                            out     = { {16{read_data_m[15]}}, read_data_m[15:0]};
                        end else begin
                            out     = { {16{read_data_m[31]}}, read_data_m[31:16]};
                        end
                    end else begin                              // Miss align
                        miss_align  = `ENABLE;
                    end
                end
                `MEM_OP_LB : begin                              // Read a byte
                    load_rdy     = `ENABLE;
                    case (offset)
                        `BYTE0:begin
                            out     = { {24{read_data_m[7]}}, read_data_m[7:0]};
                        end
                        `BYTE1:begin
                            out     = { {24{read_data_m[15]}}, read_data_m[15:8]};
                        end
                        `BYTE2:begin
                            out     = { {24{read_data_m[23]}}, read_data_m[23:16]};
                        end
                        `BYTE3:begin
                            out     = { {24{read_data_m[31]}}, read_data_m[31:24]};
                        end
                    endcase
                end
                `MEM_OP_LBU : begin                             // Read a unsigned byte
                    load_rdy     = `ENABLE;
                    case (offset)
                        `BYTE0:begin
                            out     = { {24{1'b0}}, read_data_m[7:0]};
                        end
                        `BYTE1:begin
                            out     = { {24{1'b0}}, read_data_m[15:8]};
                        end
                        `BYTE2:begin
                            out     = { {24{1'b0}}, read_data_m[23:16]};
                        end
                        `BYTE3:begin
                            out     = { {24{1'b0}}, read_data_m[31:24]};
                        end
                    endcase
                end
                `MEM_OP_LHU : begin                             // Read a half unsigned word
                    /* Check offset */
                    if (offset[0] == 1'b0) begin // Align
                        load_rdy     = `ENABLE;
                        if (offset[1] == 1'b0) begin
                            out     = { {16{1'b0}}, read_data_m[15:0]};
                        end else begin
                            out     = { {16{1'b0}}, read_data_m[31:16]};
                        end
                    end else begin                              // Miss align
                        miss_align  = `ENABLE;
                    end
                end
                `MEM_OP_SW : begin                              // Write a word
                    /* Check offset */
                    if (offset == `BYTE_OFFSET_WORD) begin      // Align
                        rw          = `WRITE;
                    end else begin                              // Miss align
                        miss_align  = `ENABLE;
                    end
                end
                `MEM_OP_SH : begin                              // Write a half word
                    /* Check offset */
                    if (offset[0] == 1'b0) begin // Align
                        if (offset[1] == 1'b0) begin
                            wr_data     = { rd_to_write_m[31:16], ex_mem_wr_data[15:0]};
                        end else begin
                            wr_data     = { ex_mem_wr_data[15:0],rd_to_write_m[15:0] };
                        end 
                        rw          = `WRITE;
                    end else begin                              // Miss align
                        miss_align  = `ENABLE;
                    end
                end
                `MEM_OP_SB : begin                              // Write a byte
                    case (offset)
                        `BYTE0:begin
                            wr_data     = { rd_to_write_m[31:8], ex_mem_wr_data[7:0]};
                        end
                        `BYTE1:begin
                            wr_data     = { rd_to_write_m[31:16], ex_mem_wr_data[7:0],rd_to_write_m[7:0]};
                        end
                        `BYTE2:begin
                            wr_data     = { rd_to_write_m[31:24], ex_mem_wr_data[7:0],rd_to_write_m[15:0]};
                        end
                        `BYTE3:begin
                            wr_data     = { ex_mem_wr_data[7:0],rd_to_write_m[23:0]};
                        end
                    endcase
                    rw   = `WRITE;
                end
                default : begin                             // No memory accessS
                    out  = ex_out;
                end
            endcase
        end
    end

endmodule
