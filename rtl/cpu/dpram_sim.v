/*
 *   SPM Size:   16384 Byte (16KB)
 *   SPM_DEPTH:  16384 / 4  = 4096 (Word address)
 *   SPM_ADDR_W: log2(4096) = 12
 */
`include "spm.h"

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
    
    reg [31:0] RAM[`SPM_DEPTH-1:0];

    initial begin
        $readmemh("test.dat", RAM);
    end

    assign q_a = RAM[address_a];
    assign q_b = RAM[address_b];

    always @(posedge clock_a) begin
        if (wren_a) begin
            RAM[address_a] <= data_a;
        end
    end

    always @(posedge clock_b) begin
        if (wren_b) begin
            RAM[address_b] <= data_b;
        end
    end
endmodule