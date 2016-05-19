//////////////////////////////////////////////////////////////////////
// Engineer:       Kippy Chen - 799182081@qq.com                    //
//                                                                  //
// Additional contributions by:                                     //
//                 Beyond Sky - fan-dave@163.com                    //
//                 Leway Colin - colin4124@gmail.com                //
//                 Junhao Chen                                      //
//                                                                  //
// Design Name:    IF/ID Pipeline Register                          //
// Project Name:   FMRT Mini Core                                   //
// Language:       Verilog                                          //
//                                                                  //
// Description:    IF/ID Pipeline Register.                         //
//                                                                  //
//////////////////////////////////////////////////////////////////////

`include "common_defines.v"
`include "base_core_defines.v"

module if_reg (
    /******** Clock & Rest ********/
    input wire                       clk,      // Clk
    input wire                       reset,    // Reset
    /******** Read Instruction ********/
    input wire [`WORD_DATA_BUS]      insn,     // Reading instruction

    input wire                       stall,    // Stall
    input wire                       flush,    // Flush
    input wire [`WORD_DATA_BUS]      new_pc,   // New value of program counter
    input wire                       br_taken, // Branch taken
    input wire [`WORD_DATA_BUS]      br_addr,  // Branch target

    output reg [`WORD_DATA_BUS] pc,       // Current Program counter
    output reg [`WORD_DATA_BUS] if_pc,    // Next Program counter
    output reg [`WORD_DATA_BUS] if_insn,  // Instruction
    output reg                  if_en     // Effective mark of pipeline
);

    always @(posedge clk) begin
        if (reset == `ENABLE) begin
            /******** Reset ********/
            pc      <=  `WORD_DATA_W'h0;
            if_pc   <=  `WORD_DATA_W'h0;
            if_insn <=  `OP_NOP;
            if_en   <=  `DISABLE;
        end else begin
            /******** Update pipeline ********/
            if (stall == `DISABLE) begin
                if (flush == `ENABLE) begin
                    /* Flush */
                    if_pc   <=  new_pc;
                    if_insn <=  `OP_NOP;
                    if_en   <=  `DISABLE;
                end else if (br_taken == `ENABLE) begin
                    /* Branch taken */
                    if_pc   <=  br_addr;
                    if_insn <=  `OP_NOP;
                    if_en   <=  `DISABLE;
                end else begin
                    /* Next PC */
                    pc      <=  if_pc;
                    if_pc   <= #1 if_pc + `WORD_DATA_W'd4;
                    if_insn <=  insn;
                    if_en   <=  `ENABLE;
                end // else: !if(br_taken == `ENABLE)
            end // if (stall == `DISABLE)
        end // else: !if(reset == `ENABLE)
    end // always @ (posedge clk)

endmodule
