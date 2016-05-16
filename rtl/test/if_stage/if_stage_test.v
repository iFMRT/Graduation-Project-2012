/******** Time scale ********/
`timescale 1ns/1ps
////////////////////////////////////////////////////////////////////////
// Engineer:       Kippy Chen - 799182081@qq.com                      //
//                                                                    //
// Additional contributions by:                                       //
//                 Beyond Sky - fan-dave@163.com                      //
//                 Leway Colin - colin4124@gmail.com                  //
//                 Junhao Chen                                        //
//                                                                    //
// Design Name:    Instruction Fetch Stage                            //
// Project Name:   FMRT Mini Core                                     //
// Language:       Verilog                                            //
//                                                                    //
// Description:    Instruction fetch unit: Selection of the next PC.  //
//                                                                    //
////////////////////////////////////////////////////////////////////////

`include "common_defines.v"
`include "base_core_defines.v"

module if_stage_test;
    /********** clock & reset *********/
    reg                    clk;            // Clk
    reg                    reset;          // Reset
    /********* SPM Interface *********/
    reg   [`WORD_DATA_BUS] spm_rd_data;    // Address of reading SPM
    wire [`WORD_ADDR_BUS] spm_addr;       // Address of SPM
    wire                  spm_as_;        // SPM strobe
    wire                  spm_rw;         // Read/Write SPM
    wire [`WORD_DATA_BUS] spm_wr_data;    // Write data of SPM
    /******** Pipeline control ********/
    reg                    stall;          // Stall
    reg                    flush;          // Flush
    reg   [`WORD_DATA_BUS] new_pc;         // New value of program counter
    reg                    br_taken;       // Branch taken
    reg   [`WORD_DATA_BUS] br_addr;        // Branch target
    /******** IF/ID Pipeline Register ********/
    wire [`WORD_DATA_BUS] pc;             // Current Program counter
    wire [`WORD_DATA_BUS] if_pc;          // Next PC
    wire [`WORD_DATA_BUS] if_insn;        // Instruction
    wire                  if_en           // Effective mark of pipeline
;


    /******** Define Simulation Loop********/
    parameter             STEP = 10;

    /******** Generate Clock ********/
    always #(STEP / 2) begin
        clk <= ~clk;
    end

    assign clk_ = ~clk;

    if_stage if_stage (
        .clk(clk),
        .reset(reset),
        .spm_rd_data(spm_rd_data),
        .spm_addr(spm_addr),
        .spm_as_(spm_as_),
        .spm_rw(spm_rw),
        .spm_wr_data(spm_wr_data),
        .stall(stall),
        .flush(flush),
        .new_pc(new_pc),
        .br_taken(br_taken),
        .br_addr(br_addr),
        .pc(pc),
        .if_pc(if_pc),
        .if_insn(if_insn),
        .if_en(if_en)
    );

    task if_stage_tb;
        input [`WORD_ADDR_BUS] _spm_addr;
        input  _spm_as_;
        input  _spm_rw;
        input [`WORD_DATA_BUS] _spm_wr_data;
        input [`WORD_DATA_BUS] _pc;
        input [`WORD_DATA_BUS] _if_pc;
        input [`WORD_DATA_BUS] _if_insn;
        input  _if_en;

        begin
            if((spm_addr  === _spm_addr)  &&
               (spm_as_  === _spm_as_)  &&
               (spm_rw  === _spm_rw)  &&
               (spm_wr_data  === _spm_wr_data)  &&
               (pc  === _pc)  &&
               (if_pc  === _if_pc)  &&
               (if_insn  === _if_insn)  &&
               (if_en  === _if_en)
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
            stall <= `DISABLE;
            spm_rd_data <= `WORD_DATA_W'h128;
            reset <= `ENABLE;
            new_pc <= `WORD_DATA_W'h160;
            clk <= `ENABLE;
            br_taken <= `DISABLE;
            flush <= `DISABLE;
            br_addr <= `WORD_DATA_W'h128;
            end
        # (STEP * 3/4)
        # STEP begin
            $display("\n=== Initialize: Reset ===");
           if_stage_tb(
           	`WORD_ADDR_W'h0, // spm_addr
           	`ENABLE_, // spm_as_
           	`READ, // spm_rw
           	`WORD_DATA_W'h0, // spm_wr_data
           	`WORD_DATA_W'h0, // pc
           	`WORD_DATA_W'h0, // if_pc
           	`ISA_NOP, // if_insn
           	`DISABLE // if_en
           );
           
            reset <= `DISABLE;
           end
        
        # STEP begin
            $display("\n=== Clock 1: Next PC ===");
           if_stage_tb(
           	`WORD_ADDR_W'h1, // spm_addr
           	`ENABLE_, // spm_as_
           	`READ, // spm_rw
           	`WORD_DATA_W'h0, // spm_wr_data
           	`WORD_DATA_W'h0, // pc
           	`WORD_DATA_W'h4, // if_pc
           	`WORD_DATA_W'h128, // if_insn
           	`ENABLE // if_en
           );
           
            flush <= `ENABLE;
           end
        
        # STEP begin
            $display("\n=== Clock 2: Flush ===");
           if_stage_tb(
           	           `WORD_ADDR_W'h58, // spm_addr
           	           `DISABLE_, // spm_as_
           	           `READ, // spm_rw
           	           `WORD_DATA_W'h0, // spm_wr_data
           	           `WORD_DATA_W'h0, // pc
           	           `WORD_DATA_W'h160, // if_pc
           	           `ISA_NOP, // if_insn
           	           `DISABLE // if_en
           );
           
            br_taken <= `ENABLE;
           flush <= `DISABLE;
           end
        # STEP begin
            $display("\n=== Clock 3: Branch ===");
            if_stage_tb(
            	`WORD_ADDR_W'h4a, // spm_addr
            	`ENABLE_, // spm_as_
            	`READ, // spm_rw
            	`WORD_DATA_W'h0, // spm_wr_data
            	`WORD_DATA_W'h0, // pc
            	`WORD_DATA_W'h128, // if_pc
            	`ISA_NOP, // if_insn
            	`DISABLE // if_en
            );
            $finish;
        end
    end
	/******** Output Waveform ********/
    initial begin
       $dumpfile("if_stage.vcd");
       $dumpvars(0, if_stage);
    end

endmodule
