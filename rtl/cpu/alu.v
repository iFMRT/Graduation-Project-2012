////////////////////////////////////////////////////////////////////
// Engineer:       Beyond Sky - fan-dave@163.com                  //
//                                                                //
// Additional contributions by:                                   //
//                 Leway Colin - colin4124@gmail.com              //
//                 Junhao Chen                                    //
//                 Kippy Chen - 799182081@qq.com                  //
//                                                                //
// Design Name:    ALU                                            //
// Project Name:   FMRT Mini Core                                 //
// Language:       Verilog                                        //
//                                                                //
// Description:    Arithmetic Logic Unit.                         //
//                                                                //
////////////////////////////////////////////////////////////////////

`include "common_defines.v"
`include "base_core_defines.v"

module alu (
    input  wire signed [`WORD_DATA_BUS] arg0,
    input  wire signed [`WORD_DATA_BUS] arg1,
    input  wire        [`ALU_OP_BUS]    op,
    output reg  signed [`WORD_DATA_BUS] val
);

    always @(*) begin
        case(op)
            `ALU_OP_AND : val = arg0 & arg1;
            `ALU_OP_OR  : val = arg0 | arg1;
            `ALU_OP_XOR : val = arg0 ^ arg1;
            `ALU_OP_SLL : val = arg0 << arg1;
            `ALU_OP_SRL : val = arg0 >> arg1;
            `ALU_OP_SRA : val = arg0 >>> arg1;
            `ALU_OP_ADD : val = arg0 + arg1;
            `ALU_OP_SUB : val = arg0 - arg1;
            default     : val = `WORD_DATA_W'b0;
        endcase
    end
endmodule
