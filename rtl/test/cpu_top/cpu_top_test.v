/******** Time scale ********/
`timescale 1ns/1ps
////////////////////////////////////////////////////////////////////////
// Engineer:       Leway Colin - colin4124@gmail.com                  //
//                                                                    //
// Additional contributions by:                                       //
//                 Beyond Sky - fan-dave@163.com                      //
//                 Kippy Chen - 799182081@qq.com                      //
//                 Junhao Chen                                        //
//                                                                    //
// Design Name:    Top of CPU                                         //
// Project Name:   FMRT Mini Core                                     //
// Language:       Verilog                                            //
//                                                                    //
// Description:    Combine all the CPU components together.           //
//                                                                    //
////////////////////////////////////////////////////////////////////////

`include "common_defines.v"
`include "base_core_defines.v"

`timescale 1ns/1ps

module cpu_top_test;
    reg                   clk;            // Clock
    reg                   reset;          // Asynchronous Reset
    wire[`WORD_DATA_BUS] gpr_rs1_data; // Read data 0
    wire[`WORD_DATA_BUS] gpr_rs2_data; // Read data 1
    wire[`REG_ADDR_BUS]  gpr_rs1_addr; // Read  address 0
    wire[`REG_ADDR_BUS]  gpr_rs2_addr; // Read  address 1
    wire[`REG_ADDR_BUS]  mem_rd_addr; // General purpose register write  address
    wire[`WORD_DATA_BUS] mem_out         // Operating result
;


    /******** Define Simulation Loop********/
    parameter             STEP = 10;

    /******** Generate Clock ********/
    always #(STEP / 2) begin
        clk <= ~clk;
    end

    cpu_top cpu_top (
        .clk(clk),
        .reset(reset),
        .gpr_rs1_data(gpr_rs1_data),
        .gpr_rs2_data(gpr_rs2_data),
        .gpr_rs1_addr(gpr_rs1_addr),
        .gpr_rs2_addr(gpr_rs2_addr),
        .mem_rd_addr(mem_rd_addr),
        .mem_out(mem_out)
    );

    task cpu_top_tb;
        input [`WORD_DATA_BUS] _gpr_rs1_data;
        input [`WORD_DATA_BUS] _gpr_rs2_data;
        input [`REG_ADDR_BUS] _gpr_rs1_addr;
        input [`REG_ADDR_BUS] _gpr_rs2_addr;
        input [`REG_ADDR_BUS] _mem_rd_addr;
        input [`WORD_DATA_BUS] _mem_out;

        begin
            if((gpr_rs1_data  === _gpr_rs1_data)  &&
               (gpr_rs2_data  === _gpr_rs2_data)  &&
               (gpr_rs1_addr  === _gpr_rs1_addr)  &&
               (gpr_rs2_addr  === _gpr_rs2_addr)  &&
               (mem_rd_addr   === _mem_rd_addr)  &&
               (mem_out       === _mem_out)
              ) begin
                $display("Test Succeeded !");
            end else begin
                $display("Test Failed !");
            end
            if(gpr_rs1_data  !== _gpr_rs1_data) begin
               $display("gpr_rs1_data:%d(%d)",gpr_rs1_data,_gpr_rs1_data);
            end
            // if(gpr_rs2_data  !== _gpr_rs2_addr) begin
            //    $display("gpr_rs2_data:%d(%d)",gpr_rs2_data,_gpr_rs2_data);
            // end
            if(gpr_rs1_addr  !== _gpr_rs1_addr) begin
               $display("gpr_rs1_addr:%d(%d)",gpr_rs1_addr,_gpr_rs1_addr);
            end
            if(gpr_rs2_addr  !== _gpr_rs2_addr) begin
               $display("gpr_rs2_addr:%d(%d)",gpr_rs2_addr,_gpr_rs2_addr);
            end
            if(mem_rd_addr   !== _mem_rd_addr) begin
              $display("mem_rd_addr:%d(%d)",mem_rd_addr,_mem_rd_addr);
            end
            if(mem_out       !== _mem_out) begin
              $display("mem_out:%d(%d)",mem_out,_mem_out);
            end
        end

    endtask

    /******** Test Case ********/
    initial begin
      # 0 begin
        clk      <= 1'h1;
        reset    <= `ENABLE;
      end
      # (STEP * 3/4)
      # STEP begin
        /******** Initialize Test Output ********/
        reset <= `DISABLE;
      end
      # STEP begin
        $display("\n========= Clock 2 ========");
        cpu_top_tb(
                   `WORD_DATA_W'h0,                 // gpr_rs1_data
                   `WORD_DATA_W'hx,                 // gpr_rs2_data
                   `REG_ADDR_W'h0,                  // gpr_rs1_addr
                   `REG_ADDR_W'h1,                  // gpr_rs2_addr
                   `REG_ADDR_W'h0,                  // mem_rd_addr
                   `WORD_DATA_W'h0                  // mem_out
                   );
      end
      # STEP begin
        $display("\n========= Clock 3 ========");
        cpu_top_tb(
                   `WORD_DATA_W'h0,                 // gpr_rs1_data
                   `WORD_DATA_W'hx,                 // gpr_rs2_data
                   `REG_ADDR_W'h0,                  // gpr_rs1_addr
                   `REG_ADDR_W'd2,                  // gpr_rs2_addr
                   `REG_ADDR_W'h0,                  // mem_rd_addr
                   `WORD_DATA_W'h0                  // mem_out
                   );
      end
      # STEP begin
        $display("\n========= Clock 4 ========");
        cpu_top_tb(
                   `WORD_DATA_W'dx,                 // gpr_rs1_data
                   `WORD_DATA_W'dx,                 // gpr_rs2_data
                   `REG_ADDR_W'd26,                 // gpr_rs1_addr
                   `REG_ADDR_W'd27,                 // gpr_rs2_addr
                   `REG_ADDR_W'h0,                  // mem_rd_addr
                   `WORD_DATA_W'h0                  // mem_out
                   );
      end
      # STEP begin
        $display("\n========= Clock 5 ========");
        cpu_top_tb(
                   `WORD_DATA_W'd1025,              // gpr_rs1_data
                   `WORD_DATA_W'dx,                 // gpr_rs2_data
                   `REG_ADDR_W'd26,                 // gpr_rs1_addr
                   `REG_ADDR_W'd4,                  // gpr_rs2_addr
                   `REG_ADDR_W'd26,                 // mem_rd_addr
                   `WORD_DATA_W'd1025               // mem_out
                   );
      end
      # STEP begin
        $display("\n========= Clock 6 ========");
        cpu_top_tb(
                   `WORD_DATA_W'd0,                 // gpr_rs1_data
                   `WORD_DATA_W'dx,                 // gpr_rs2_data
                   `REG_ADDR_W'd0,                  // gpr_rs1_addr
                   `REG_ADDR_W'd20,                 // gpr_rs2_addr
                   `REG_ADDR_W'd27,                 // mem_rd_addr
                   `WORD_DATA_W'd2                  // mem_out
                   );
      end

      # STEP begin
        $display("\n========= Clock 7 ========");
        cpu_top_tb(
                   `WORD_DATA_W'd2,                 // gpr_rs1_data
                   `WORD_DATA_W'd1025,              // gpr_rs2_data
                   `REG_ADDR_W'd27,                 // gpr_rs1_addr
                   `REG_ADDR_W'd26,                 // gpr_rs2_addr
                   `REG_ADDR_W'd12,                 // mem_rd_addr
                   `WORD_DATA_W'd20                 // mem_out
                   );
      end

      # STEP begin
        $display("\n========= Clock 8 ========");
        cpu_top_tb(
                   `WORD_DATA_W'd0,                 // gpr_rs1_data
                   `WORD_DATA_W'd0,                 // gpr_rs2_data
                   `REG_ADDR_W'd0,                  // gpr_rs1_addr
                   `REG_ADDR_W'd0,                  // gpr_rs2_addr
                   `REG_ADDR_W'd27,                 // mem_rd_addr
                   `WORD_DATA_W'd1029               // mem_out
                   );
      end

      # STEP begin
        $display("\n========= Clock 9 ========");
        cpu_top_tb(
                   `WORD_DATA_W'd1025,              // gpr_rs1_data
                   `WORD_DATA_W'd1025,              // gpr_rs2_data
                   `REG_ADDR_W'd26,                 // gpr_rs1_addr
                   `REG_ADDR_W'd26,                 // gpr_rs2_addr
                   `REG_ADDR_W'd0,                  // mem_rd_addr
                   `WORD_DATA_W'd20                 // mem_out
                   );
      end // #

      # STEP begin
        $display("\n========= Clock 10 ========");
        cpu_top_tb(
                   `WORD_DATA_W'd1025,              // gpr_rs1_data
                   `WORD_DATA_W'dx,                 // gpr_rs2_data
                   `REG_ADDR_W'd26,                 // gpr_rs1_addr
                   `REG_ADDR_W'd3,                  // gpr_rs2_addr
                   `REG_ADDR_W'd0,                  // mem_rd_addr
                   `WORD_DATA_W'd0                  // mem_out
                   );
      end

      # STEP begin
        $display("\n========= Clock 11 ========");
        cpu_top_tb(
                   `WORD_DATA_W'd1025,              // gpr_rs1_data
                   `WORD_DATA_W'dx,                 // gpr_rs2_data
                   `REG_ADDR_W'd26,                 // gpr_rs1_addr
                   `REG_ADDR_W'd3,                  // gpr_rs2_addr
                   `REG_ADDR_W'd0,                  // mem_rd_addr
                   `WORD_DATA_W'd0                  // mem_out
                   );
      end

      # STEP begin
        $display("\n========= Clock 12 ========");
        cpu_top_tb(
                   `WORD_DATA_W'd1025,              // gpr_rs1_data
                   `WORD_DATA_W'd1029,              // gpr_rs2_data
                   `REG_ADDR_W'd26,                 // gpr_rs1_addr
                   `REG_ADDR_W'd27,                 // gpr_rs2_addr
                   `REG_ADDR_W'd3,                  // mem_rd_addr
                   `WORD_DATA_W'd0                  // mem_out
                   );
      end

      # STEP begin
        $display("\n========= Clock 13 ========");
        cpu_top_tb(
                   `WORD_DATA_W'd0,                 // gpr_rs1_data
                   `WORD_DATA_W'hx,                 // gpr_rs2_data
                   `REG_ADDR_W'd0,                  // gpr_rs1_addr
                   `REG_ADDR_W'd14,                 // gpr_rs2_addr
                   `REG_ADDR_W'd27,                 // mem_rd_addr
                   `WORD_DATA_W'd1                  // mem_out
                   );
      end

      # STEP begin
        $display("\n========= Clock 14 ========");
        cpu_top_tb(
                   `WORD_DATA_W'd1025,              // gpr_rs1_data
                   `WORD_DATA_W'hx,                 // gpr_rs2_data
                   `REG_ADDR_W'd26,                 // gpr_rs1_addr
                   `REG_ADDR_W'd28,                 // gpr_rs2_addr
                   `REG_ADDR_W'd30,                 // mem_rd_addr
                   `WORD_DATA_W'd1025               // mem_out
                   );
      end

      # STEP begin
        $display("\n========= Clock 15 ========");
        cpu_top_tb(
                   `WORD_DATA_W'd1,                 // gpr_rs1_data
                   `WORD_DATA_W'd1026,              // gpr_rs2_data
                   `REG_ADDR_W'd27,                 // gpr_rs1_addr
                   `REG_ADDR_W'd29,                 // gpr_rs2_addr
                   `REG_ADDR_W'd29,                 // mem_rd_addr
                   `WORD_DATA_W'd1026               // mem_out
                   );
      end

      # STEP begin
        $display("\n========= Clock 16 ========");
        cpu_top_tb(
                   `WORD_DATA_W'h1,                 // gpr_rs1_data
                   `WORD_DATA_W'd1025,              // gpr_rs2_data
                   `REG_ADDR_W'd27,                 // gpr_rs1_addr
                   `REG_ADDR_W'd30,                 // gpr_rs2_addr
                   `REG_ADDR_W'd28,                 // mem_rd_addr
                   `WORD_DATA_W'd14                 // mem_out
                   );
      end

      # STEP begin
        $display("\n========= Clock 17 ========");
        cpu_top_tb(
                   `WORD_DATA_W'd1025,              // gpr_rs1_data
                   `WORD_DATA_W'dx,                 // gpr_rs2_data
                   `REG_ADDR_W'd26,                 // gpr_rs1_addr
                   `REG_ADDR_W'd3,                  // gpr_rs2_addr
                   `REG_ADDR_W'd30,                 // mem_rd_addr
                   `WORD_DATA_W'd1039               // mem_out
                   );
      end
      # STEP begin
        $display("\n========= Clock 18 ========");
        cpu_top_tb(
                   `WORD_DATA_W'h0,                 // gpr_rs1_data
                   `WORD_DATA_W'd0,                 // gpr_rs2_data
                   `REG_ADDR_W'd0,                  // gpr_rs1_addr
                   `REG_ADDR_W'd0,                  // gpr_rs2_addr
                   `REG_ADDR_W'd27,                 // mem_rd_addr
                   `WORD_DATA_W'd1027               // mem_out
                   );
      end

      # STEP begin
        $display("\n========= Clock 19 ========");
        cpu_top_tb(
                   `WORD_DATA_W'd1027,              // gpr_rs1_data
                   `WORD_DATA_W'd1026,              // gpr_rs2_data
                   `REG_ADDR_W'd27,                 // gpr_rs1_addr
                   `REG_ADDR_W'd29,                 // gpr_rs2_addr
                   `REG_ADDR_W'd12,                 // mem_rd_addr
                   `WORD_DATA_W'd76                 // mem_out
                   );
      end

      # STEP begin
        $display("\n========= Clock 20 ========");
        cpu_top_tb(
                   `WORD_DATA_W'd1026,              // gpr_rs1_data
                   `WORD_DATA_W'd14,                // gpr_rs2_data
                   `REG_ADDR_W'd29,                 // gpr_rs1_addr
                   `REG_ADDR_W'd28,                 // gpr_rs2_addr
                   `REG_ADDR_W'd0,                  // mem_rd_addr
                   `WORD_DATA_W'd0                  // mem_out
                   );
      end
      # STEP begin
        $display("\n========= Clock 21 ========");
        cpu_top_tb(
                   `WORD_DATA_W'd1027,              // gpr_rs1_data
                   `WORD_DATA_W'd1026,              // gpr_rs2_data
                   `REG_ADDR_W'd27,                 // gpr_rs1_addr
                   `REG_ADDR_W'd29,                 // gpr_rs2_addr
                   `REG_ADDR_W'd0,                  // mem_rd_addr
                   `WORD_DATA_W'd0                  // mem_out
                   );
      end
      # STEP begin
        $display("\n========= Clock 22 ========");
        cpu_top_tb(
                   `WORD_DATA_W'd0,                 // gpr_rs1_data
                   `WORD_DATA_W'd0,                 // gpr_rs2_data
                   `REG_ADDR_W'd0,                  // gpr_rs1_addr
                   `REG_ADDR_W'd0,                  // gpr_rs2_addr
                   `REG_ADDR_W'd27,                 // mem_rd_addr
                   `WORD_DATA_W'd2053               // mem_out
                   );
      end
      # STEP begin
        $display("\n========= Clock 23 ========");
        cpu_top_tb(
                   `WORD_DATA_W'd1026,              // gpr_rs1_data
                   `WORD_DATA_W'd14,                // gpr_rs2_data
                   `REG_ADDR_W'd29,                 // gpr_rs1_addr
                   `REG_ADDR_W'd28,                 // gpr_rs2_addr
                   `REG_ADDR_W'd12,                 // mem_rd_addr
                   `WORD_DATA_W'd92                 // mem_out
                   );
      end
      # STEP begin
        $display("\n========= Clock 24 ========");
        cpu_top_tb(
                   `WORD_DATA_W'd1026,              // gpr_rs1_data
                   `WORD_DATA_W'd14,                // gpr_rs2_data
                   `REG_ADDR_W'd29,                 // gpr_rs1_addr
                   `REG_ADDR_W'd28,                 // gpr_rs2_addr
                   `REG_ADDR_W'd0,                  // mem_rd_addr
                   `WORD_DATA_W'd0                  // mem_out
                   );
      end
      # STEP begin
        $display("\n========= Clock 25 ========");
        cpu_top_tb(
                   `WORD_DATA_W'd1025,              // gpr_rs1_data
                   `WORD_DATA_W'd14,                // gpr_rs2_data
                   `REG_ADDR_W'd26,                 // gpr_rs1_addr
                   `REG_ADDR_W'd28,                 // gpr_rs2_addr
                   `REG_ADDR_W'd0,                  // mem_rd_addr
                   `WORD_DATA_W'd0                  // mem_out
                   );
      end
      # STEP begin
        $display("\n========= Clock 26 ========");
        cpu_top_tb(
                   `WORD_DATA_W'h0,                 // gpr_rs1_data
                   `WORD_DATA_W'h0,                 // gpr_rs2_data
                   `REG_ADDR_W'h0,                  // gpr_rs1_addr
                   `REG_ADDR_W'h0,                  // gpr_rs2_addr
                   `REG_ADDR_W'd12,                 // mem_rd_addr
                   `WORD_DATA_W'd104                // mem_out
                   );
      end 
      # STEP begin
        $display("\n========= Clock 27 ========");
        cpu_top_tb(
                   `WORD_DATA_W'd2053,              // gpr_rs1_data
                   `WORD_DATA_W'd1026,              // gpr_rs2_data
                   `REG_ADDR_W'd27,                 // gpr_rs1_addr
                   `REG_ADDR_W'd29,                 // gpr_rs2_addr
                   `REG_ADDR_W'd12,                 // mem_rd_addr
                   `WORD_DATA_W'd108                // mem_out
                   );
      end
      # STEP begin
        $finish;
      end
    end

  /******** Output Waveform ********/
    initial begin
       $dumpfile("cpu_top.vcd");
       $dumpvars(0, cpu_top);
    end

endmodule
