////////////////////////////////////////////////////////////////////
// Engineer:       Leway Colin - colin4124@gmail.com              //
//                                                                //
// Additional contributions by:                                   //
//                 Beyond Sky - fan-dave@163.com                  //
//                 Junhao Chen                                    //
//                 Kippy Chen - 799182081@qq.com                  //
//                                                                //
// Design Name:    Memory Access Control Unit                     //
// Project Name:   FMRT Mini Core                                 //
// Language:       Verilog                                        //
//                                                                //
// Description:    Memory Access Control Unit.                    //
//                                                                //
////////////////////////////////////////////////////////////////////

`include "common_defines.v"
`include "base_core_defines.v"

/********** Memory Access Control Module **********/
module mem_ctrl (
    /********** EX/MEM Pipeline Register **********/
    input wire                   ex_en,          // If Pipeline data enable
    input wire  [`MEM_OP_BUS]    ex_mem_op,      // Memory operation
    input wire  [`WORD_DATA_BUS] ex_mem_wr_data, // Memory write data
    input wire  [`WORD_DATA_BUS] ex_out,         // EX stage operating result
    /********** Memory Access Interface **********/
    input wire [`WORD_DATA_BUS]  rd_data,        // Read data
    output wire [`WORD_ADDR_BUS] addr,           // address
    output reg                   as_,            // Address strobe
    output reg                   rw,             // Read/Write
    output reg  [`WORD_DATA_BUS] wr_data,        // Write data
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
                    if (offset[0] == 1'b0) begin // Align
                        as_     = `ENABLE_;
                        if (offset[1] == 1'b0) begin
                            out     = { {16{rd_data[15]}}, rd_data[15:0]};
                        end else begin
                            out     = { {16{rd_data[31]}}, rd_data[31:16]};
                        end
                    end else begin                              // Miss align
                        miss_align  = `ENABLE;
                    end
                end
                // Read a half unsigned word
                `MEM_OP_LHU : begin
                    /* Check offset */
                    if (offset[0] == 1'b0) begin // Align
                        as_     = `ENABLE_;
                        if (offset[1] == 1'b0) begin
                            out     = { {16{1'b0}}, rd_data[15:0]};
                        end else begin
                            out     = { {16{1'b0}}, rd_data[31:16]};
                        end
                    end else begin                              // Miss align
                        miss_align  = `ENABLE;
                    end
                end
                // Read a byte
                `MEM_OP_LB : begin
                    as_     = `ENABLE_;
                    case (offset)
                        `BYTE0: out = { {24{rd_data[7]}}, rd_data[7:0]};
                        `BYTE1: out = { {24{rd_data[15]}}, rd_data[15:8]};
                        `BYTE2: out = { {24{rd_data[23]}}, rd_data[23:16]};
                        `BYTE3: out = { {24{rd_data[31]}}, rd_data[31:24]};
                    endcase
                end
                // Read a unsigned byte
                `MEM_OP_LBU : begin
                    as_     = `ENABLE_;
                    case (offset)
                        `BYTE0: out = { {24{1'b0}}, rd_data[7:0]};
                        `BYTE1: out = { {24{1'b0}}, rd_data[15:8]};
                        `BYTE2: out = { {24{1'b0}}, rd_data[23:16]};
                        `BYTE3: out = { {24{1'b0}}, rd_data[31:24]};
                    endcase
                end
                `MEM_OP_SW : begin                              // Write a word
                    /* Check offset */
                    if (offset == `BYTE_OFFSET_WORD) begin      // Align
                        as_         = `ENABLE_;
                        rw          = `WRITE;
                    end else begin                              // Miss align
                        miss_align  = `ENABLE;
                    end
                end
                `MEM_OP_SH : begin                              // Write a half word
                    /* Check offset */
                    if (offset[0] == 1'b0) begin                // Align
                        if (offset[1] == 1'b0) begin
                            wr_data = { rd_data[31:16], ex_mem_wr_data[15:0]};
                        end else begin
                            wr_data = { ex_mem_wr_data[15:0], rd_data[15:0] };
                        end
                        as_         = `ENABLE_;
                        rw          = `WRITE;
                    end else begin                              // Miss align
                        miss_align  = `ENABLE;
                    end
                end
                `MEM_OP_SB : begin                              // Write a byte
                    case (offset)
                        `BYTE0: wr_data = { rd_data[31:8], ex_mem_wr_data[7:0]};
                        `BYTE1: wr_data = { rd_data[31:16], ex_mem_wr_data[7:0],rd_data[7:0]};
                        `BYTE2: wr_data = { rd_data[31:24], ex_mem_wr_data[7:0],rd_data[15:0]};
                        `BYTE3: wr_data = { ex_mem_wr_data[7:0],rd_data[23:0]};
                    endcase
                    as_  = `ENABLE_;
                    rw   = `WRITE;
                end
                default    : begin                             // No memory accessS
                    out  = ex_out;
                end
            endcase
        end
    end

endmodule
