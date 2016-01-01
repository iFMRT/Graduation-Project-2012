`timescale 1ns/1ps

`include "stddef.h"
`include "cpu.h"
`include "mem.h"
`include "spm.h"
`include "alu.h"
`include "isa.h"
`include "ctrl.h"

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
    // ID/EX Pipeline  Register
    wire [`WORD_DATA_BUS]          id_pc;          // Program count
    wire                         id_en;          //  Pipeline data enable
    wire [`ALU_OP_BUS]             id_alu_op;      // ALU operation
    wire [`WORD_DATA_BUS]          id_alu_in_0;    // ALU input 0
    wire [`WORD_DATA_BUS]          id_alu_in_1;    // ALU input 1
    wire [`MEM_OP_BUS]             id_mem_op;      // Memory operation
    wire [`WORD_DATA_BUS]          id_mem_wr_data; // Memory Write data
    wire [`REG_ADDR_BUS]           id_dst_addr;    // GPRWrite  address
    wire                         id_gpr_we_;     // GPRWrite enable
    output                  id_gpr_mux_ex;
    output                  id_gpr_mux_mem;
    output [`WORD_DATA_BUS] id_gpr_wr_data;
    /**********  Pipeline Control Signal **********/
    // Stall  Signal
    reg                         if_stall;       // IF Stage
    // Flush Signal
    reg                         if_flush;       // IF Stage
    // Control Signal
    reg [`WORD_DATA_BUS]        new_pc;         // New PC
    reg [`WORD_DATA_BUS]        br_addr;        // Branch  address
    reg                         br_taken;       // Branch taken
    /********** General Purpose Register Signal **********/
    wire [`WORD_DATA_BUS]          gpr_rd_data_0;  // Read data 0
    wire [`WORD_DATA_BUS]          gpr_rd_data_1;  // Read data 1
    wire [`REG_ADDR_BUS]           gpr_rd_addr_0;  // Read  address 0
    wire [`REG_ADDR_BUS]           gpr_rd_addr_1;  // Read  address 1

    wire                         ex_en;          //  Pipeline data enable

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

    /********** ID Stage **********/
    id_stage id_stage (
        /********** Clock & Reset **********/
        .clk            (clk),              // Clock
        .reset          (reset),            // Asynchronous Reset
        /********** GPR Interface **********/
        .gpr_rd_data_0  (gpr_rd_data_0),    // Read data 0
        .gpr_rd_data_1  (gpr_rd_data_1),    // Read data 1
        .gpr_rd_addr_0  (gpr_rd_addr_0),    // Read  address 0
        .gpr_rd_addr_1  (gpr_rd_addr_1),    // Read  address 1
        /********** IF/ID Pipeline  Register **********/
        .if_pc          (if_pc),            // Program count
        .if_pc_plus4    (if_pc_plus4),   // Jump adn link return address
        .if_insn        (if_insn),          // Instruction
        .if_en          (if_en),            //  Pipeline data enable
        /********** ID/EX Pipeline  Register **********/
        .id_en          (id_en),            //  Pipeline data enable
        .id_alu_op      (id_alu_op),        // ALU operation
        .id_alu_in_0    (id_alu_in_0),      // ALU input 0
        .id_alu_in_1    (id_alu_in_1),      // ALU input 1
        .id_mem_op      (id_mem_op),        // Memory operation
        .id_mem_wr_data (id_mem_wr_data),   // Memory Write data
        .id_dst_addr    (id_dst_addr),      // GPRWrite  address
        .id_gpr_we_     (id_gpr_we_),       // GPRWrite enable
        .id_gpr_mux_ex  (id_gpr_mux_ex),
        .id_gpr_mux_mem (id_gpr_mux_mem),
        .id_gpr_wr_data (id_gpr_wr_data)
    );

    /********** EX Stage **********/
    ex_stage ex_stage (
        /********** Clock & Reset **********/
         .clk            (clk),              // Clock
         .reset          (reset),            // Asynchronous Reset
         /********** ID/EX Pipeline  Register **********/
        
        
         .id_mem_op      (id_mem_op),        // Memory operation
         .id_mem_wr_data (id_mem_wr_data),   // Memory Write data
         .id_dst_addr    (id_dst_addr),      // General purpose RegisterWrite  address
         .id_gpr_we_     (id_gpr_we_),       // General purpose RegisterWrite enable
         /********** EX/MEM Pipeline  Register **********/

         .ex_mem_op      (ex_mem_op),        // Memory operation
         .ex_mem_wr_data (ex_mem_wr_data),   // Memory Write data
         .ex_dst_addr    (ex_dst_addr),      // General purpose RegisterWrite address
         .ex_gpr_we_     (ex_gpr_we_),       // General purpose RegisterWrite enable
         
         .alu_op         (alu_op),           // ALU operation
         .alu_in_0       (alu_in_0),         // ALU input 0
         .alu_in_1       (alu_in_1),         // ALU input 1
         .ex_out         (ex_out)            // Operating result
    );
    
    /********** General purpose Register **********/
    gpr gpr (
     /********** Clock & Reset **********/
     .clk       (clk),                   // Clock
     .reset     (reset),                 // Asynchronous Reset
     /********** Read Port  0 **********/
     .rd_addr_0 (gpr_rd_addr_0),         // Read  address
     .rd_data_0 (gpr_rd_data_0),         // Read data
     /********** Read Port  1 **********/
     .rd_addr_1 (gpr_rd_addr_1),         // Read  address
     .rd_data_1 (gpr_rd_data_1)         // Read data
     /********** Write Port  **********/
     // .we_       (mem_gpr_we_),           // Write enable
     // .wr_addr   (mem_dst_addr),          // Write  address
     // .wr_data   (mem_out)                //  Write data
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
            if( (if_pc        == `WORD_DATA_W'h4)    &&
                (if_pc_plus4  == `WORD_DATA_W'h8)    &&
                (if_insn      == `WORD_DATA_W'h400093)         &&
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
            if( (if_pc        == `WORD_DATA_W'h8)          &&
                (if_pc_plus4  == `WORD_DATA_W'hc)          &&
                (if_insn      == `WORD_DATA_W'h40102023)   &&
                (id_en        == `ENABLE) &&
                (id_alu_op    == `ALU_OP_ADD) &&
                (id_alu_in_0  == `WORD_DATA_W'h0) &&
                (id_alu_in_1  == `WORD_DATA_W'h4) &&
                (id_mem_op    == `MEM_OP_NOP) &&
                (id_mem_wr_data == `WORD_DATA_W'h0) &&
                (id_dst_addr  == `REG_ADDR_W'h1) &&
                (id_gpr_we_   ==  `ENABLE_) &&
                (id_gpr_mux_ex == `EX_EX_OUT) &&
                (id_gpr_mux_mem == `MEM_EX_OUT) &&
                (id_gpr_wr_data == `WORD_DATA_W'h8) &&
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
       $dumpvars(0,if_stage, spm, id_stage, gpr);
    end

endmodule
