`timescale 1ns/1ps

`include "stddef.h"
`include "cpu.h"
`include "mem.h"
`include "spm.h"
`include "isa.h"

module cpu_test;
    /********** Clock & Reset **********/
    reg                        clk;            // Clock
    wire                       clk_;           // Reverse Clock
    reg                        reset;          // Asynchronous Reset
     /**********  Pipeline  Register **********/
    // IF/ID
    wire [`WORD_DATA_BUS]        if_pc;          // Program count
    wire [`WORD_DATA_BUS]        if_pc_plus4;          // Program count
    wire [`WORD_DATA_BUS]        if_insn;        // Instruction
    wire                         if_en;          //  Pipeline data enable
    /**********  Pipeline Control Signal **********/
    // Stall  Signal
    reg                         if_stall;       // IF Stage
    // Flush Signal
    reg                         if_flush;       // IF Stage
    // Control Signal
    reg [`WORD_DATA_BUS]        new_pc;         // New PC
    reg [`WORD_DATA_BUS]        br_addr;        // Branch  address
    reg                         br_taken;       // Branch taken
    /********** Scratch Pad Memory Signal **********/
    // IF Stage
    wire [`WORD_DATA_BUS]        if_spm_rd_data;  // Read data
    wire [`WORD_ADDR_BUS]        if_spm_addr;     //  address
    wire                         if_spm_as_;      //  address strobe
    wire                         if_spm_rw;       // Read/Write
    wire [`WORD_DATA_BUS]        if_spm_wr_data;  //  Write data

    /******** Define Simulation Loop********/
    parameter             STEP = 10;

    /******** Generate Clock ********/
    always #(STEP / 2) begin
        clk <= ~clk;
    end

    assign clk_ = ~clk;


    /********** IF Stage **********/
    if_stage if_stage (
        /********** Clock & Reset **********/
        .clk            (clk),              // Clock
        .reset          (reset),            // Asynchronous Reset
        /********** SPM Interface **********/
        .spm_rd_data    (if_spm_rd_data),   // Read data
        .spm_addr       (if_spm_addr),      //  address
        .spm_as_        (if_spm_as_),       //  address strobe
        .spm_rw         (if_spm_rw),        // Read/Write
        .spm_wr_data    (if_spm_wr_data),   //  Write data
        /**********  Pipeline Control Signal **********/
        .stall          (if_stall),         // Stall 
        .flush          (if_flush),         // Flush
        .new_pc         (new_pc),           // New PC
        .br_taken       (br_taken),         // Branch taken
        .br_addr        (br_addr),          // Branch address
        /********** IF/ID Pipeline Register **********/
        .if_pc          (if_pc),            // Program count
        .if_pc_plus4    (if_pc_plus4),      // Next PC
        .if_insn        (if_insn),          // Instruction
        .if_en          (if_en)             //  Pipeline data enable
    );

    /********** Scratch Pad Memory **********/
    spm spm (
        /********** Clock **********/
        .clk             (clk_),                      // Clock
        /********** Port A: IF Stage **********/
        .if_spm_addr     (if_spm_addr[`SpmAddrLoc]),  //  address
        .if_spm_as_      (if_spm_as_),                //  address strobe
        .if_spm_rw       (if_spm_rw),                 // Read/Write
        .if_spm_wr_data  (if_spm_wr_data),            //  Write data
        .if_spm_rd_data  (if_spm_rd_data)             // Read data
        /********** Port B: MEM Stage **********/
        // .mem_spm_addr     (mem_spm_addr[`SpmAddrLoc]), //  address
        // .mem_spm_as_  (mem_spm_as_),               //  address strobe
        // .mem_spm_rw       (mem_spm_rw),                // Read/Write
        // .mem_spm_wr_data (mem_spm_wr_data),            //  Write data
        // .mem_spm_rd_data (mem_spm_rd_data)             // Read data
    );
    
    /******** Test Case ********/
    initial begin
        # 0 begin
            clk            <= 1'h1;
            reset          <= `ENABLE;
            if_stall       <= `DISABLE;
            if_flush       <= `DISABLE; 
            new_pc         <= `WORD_ADDR_W'hx;  // don't care
            br_taken       <= `DISABLE;
            br_addr        <=  `WORD_DATA_W'hx; // don't care
        end
        # (STEP * 3/4)
        # STEP begin
            /******** Initialize Test Output ********/
            if ( (if_pc        == `WORD_DATA_W'h0)    &&
                 (if_pc_plus4  == `WORD_DATA_W'h4)    &&
                 (if_insn      == `ISA_NOP)           &&
                 (if_en        == `DISABLE)    
               ) begin
                $display("CPU Initialize Test Succeeded !");
            end else begin
                $display("CPU Initialize Test Failed !");
            end
            // Case: read the word 0x41a4d9 from address 0x154
            /******** Read a Word(align) Test Input ********/
            reset          <= `DISABLE;
        end
        # STEP begin
            /******** Initialize Test Output ********/
            if ( (if_pc        == `WORD_DATA_W'h4)    &&
                 (if_pc_plus4  == `WORD_DATA_W'h8)    &&
                 (if_insn      == `WORD_DATA_W'h0c008000)         &&
                 (if_en        == `ENABLE)    
               ) begin
                $display("Read a Instruction Test Succeeded !");
            end else begin
                $display("Read a Instruction Test Failed !");
            end
            // Case: read the word 0x41a4d9 from address 0x154
            /******** Read a Word(align) Test Input ********/
        end
        # STEP begin
            /******** Initialize Test Output ********/
            if ( (if_pc        == `WORD_DATA_W'h8)    &&
                 (if_pc_plus4  == `WORD_DATA_W'hc)    &&
                 (if_insn      == `WORD_DATA_W'h0c21ffff)   &&
                 (if_en        == `ENABLE)    
               ) begin
                $display("Read Next a Instruction Test Succeeded !");
            end else begin
                $display("Read Next a Instruction Test Failed !");
            end
            // Case: read the word 0x41a4d9 from address 0x154
            /******** Read a Word(align) Test Input ********/
            $finish;
        end
    end

    /******** Output Waveform ********/
    initial begin
       $dumpfile("cpu.vcd");
       $dumpvars(0,if_stage, spm);
    end

endmodule