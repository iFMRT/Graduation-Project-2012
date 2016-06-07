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
`include "common_defines.v"
`include "base_core_defines.v"

module mem(
  input  wire               clock,    // Clock
  input  wire               rst,    // Asynchronous reset active low
  input  wire               rden,
  input  wire               wren,
  input  wire      [25:0]   address,
  /*memory part*/
  output wire      [511:0]  mem_rd,
  input  wire      [511:0]  mem_wd,
  output reg            complete_w,
  output reg            complete_r
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
    always @(posedge clock) begin
        if(rst == `ENABLE) begin
            complete_w <= `DISABLE;
            complete_r <= `DISABLE;
            i          <= `CLOCK0;
        end else begin
            i        <= next_i;
        end 
        if (next_i == `CLOCK1 && wren == `ENABLE) begin
            complete_w <= `ENABLE;      
        end else begin
            complete_w <= `DISABLE;
        end
        if (next_i == `CLOCK1 && rden == `ENABLE) begin
            complete_r <= `ENABLE;      
        end else begin
            complete_r <= `DISABLE;
        end
    end
  
    ram ram(
      .clock     (clock),
      .address   (address[11:0]),
      .mem_wd    (mem_wd),
      .rden      (rden),
      .wren      (wren),
      .mem_rd    (mem_rd)
      );
endmodule

module ram(
  input   wire          clock,        // clock
  input   wire [11:0]   address,      // ram address
  input   wire [511:0]  mem_wd,       // wrenite data
  input   wire          rden,         // is read
  input   wire          wren,         // is wrenite
  output  wire [511:0]  mem_rd        // read data
);
reg  [7:0] ram[`RAM_DEPTH-1:0];  // t_buffer is a ram
wire [31:0] data15,data14,data13,data12,data11,data10,data9,data8,data7,data6,data5,data4,data3,data2,data1,data0;
reg  [31:0] q15,q14,q13,q12,q11,q10,q9,q8,q7,q6,q5,q4,q3,q2,q1,q0;
    
    initial begin
       $readmemh("test.dat",ram);
    end

    assign mem_rd = {q15,q14,q13,q12,q11,q10,q9,q8,q7,q6,q5,q4,q3,q2,q1,q0};

    assign {data15,data14,data13,data12,data11,data10,data9,data8,data7,data6,data5,data4,data3,data2,data1,data0} = mem_wd;
    /******   read data from ram    ******/
    always @(posedge clock) begin
        if (rden) begin
          // q <= ram[address];  
          q0  <= {ram[{address, 4'b0000,2'b11}], ram[{address, 4'b0000,2'b10}], ram[{address, 4'b0000,2'b01}], ram[{address, 4'b0000,2'b00}]};
          q1  <= {ram[{address, 4'b0001,2'b11}], ram[{address, 4'b0001,2'b10}], ram[{address, 4'b0001,2'b01}], ram[{address, 4'b0001,2'b00}]};
          q2  <= {ram[{address, 4'b0010,2'b11}], ram[{address, 4'b0010,2'b10}], ram[{address, 4'b0010,2'b01}], ram[{address, 4'b0010,2'b00}]};
          q3  <= {ram[{address, 4'b0011,2'b11}], ram[{address, 4'b0011,2'b10}], ram[{address, 4'b0011,2'b01}], ram[{address, 4'b0011,2'b00}]};
          q4  <= {ram[{address, 4'b0100,2'b11}], ram[{address, 4'b0100,2'b10}], ram[{address, 4'b0100,2'b01}], ram[{address, 4'b0100,2'b00}]};
          q5  <= {ram[{address, 4'b0101,2'b11}], ram[{address, 4'b0101,2'b10}], ram[{address, 4'b0101,2'b01}], ram[{address, 4'b0101,2'b00}]};
          q6  <= {ram[{address, 4'b0110,2'b11}], ram[{address, 4'b0110,2'b10}], ram[{address, 4'b0110,2'b01}], ram[{address, 4'b0110,2'b00}]};
          q7  <= {ram[{address, 4'b0111,2'b11}], ram[{address, 4'b0111,2'b10}], ram[{address, 4'b0111,2'b01}], ram[{address, 4'b0111,2'b00}]};
          q8  <= {ram[{address, 4'b1000,2'b11}], ram[{address, 4'b1000,2'b10}], ram[{address, 4'b1000,2'b01}], ram[{address, 4'b1000,2'b00}]};
          q9  <= {ram[{address, 4'b1001,2'b11}], ram[{address, 4'b1001,2'b10}], ram[{address, 4'b1001,2'b01}], ram[{address, 4'b1001,2'b00}]};
          q10 <= {ram[{address, 4'b1010,2'b11}], ram[{address, 4'b1010,2'b10}], ram[{address, 4'b1010,2'b01}], ram[{address, 4'b1010,2'b00}]};
          q11 <= {ram[{address, 4'b1011,2'b11}], ram[{address, 4'b1011,2'b10}], ram[{address, 4'b1011,2'b01}], ram[{address, 4'b1011,2'b00}]};
          q12 <= {ram[{address, 4'b1100,2'b11}], ram[{address, 4'b1100,2'b10}], ram[{address, 4'b1100,2'b01}], ram[{address, 4'b1100,2'b00}]};
          q13 <= {ram[{address, 4'b1101,2'b11}], ram[{address, 4'b1101,2'b10}], ram[{address, 4'b1101,2'b01}], ram[{address, 4'b1101,2'b00}]};
          q14 <= {ram[{address, 4'b1110,2'b11}], ram[{address, 4'b1110,2'b10}], ram[{address, 4'b1110,2'b01}], ram[{address, 4'b1110,2'b00}]};
          q15 <= {ram[{address, 4'b1111,2'b11}], ram[{address, 4'b1111,2'b10}], ram[{address, 4'b1111,2'b01}], ram[{address, 4'b1111,2'b00}]};
        end 
    end

    /******   wrenite data to ram     ******/
    always @(posedge clock) begin
        if (wren) begin
            // ram [address] <= data; 
            if (wren) begin
                ram[{address, 4'b0000,2'b11}] <= data0[31:24];
                ram[{address, 4'b0000,2'b10}] <= data0[23:16];
                ram[{address, 4'b0000,2'b01}] <= data0[15:8];
                ram[{address, 4'b0000,2'b00}] <= data0[7:0];

                ram[{address, 4'b0001,2'b11}] <= data1[31:24];
                ram[{address, 4'b0001,2'b10}] <= data1[23:16];
                ram[{address, 4'b0001,2'b01}] <= data1[15:8];
                ram[{address, 4'b0001,2'b00}] <= data1[7:0];

                ram[{address, 4'b0010,2'b11}] <= data2[31:24];
                ram[{address, 4'b0010,2'b10}] <= data2[23:16];
                ram[{address, 4'b0010,2'b01}] <= data2[15:8];
                ram[{address, 4'b0010,2'b00}] <= data2[7:0];

                ram[{address, 4'b0011,2'b11}] <= data3[31:24];
                ram[{address, 4'b0011,2'b10}] <= data3[23:16];
                ram[{address, 4'b0011,2'b01}] <= data3[15:8];
                ram[{address, 4'b0011,2'b00}] <= data3[7:0];

                ram[{address, 4'b0100,2'b11}] <= data4[31:24];
                ram[{address, 4'b0100,2'b10}] <= data4[23:16];
                ram[{address, 4'b0100,2'b01}] <= data4[15:8];
                ram[{address, 4'b0100,2'b00}] <= data4[7:0];

                ram[{address, 4'b0101,2'b11}] <= data5[31:24];
                ram[{address, 4'b0101,2'b10}] <= data5[23:16];
                ram[{address, 4'b0101,2'b01}] <= data5[15:8];
                ram[{address, 4'b0101,2'b00}] <= data5[7:0];

                ram[{address, 4'b0110,2'b11}] <= data6[31:24];
                ram[{address, 4'b0110,2'b10}] <= data6[23:16];
                ram[{address, 4'b0110,2'b01}] <= data6[15:8];
                ram[{address, 4'b0110,2'b00}] <= data6[7:0];

                ram[{address, 4'b0111,2'b11}] <= data7[31:24];
                ram[{address, 4'b0111,2'b10}] <= data7[23:16];
                ram[{address, 4'b0111,2'b01}] <= data7[15:8];
                ram[{address, 4'b0111,2'b00}] <= data7[7:0];

                ram[{address, 4'b1000,2'b11}] <= data8[31:24];
                ram[{address, 4'b1000,2'b10}] <= data8[23:16];
                ram[{address, 4'b1000,2'b01}] <= data8[15:8];
                ram[{address, 4'b1000,2'b00}] <= data8[7:0];

                ram[{address, 4'b1001,2'b11}] <= data9[31:24];
                ram[{address, 4'b1001,2'b10}] <= data9[23:16];
                ram[{address, 4'b1001,2'b01}] <= data9[15:8];
                ram[{address, 4'b1001,2'b00}] <= data9[7:0];

                ram[{address, 4'b1010,2'b11}] <= data10[31:24];
                ram[{address, 4'b1010,2'b10}] <= data10[23:16];
                ram[{address, 4'b1010,2'b01}] <= data10[15:8];
                ram[{address, 4'b1010,2'b00}] <= data10[7:0];

                ram[{address, 4'b1011,2'b11}] <= data11[31:24];
                ram[{address, 4'b1011,2'b10}] <= data11[23:16];
                ram[{address, 4'b1011,2'b01}] <= data11[15:8];
                ram[{address, 4'b1011,2'b00}] <= data11[7:0];

                ram[{address, 4'b1100,2'b11}] <= data12[31:24];
                ram[{address, 4'b1100,2'b10}] <= data12[23:16];
                ram[{address, 4'b1100,2'b01}] <= data12[15:8];
                ram[{address, 4'b1100,2'b00}] <= data12[7:0];

                ram[{address, 4'b1101,2'b11}] <= data13[31:24];
                ram[{address, 4'b1101,2'b10}] <= data13[23:16];
                ram[{address, 4'b1101,2'b01}] <= data13[15:8];
                ram[{address, 4'b1101,2'b00}] <= data13[7:0];

                ram[{address, 4'b1110,2'b11}] <= data14[31:24];
                ram[{address, 4'b1110,2'b10}] <= data14[23:16];
                ram[{address, 4'b1110,2'b01}] <= data14[15:8];
                ram[{address, 4'b1110,2'b00}] <= data14[7:0];

                ram[{address, 4'b1111,2'b11}] <= data15[31:24];
                ram[{address, 4'b1111,2'b10}] <= data15[23:16];
                ram[{address, 4'b1111,2'b01}] <= data15[15:8];
                ram[{address, 4'b1111,2'b00}] <= data15[7:0];
            end
        end 
    end
endmodule