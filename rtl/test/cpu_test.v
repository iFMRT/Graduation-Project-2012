`timescale 1ns/1ps

`include "stddef.h"
`include "cpu.h"
`include "mem.h"
`include "spm.h"
`include "alu.h"
`include "isa.h"
`include "ctrl.h"
`include "ex_stage.h"

module cpu_test;
    /********** Clock & Reset **********/
    reg                        clk;            // Clock
    wire                       clk_;           // Reverse Clock
    reg                        reset;          // Asynchronous Reset
     /**********  Pipeline  Register **********/
    // IF/ID
    wire [`WORD_DATA_BUS]      if_pc;          // Program count
    wire [`WORD_DATA_BUS]      if_pc_plus4;    // Program count
    wire [`WORD_DATA_BUS]      if_insn;        // Instruction
    wire                       if_en;          //  Pipeline data enable
    // ID/EX Pipeline  Register
    wire [`WORD_DATA_BUS]      id_pc;          // Program count
    wire                       id_en;          //  Pipeline data enable
    wire [`ALU_OP_BUS]         id_alu_op;      // ALU operation
    wire [`WORD_DATA_BUS]      id_alu_in_0;    // ALU input 0
    wire [`WORD_DATA_BUS]      id_alu_in_1;    // ALU input 1
    wire [`MEM_OP_BUS]         id_mem_op;      // Memory operation
    wire [`WORD_DATA_BUS]      id_mem_wr_data; // Memory Write data
    wire [`REG_ADDR_BUS]       id_dst_addr;    // GPRWrite  address
    wire                       id_gpr_we_;     // GPRWrite enable
    output [`EX_OUT_SEL_BUS]   id_gpr_mux_ex;
    output [`WORD_DATA_BUS]    id_gpr_wr_data;
    // EX/MEM Pipeline  Register
    wire [`MEM_OP_BUS]         ex_mem_op;      // Memory operation
    wire [`WORD_DATA_BUS]      ex_mem_wr_data; // Memory Write data
    wire [`REG_ADDR_BUS]       ex_dst_addr;    // General purpose RegisterWrite  address
    wire                       ex_gpr_we_;     // General purpose RegisterWrite enable
    wire [`WORD_DATA_BUS]      ex_out;         // Operating result
    // MEM/WB Pipeline  Register
    wire [`REG_ADDR_BUS]       mem_dst_addr;   // General purpose RegisterWrite  address
    wire                       mem_gpr_we_;    // General purpose RegisterWrite enable
    wire [`WORD_DATA_BUS]      mem_out;        // Operating result
    /**********  Pipeline Control Signal **********/
    // Stall  Signal
    wire                       if_stall;       // IF Stage
    wire                       id_stall;       // ID Stage
    wire                       ex_stall;       // EX Stage
    wire                       mem_stall;      // MEM Stage
    // Flush Signal
    wire                       if_flush;       // IF Stage
    wire                       id_flush;       // ID Stage
    wire                       ex_flush;       // EX Stage
    wire                       mem_flush;      // MEM Stage
    // Control Signal
    wire [`WORD_DATA_BUS]       new_pc;         // New PC
    // reg [`WORD_DATA_BUS]       br_addr;        // Branch  address
    // reg                        br_taken;       // Branch taken
    wire                       ld_hazard;      // Hazard

    /********** General Purpose Register Signal **********/
    wire [`WORD_DATA_BUS]      gpr_rd_data_0;  // Read data 0
    wire [`WORD_DATA_BUS]      gpr_rd_data_1;  // Read data 1
    wire [`REG_ADDR_BUS]       gpr_rd_addr_0;  // Read  address 0
    wire [`REG_ADDR_BUS]       gpr_rd_addr_1;  // Read  address 1

    wire                       ex_en;          //  Pipeline data enable

    /********** Scratch Pad Memory Signal **********/
    // IF Stage
    wire [`WORD_DATA_BUS]      if_spm_rd_data;  // Read data
    wire [`WORD_ADDR_BUS]      if_spm_addr;     //  address
    wire                       if_spm_as_;      //  address strobe
    wire                       if_spm_rw;       // Read/Write
    wire [`WORD_DATA_BUS]      if_spm_wr_data;  //  Write data
    // MEM Stage
    wire [`WORD_DATA_BUS]      mem_spm_rd_data; // Read data
    wire [`WORD_ADDR_BUS]      mem_spm_addr;    //  address
    wire                       mem_spm_as_;     //  address strobe
    wire                       mem_spm_rw;      // Read/Write
    wire [`WORD_DATA_BUS]      mem_spm_wr_data; //  Write data
    /********** Forward  Signal **********/
    wire [`WORD_DATA_BUS]      ex_fwd_data;     // EX Stage
    wire [`WORD_DATA_BUS]      mem_fwd_data;    // MEM Stage

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
        .spm_addr       (if_spm_addr),      // Address
        .spm_as_        (if_spm_as_),       // Address strobe
        .spm_rw         (if_spm_rw),        // Read/Write
        .spm_wr_data    (if_spm_wr_data),   // Write data
        /**********  Pipeline Control Signal **********/
        .stall          (if_stall),         // Stall
        .flush          (if_flush),         // Flush
        .new_pc         (new_pc),           // New PC
        // .br_taken       (br_taken),         // Branch taken
        // .br_addr        (br_addr),          // Branch address
        /********** IF/ID Pipeline Register **********/
        .if_pc          (if_pc),            // Program count
        .if_pc_plus4    (if_pc_plus4),      // Next PC
        .if_insn        (if_insn),          // Instruction
        .if_en          (if_en)             // Pipeline data enable
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

        .ex_en          (ex_en),
        /********** Forward  **********/
        // EX Stage Forward 
        .ex_fwd_data    (ex_fwd_data),      // Forward data
        .ex_dst_addr    (ex_dst_addr),      // Write  address
        .ex_gpr_we_     (ex_gpr_we_),       // Write enable
        // MEM Stage Forward 
        .mem_fwd_data   (mem_fwd_data),     // Forward data
        /*********  Pipeline Control Signal *********/
        .stall          (id_stall),         // Stall 
        .flush          (id_flush),         // Flush
        .ld_hazard      (ld_hazard),        // Hazard
        /********** IF/ID Pipeline  Register **********/
        .if_pc          (if_pc),            // Program count
        .if_pc_plus4    (if_pc_plus4),      // Jump adn link return address
        .if_insn        (if_insn),          // Instruction
        .if_en          (if_en),            // Pipeline data enable
        /********** ID/EX Pipeline  Register **********/
        .id_en          (id_en),            // Pipeline data enable
        .id_alu_op      (id_alu_op),        // ALU operation
        .id_alu_in_0    (id_alu_in_0),      // ALU input 0
        .id_alu_in_1    (id_alu_in_1),      // ALU input 1
        .id_mem_op      (id_mem_op),        // Memory operation
        .id_mem_wr_data (id_mem_wr_data),   // Memory Write data
        .id_dst_addr    (id_dst_addr),      // GPRWrite  address
        .id_gpr_we_     (id_gpr_we_),       // GPRWrite enable
        .id_gpr_mux_ex  (id_gpr_mux_ex),
        .id_gpr_wr_data (id_gpr_wr_data)
    );

    /********** EX Stage **********/
    ex_stage ex_stage (
        /********** Clock & Reset **********/
        .clk            (clk),              // Clock
        .reset          (reset),            // Asynchronous Reset
        /**********  Pipeline Control Signal **********/
        .stall          (ex_stall),         // Stall 
        .flush          (ex_flush),         // Flush
        /********** Forward  **********/
        .fwd_data       (ex_fwd_data),      // Forward data
        /********** ID/EX Pipeline  Register **********/
        .id_en          (id_en),
        .id_alu_op      (id_alu_op),        // ALU operation
        .id_alu_in_0    (id_alu_in_0),       // ALU input 0
        .id_alu_in_1    (id_alu_in_1),       // ALU input 1

        .id_mem_op      (id_mem_op),        // Memory operation
        .id_mem_wr_data (id_mem_wr_data),   // Memory Write data
        .id_dst_addr    (id_dst_addr),      // General purpose RegisterWrite  address
        .id_gpr_we_     (id_gpr_we_),       // General purpose RegisterWrite enable
        .ex_out_sel     (id_gpr_mux_ex),
         /********** EX/MEM Pipeline  Register **********/
        .ex_en          (ex_en),  
        .ex_mem_op      (ex_mem_op),        // Memory operation
        .ex_mem_wr_data (ex_mem_wr_data),   // Memory Write data
        .ex_dst_addr    (ex_dst_addr),      // General purpose RegisterWrite address
        .ex_gpr_we_     (ex_gpr_we_),       // General purpose RegisterWrite enable
        .ex_out         (ex_out)            // Operating result
    );

    /********** MEM Stage **********/
    mem_stage mem_stage (
        /********** Clock & Reset **********/
        .clk            (clk),              // Clock
        .reset          (reset),            // Asynchronous Reset
        /**********  Pipeline Control Signal **********/
        .stall          (mem_stall),        // Stall 
        .flush          (mem_flush),        // Flush
        /********** Forward  **********/
        .fwd_data       (mem_fwd_data),     // Forward data
        /********** SPM Interface **********/
        .spm_rd_data    (mem_spm_rd_data),  // Read data
        .spm_addr       (mem_spm_addr),     //  address
        .spm_as_        (mem_spm_as_),      //  address strobe
        .spm_rw         (mem_spm_rw),       // Read/Write
        .spm_wr_data    (mem_spm_wr_data),  //  Write data
        /********** EX/MEM Pipeline  Register **********/
        .ex_en          (ex_en),
        .ex_mem_op      (ex_mem_op),        // Memory operation
        .ex_mem_wr_data (ex_mem_wr_data),   // Memory Write data
        .ex_dst_addr    (ex_dst_addr),      // General purpose RegisterWrite address
        .ex_gpr_we_     (ex_gpr_we_),       // General purpose RegisterWrite enable
        .ex_out         (ex_out),           // Operating result

        /********** MEM/WB Pipeline  Register **********/
        .mem_en         (mem_en),
        .mem_dst_addr   (mem_dst_addr),     // General purpose RegisterWrite address
        .mem_gpr_we_    (mem_gpr_we_),      // General purpose RegisterWrite enable
        .mem_out        (mem_out)           // Operating result
    );

     /********** Control Module **********/
    ctrl ctrl (
        /**********  Pipeline Control Signal **********/
        //  Pipeline Status
        .ld_hazard      (ld_hazard),        // Load hazard
        // Stall  Signal
        .if_stall       (if_stall),         // IF Stage Stall 
        .id_stall       (id_stall),         // ID Stage Stall 
        .ex_stall       (ex_stall),         // EX Stage Stall 
        .mem_stall      (mem_stall),        // MEM Stage Stall 
        // Flush Signal
        .if_flush       (if_flush),         // IF StageFlush
        .id_flush       (id_flush),         // ID StageFlush
        .ex_flush       (ex_flush),         // EX StageFlush
        .mem_flush      (mem_flush),        // MEM StageFlush
        .new_pc         (new_pc)
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
        .rd_data_1 (gpr_rd_data_1),         // Read data
        /********** Write Port  **********/
        .we_       (mem_gpr_we_),           // Write enable
        .wr_addr   (mem_dst_addr),          // Write  address
        .wr_data   (mem_out)                //  Write data
    );

    /********** Scratch Pad Memory **********/
    spm spm (
        /********** Clock **********/
        .clk             (clk_),                      // Clock
        /********** Port A: IF Stage **********/
        .if_spm_addr     (if_spm_addr[`SPM_ADDR_LOC]),  //  address
        .if_spm_as_      (if_spm_as_),                //  address strobe
        .if_spm_rw       (if_spm_rw),                 // Read/Write
        .if_spm_wr_data  (if_spm_wr_data),            //  Write data
        .if_spm_rd_data  (if_spm_rd_data),            // Read data
        /********** Port B: MEM Stage **********/
        .mem_spm_addr    (mem_spm_addr[`SPM_ADDR_LOC]), //  address
        .mem_spm_as_     (mem_spm_as_),               //  address strobe
        .mem_spm_rw      (mem_spm_rw),                // Read/Write
        .mem_spm_wr_data (mem_spm_wr_data),           //  Write data
        .mem_spm_rd_data (mem_spm_rd_data)            // Read data
    );

    task if_tb;
        input [`WORD_DATA_BUS] _if_pc;
        input [`WORD_DATA_BUS] _if_pc_plus4;
        input [`WORD_DATA_BUS] _if_insn;
        input                  _if_en;

        begin
            if( (if_pc       == _if_pc)        &&
                (if_pc_plus4 == _if_pc_plus4)  &&
                (if_insn     == _if_insn)      &&
                (if_en       == _if_en)
              ) begin
                $display("IF  Stage Test Succeeded !");
            end else begin
                $display("IF  Stage Test Failed !");
            end
        end
    endtask

    task id_tb;
        input                   _ld_hazard;
        input                   _id_en;          //  Pipeline data enable
        input [`ALU_OP_BUS]     _id_alu_op;      // ALU operation
        input [`WORD_DATA_BUS]  _id_alu_in_0;    // ALU input 0
        input [`WORD_DATA_BUS]  _id_alu_in_1;    // ALU input 1
        input [`MEM_OP_BUS]     _id_mem_op;      // Memory operation
        input [`WORD_DATA_BUS]  _id_mem_wr_data; // Memory Write data
        input [`REG_ADDR_BUS]   _id_dst_addr;    // GPRWrite  address
        input                   _id_gpr_we_;     // GPRWrite enable
        input [`EX_OUT_SEL_BUS] _id_gpr_mux_ex;
        input [`WORD_DATA_BUS]  _id_gpr_wr_data;

        begin
            if( (ld_hazard      == _ld_hazard)      &&
                (id_en          == _id_en)          &&
                (id_alu_op      == _id_alu_op)      &&
                (id_alu_in_0    == _id_alu_in_0)    &&
                (id_alu_in_1    == _id_alu_in_1)    &&
                (id_mem_op      == _id_mem_op)      &&
                (id_mem_wr_data == _id_mem_wr_data) &&
                (id_dst_addr    == _id_dst_addr)    &&
                (id_gpr_we_     == _id_gpr_we_)     &&
                (id_gpr_mux_ex  == _id_gpr_mux_ex)  &&
                (id_gpr_wr_data == _id_gpr_wr_data)
              ) begin
                $display("ID  Stage Test Succeeded !");
            end else begin
                $display("ID  Stage Test Failed !");
            end
        end
    endtask

    task ex_tb;
        input [`WORD_DATA_BUS]     _ex_fwd_data;
        input                      _ex_en; 
        input [`MEM_OP_BUS]        _ex_mem_op;      // Memory operation
        input [`WORD_DATA_BUS]     _ex_mem_wr_data; // Memory Write data
        input [`REG_ADDR_BUS]      _ex_dst_addr;    // General purpose RegisterWrite  address
        input                      _ex_gpr_we_;     // General purpose RegisterWrite enable
        input [`WORD_DATA_BUS]     _ex_out;         // Operating result

        begin
            if( (ex_fwd_data    == _ex_fwd_data)     &&
                (ex_en          == _ex_en)           &&
                (ex_mem_op      == _ex_mem_op)       &&      // Memory operation
                (ex_mem_wr_data == _ex_mem_wr_data)  &&      // Memory Write data
                (ex_dst_addr    == _ex_dst_addr)     &&      // General purpose RegisterWrite address
                (ex_gpr_we_     == _ex_gpr_we_)      &&      // General purpose RegisterWrite enable
                (ex_out         == _ex_out)                  // Operating result
              ) begin
                $display("EX  Stage Test Succeeded !");
            end else begin
                $display("EX  Stage Test Failed !");
            end
        end
    endtask

    task mem_tb;
        input [`WORD_DATA_BUS]        _mem_fwd_data;
        input                         _mem_en;
        input [`REG_ADDR_BUS]         _mem_dst_addr; // General purpose RegisterWrite  address
        input                         _mem_gpr_we_;  // General purpose RegisterWrite enable
        input [`WORD_DATA_BUS]        _mem_out;      // Operating result

        begin
            if( (mem_fwd_data  == _mem_fwd_data)     &&      
                (mem_en        == _mem_en)           &&      
                (mem_dst_addr  == _mem_dst_addr)     &&      // Memory operation
                (mem_gpr_we_   == _mem_gpr_we_)      &&      // Memory Write data
                (mem_out       == _mem_out)                  // General purpose RegisterWrite address
              ) begin
                $display("MEM Stage Test Succeeded !");
            end else begin
                $display("MEM Stage Test Failed !");
            end
        end
    endtask

    task ctrl_tb;
        input                   _if_stall;     // IF stage stall 
        input                   _id_stall;     // ID stage stall 
        input                   _ex_stall;     // EX stage stall 
        input                   _mem_stall;    // MEM stage stall 

        input                   _if_flush;     // IF stage flush
        input                   _id_flush;     // ID stage flush
        input                   _ex_flush;     // EX stage flush
        input                   _mem_flush;    // MEM stage flush

        input [`WORD_DATA_BUS]  _new_pc;

        begin
            if( (if_stall  == _if_stall)     &&      
                (id_stall  == _id_stall)     &&      
                (ex_stall  == _ex_stall)     &&
                (mem_stall == _mem_stall)    &&
                (if_flush  == _if_flush)     &&
                (id_flush  == _id_flush)     &&
                (ex_flush  == _ex_flush)     &&
                (mem_flush == _mem_flush)    &&
                (new_pc    == _new_pc)
              ) begin
                $display("Ctrl      Test Succeeded !");
            end else begin
                $display("Ctrl      Test Failed !");
            end
        end

    endtask
    /******** Test Case ********/
    initial begin
        # 0 begin
            clk      <= 1'h1;
            reset    <= `ENABLE;
            // br_taken <= `DISABLE;
            // br_addr  <=  `WORD_DATA_W'hx; // don't care
        end
        # (STEP * 3/4)
        # STEP begin
            /******** Initialize Test Output ********/
            if_tb(`WORD_DATA_W'h0,              // if_pc
                  `WORD_DATA_W'h4,              // if_pc_plus4
                  `ISA_NOP,                     // if_insn
                  `DISABLE                      // if_en
                  );

            // Case: read the word 0x41a4d9 from address 0x154
            /******** Read a Word(align) Test Input ********/
            reset          <= `DISABLE;
        end
        # STEP begin
            $display("\n========= Clock 1 ========");
            /******** ADDI r1, r0, 4 IF Stage Test Output ********/
            if_tb(`WORD_DATA_W'h4,               // if_pc
                  `WORD_DATA_W'h8,               // if_pc_plus4
                  `WORD_DATA_W'h400093,          // if_insn
                  `ENABLE
                 );

            ctrl_tb(`DISABLE,
                    `DISABLE,
                    `DISABLE,
                    `DISABLE,
                    `DISABLE,
                    `DISABLE,
                    `DISABLE,
                    `DISABLE,
                    `WORD_DATA_W'h0
                   );
        end
        # STEP begin
            $display("\n========= Clock 2 ========");
            /******** ADDI r2 r0, 9 IF Stage Test Output ********/
            if_tb(`WORD_DATA_W'h8,               // if_pc
                  `WORD_DATA_W'hc,               // if_pc_plus4
                  `WORD_DATA_W'h900113,          // if_insn
                  `ENABLE
                 );

            /******** ADDI r1, r0, 4 ID Stage Test Output ********/
            id_tb(`DISABLE,                       // ld_hazard
                  `ENABLE,                       // id_en
                  `ALU_OP_ADD,                   // id_alu_op
                  `WORD_DATA_W'h0,               // id_alu_in_0
                  `WORD_DATA_W'h4,               // id_alu_in_1
                  `MEM_OP_NOP,                   // id_mem_op
                  `WORD_DATA_W'h0,               // id_mem_wr_data
                  `REG_ADDR_W'h1,                // id_dst_addr
                  `ENABLE_,                      // id_gpr_we_
                  `EX_OUT_ALU,                   // id_gpr_mux_ex
                  `WORD_DATA_W'h8                // id_gpr_wr_data
                 );

             ctrl_tb(`DISABLE,
                     `DISABLE,
                     `DISABLE,
                     `DISABLE,
                     `DISABLE,
                     `DISABLE,
                     `DISABLE,
                     `DISABLE,
                     `WORD_DATA_W'h0
                    );
        end
        # STEP begin
            $display("\n========= Clock 3 ========");
            /******** ADDI r3 r0, 13 IF Stage Test Output ********/
            if_tb(`WORD_DATA_W'hc,               // if_pc
                  `WORD_DATA_W'h10,              // if_pc_plus4
                  `WORD_DATA_W'hd00193,          // if_insn
                  `ENABLE
                 );

            /********ADDI r2 r0, 9  ID Stage Test Output ********/
            id_tb(`DISABLE,                       // ld_hazard
                  `ENABLE,                       // id_en
                  `ALU_OP_ADD,                   // id_alu_op
                  `WORD_DATA_W'h0,               // id_alu_in_0
                  `WORD_DATA_W'h9,               // id_alu_in_1
                  `MEM_OP_NOP,                   // id_mem_op
                  `WORD_DATA_W'h0,
                  `REG_ADDR_W'h2,
                  `ENABLE_,
                  `EX_OUT_ALU,
                  `WORD_DATA_W'hc
                 );

            /******** ADDI r1, r0, 4 EX Stage Test Output ********/
            ex_tb(`WORD_DATA_W'h9,
                  `ENABLE,
                  `MEM_OP_NOP,
                  `WORD_DATA_W'h0,
                  `REG_ADDR_W'h1,
                  `ENABLE_,
                  `WORD_DATA_W'h4
                 );

            ctrl_tb(`DISABLE,
                    `DISABLE,
                    `DISABLE,
                    `DISABLE,
                    `DISABLE,
                    `DISABLE,
                    `DISABLE,
                    `DISABLE,
                    `WORD_DATA_W'h0
                   );
        end
        # STEP begin
            $display("\n========= Clock 4 ========");
            /******** SW   r1, r0(1024) IF Stage Test Output ********/
            if_tb(`WORD_DATA_W'h10,
                  `WORD_DATA_W'h14,
                  `WORD_DATA_W'h40102023,
                  `ENABLE
                 );

            /******** ADDI r3, r0, 13 ID Stage Test Output ********/
            id_tb(`DISABLE,                       // ld_hazard
                  `ENABLE,
                  `ALU_OP_ADD,
                  `WORD_DATA_W'h0,
                  `WORD_DATA_W'hd,
                  `MEM_OP_NOP,
                  `WORD_DATA_W'h0,
                  `REG_ADDR_W'h3,
                  `ENABLE_,
                  `EX_OUT_ALU,
                  `WORD_DATA_W'h10
                 );

            /******** ADDI r2, r0, 9  EX Stage Test Output ********/
            ex_tb(`WORD_DATA_W'hd,
                  `ENABLE,
                  `MEM_OP_NOP,
                  `WORD_DATA_W'h0,
                  `REG_ADDR_W'h2,
                  `ENABLE_,
                  `WORD_DATA_W'h9
                 );

            /******** ADDI r1, r0, 4  MEM Stage Test Output ********/
            mem_tb(`WORD_DATA_W'h9,
                   `ENABLE,
                   `REG_ADDR_W'h1,
                   `ENABLE_,
                   `WORD_DATA_W'h4
                  );
            ctrl_tb(`DISABLE,
                    `DISABLE,
                    `DISABLE,
                    `DISABLE,
                    `DISABLE,
                    `DISABLE,
                    `DISABLE,
                    `DISABLE,
                    `WORD_DATA_W'h0
                   );
        end
        # STEP begin
            $display("\n========= Clock 5 ========");
            /******** SW   r2, r0(1028) IF Stage Test Output ********/
            if_tb(`WORD_DATA_W'h14,
                  `WORD_DATA_W'h18,
                  `WORD_DATA_W'h40202223,
                  `ENABLE
                 );

            /******** SW   r1, r0(1024) ID Stage Test Output ********/
            id_tb(`DISABLE,                       // ld_hazard
                  `ENABLE,
                  `ALU_OP_ADD,
                  `WORD_DATA_W'h0,
                  `WORD_DATA_W'h400,
                  `MEM_OP_SW,
                  `WORD_DATA_W'h4,
                  `REG_ADDR_W'h0,
                  `DISABLE_,
                  `EX_OUT_ALU,
                  `WORD_DATA_W'h14
                 );

            /******** ADDI r3, r0, 13  EX Stage Test Output ********/
            ex_tb(`WORD_DATA_W'h400,
                  `ENABLE,
                  `MEM_OP_NOP,
                  `WORD_DATA_W'h0,
                  `REG_ADDR_W'h3,
                  `ENABLE_,
                  `WORD_DATA_W'hd
                 );

            /******** ADDI r2, r0, 9  MEM Stage Test Output ********/
            mem_tb(`WORD_DATA_W'hd,
                    `ENABLE,
                   `REG_ADDR_W'h2,
                   `ENABLE_,
                   `WORD_DATA_W'h9
                  );

            $display("WB Stage ...");
            ctrl_tb(`DISABLE,
                    `DISABLE,
                    `DISABLE,
                    `DISABLE,
                    `DISABLE,
                    `DISABLE,
                    `DISABLE,
                    `DISABLE,
                    `WORD_DATA_W'h0
                   );
        end
        # STEP begin
            $display("\n========= Clock 6 ========");
            /******** LW    r4, r0(1024) IF Stage Test Output ********/
            if_tb(`WORD_DATA_W'h18,
                  `WORD_DATA_W'h1c,
                  `WORD_DATA_W'h40002203,
                  `ENABLE
                 );

            /******** SW   r2, r0(1028) ID Stage Test Output ********/
            id_tb(`DISABLE,                       // ld_hazard
                  `ENABLE,
                  `ALU_OP_ADD,
                  `WORD_DATA_W'h0,
                  `WORD_DATA_W'h404,
                  `MEM_OP_SW,
                  `WORD_DATA_W'h9,
                  `REG_ADDR_W'h4,
                  `DISABLE_,
                  `EX_OUT_ALU,
                  `WORD_DATA_W'h18
                 );

            /******** SW   r1, r0(1024)  EX Stage Test Output ********/
            ex_tb(`WORD_DATA_W'h404,
                  `ENABLE,
                  `MEM_OP_SW,
                  `WORD_DATA_W'h4,
                  `REG_ADDR_W'h0,
                  `DISABLE_,
                  `WORD_DATA_W'h400
                 );

            /******** ADDI r3, r0, 13  MEM Stage Test Output ********/
             mem_tb(`WORD_DATA_W'h0,
                    `ENABLE,
                    `REG_ADDR_W'h3,
                    `ENABLE_,
                    `WORD_DATA_W'hd
                   );

            $display("WB Stage ...");
            ctrl_tb(`DISABLE,
                    `DISABLE,
                    `DISABLE,
                    `DISABLE,
                    `DISABLE,
                    `DISABLE,
                    `DISABLE,
                    `DISABLE,
                    `WORD_DATA_W'h0
                   );
        end
        # STEP begin
            $display("\n========= Clock 7 ========");
            /******** LW   r5, r0(1028) IF Stage Test Output ********/
            if_tb(`WORD_DATA_W'h1c,
                  `WORD_DATA_W'h20,
                  `WORD_DATA_W'h40402283,
                  `ENABLE
                 );

            /******** LW   r4, r0(1024) ID Stage Test Output ********/
            id_tb(`DISABLE,                       // ld_hazard
                  `ENABLE,
                  `ALU_OP_ADD,
                  `WORD_DATA_W'h0,
                  `WORD_DATA_W'h400,
                  `MEM_OP_LW,
                  `WORD_DATA_W'h0,
                  `REG_ADDR_W'h4,
                  `ENABLE_,
                  `EX_OUT_ALU,
                  `WORD_DATA_W'h1c
                 );

            /******** SW   r2, r0(1028)  EX Stage Test Output ********/
            ex_tb(`WORD_DATA_W'h400,
                  `ENABLE,
                  `MEM_OP_SW,
                  `WORD_DATA_W'h9,
                  `REG_ADDR_W'h4,
                  `DISABLE_,
                  `WORD_DATA_W'h404
                 );

            /******** SW   r1, r0(1024)  MEM Stage Test Output ********/
            mem_tb(`WORD_DATA_W'h0,
                   `ENABLE,
                   `REG_ADDR_W'h0,
                   `DISABLE_,
                   `WORD_DATA_W'h0
                  );

            $display("WB Stage ...");
            ctrl_tb(`DISABLE,
                    `DISABLE,
                    `DISABLE,
                    `DISABLE,

                    `DISABLE,
                    `DISABLE,
                    `DISABLE,
                    `DISABLE,
                    `WORD_DATA_W'h0
                   );
        end
        # STEP begin
            $display("\n========= Clock 8 ========");
            /******** NOP            IF Stage Test Output ********/
            if_tb(`WORD_DATA_W'h20,
                  `WORD_DATA_W'h24,
                  `WORD_DATA_W'h0,
                  `ENABLE
                 );

            /******** LW   r5, r0(1028) ID Stage Test Output ********/
            id_tb(`DISABLE,                       // ld_hazard
                  `ENABLE,                        // id_en
                  `ALU_OP_ADD,                    // id_alu_op
                  `WORD_DATA_W'h0,                // id_alu_in_0
                  `WORD_DATA_W'h404,              // id_alu_in_1
                  `MEM_OP_LW,                     // id_mem_op
                  `WORD_DATA_W'h0,                // id_mem_wr_data
                  `REG_ADDR_W'h5,                 // id_dst_addr
                  `ENABLE_,                       // id_gpr_we_
                  `EX_OUT_ALU,                    // id_gpr_mux_ex
                  `WORD_DATA_W'h20                // id_gpr_wr_data 
                 );

            /******** LW   r4, r0(1024)  EX Stage Test Output ********/
            ex_tb(`WORD_DATA_W'h404,
                  `ENABLE,
                  `MEM_OP_LW,
                  `WORD_DATA_W'h0,
                  `REG_ADDR_W'h4,
                  `ENABLE_,
                  `WORD_DATA_W'h400
                 );

            /******** SW   r2, r0(1028)  MEM Stage Test Output ********/
            mem_tb(`WORD_DATA_W'h4,
                   `ENABLE,
                   `REG_ADDR_W'h4,
                   `DISABLE_,
                   `WORD_DATA_W'h0
                  );

            $display("WB Stage ...");
            ctrl_tb(`DISABLE,
                    `DISABLE,
                    `DISABLE,
                    `DISABLE,
                    `DISABLE,
                    `DISABLE,
                    `DISABLE,
                    `DISABLE,
                    `WORD_DATA_W'h0
                   );
        end
        # STEP begin
            $display("\n========= Clock 9 ========");
            /******** NOP IF Stage Test Output ********/
            if_tb(`WORD_DATA_W'h24,
                  `WORD_DATA_W'h28,
                  `WORD_DATA_W'h0,
                  `ENABLE
                 );

            /******** NOP               ID Stage Test Output ********/
            id_tb(`DISABLE,                       // ld_hazard
                  `ENABLE,
                  `ALU_OP_NOP,
                  `WORD_DATA_W'h0,
                  `WORD_DATA_W'h0,
                  `MEM_OP_NOP,
                  `WORD_DATA_W'h0,
                  `REG_ADDR_W'h0,
                  `DISABLE_,
                  `EX_OUT_ALU,
                  `WORD_DATA_W'h24
                 );

            /******** LW   r5, r0(1028)  EX Stage Test Output ********/
            ex_tb(`WORD_DATA_W'h0,
                  `ENABLE,
                  `MEM_OP_LW,
                  `WORD_DATA_W'h0,
                  `REG_ADDR_W'h5,
                  `ENABLE_,
                  `WORD_DATA_W'h404
                 );

            /******** LW   r4, r0(1024)  MEM Stage Test Output ********/
            mem_tb(`WORD_DATA_W'h9,
                   `ENABLE,
                   `REG_ADDR_W'h4,
                   `ENABLE_,
                   `WORD_DATA_W'h4
                  );

            $display("WB Stage ...");
            ctrl_tb(`DISABLE,
                    `DISABLE,
                    `DISABLE,
                    `DISABLE,
                    `DISABLE,
                    `DISABLE,
                    `DISABLE,
                    `DISABLE,
                    `WORD_DATA_W'h0
                   );
        end
        # STEP begin
            $display("\n========= Clock 10 ========");
            /******** ADD  r6, r4, r5 IF Stage Test Output ********/
            if_tb(`WORD_DATA_W'h28,
                  `WORD_DATA_W'h2c,
                  `WORD_DATA_W'h520333,
                  `ENABLE
                 );

            /******** NOP               ID Stage Test Output ********/
            id_tb(`DISABLE,                       // ld_hazard
                  `ENABLE,
                  `ALU_OP_NOP,
                  `WORD_DATA_W'h0,
                  `WORD_DATA_W'h0,
                  `MEM_OP_NOP,
                  `WORD_DATA_W'h0,
                  `REG_ADDR_W'h0,
                  `DISABLE_,
                  `EX_OUT_ALU,
                  `WORD_DATA_W'h28
                 );

            /******** NOP                 EX Stage Test Output ********/
            ex_tb(`WORD_DATA_W'h0,
                  `ENABLE,
                  `MEM_OP_NOP,
                  `WORD_DATA_W'h0,
                  `REG_ADDR_W'h0,
                  `DISABLE_,
                  `WORD_DATA_W'h0
                 );

            /******** LW   r5, r0(1028)  MEM Stage Test Output ********/
            mem_tb(`WORD_DATA_W'h0,
                   `ENABLE,
                   `REG_ADDR_W'h5,
                   `ENABLE_,
                   `WORD_DATA_W'h9
                  );

            $display("WB Stage ...");
            ctrl_tb(`DISABLE,
                    `DISABLE,
                    `DISABLE,
                    `DISABLE,
                    `DISABLE,
                    `DISABLE,
                    `DISABLE,
                    `DISABLE,
                    `WORD_DATA_W'h0
                   );
        end
        # STEP begin
            $display("\n========= Clock 11 ========");
            /******** NOP              IF Stage Test Output ********/
            if_tb(`WORD_DATA_W'h2c,
                  `WORD_DATA_W'h30,
                  `WORD_DATA_W'h0,
                  `ENABLE
                 );

            /******** ADD  r6, r4, r5 ID Stage Test Output ********/
            id_tb(`DISABLE,                       // ld_hazard
                  `ENABLE,
                  `ALU_OP_ADD,
                  `WORD_DATA_W'h4,
                  `WORD_DATA_W'h9,
                  `MEM_OP_NOP,
                  `WORD_DATA_W'h9,
                  `REG_ADDR_W'h6,
                  `ENABLE_,
                  `EX_OUT_ALU,
                  `WORD_DATA_W'h2c
                 );

            /******** NOP                 EX Stage Test Output ********/
            ex_tb(`WORD_DATA_W'hd,
                  `ENABLE,
                  `MEM_OP_NOP,
                  `WORD_DATA_W'h0,
                  `REG_ADDR_W'h0,
                  `DISABLE_,
                  `WORD_DATA_W'h0
                 );

            /******** NOP  MEM Stage Test Output ********/
            mem_tb(`WORD_DATA_W'h0,
                   `ENABLE,
                   `REG_ADDR_W'h0,
                   `DISABLE_,
                   `WORD_DATA_W'h0
                  );

            $display("WB Stage ...");
            ctrl_tb(`DISABLE,
                    `DISABLE,
                    `DISABLE,
                    `DISABLE,
                    `DISABLE,
                    `DISABLE,
                    `DISABLE,
                    `DISABLE,
                    `WORD_DATA_W'h0
                   );
        end
        # STEP begin
            $display("\n========= Clock 12 ========");
            /******** NOP              IF Stage Test Output ********/
            if_tb(`WORD_DATA_W'h30,
                  `WORD_DATA_W'h34,
                  `WORD_DATA_W'h0,
                  `ENABLE
                 );

            /******** NOP ID Stage Test Output ********/
            id_tb(`DISABLE,                       // ld_hazard
                  `ENABLE,
                  `ALU_OP_NOP,
                  `WORD_DATA_W'h0,
                  `WORD_DATA_W'h0,
                  `MEM_OP_NOP,
                  `WORD_DATA_W'h0,
                  `REG_ADDR_W'h0,
                  `DISABLE_,
                  `EX_OUT_ALU,
                  `WORD_DATA_W'h30
                 );

            /******** ADD  r6, r4, r5  EX Stage Test Output ********/
            ex_tb(`WORD_DATA_W'h0,
                  `ENABLE,
                  `MEM_OP_NOP,
                  `WORD_DATA_W'h9,
                  `REG_ADDR_W'h6,
                  `ENABLE_,
                  `WORD_DATA_W'hd
                 );

            /******** NOP  MEM Stage Test Output ********/
            mem_tb(`WORD_DATA_W'hd,
                   `ENABLE,
                   `REG_ADDR_W'h0,
                   `DISABLE_,
                   `WORD_DATA_W'h0
                  );

            $display("WB Stage ...");
            ctrl_tb(`DISABLE,
                    `DISABLE,
                    `DISABLE,
                    `DISABLE,
                    `DISABLE,
                    `DISABLE,
                    `DISABLE,
                    `DISABLE,
                    `WORD_DATA_W'h0
                   );
        end
        # STEP begin
            $display("\n========= Clock 13 ========");
            /******** NOP              IF Stage Test Output ********/
            if_tb(`WORD_DATA_W'h34,
                  `WORD_DATA_W'h38,
                  `WORD_DATA_W'h0,
                  `ENABLE
                 );

            /******** NOP ID Stage Test Output ********/
            id_tb(`DISABLE,                       // ld_hazard
                  `ENABLE,
                  `ALU_OP_NOP,
                  `WORD_DATA_W'h0,
                  `WORD_DATA_W'h0,
                  `MEM_OP_NOP,
                  `WORD_DATA_W'h0,
                  `REG_ADDR_W'h0,
                  `DISABLE_,
                  `EX_OUT_ALU,
                  `WORD_DATA_W'h34
                 );

            /******** NOP  EX Stage Test Output ********/
            ex_tb(`WORD_DATA_W'h0,
                  `ENABLE,
                  `MEM_OP_NOP,
                  `WORD_DATA_W'h0,
                  `REG_ADDR_W'h0,
                  `DISABLE_,
                  `WORD_DATA_W'h0
                 );

            /******** ADD  r6, r4, r5  MEM Stage Test Output ********/
                mem_tb(`WORD_DATA_W'h0,
                      `ENABLE,
                   `REG_ADDR_W'h6,
                   `ENABLE_,
                   `WORD_DATA_W'hd
                  );

            $display("WB Stage ...");
            ctrl_tb(`DISABLE,
                    `DISABLE,
                    `DISABLE,
                    `DISABLE,
                    `DISABLE,
                    `DISABLE,
                    `DISABLE,
                    `DISABLE,
                    `WORD_DATA_W'h0
                   );
        end
        # STEP begin
            $display("\n========= Clock 14 ======== ");
            /******** NOP              IF Stage Test Output ********/
            if_tb(`WORD_DATA_W'h38,
                  `WORD_DATA_W'h3c,
                  `WORD_DATA_W'h0,
                  `ENABLE
                 );

            /******** NOP ID Stage Test Output ********/
            id_tb(`DISABLE,                       // ld_hazard
                  `ENABLE,
                  `ALU_OP_NOP,
                  `WORD_DATA_W'h0,
                  `WORD_DATA_W'h0,
                  `MEM_OP_NOP,
                  `WORD_DATA_W'h0,
                  `REG_ADDR_W'h0,
                  `DISABLE_,
                  `EX_OUT_ALU,
                  `WORD_DATA_W'h38
                 );

            /******** NOP  EX Stage Test Output ********/
            ex_tb(`WORD_DATA_W'h0,
                  `ENABLE,
                  `MEM_OP_NOP,
                  `WORD_DATA_W'h0,
                  `REG_ADDR_W'h0,
                  `DISABLE_,
                  `WORD_DATA_W'h0
                 );

            /******** NOP  MEM Stage Test Output ********/
            mem_tb(`WORD_DATA_W'h0,
                   `ENABLE,
                   `REG_ADDR_W'h0,
                   `DISABLE_,
                   `WORD_DATA_W'h0
                  );

            $display("WB Stage ...");

            ctrl_tb(`DISABLE,
                    `DISABLE,
                    `DISABLE,
                    `DISABLE,
                    `DISABLE,
                    `DISABLE,
                    `DISABLE,
                    `DISABLE,
                    `WORD_DATA_W'h0
                   );

            $finish;
        end
    end

    /******** Output Waveform ********/
    initial begin
       $dumpfile("cpu.vcd");
       $dumpvars(0,if_stage, id_stage, ex_stage, mem_stall, ctrl ,gpr);
    end

endmodule
