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
`include "hart_ctrl.h"

`timescale 1ns/1ps

module cpu_top_test;
    reg                    clk;          // Clock
    reg                    reset;        // Asynchronous Reset
    wire [`WORD_DATA_BUS]  gpr_rs1_data; // Read data 0
    wire [`WORD_DATA_BUS]  gpr_rs2_data; // Read data 1
    wire [`REG_ADDR_BUS]   gpr_rs1_addr; // Read address 0
    wire [`REG_ADDR_BUS]   gpr_rs2_addr; // Read address 1
    wire [`REG_ADDR_BUS]   mem_rd_addr;  // General purpose register write address
    wire [`WORD_DATA_BUS]  mem_out;      // Operating result
    wire [`WORD_DATA_BUS]  if_pc;
    wire [`WORD_DATA_BUS]  pc;
    wire [`HART_ID_B]      if_hart_id;
    wire [`HART_ID_B]      mem_hart_id;
    wire [`WORD_DATA_BUS]  mem_spm_addr;
    wire                   mem_spm_rw;
    wire [`WORD_DATA_BUS]  mem_spm_wr_data;

    /******** Define Simulation Loop********/
    parameter             STEP = 10;

    /******** Generate Clock ********/
    always #(STEP / 2) begin
        clk <= ~clk;
    end

    cpu_top cpu_top (
        .clk              (clk),
        .reset            (reset),
        .gpr_rs1_data     (gpr_rs1_data),
        .gpr_rs2_data     (gpr_rs2_data),
        .gpr_rs1_addr     (gpr_rs1_addr),
        .gpr_rs2_addr     (gpr_rs2_addr),
        .mem_rd_addr      (mem_rd_addr),
        .mem_out          (mem_out),
        .if_pc            (if_pc),
        .pc               (pc),
        .if_hart_id       (if_hart_id),
        .mem_hart_id      (mem_hart_id),
        .hk_mem_spm_addr      (mem_spm_addr),
        .hk_mem_spm_rw        (mem_spm_rw),
        .hk_mem_spm_wr_data   (mem_spm_wr_data)
    );

    /******** Test Case ********/
    initial begin
        # 0 begin
            clk      <= 1'h1;
            reset    <= `ENABLE;
        end
        # (STEP * 3/4)
        # STEP begin
            reset <= `DISABLE;
        end

    end

    integer END = 0;
    integer TOTAL = 4000;
    always @(negedge clk) begin
        TOTAL = TOTAL - 1;
        if (TOTAL === 0)
            $finish;
        else if (mem_spm_addr === 32'd2560 || mem_spm_addr === 32'd5632) begin
            if (mem_spm_rw == `WRITE) begin
                if (mem_spm_wr_data === 32'd1) begin
                    $display("success");
                end else begin
                    $display("failed");
                end
            end
        end else if (if_pc === 32'd512 || if_pc === 32'd768) begin
            END = END + 1;
            $display("a hart stop");
            if (END === 1) begin
                $finish;
            end
        end
    end
    always @(negedge clk) begin
        if (if_hart_id === 2'b01) begin
            // $display("id stage pc: %8d, (%d) : %d", pc, mem_rd_addr, mem_out);
            $display("id stage pc: %h", pc);
        end
    end
    // always @(negedge clk) begin
    //     if (!reset) begin
    //         if (if_pc === 32'b0) begin
    //             END = END + 1;
    //             $display("END = %d.", END);
    //             if (END === 2) begin
    //                 $display("Failed");
    //                 $finish;
    //             end
    //         end else if (if_pc === 32'd768) begin
    //             $display("END = %d.", END);
    //             $display("Success.");
    //             $finish;
    //             // end
    //         end
    //     end
    // end
    // always @(negedge clk) begin
    //     if (if_spm_rw == `WRITE) begin
    //         if (if_spm_addr === ) begin
    //             $display("%d.write_mem[%h] = %d", i, if_spm_addr, if_spm_wr_data);
    //         end
    //     end
    // end
 
	/******** Output Waveform ********/
    initial begin
       $dumpfile("cpu_top.vcd");
       $dumpvars(0, cpu_top);
    end

endmodule
