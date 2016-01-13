/*
 -- ============================================================================
 -- FILE NAME   : ram.v
 -- DESCRIPTION : ram
 -- ----------------------------------------------------------------------------
 -- Date:2016/1/8         Coding_by: 
 -- ============================================================================
*/
/********** General header file **********/
`include "stddef.h"

module ram0(
    input  [27:0] a,    // address of memory
    output [31:0] rd    // read data of ram0
    );
   reg [31:0]ram[1023:0];

   initial
   begin
    $readmemh("memfile0.dat",ram);
   end
   assign rd = ram[a];
endmodule

module ram1(
    input  [27:0] a,    // address of memory
    output [31:0] rd    // read data of ram1
    );
   reg [31:0]ram[1023:0];

   initial
   begin
    $readmemh("memfile1.dat",ram);
   end
   assign rd = ram[a];
endmodule

module ram2(
    input  [27:0] a,    // address of memory
    output [31:0] rd    // read data of ram2
    );
   reg [31:0]ram[1023:0];

   initial
   begin
    $readmemh("memfile2.dat",ram);
   end
   assign rd = ram[a];
endmodule

module ram3(
    input  [27:0] a,      // address of memory
    output [31:0] rd      // read data of ram3
    );
   reg [31:0]ram[1023:0];
   initial
   begin
    $readmemh("memfile3.dat",ram);
   end
   assign rd = ram[a];
endmodule