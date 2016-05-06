/*
 -- ============================================================================
 -- FILE NAME   : ram.v
 -- DESCRIPTION : ram
 -- ----------------------------------------------------------------------------
 -- Date:2016/1/8         Coding_by: 
 -- ============================================================================
*/
`timescale 1ns/1ps

/********** General header file **********/
`include "stddef.h"

module mem(
  input      clk,    // Clock
  input      rst,    // Asynchronous reset active low
  input      rw,
  output reg complete
);
reg  [1:0] i,next_i;
    always @(*) begin
      case(i)
          `CLOCK0:begin
            next_i = `CLOCK1;
          end
          `CLOCK1:begin
            next_i = `CLOCK2;
          end
          `CLOCK2:begin
            next_i = `CLOCK3;
          end
          `CLOCK3:begin
            next_i = `CLOCK0;
          end
      endcase
    end
    always @(posedge clk) begin
        if(rst == `ENABLE) begin
            complete <= `DISABLE;
            i        <= `CLOCK0;
        end else begin
            i        <= next_i;
        end 
        if (i == `CLOCK1 && rw == `WRITE) begin
            complete <= `ENABLE;      
        end else begin
            complete <= `DISABLE;
        end
    end
endmodule

// module ram0(
//     input         clk,    // Clock
//     input         rst,    // Asynchronous reset active low
//     input  [25:0] a,    // address of memory
//     input         rw,
//     input  [31:0] wd,
//     output [31:0] rd    // read data of ram0
//     );
//    reg [31:0]ram[1023:0];

//    initial begin
//     $readmemh("memfile0.dat",ram);
//    end

//    assign rd = ram[a];
//    always @(posedge clk) begin
//         if(rst !== `ENABLE) begin
//             if (rw == `WRITE) begin
//                 ram[a] <= wd;
//             end
//         end
//     end
// endmodule

// module ram1(
//     input         clk,    // Clock
//     input         rst,    // Asynchronous reset active low
//     input  [25:0] a,    // address of memory
//     input         rw,
//     input  [31:0] wd,
//     output [31:0] rd    // read data of ram1
//     );
//    reg [31:0]ram[1023:0];

//    initial
//    begin
//     $readmemh("memfile1.dat",ram);
//    end
//    assign rd = ram[a];
//    always @(posedge clk) begin
//         if(rst !== `ENABLE) begin
//             if (rw == `WRITE) begin
//                 ram[a] <= wd;
//             end
//         end
//     end
// endmodule

// module ram2(
//     input         clk,    // Clock
//     input         rst,    // Asynchronous reset active low
//     input  [25:0] a,    // address of memory
//     input         rw,
//     input  [31:0] wd,
//     output [31:0] rd    // read data of ram2
//     );
//    reg [31:0]ram[1023:0];

//    initial
//    begin
//     $readmemh("memfile2.dat",ram);
//    end
//    assign rd = ram[a];
//    always @(posedge clk) begin
//         if(rst !== `ENABLE) begin
//             if (rw == `WRITE) begin
//                 ram[a] <= wd;
//             end
//         end
//     end
// endmodule

// module ram3(
//     input         clk,    // Clock
//     input         rst,    // Asynchronous reset active low
//     input  [25:0] a,    // address of memory
//     input         rw,
//     input  [31:0] wd,
//     output [31:0] rd      // read data of ram3
//     );
//    reg [31:0]ram[1023:0];
//    initial
//    begin
//     $readmemh("memfile3.dat",ram);
//    end
//    assign rd = ram[a];
//    always @(posedge clk) begin
//         if(rst !== `ENABLE) begin
//             if (rw == `WRITE) begin
//                 ram[a] <= wd;
//             end
//         end
//     end
// endmodule

// module ram4(
//     input         clk,    // Clock
//     input         rst,    // Asynchronous reset active low
//     input  [25:0] a,    // address of memory
//     input         rw,
//     input  [31:0] wd,
//     output [31:0] rd    // read data of ram0
//     );
//    reg [31:0]ram[1023:0];

//    initial
//    begin
//     $readmemh("memfile4.dat",ram);
//    end
//    assign rd = ram[a];
//    always @(posedge clk) begin
//         if(rst !== `ENABLE) begin
//             if (rw == `WRITE) begin
//                 ram[a] <= wd;
//             end
//         end
//     end
// endmodule

// module ram5(
//     input         clk,    // Clock
//     input         rst,    // Asynchronous reset active low
//     input  [25:0] a,    // address of memory
//     input         rw,
//     input  [31:0] wd,
//     output [31:0] rd    // read data of ram1
//     );
//    reg [31:0]ram[1023:0];

//    initial
//    begin
//     $readmemh("memfile5.dat",ram);
//    end
//    assign rd = ram[a];
//    always @(posedge clk) begin
//         if(rst !== `ENABLE) begin
//             if (rw == `WRITE) begin
//                 ram[a] <= wd;
//             end
//         end
//     end
// endmodule

// module ram6(
//     input         clk,    // Clock
//     input         rst,    // Asynchronous reset active low
//     input  [25:0] a,    // address of memory
//     input         rw,
//     input  [31:0] wd,
//     output [31:0] rd    // read data of ram2
//     );
//    reg [31:0]ram[1023:0];

//    initial
//    begin
//     $readmemh("memfile6.dat",ram);
//    end
//    assign rd = ram[a];
//    always @(posedge clk) begin
//         if(rst !== `ENABLE) begin
//             if (rw == `WRITE) begin
//                 ram[a] <= wd;
//             end
//         end
//     end
// endmodule

// module ram7(
//     input         clk,    // Clock
//     input         rst,    // Asynchronous reset active low
//     input  [25:0] a,    // address of memory
//     input         rw,
//     input  [31:0] wd,
//     output [31:0] rd      // read data of ram3
//     );
//    reg [31:0]ram[1023:0];
//    initial
//    begin
//     $readmemh("memfile7.dat",ram);
//    end
//    assign rd = ram[a];
//    always @(posedge clk) begin
//         if(rst !== `ENABLE) begin
//             if (rw == `WRITE) begin
//                 ram[a] <= wd;
//             end
//         end
//     end
// endmodule

// module ram8(
//     input         clk,    // Clock
//     input         rst,    // Asynchronous reset active low
//     input  [25:0] a,    // address of memory
//     input         rw,
//     input  [31:0] wd,
//     output [31:0] rd    // read data of ram0
//     );
//    reg [31:0]ram[1023:0];

//    initial
//    begin
//     $readmemh("memfile8.dat",ram);
//    end
//    assign rd = ram[a];
//    always @(posedge clk) begin
//         if(rst !== `ENABLE) begin
//             if (rw == `WRITE) begin
//                 ram[a] <= wd;
//             end
//         end
//     end
// endmodule

// module ram9(
//     input         clk,    // Clock
//     input         rst,    // Asynchronous reset active low
//     input  [25:0] a,    // address of memory
//     input         rw,
//     input  [31:0] wd,
//     output [31:0] rd    // read data of ram1
//     );
//    reg [31:0]ram[1023:0];

//    initial
//    begin
//     $readmemh("memfile9.dat",ram);
//    end
//    assign rd = ram[a];
//    always @(posedge clk) begin
//         if(rst !== `ENABLE) begin
//             if (rw == `WRITE) begin
//                 ram[a] <= wd;
//             end
//         end
//     end
// endmodule

// module ram10(
//     input         clk,    // Clock
//     input         rst,    // Asynchronous reset active low
//     input  [25:0] a,    // address of memory
//     input         rw,
//     input  [31:0] wd,
//     output [31:0] rd    // read data of ram2
//     );
//    reg [31:0]ram[1023:0];

//    initial
//    begin
//     $readmemh("memfile10.dat",ram);
//    end
//    assign rd = ram[a];
//    always @(posedge clk) begin
//         if(rst !== `ENABLE) begin
//             if (rw == `WRITE) begin
//                 ram[a] <= wd;
//             end
//         end
//     end
// endmodule

// module ram11(
//     input         clk,    // Clock
//     input         rst,    // Asynchronous reset active low
//     input  [25:0] a,    // address of memory
//     input         rw,
//     input  [31:0] wd,
//     output [31:0] rd      // read data of ram3
//     );
//    reg [31:0]ram[1023:0];
//    initial
//    begin
//     $readmemh("memfile11.dat",ram);
//    end
//    assign rd = ram[a];
//    always @(posedge clk) begin
//         if(rst !== `ENABLE) begin
//             if (rw == `WRITE) begin
//                 ram[a] <= wd;
//             end
//         end
//     end
// endmodule

// module ram12(
//     input         clk,    // Clock
//     input         rst,    // Asynchronous reset active low
//     input  [25:0] a,    // address of memory
//     input         rw,
//     input  [31:0] wd,
//     output [31:0] rd    // read data of ram0
//     );
//    reg [31:0]ram[1023:0];

//    initial
//    begin
//     $readmemh("memfile12.dat",ram);
//    end
//    assign rd = ram[a];
//    always @(posedge clk) begin
//         if(rst !== `ENABLE) begin
//             if (rw == `WRITE) begin
//                 ram[a] <= wd;
//             end
//         end
//     end
// endmodule

// module ram13(
//     input         clk,    // Clock
//     input         rst,    // Asynchronous reset active low
//     input  [25:0] a,    // address of memory
//     input         rw,
//     input  [31:0] wd,
//     output [31:0] rd    // read data of ram1
//     );
//    reg [31:0]ram[1023:0];

//    initial
//    begin
//     $readmemh("memfile13.dat",ram);
//    end
//    assign rd = ram[a];
//    always @(posedge clk) begin
//         if(rst !== `ENABLE) begin
//             if (rw == `WRITE) begin
//                 ram[a] <= wd;
//             end
//         end
//     end
// endmodule

// module ram14(
//     input         clk,    // Clock
//     input         rst,    // Asynchronous reset active low
//     input  [25:0] a,    // address of memory
//     input         rw,
//     input  [31:0] wd,
//     output [31:0] rd    // read data of ram2
//     );
//    reg [31:0]ram[1023:0];

//    initial
//    begin
//     $readmemh("memfile14.dat",ram);
//    end
//    assign rd = ram[a];
//    always @(posedge clk) begin
//         if(rst !== `ENABLE) begin
//             if (rw == `WRITE) begin
//                 ram[a] <= wd;
//             end
//         end
//     end
// endmodule

// module ram15(
//     input         clk,    // Clock
//     input         rst,    // Asynchronous reset active low
//     input  [25:0] a,    // address of memory
//     input         rw,
//     input  [31:0] wd,
//     output [31:0] rd      // read data of ram3
//     );
//    reg [31:0]ram[1023:0];
//    initial
//    begin
//     $readmemh("memfile15.dat",ram);
//    end
//    assign rd = ram[a];
//    always @(posedge clk) begin
//         if(rst !== `ENABLE) begin
//             if (rw == `WRITE) begin
//                 ram[a] <= wd;
//             end
//         end
//     end
// endmodule