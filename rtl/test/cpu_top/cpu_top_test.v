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
               (mem_rd_addr  === _mem_rd_addr)  &&
               (mem_out  === _mem_out)
              ) begin
                $display("Test Succeeded !");
            end else begin
                $display("Test Failed !");
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
        # (STEP) begin
            $display("\n========= Clock 2 ========");
            cpu_top_tb(
              `WORD_DATA_W'h0, // gpr_rs1_data
              `WORD_DATA_W'hx, // gpr_rs2_data
              `WORD_ADDR_W'h0, // gpr_rs1_addr
              `WORD_ADDR_W'h4, // gpr_rs2_addr
              `WORD_ADDR_W'h0, // mem_rd_addr
              `WORD_DATA_W'h0 // mem_out
            );
        end
        # STEP begin
            $display("\n========= Clock 3 ========");
            cpu_top_tb(
                `WORD_DATA_W'h0,                 // gpr_rs1_data
                `WORD_DATA_W'hx,                 // gpr_rs2_data
                `REG_ADDR_W'h0,                  // gpr_rs1_addr
                `REG_ADDR_W'h1e,                 // gpr_rs2_addr
                `REG_ADDR_W'h0,                  // mem_rd_addr
                `WORD_DATA_W'h0                  // mem_out
            );
        end
        # STEP begin
            $display("\n========= Clock 4 ========");
            cpu_top_tb(
                `WORD_DATA_W'h0,                 // gpr_rs1_data
                `WORD_DATA_W'hx,                 // gpr_rs2_data
                `REG_ADDR_W'h0,                  // gpr_rs1_addr
                `REG_ADDR_W'h1e,                  // gpr_rs2_addr
                `REG_ADDR_W'h0,                  // mem_rd_addr
                `WORD_DATA_W'h0                  // mem_out
            );
        end
        # STEP begin
            $display("\n========= Clock 5 ========");
            cpu_top_tb(
                `WORD_DATA_W'h4,                 // gpr_rs1_data
                `WORD_DATA_W'hx,                 // gpr_rs2_data
                `REG_ADDR_W'h1,                  // gpr_rs1_addr
                `REG_ADDR_W'h5,                  // gpr_rs2_addr
                `REG_ADDR_W'h1,                  // mem_rd_addr
                `WORD_DATA_W'h4                  // mem_out
            );
        end
        # STEP begin
            $display("\n========= Clock 6 ========");
            cpu_top_tb(
                `WORD_DATA_W'h0,                 // gpr_rs1_data
                `WORD_DATA_W'hx,                 // gpr_rs2_data
                `REG_ADDR_W'h2,                  // gpr_rs1_addr
                `REG_ADDR_W'h1a,                 // gpr_rs2_addr
                `REG_ADDR_W'h2,                  // mem_rd_addr
                `WORD_DATA_W'h0                  // mem_out
            );
        end
        # STEP begin
        $display("\n========= Clock 7 ========");
            cpu_top_tb(
                `WORD_DATA_W'h1,                 // gpr_rs1_data
                `WORD_DATA_W'hx,                 // gpr_rs2_data
                `REG_ADDR_W'h3,                  // gpr_rs1_addr
                `REG_ADDR_W'h7,                  // gpr_rs2_addr
                `REG_ADDR_W'h3,                  // mem_rd_addr
                `WORD_DATA_W'h1                  // mem_out
            );
        end
        # STEP begin
            $display("\n========= Clock 8 ========");
            cpu_top_tb(
                `WORD_DATA_W'h1,                 // gpr_rs1_data
                `WORD_DATA_W'h1,                 // gpr_rs2_data
                `REG_ADDR_W'h4,                  // gpr_rs1_addr
                `REG_ADDR_W'h3,                  // gpr_rs2_addr
                `REG_ADDR_W'h4,                  // mem_rd_addr
                `WORD_DATA_W'h1                  // mem_out
            );
        end
        # STEP begin
            $display("\n========= Clock 9 ========");
            cpu_top_tb(
                `WORD_DATA_W'hfffffffa,          // gpr_rs1_data
                `WORD_DATA_W'h0,                 // gpr_rs2_data
                `REG_ADDR_W'h5,                  // gpr_rs1_addr
                `REG_ADDR_W'h2,                  // gpr_rs2_addr
                `REG_ADDR_W'h5,                  // mem_rd_addr
                `WORD_DATA_W'hfffffffa                 // mem_out
            );
        end
        # STEP begin
            $display("\n========= Clock 10 ========");
            cpu_top_tb(
                `WORD_DATA_W'hfffffffa,                // gpr_rs1_data
                `WORD_DATA_W'h0,                 // gpr_rs2_data
                `REG_ADDR_W'h5,                  // gpr_rs1_addr
                `REG_ADDR_W'h2,                  // gpr_rs2_addr
                `REG_ADDR_W'h6,                  // mem_rd_addr
                `WORD_DATA_W'h1                  // mem_out
            );
        end
        # STEP begin
            $display("\n========= Clock 11 ========");
            cpu_top_tb(
                       `WORD_DATA_W'h0,                 // gpr_rs1_data
                       `WORD_DATA_W'h0,                 // gpr_rs2_data
                       `REG_ADDR_W'h2,                 // gpr_rs1_addr
                       `REG_ADDR_W'h0,                  // gpr_rs2_addr
                       `REG_ADDR_W'h7,                  // mem_rd_addr
                       `WORD_DATA_W'h8                  // mem_out
                       );
        end
        # STEP begin
            $display("\n========= Clock 12 ========");
            cpu_top_tb(
                       `WORD_DATA_W'h0,                 // gpr_rs1_data
                       `WORD_DATA_W'h0,                 // gpr_rs2_data
                       `REG_ADDR_W'h2,                 // gpr_rs1_addr
                       `REG_ADDR_W'h0,                  // gpr_rs2_addr
                       `REG_ADDR_W'h8,                  // mem_rd_addr
                       `WORD_DATA_W'h3ffffffe           // mem_out
                       );
        end
        # STEP begin
            $display("\n========= Clock 13 ========");
            cpu_top_tb(
                       `WORD_DATA_W'h4,                 // gpr_rs1_data
                       `WORD_DATA_W'h0,                 // gpr_rs2_data
                       `REG_ADDR_W'h1,                  // gpr_rs1_addr
                       `REG_ADDR_W'h2,                  // gpr_rs2_addr
                       `REG_ADDR_W'h9,                  // mem_rd_addr
                       `WORD_DATA_W'hfffffffe           // mem_out
                       );
        end
        # STEP begin
            $display("\n========= Clock 14 ========");
            cpu_top_tb(
                       `WORD_DATA_W'h1,                 // gpr_rs1_data
                       `WORD_DATA_W'h8,                 // gpr_rs2_data
                       `REG_ADDR_W'h6,                  // gpr_rs1_addr
                       `REG_ADDR_W'h7,                  // gpr_rs2_addr
                       `REG_ADDR_W'hc,                 // mem_rd_addr
                       `WORD_DATA_W'h14000              // mem_out
                       );
        end
        # STEP begin
            $display("\n========= Clock 15 ========");
            $display("%h", mem_rd_addr);
            $display("%h", mem_out);
            cpu_top_tb(
                       `WORD_DATA_W'hx,                 // gpr_rs1_data
                       `WORD_DATA_W'h4,                 // gpr_rs2_data
                       `REG_ADDR_W'ha,                 // gpr_rs1_addr
                       `REG_ADDR_W'h1,                  // gpr_rs2_addr
                       (`REG_ADDR_W)'hd,                 // mem_rd_addr
                       `WORD_DATA_W'h3c000              // mem_out
                       );
        end
    # STEP begin
        $display("\n========= Clock 16 ========");
        cpu_top_tb(
            `WORD_DATA_W'h1,                 // gpr_rs1_data
            `WORD_DATA_W'hfffffffa,          // gpr_rs2_data
            `REG_ADDR_W'h4,                  // gpr_rs1_addr
            `REG_ADDR_W'h5,                  // gpr_rs2_addr
            `REG_ADDR_W'd10,                 // mem_rd_addr
            `WORD_DATA_W'h4                  // mem_out
        );
        end

    # STEP begin
        $display("\n========= Clock 17 ========");
        cpu_top_tb(
            `WORD_DATA_W'h1,                 // gpr_rs1_data
            `WORD_DATA_W'hfffffffa,          // gpr_rs2_data
            `REG_ADDR_W'h4,                  // gpr_rs1_addr
            `REG_ADDR_W'h5,                  // gpr_rs2_addr
            `REG_ADDR_W'd11,                 // mem_rd_addr
            `WORD_DATA_W'hffffff9            // mem_out
        );
        end
    
    # STEP begin
        $display("\n========= Clock 18 ========");
        cpu_top_tb(
            `WORD_DATA_W'h8,                 // gpr_rs1_data
            `WORD_DATA_W'h3ffffffe,          // gpr_rs2_data
            `REG_ADDR_W'h7,                  // gpr_rs1_addr
            `REG_ADDR_W'h8,                  // gpr_rs2_addr
            `REG_ADDR_W'd20,                 // mem_rd_addr
            `WORD_DATA_W'd64                 // mem_out
        );
        end
    # STEP begin
        $display("\n========= Clock 19 ========");
        cpu_top_tb(
            `WORD_DATA_W'hfffffffa,          // gpr_rs1_data
            `WORD_DATA_W'h1,                 // gpr_rs2_data
            `REG_ADDR_W'h5,                  // gpr_rs1_addr
            `REG_ADDR_W'h3,                  // gpr_rs2_addr
            `REG_ADDR_W'd21,                 // mem_rd_addr
            `WORD_DATA_W'h0                  // mem_out
        );
        end
    
    # STEP begin
        $display("\n========= Clock 20 ========");
        cpu_top_tb(
            `WORD_DATA_W'hfffffffa,          // gpr_rs1_data
            `WORD_DATA_W'h1,                 // gpr_rs2_data
            `REG_ADDR_W'h5,                  // gpr_rs1_addr
            `REG_ADDR_W'h3,                  // gpr_rs2_addr
            `REG_ADDR_W'd22,                 // mem_rd_addr
            `WORD_DATA_W'h1                  // mem_out
        );
        end
    
    # STEP begin
        $display("\n========= Clock 21 ========");
        cpu_top_tb(
            `WORD_DATA_W'h3ffffffe,          // gpr_rs1_data
            `WORD_DATA_W'hfffffffe,          // gpr_rs2_data
            `REG_ADDR_W'h8,                  // gpr_rs1_addr
            `REG_ADDR_W'h9,                  // gpr_rs2_addr
            `REG_ADDR_W'h23,                 // mem_rd_addr
            `WORD_DATA_W'h3ffffff6           // mem_out
        );
        end
    # STEP begin
        $display("\n========= Clock 22 ========");
        cpu_top_tb(
            `WORD_DATA_W'h4,                 // gpr_rs1_data
            `WORD_DATA_W'hfffffff9,          // gpr_rs2_data
            `REG_ADDR_W'h10,                 // gpr_rs1_addr
            `REG_ADDR_W'h11,                 // gpr_rs2_addr
            `REG_ADDR_W'h24,                 // mem_rd_addr
            `WORD_DATA_W'h7ffffffe           // mem_out
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
