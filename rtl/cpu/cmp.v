////////////////////////////////////////////////////////////////////
// Engineer:       Beyond Sky - fan-dave@163.com                  //
//                                                                //
// Additional contributions by:                                   //
//                 Leway Colin - colin4124@gmail.com              //
//                 Junhao Chen                                    //
//                 Kippy Chen - 799182081@qq.com                  //
//                                                                //
// Design Name:    CMP                                            //
// Project Name:   FMRT Mini Core                                 //
// Language:       Verilog                                        //
//                                                                //
// Description:    Compare Unit.                                  //
//                                                                //
////////////////////////////////////////////////////////////////////

`include "common_defines.v"
`include "base_core_defines.v"

module cmp #(parameter WIDTH = `WORD_DATA_W) (
    input  wire signed [WIDTH-1:0]   arg0,
    input  wire signed [WIDTH-1:0]   arg1,
    input  wire        [`CMP_OP_BUS] op,
    output reg                       true
);

    wire [WIDTH-1:0]  arg0_u;
    wire [WIDTH-1:0]  arg1_u;
    wire              eq,ne,lt,ltu,ge,geu;

    assign arg0_u = arg0;
    assign arg1_u = arg1;

    always @(*) begin
        case(op)
            `CMP_OP_NOP : true = `CMP_FALSE;
            `CMP_OP_EQ  : true = eq;
            `CMP_OP_NE  : true = ne;
            `CMP_OP_LT  : true = lt;
            `CMP_OP_LTU : true = ltu;
            `CMP_OP_GE  : true = ge;
            `CMP_OP_GEU : true = geu;
            default     : true = `CMP_FALSE;
        endcase
    end

    assign eq  = (arg0 == arg1) ? `CMP_TRUE : `CMP_FALSE;
    assign ne  = ~eq;
    assign lt  = (arg0 <  arg1) ? `CMP_TRUE : `CMP_FALSE;
    assign ltu = (arg0_u <  arg1_u) ? `CMP_TRUE : `CMP_FALSE;
    assign ge  = ~lt;
    assign geu = ~ltu;

endmodule
