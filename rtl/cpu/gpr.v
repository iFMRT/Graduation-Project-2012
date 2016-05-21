////////////////////////////////////////////////////////////////////
// Engineer:       Junhao Chang                                   //
//                                                                //
// Additional contributions by:                                   //
//                 Beyond Sky - fan-dave@163.com                  //
//                 Kippy Chen - 799182081@qq.com                  //
//                 Leway Colin - colin4124@gmail.com              //
//                                                                //
// Design Name:    General Purpose Registers                      //
// Project Name:   FMRT Mini Core                                 //
// Language:       Verilog                                        //
//                                                                //
// Description:    32 32-bit register files.                      //
//                                                                //
////////////////////////////////////////////////////////////////////

`include "common_defines.v"
`include "base_core_defines.v"

module gpr (
    /********** Clock & Reset **********/
    input  wire                     clk,           // Clock
    input  wire                     reset,         // Reset
    /********** Read Port 0 **********/
    input  wire [`REG_ADDR_BUS]     rs1_addr,      // Read address
    output wire [`WORD_DATA_BUS]    rs1_data,      // Read data
    /********** Read Port 1 **********/
    input  wire [`REG_ADDR_BUS]     rs2_addr,      // Read address
    output wire [`WORD_DATA_BUS]    rs2_data,      // Read data
    /********** Write Port **********/
    input  wire                      we_,          // Write enable
    input  wire [`REG_ADDR_BUS]      wr_addr,      // Write address
    input  wire [`WORD_DATA_BUS]     wr_data       // Write data
);

    wire [`WORD_DATA_BUS]     rs1_data_tmp;        // Read data temporary
    wire [`WORD_DATA_BUS]     rs2_data_tmp;        // Read data temporary
    reg  [`WORD_DATA_BUS]     gpr [`REG_NUM_BUS];  // Register files
    integer                   i;                   // Counter

    assign rs1_data = (rs1_addr != 0) ? rs1_data_tmp : 0;
    assign rs2_data = (rs2_addr != 0) ? rs2_data_tmp : 0;

    /********** Read Access (read fisrt, then write) **********/
    // Read Port 0
    assign rs1_data_tmp = ((we_ == `ENABLE_) && (wr_addr == rs1_addr)) ? wr_data : gpr[rs1_addr];

    // Read Port 1
    assign rs2_data_tmp = ((we_ == `ENABLE_) && (wr_addr == rs2_addr)) ? wr_data : gpr[rs2_addr];

    /********** Write Access **********/
    always @ (posedge clk) begin
        if (reset != `ENABLE) begin
            if (we_ == `ENABLE_) begin
                gpr[wr_addr] <= #1 wr_data;
            end
        end
    end

endmodule
