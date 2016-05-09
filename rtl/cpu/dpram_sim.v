////////////////////////////////////////////////////////////////////
// Engineer:       Leway Colin - colin4124@gmail.com              //
//                                                                //
// Additional contributions by:                                   //
//                 Beyond Sky - fan-dave@163.com                  //
//                 Junhao Chen                                    //
//                 Kippy Chen - 799182081@qq.com                  //
//                                                                //
// Design Name:    Dual Port RAM Simulation                       //
// Project Name:   FMRT Mini Core                                 //
// Language:       Verilog                                        //
//                                                                //
// Description:    Simulate FPGA Block RAM: dpram_sim.            //
//                                                                //
//                 SPM Size:   16384 Byte (16KB)                  //
//                 SPM_DEPTH:  16384 (Byte address)               //
//                 SPM_ADDR_W: log2(4096) = 12                    //
//                                                                //
////////////////////////////////////////////////////////////////////

`include "common_defines.v"
`include "base_core_defines.v"

/********** Simulate FPGA Block RAM: dpram_sim **********/
module  dpram_sim (
    /********** Port A: IF Stage **********/
    input         clock_a,          // Clock
    input [11:0]  address_a,        // Address
    input [31:0]  data_a,           // Write data (Not Connected)
    input         wren_a,           // Write enable A (Disable)
    output [31:0] q_a,              // Read data
    /********** Port B: MEM Stage **********/
    input         clock_b,          // Clock
    input [11:0]  address_b,        // Address
    input [31:0]  data_b,           // Write data
    input         wren_b,           // Write enable
    output [31:0] q_b               // Read data
);

    reg [7:0]     RAM[`SPM_DEPTH-1:0];
    reg [31:0]    WRAM[`SPM_DEPTH-1:0];

    initial begin
        $readmemh("test.dat", RAM);
    end

    assign q_a = {RAM[{address_a, 2'b11}], RAM[{address_a, 2'b10}], RAM[{address_a, 2'b01}], RAM[{address_a, 2'b00}]};
    assign q_b = {RAM[{address_b, 2'b11}], RAM[{address_b, 2'b10}], RAM[{address_b, 2'b01}], RAM[{address_b, 2'b00}]};

    always @(posedge clock_a) begin
        if (wren_a) begin
            RAM[{address_a, 2'b11}] <= data_a[31:24];
            RAM[{address_a, 2'b10}] <= data_a[23:16];
            RAM[{address_a, 2'b01}] <= data_a[15:8];
            RAM[{address_a, 2'b00}] <= data_a[7:0];
        end
    end

    always @(posedge clock_b) begin
        if (wren_b) begin
            RAM[{address_b, 2'b11}] <= data_b[31:24];
            RAM[{address_b, 2'b10}] <= data_b[23:16];
            RAM[{address_b, 2'b01}] <= data_b[15:8];
            RAM[{address_b, 2'b00}] <= data_b[7:0];
        end
    end
endmodule
