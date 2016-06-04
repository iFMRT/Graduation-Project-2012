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
    wire [`HART_ID_B]      hart_hid;
    wire [`HART_ID_B]      if_hart_id;
    wire [`HART_ID_B]      mem_hart_id;
    wire [`WORD_DATA_BUS]  mem_spm_addr;
    wire                   mem_spm_rw;
    wire [`WORD_DATA_BUS]  mem_spm_wr_data;

    reg                    i_cache_miss;
    reg                    i_cache_fin;
    reg  [`HART_ID_B]      i_cache_fin_hid;
    reg                    d_cache_miss;
    reg                    d_cache_fin;
    reg  [`HART_ID_B]      d_cache_fin_hid;
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
        .hart_issue_hid   (hart_hid),
        .if_hart_id       (if_hart_id),
        .mem_hart_id      (mem_hart_id),
        .hk_mem_spm_addr      (mem_spm_addr),
        .hk_mem_spm_rw        (mem_spm_rw),
        .hk_mem_spm_wr_data   (mem_spm_wr_data),

        .i_cache_miss         (i_cache_miss),
        .i_cache_fin          (i_cache_fin),
        .i_cache_fin_hid      (i_cache_fin_hid),
        .d_cache_miss         (d_cache_miss),
        .d_cache_fin          (d_cache_fin),
        .d_cache_fin_hid      (d_cache_fin_hid) 
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
    integer MAX = 10000;
    integer CYCLES = 0;
    always @(negedge clk) begin
        CYCLES = CYCLES + 1;
        MAX = MAX - 1;
        if (MAX === 0) begin
            $display("MAX!!!");
            $finish;
        end
        else if (mem_spm_addr === 32'd768) begin
            if (mem_spm_rw == `WRITE) begin
                if (mem_spm_wr_data === 32'd1)
                    $display("Hart[%d]: success. At cycles: %d", mem_hart_id, CYCLES);
                else
                    $display("Hart[%d]: failing !!! At cycles: %d", mem_hart_id, CYCLES);
            end
        end else if (if_pc === 32'd512) begin
            END = END + 1;
            $display("Hart[%d]: stop. At cycles: %d", hart_hid, CYCLES);
            if (END === 4) begin
                $display("Take cycles: %d", CYCLES);
                $finish;
            end
        end
    end

    // Test Cache Miss
    integer MISSED = 0;
    always @(negedge clk) begin
        if (reset) begin
            i_cache_miss    <= `DISABLE;
            d_cache_miss    <= `DISABLE;
            i_cache_fin     <= `DISABLE;
            d_cache_fin     <= `DISABLE;
            i_cache_fin_hid <= 2'b0;
            d_cache_fin_hid <= 2'b0;
        end 
        else if ((hart_hid === 2'b10)) begin
            if (CYCLES > 1000 && !MISSED) begin
                i_cache_miss <= `ENABLE;
                MISSED = 1;
            end
        end else if (CYCLES > 2000 && MISSED) begin
                i_cache_miss    <= `DISABLE;
                i_cache_fin     <= `ENABLE;
                i_cache_fin_hid <= 2'b10;
        end else begin
            i_cache_miss <= `DISABLE;
        end
    end
/*    
    always @(negedge clk) begin
        if (if_hart_id === 2'b01) begin
            $display("id stage pc: %8d, (%d) : %d", pc, mem_rd_addr, mem_out);
            $display("id stage pc: %h", pc);
        end
    end
*/
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
