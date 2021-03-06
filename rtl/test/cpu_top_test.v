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
    wire                   mem_gpr_we_;
    wire [`WORD_DATA_BUS]  if_pc;
    wire [`WORD_DATA_BUS]  pc;
    wire [`HART_ID_B]      hart_hid;
    wire [`HART_ID_B]      if_hart_id;
    wire [`HART_ID_B]      ex_hart_id;
    wire [`HART_ID_B]      mem_hart_id;
    wire [`WORD_DATA_BUS]  mem_spm_addr;
    wire                   mem_spm_rw;
    wire [`WORD_DATA_BUS]  mem_spm_wr_data;

    wire [`WORD_DATA_BUS]  ex_out;
    wire [`WORD_DATA_BUS]  wr_data;
    wire                   rw;
    wire                   i_cache_miss;
    wire                   i_cache_fin;
    wire [`HART_ID_B]      i_cache_fin_hid;
    wire                   d_cache_miss;
    wire                   d_cache_fin;
    wire [`HART_ID_B]      d_cache_fin_hid;
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
        .mem_gpr_we_      (mem_gpr_we_),
        .if_pc            (if_pc),
        .pc               (pc),
        .hart_issue_hid   (hart_hid),
        .if_hart_id       (if_hart_id),
        .ex_hart_id       (ex_hart_id),
        .mem_hart_id      (mem_hart_id),

        .ex_out          (ex_out),
        .wr_data          (wr_data),
        .rw               (rw),

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

    // reg [`WORD_DATA_BUS] ex_alu_out;
    // always @(posedge clk) begin
    //     if(reset) begin
    //         ex_alu_out <= 32'b0;
    //     end else begin
    //         ex_alu_out <= alu_out;
    //     end
    // end

    integer END = 0;
    integer MAX = 15000;
    integer CYCLES = 0;
    always @(negedge clk) begin
        CYCLES = CYCLES + 1;
        MAX = MAX - 1;
        
        if (hart_hid == 2'b01) begin
            $display("pc:%h,mem_rd_addr:%d,mem_out:%d,mem_gpr_we_:%d", pc, mem_rd_addr,mem_out,mem_gpr_we_);
        end 
        // if (rw == `WRITE) begin
        //     $display("ex_out:%h,wr_data:%d", ex_out,wr_data);
        // end
        if (MAX === 0) begin
            $display("MAX!!!");
            $stop;
        end else if (ex_out === 32'd768) begin
            if (rw == `WRITE) begin
                if (wr_data === 32'd1)
                    $display("Hart[%d]: success. At cycles: %d", mem_hart_id, CYCLES);
                else
                    $display("Hart[%d]: failing !!! At cycles: %d", mem_hart_id, CYCLES);
            end
        end else if (if_pc === 32'd512) begin
            END = END + 1;
            $display("Hart[%d]: stop. At cycles: %d", hart_hid, CYCLES);
            if (END === 1) begin
                $display("Take cycles: %d", CYCLES);
                $stop;
            end
        end
    end

    // Test Cache Miss
    // integer hart_0_miss_ed = 0;
    // integer hart_1_miss_ed = 0;
    // integer hart_0_fin_ed = 0;
    // integer hart_1_fin_ed = 0;
    // integer hart_1_dcm_ed = 0;
    // integer hart_1_dcf_ed = 0;
    // always @(negedge clk) begin
    //     if (reset) begin
    //         i_cache_miss    <= `DISABLE;
    //         d_cache_miss    <= `DISABLE;
    //         i_cache_fin     <= `DISABLE;
    //         d_cache_fin     <= `DISABLE;
    //         i_cache_fin_hid <= 2'b0;
    //         d_cache_fin_hid <= 2'b0;
    //     end else if (!hart_0_miss_ed && CYCLES > 1000 && hart_hid == 2'd0) begin
    //         hart_0_miss_ed = 1;
    //         i_cache_miss    <= `ENABLE;
    //     end else if (!hart_1_miss_ed && CYCLES > 1300 && hart_hid == 2'd2) begin
    //         hart_1_miss_ed = 1;
    //         i_cache_miss    <= `ENABLE;
    //     end else if (hart_1_miss_ed && !hart_1_fin_ed && CYCLES > 2000) begin
    //         i_cache_fin     <= `ENABLE;
    //         i_cache_fin_hid <= 2'd2;
    //         hart_1_fin_ed   = 1;
    //     end else if (hart_0_miss_ed && !hart_0_fin_ed && CYCLES > 2100) begin
    //         i_cache_fin     <= `ENABLE;
    //         i_cache_fin_hid <= 2'd0;
    //         hart_0_fin_ed   = 1;
    //     end else if (!hart_1_dcm_ed && ex_hart_id == 2'd2 && CYCLES > 2200) begin
    //         d_cache_miss    <= `ENABLE;
    //         hart_1_dcm_ed   = 1;
    //     end else if(hart_1_dcm_ed && !hart_1_dcf_ed && CYCLES > 2400) begin
    //         d_cache_fin     <= `ENABLE;
    //         d_cache_fin_hid <= 2'd2;
    //         hart_1_dcf_ed   = 1;
    //     end else begin
    //         i_cache_miss    <= `DISABLE;
    //         d_cache_miss    <= `DISABLE;
    //         i_cache_fin     <= `DISABLE;
    //         d_cache_fin     <= `DISABLE;
    //         i_cache_fin_hid <= 2'b0;
    //         d_cache_fin_hid <= 2'b0;
    //     end
    // end
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
