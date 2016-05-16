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
    input                       clk,      // Clk
    input                       reset,    // Reset
    /******** Read Instruction ********/
    input [`WORD_DATA_BUS]      insn,     // Reading instruction

    input                       stall,    // Stall
    input                       flush,    // Flush
    input [`WORD_DATA_BUS]      new_pc,   // New value of program counter
    input                       br_taken, // Branch taken
    input [`WORD_DATA_BUS]      br_addr,  // Branch target

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
