`timescale 1ns/1ps

`include "stddef.h"
`include "cpu.h"
`include "mem.h"
`include "spm.h"
`include "alu.h"
`include "cmp.h"
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
    wire [`WORD_DATA_BUS]      if_pc;          // Next Program count
    wire [`WORD_DATA_BUS]      pc;             // Current Program count
    wire [`WORD_DATA_BUS]      if_insn;        // Instruction
    wire                       if_en;          //  Pipeline data enable
    // ID/EX Pipeline  Register
    wire      [1:0]            src_reg_used;
    wire [`WORD_DATA_BUS]      id_pc;          // Program count
    wire                       id_en;          //  Pipeline data enable
    wire [`ALU_OP_BUS]         id_alu_op;      // ALU operation
    wire [`WORD_DATA_BUS]      id_alu_in_0;    // ALU input 0
    wire [`WORD_DATA_BUS]      id_alu_in_1;    // ALU input 1
    wire [`CMP_OP_BUS]         id_cmp_op;      // CMP Operation
    wire [`WORD_DATA_BUS]      id_cmp_in_0;    // CMP input 0
    wire [`WORD_DATA_BUS]      id_cmp_in_1;    // CMP input 1
    wire                       id_jump_taken;
    wire [`MEM_OP_BUS]         id_mem_op;      // Memory operation
    wire [`WORD_DATA_BUS]      id_mem_wr_data; // Memory Write data
    wire [`REG_ADDR_BUS]       id_dst_addr;    // GPRWrite  address
    wire                       id_gpr_we_;     // GPRWrite enable
    wire [`EX_OUT_SEL_BUS]     id_gpr_mux_ex;
    wire [`WORD_DATA_BUS]      id_gpr_wr_data;

    wire [`INS_OP_BUS]         op;
    wire [`REG_ADDR_BUS]       ra_addr;
    wire [`REG_ADDR_BUS]       rb_addr;
    // LOAD STORE Forward
    wire [`REG_ADDR_BUS]       id_ra_addr;
    wire [`REG_ADDR_BUS]       id_rb_addr;

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
    wire [`WORD_DATA_BUS]      new_pc;         // New PC
    wire [`WORD_DATA_BUS]      br_addr;        // Branch  address
    wire                       br_taken;       // Branch taken
    wire                       ld_hazard;      // Hazard

    /********** Forward Control **********/
    wire [`FWD_CTRL_BUS]       ra_fwd_ctrl;
    wire [`FWD_CTRL_BUS]       rb_fwd_ctrl;
    wire                       ex_ra_fwd_en;
    wire                       ex_rb_fwd_en;

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
        .br_taken       (br_taken),         // Branch taken
        .br_addr        (br_addr),          // Branch address
        /********** IF/ID Pipeline Register **********/
        .pc             (pc),               // Current Program count
        .if_pc          (if_pc),            // Next Program count
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

        /********** Forward Signal **********/
        .ra_fwd_ctrl    (ra_fwd_ctrl),
        .rb_fwd_ctrl    (rb_fwd_ctrl),

        /********** IF/ID Pipeline  Register **********/
        .pc             (pc),               // Current Program count
        .if_pc          (if_pc),            // Next Program count
        .if_insn        (if_insn),          // Instruction
        .if_en          (if_en),            // Pipeline data enable

        /********** ID/EX Pipeline  Register **********/
        .id_en          (id_en),            // Pipeline data enable
        .id_alu_op      (id_alu_op),        // ALU operation
        .id_alu_in_0    (id_alu_in_0),      // ALU input 0
        .id_alu_in_1    (id_alu_in_1),      // ALU input 1
        .id_cmp_op      (id_cmp_op),        // CMP Operation
        .id_cmp_in_0    (id_cmp_in_0),      // CMP input 0
        .id_cmp_in_1    (id_cmp_in_1),      // CMP input 1
        .id_ra_addr     (id_ra_addr),
        .id_rb_addr     (id_rb_addr),
        .id_jump_taken  (id_jump_taken),
        .id_mem_op      (id_mem_op),        // Memory operation
        .id_mem_wr_data (id_mem_wr_data),   // Memory Write data
        .id_dst_addr    (id_dst_addr),      // GPRWrite  address
        .id_gpr_we_     (id_gpr_we_),       // GPRWrite enable
        .id_gpr_mux_ex  (id_gpr_mux_ex),
        .id_gpr_wr_data (id_gpr_wr_data),

        .op             (op),
        .ra_addr        (ra_addr),
        .rb_addr        (rb_addr),
        .src_reg_used   (src_reg_used)
    );

    /********** EX Stage **********/
    ex_stage ex_stage (
        /********** Clock & Reset **********/
        .clk            (clk),              // Clock
        .reset          (reset),            // Asynchronous Reset
        /**********  Pipeline Control Signal **********/
        .stall          (ex_stall),         // Stall
        .flush          (ex_flush),         // Flush
        /********** ID/EX Pipeline  Register **********/
        .id_en          (id_en),
        .id_alu_op      (id_alu_op),        // ALU operation
        .id_alu_in_0    (id_alu_in_0),      // ALU input 0
        .id_alu_in_1    (id_alu_in_1),      // ALU input 1
        .id_cmp_op      (id_cmp_op),        // CMP operation
        .id_cmp_in_0    (id_cmp_in_0),      // CMP input 0
        .id_cmp_in_1    (id_cmp_in_1),      // CMP input 1

        .id_mem_op      (id_mem_op),        // Memory operation
        .id_mem_wr_data (id_mem_wr_data),   // Memory Write data
        .id_dst_addr    (id_dst_addr),      // General purpose RegisterWrite  address
        .id_gpr_we_     (id_gpr_we_),       // General purpose RegisterWrite enable
        .ex_out_sel     (id_gpr_mux_ex),
        .id_gpr_wr_data (id_gpr_wr_data),

        // Forward Data From MEM Stage
        .ex_ra_fwd_en   (ex_ra_fwd_en),
        .ex_rb_fwd_en   (ex_rb_fwd_en),
        .mem_fwd_data   (mem_fwd_data),     // MEM Stage

        /********** Forward  **********/
        .fwd_data       (ex_fwd_data),      // Forward data
         /********** EX/MEM Pipeline  Register **********/
        .ex_en          (ex_en),
        .ex_mem_op      (ex_mem_op),        // Memory operation
        .ex_mem_wr_data (ex_mem_wr_data),   // Memory Write data
        .ex_dst_addr    (ex_dst_addr),      // General purpose RegisterWrite address
        .ex_gpr_we_     (ex_gpr_we_),       // General purpose RegisterWrite enable
        .ex_out         (ex_out),           // Operating result

        .id_jump_taken  (id_jump_taken),

        .br_addr        (br_addr),
        .br_taken       (br_taken)
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
        .br_taken       (br_taken),
        .src_reg_used   (src_reg_used),
        .id_en          (id_en),
        .id_dst_addr    (id_dst_addr),
        .id_gpr_we_     (id_gpr_we_),
        .id_mem_op      (id_mem_op),

        .op             (op),
        .ra_addr        (ra_addr),
        .rb_addr        (rb_addr),

        .id_ra_addr     (id_ra_addr),
        .id_rb_addr     (id_rb_addr),

        .ex_en          (ex_en),
        .ex_dst_addr    (ex_dst_addr),
        .ex_gpr_we_     (ex_gpr_we_),
        .ex_mem_op      (ex_mem_op),

        /**********  Pipeline Control Signal **********/
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
        .new_pc         (new_pc),

        .ra_fwd_ctrl    (ra_fwd_ctrl),
        .rb_fwd_ctrl    (rb_fwd_ctrl),
        .ex_ra_fwd_en   (ex_ra_fwd_en),
        .ex_rb_fwd_en   (ex_rb_fwd_en)
    );

    /********** General purpose Register **********/
    gpr gpr (
        /********** Clock & Reset **********/
        .clk            (clk),              // Clock
        .reset          (reset),            // Asynchronous Reset
        /********** Read Port  0 **********/
        .rd_addr_0      (gpr_rd_addr_0),    // Read  address
        .rd_data_0      (gpr_rd_data_0),    // Read data
        /********** Read Port  1 **********/
        .rd_addr_1      (gpr_rd_addr_1),    // Read  address
        .rd_data_1      (gpr_rd_data_1),    // Read data
        /********** Write Port  **********/
        .we_            (mem_gpr_we_),      // Write enable
        .wr_addr        (mem_dst_addr),     // Write  address
        .wr_data        (mem_out)           //  Write data
    );

    /********** Scratch Pad Memory **********/
    spm spm (
        /********** Clock **********/
        .clk             (clk_),                        // Clock
        /********** Port A: IF Stage **********/
        .if_spm_addr     (if_spm_addr[`SPM_ADDR_LOC]),  //  address
        .if_spm_as_      (if_spm_as_),                  //  address strobe
        .if_spm_rw       (if_spm_rw),                   // Read/Write
        .if_spm_wr_data  (if_spm_wr_data),              //  Write data
        .if_spm_rd_data  (if_spm_rd_data),              // Read data
        /********** Port B: MEM Stage **********/
        .mem_spm_addr    (mem_spm_addr[`SPM_ADDR_LOC]), //  address
        .mem_spm_as_     (mem_spm_as_),                 //  address strobe
        .mem_spm_rw      (mem_spm_rw),                  // Read/Write
        .mem_spm_wr_data (mem_spm_wr_data),             //  Write data
        .mem_spm_rd_data (mem_spm_rd_data)              // Read data
    );

    task if_tb;
        input [`WORD_DATA_BUS] _pc;
        input [`WORD_DATA_BUS] _if_pc;
        input [`WORD_DATA_BUS] _if_insn;
        input                  _if_en;

        begin
            if( (pc          === _pc)           &&
                (if_pc       === _if_pc)        &&
                (if_insn     === _if_insn)      &&
                (if_en       === _if_en)
              ) begin
                $display("IF  Stage Test Succeeded !");
            end else begin
                $display("IF  Stage Test Failed !");
            end
        end
    endtask

    task id_tb;
        input                   _id_en;          //  Pipeline data enable
        input [`ALU_OP_BUS]     _id_alu_op;      // ALU operation
        input [`WORD_DATA_BUS]  _id_alu_in_0;    // ALU input 0
        input [`WORD_DATA_BUS]  _id_alu_in_1;    // ALU input 1
        input [`CMP_OP_BUS]     _id_cmp_op;     // CMP Operation
        input [`WORD_DATA_BUS]  _id_cmp_in_0;   // CMP input 0
        input [`WORD_DATA_BUS]  _id_cmp_in_1;   // CMP input 1
        input [`REG_ADDR_BUS]   _id_ra_addr;
        input [`REG_ADDR_BUS]   _id_rb_addr;
        input                   _id_jump_taken;
        input [`MEM_OP_BUS]     _id_mem_op;      // Memory operation
        input [`WORD_DATA_BUS]  _id_mem_wr_data; // Memory Write data
        input [`REG_ADDR_BUS]   _id_dst_addr;    // GPRWrite  address
        input                   _id_gpr_we_;     // GPRWrite enable
        input [`EX_OUT_SEL_BUS] _id_gpr_mux_ex;
        input [`WORD_DATA_BUS]  _id_gpr_wr_data;

        input [`INS_OP_BUS]     _op;
        input [`REG_ADDR_BUS]   _ra_addr;
        input [`REG_ADDR_BUS]   _rb_addr;
        input [1:0]             _src_reg_used;

        begin
            if( (id_en          === _id_en)          &&
                (id_alu_op      === _id_alu_op)      &&
                (id_alu_in_0    === _id_alu_in_0)    &&
                (id_alu_in_1    === _id_alu_in_1)    &&
                (id_cmp_op      === _id_cmp_op)      &&
                (id_cmp_in_0    === _id_cmp_in_0)    &&
                (id_cmp_in_1    === _id_cmp_in_1)    &&
                (id_ra_addr     === _id_ra_addr)     &&
                (id_rb_addr     === _id_rb_addr)     &&
                (id_jump_taken  === _id_jump_taken)  &&
                (id_mem_op      === _id_mem_op)      &&
                (id_mem_wr_data === _id_mem_wr_data) &&
                (id_dst_addr    === _id_dst_addr)    &&
                (id_gpr_we_     === _id_gpr_we_)     &&
                (id_gpr_mux_ex  === _id_gpr_mux_ex)  &&
                (id_gpr_wr_data === _id_gpr_wr_data) &&

                (op             === _op)             &&
                (ra_addr        === _ra_addr)        &&
                (rb_addr        === _rb_addr)        &&
                (src_reg_used   === _src_reg_used)

              ) begin
                $display("ID  Stage Test Succeeded !");
            end else begin
                $display("ID  Stage Test Failed !");
            end
        end
    endtask

    task ex_tb;
        input [`WORD_DATA_BUS] _ex_fwd_data;
        input                  _ex_en;
        input [`MEM_OP_BUS]    _ex_mem_op;      // Memory operation
        input [`WORD_DATA_BUS] _ex_mem_wr_data; // Memory Write data
        input [`REG_ADDR_BUS]  _ex_dst_addr;    // General purpose RegisterWrite  address
        input                  _ex_gpr_we_;     // General purpose RegisterWrite enable
        input [`WORD_DATA_BUS] _ex_out;         // Operating result

        input [`WORD_DATA_BUS] _br_addr;        // target pc value of branch or jump
        input                  _br_taken;       // ture - take branch or jump

        begin
            if( (ex_fwd_data    === _ex_fwd_data)     &&
                (ex_en          === _ex_en)           &&
                (ex_mem_op      === _ex_mem_op)       &&      // Memory operation
                (ex_mem_wr_data === _ex_mem_wr_data)  &&      // Memory Write data
                (ex_dst_addr    === _ex_dst_addr)     &&      // General purpose RegisterWrite address
                (ex_gpr_we_     === _ex_gpr_we_)      &&      // General purpose RegisterWrite enable
                (ex_out         === _ex_out)          &&      // Operating result
                (br_addr        === _br_addr)         &&      // Operating result
               (br_taken       === _br_taken)                // Operating result
              ) begin
                $display("EX  Stage Test Succeeded !");
            end else begin
                $display("EX  Stage Test Failed !");
            end
        end
    endtask

    task mem_tb;
        input [`WORD_DATA_BUS] _mem_fwd_data;
        input                  _mem_en;
        input [`REG_ADDR_BUS]  _mem_dst_addr; // General purpose RegisterWrite  address
        input                  _mem_gpr_we_;  // General purpose RegisterWrite enable
        input [`WORD_DATA_BUS] _mem_out;      // Operating result

        begin
            if( (mem_fwd_data  === _mem_fwd_data)     &&
                (mem_en        === _mem_en)           &&
                (mem_dst_addr  === _mem_dst_addr)     &&      // Memory operation
                (mem_gpr_we_   === _mem_gpr_we_)      &&      // Memory Write data
                (mem_out       === _mem_out)                  // General purpose RegisterWrite address
              ) begin
                $display("MEM Stage Test Succeeded !");
            end else begin
                $display("MEM Stage Test Failed !");
            end
        end
    endtask

    task ctrl_tb;
        input                  _if_stall;     // IF stage stall
        input                  _id_stall;     // ID stage stall
        input                  _ex_stall;     // EX stage stall
        input                  _mem_stall;    // MEM stage stall

        input                  _if_flush;     // IF stage flush
        input                  _id_flush;     // ID stage flush
        input                  _ex_flush;     // EX stage flush
        input                  _mem_flush;    // MEM stage flush

        input [`WORD_DATA_BUS] _new_pc;

        /********** Forward Output **********/
        input [`FWD_CTRL_BUS]  _ra_fwd_ctrl;
        input [`FWD_CTRL_BUS]  _rb_fwd_ctrl;
        input                  _ex_ra_fwd_en;
        input                  _ex_rb_fwd_en;

        begin
            if( (if_stall     === _if_stall)     &&
                (id_stall     === _id_stall)     &&
                (ex_stall     === _ex_stall)     &&
                (mem_stall    === _mem_stall)    &&
                (if_flush     === _if_flush)     &&
                (id_flush     === _id_flush)     &&
                (ex_flush     === _ex_flush)     &&
                (mem_flush    === _mem_flush)    &&
                (new_pc       === _new_pc)       &&

                (ra_fwd_ctrl  === _ra_fwd_ctrl)  &&
                (rb_fwd_ctrl  === _rb_fwd_ctrl)  &&
                (ex_ra_fwd_en === _ex_ra_fwd_en) &&
                (ex_rb_fwd_en === _ex_rb_fwd_en)
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
            if_tb(`WORD_DATA_W'h0,              // pc
                  `WORD_DATA_W'h0,              // if_pc
                  `ISA_NOP,                     // if_insn
                  `DISABLE                      // if_en
                  );

            reset <= `DISABLE;
        end
        # STEP begin
            $display("\n========= Clock 1 ========");
            /******** LUI   r1, 4 IF Stage Test Output ********/
            if_tb(`WORD_DATA_W'h0,              // pc
                  `WORD_DATA_W'h4,              // if_pc
                  `WORD_DATA_W'h40b7,           // if_insn
                  `ENABLE                       // if_en
                 );

            ctrl_tb(`DISABLE,                   // if_stall
                    `DISABLE,                   // id_stall
                    `DISABLE,                   // ex_stall
                    `DISABLE,                   // mem_stall
                    `DISABLE,                   // if_flush
                    `DISABLE,                   // id_flush
                    `DISABLE,                   // ex_flush
                    `DISABLE,                   // mem_flush
                    `WORD_DATA_W'h0,            // new_pc

                    `FWD_CTRL_NONE,             // ra_fwd_ctrl
                    `FWD_CTRL_NONE,             // rb_fwd_ctrl
                    `DISABLE,                   // ex_ra_fwd_en
                    `DISABLE                    // ex_rb_fwd_en
                   );
        end
        # STEP begin
            $display("\n========= Clock 2 ========");
            /******** AUIPC r2, -8 IF Stage Test Output ********/
            if_tb(`WORD_DATA_W'h4,              // pc
                  `WORD_DATA_W'h8,              // if_pc
                  `WORD_DATA_W'hffff8117,       // if_insn
                  `ENABLE                       // if_en
                 );

            /******** LUI   r1, 4 ID Stage Test Output ********/
            id_tb(`ENABLE,                      // id_en
                  `ALU_OP_NOP,                  // id_alu_op
                  `WORD_DATA_W'h0,              // id_alu_in_0
                  `WORD_DATA_W'h0,              // id_alu_in_1
                  `CMP_OP_NOP,                  // id_cmp_op
                  `WORD_DATA_W'h0,              // id_cmp_in_0
                  `WORD_DATA_W'h0,              // id_cmp_in_1
                  `REG_ADDR_W'h0,               // id_ra_addr
                  `REG_ADDR_W'h0,               // id_rb_addr
                  `DISABLE,                     // id_jump_taken
                  `MEM_OP_NOP,                  // id_mem_op
                  `WORD_DATA_W'h0,              // id_mem_wr_data
                  `REG_ADDR_W'h1,               // id_dst_addr
                  `ENABLE_,                     // id_gpr_we_
                  `EX_OUT_PCN,                  // id_gpr_mux_ex
                  `WORD_DATA_W'h4000,           // id_gpr_wr_data

                  `ISA_OP_AUIPC,                // op
                  `REG_ADDR_W'h1f,              // ra_addr
                  `REG_ADDR_W'h1f,              // rb_addr
                  2'b00                         // src_reg_used
                 );

            ctrl_tb(`DISABLE,                   // if_stall
                    `DISABLE,                   // id_stall
                    `DISABLE,                   // ex_stall
                    `DISABLE,                   // mem_stall
                    `DISABLE,                   // if_flush
                    `DISABLE,                   // id_flush
                    `DISABLE,                   // ex_flush
                    `DISABLE,                   // mem_flush
                    `WORD_DATA_W'h0,            // new_pc

                    `FWD_CTRL_NONE,             // ra_fwd_ctrl
                    `FWD_CTRL_NONE,             // rb_fwd_ctrl
                    `DISABLE,                   // ex_ra_fwd_en
                    `DISABLE                    // ex_rb_fwd_en
                    );
        end
        # STEP begin
            $display("\n========= Clock 3 ========");
            /******** SLTI  r3, r1, -4 IF Stage Test Output ********/
            if_tb(`WORD_DATA_W'h8,              // pc
                  `WORD_DATA_W'hc,              // if_pc
                  `WORD_DATA_W'hffc0a193,       // if_insn
                  `ENABLE                       // if_en
                 );

            /******** AUIPC r2, -8 ID Stage Test Output ********/
            id_tb(`ENABLE,                      // id_en
                  `ALU_OP_ADD,                  // id_alu_op
                  `WORD_DATA_W'h4,              // id_alu_in_0
                  `WORD_DATA_W'hffff8000,       // id_alu_in_1
                  `CMP_OP_NOP,                  // id_cmp_op
                  `WORD_DATA_W'h0,              // id_cmp_in_0
                  `WORD_DATA_W'h0,              // id_cmp_in_1
                  `REG_ADDR_W'h1f,              // id_ra_addr
                  `REG_ADDR_W'h1f,              // id_rb_addr
                  `DISABLE,                     // id_jump_taken
                  `MEM_OP_NOP,                  // id_mem_op
                  `WORD_DATA_W'h0,              // id_mem_wr_data
                  `REG_ADDR_W'h2,               // id_dst_addr
                  `ENABLE_,                     // id_gpr_we_
                  `EX_OUT_ALU,                  // id_gpr_mux_ex
                  `WORD_DATA_W'h8,              // id_gpr_wr_data

                  `ISA_OP_ALSI,                 // op
                  `REG_ADDR_W'h1,               // ra_addr
                  `REG_ADDR_W'h1c,              // rb_addr
                  2'b01                         // src_reg_used
                 );
            
            /******** LUI   r1, 4  EX Stage Test Output ********/
            ex_tb(`WORD_DATA_W'hffff8004,       // ex_fwd_data
                  `ENABLE,                      // ex_en
                  `MEM_OP_NOP,                  // ex_mem_op
                  `WORD_DATA_W'h0,              // ex_mem_wr_data
                  `REG_ADDR_W'h1,               // ex_dst_addr
                  `ENABLE_,                     // ex_gpr_we_
                  `WORD_DATA_W'h4000,           // ex_out
                  `WORD_DATA_W'hffff8004,       // br_addr
                  `DISABLE                      // br_taken
                 );

            ctrl_tb(`DISABLE,                   // if_stall
                    `DISABLE,                   // id_stall
                    `DISABLE,                   // ex_stall
                    `DISABLE,                   // mem_stall
                    `DISABLE,                   // if_flush
                    `DISABLE,                   // id_flush
                    `DISABLE,                   // ex_flush
                    `DISABLE,                   // mem_flush
                    `WORD_DATA_W'h0,            // new_pc

                    `FWD_CTRL_MEM,              // ra_fwd_ctrl
                    `FWD_CTRL_NONE,             // rb_fwd_ctrl
                    `DISABLE,                   // ex_ra_fwd_en
                    `DISABLE                    // ex_rb_fwd_en
                   );
        end
        # STEP begin
            $display("\n========= Clock 4 ========");
            /******** SLTIU r3, r1, -4 IF Stage Test Output ********/
            if_tb(`WORD_DATA_W'hc,              // pc
                  `WORD_DATA_W'h10,             // if_pc
                  `WORD_DATA_W'hffc0b193,       // if_insn
                  `ENABLE                       // if_en
                 );

            /******** SLTI  r3, r1, -4 ID Stage Test Output ********/
            id_tb(`ENABLE,                      // id_en
                  `ALU_OP_NOP,                  // id_alu_op
                  `WORD_DATA_W'h4000,           // id_alu_in_0
                  `WORD_DATA_W'h0,              // id_alu_in_1
                  `CMP_OP_LT,                   // id_cmp_op
                  `WORD_DATA_W'h4000,           // id_cmp_in_0
                  `WORD_DATA_W'hfffffffc,       // id_cmp_in_1
                  `REG_ADDR_W'h1,               // id_ra_addr
                  `REG_ADDR_W'h1c,              // id_rb_addr
                  `DISABLE,                     // id_jump_taken
                  `MEM_OP_NOP,                  // id_mem_op
                  `WORD_DATA_W'h0,              // id_mem_wr_data
                  `REG_ADDR_W'h3,               // id_dst_addr
                  `ENABLE_,                     // id_gpr_we_
                  `EX_OUT_CMP,                  // id_gpr_mux_ex
                  `WORD_DATA_W'hc,              // id_gpr_wr_data

                  `ISA_OP_ALSI,                 // op
                  `REG_ADDR_W'h1,               // ra_addr
                  `REG_ADDR_W'h1c,              // rb_addr
                  2'b01                         // src_reg_used
                 );
            
            /******** AUIPC r2, -8 EX Stage Test Output ********/
            ex_tb(`WORD_DATA_W'h0,              // ex_fwd_data
                  `ENABLE,                      // ex_en
                  `MEM_OP_NOP,                  // ex_mem_op
                  `WORD_DATA_W'h0,              // ex_mem_wr_data
                  `REG_ADDR_W'h2,               // ex_dst_addr
                  `ENABLE_,                     // ex_gpr_we_
                  `WORD_DATA_W'hffff8004,       // ex_out
                  `WORD_DATA_W'h0,              // br_addr
                  `DISABLE                      // br_taken
                 );

            /******** LUI   r1, 4  MEM Stage Test Output ********/
            mem_tb(`WORD_DATA_W'hffff8004,      // mem_fwd_data
                   `ENABLE,                     // mem_en
                   `REG_ADDR_W'h1,              // mem_dst_addr
                   `ENABLE_,                    // mem_gpr_we_
                   `WORD_DATA_W'h4000           // mem_out
                  );

            ctrl_tb(`DISABLE,                   // if_stall
                    `DISABLE,                   // id_stall
                    `DISABLE,                   // ex_stall
                    `DISABLE,                   // mem_stall
                    `DISABLE,                   // if_flush
                    `DISABLE,                   // id_flush
                    `DISABLE,                   // ex_flush
                    `DISABLE,                   // mem_flush
                    `WORD_DATA_W'h0,            // new_pc

                    `FWD_CTRL_NONE,             // ra_fwd_ctrl
                    `FWD_CTRL_NONE,             // rb_fwd_ctrl
                    `DISABLE,                   // ex_ra_fwd_en
                    `DISABLE                    // ex_rb_fwd_en
                   );
        end
        # STEP begin
            $display("\n========= Clock 5 ========");
            /******** SLLI  r4, r3, 3 IF Stage Test Output ********/
            if_tb(`WORD_DATA_W'h10,             // pc
                  `WORD_DATA_W'h14,             // if_pc
                  `WORD_DATA_W'h319213,         // if_insn
                  `ENABLE                       // if_en
                 );

            /******** SLTIU r3, r1, -4 ID Stage Test Output ********/
            id_tb(`ENABLE,                      // id_en
                  `ALU_OP_NOP,                  // id_alu_op
                  `WORD_DATA_W'h4000,           // id_alu_in_0
                  `WORD_DATA_W'h0,              // id_alu_in_1
                  `CMP_OP_LTU,                  // id_cmp_op
                  `WORD_DATA_W'h4000,           // id_cmp_in_0
                  `WORD_DATA_W'hfffffffc,       // id_cmp_in_1
                  `REG_ADDR_W'h1,               // id_ra_addr
                  `REG_ADDR_W'h1c,              // id_rb_addr
                  `DISABLE,                     // id_jump_taken
                  `MEM_OP_NOP,                  // id_mem_op
                  `WORD_DATA_W'h0,              // id_mem_wr_data
                  `REG_ADDR_W'h3,               // id_dst_addr
                  `ENABLE_,                     // id_gpr_we_
                  `EX_OUT_CMP,                  // id_gpr_mux_ex
                  `WORD_DATA_W'h10,             // id_gpr_wr_data

                  `ISA_OP_ALSI,                 // op
                  `REG_ADDR_W'h3,               // ra_addr
                  `REG_ADDR_W'h3,               // rb_addr
                  2'b01                         // src_reg_used
                 );
            
            /******** SLTI  r3, r1, -4 EX Stage Test Output ********/
            ex_tb(`WORD_DATA_W'h1,              // ex_fwd_data
                  `ENABLE,                      // ex_en
                  `MEM_OP_NOP,                  // ex_mem_op
                  `WORD_DATA_W'h0,              // ex_mem_wr_data
                  `REG_ADDR_W'h3,               // ex_dst_addr
                  `ENABLE_,                     // ex_gpr_we_
                  `WORD_DATA_W'h0,              // ex_out
                  `WORD_DATA_W'h0,              // br_addr
                  `DISABLE                      // br_taken
                 );

            /********  AUIPC r2, -8  MEM Stage Test Output ********/
            mem_tb(`WORD_DATA_W'h0,            // mem_fwd_data
                   `ENABLE,                     // mem_en
                   `REG_ADDR_W'h2,              // mem_dst_addr
                   `ENABLE_,                    // mem_gpr_we_
                   `WORD_DATA_W'hffff8004              // mem_out
                  );

            $display("WB Stage ...");

            ctrl_tb(`DISABLE,                   // if_stall
                    `DISABLE,                   // id_stall
                    `DISABLE,                   // ex_stall
                    `DISABLE,                   // mem_stall
                    `DISABLE,                   // if_flush
                    `DISABLE,                   // id_flush
                    `DISABLE,                   // ex_flush
                    `DISABLE,                   // mem_flush
                    `WORD_DATA_W'h0,            // new_pc

                    `FWD_CTRL_EX,               // ra_fwd_ctrl
                    `FWD_CTRL_NONE,             // rb_fwd_ctrl
                    `DISABLE,                   // ex_ra_fwd_en
                    `DISABLE                    // ex_rb_fwd_en
                   );
        end
        # STEP begin
            $display("\n========= Clock 6 ========");
            /******** SLT   r5, r4, r2 IF Stage Test Output ********/
            if_tb(`WORD_DATA_W'h14,             // pc
                  `WORD_DATA_W'h18,             // if_pc
                  `WORD_DATA_W'h2222b3,         // if_insn
                  `ENABLE                       // if_en
                 );

            /******** SLLI  r4, r3, 3 ID Stage Test Output ********/
            id_tb(`ENABLE,                      // id_en
                  `ALU_OP_SLL,                  // id_alu_op
                  `WORD_DATA_W'h1,              // id_alu_in_0
                  `WORD_DATA_W'h3,              // id_alu_in_1
                  `CMP_OP_NOP,                  // id_cmp_op
                  `WORD_DATA_W'h1,              // id_cmp_in_0
                  `WORD_DATA_W'h0,              // id_cmp_in_1
                  `REG_ADDR_W'h3,               // id_ra_addr
                  `REG_ADDR_W'h3,               // id_rb_addr
                  `DISABLE,                     // id_jump_taken
                  `MEM_OP_NOP,                  // id_mem_op
                  `WORD_DATA_W'h0,              // id_mem_wr_data
                  `REG_ADDR_W'h4,               // id_dst_addr
                  `ENABLE_,                     // id_gpr_we_
                  `EX_OUT_ALU,                  // id_gpr_mux_ex
                  `WORD_DATA_W'h14,             // id_gpr_wr_data

                  `ISA_OP_ALS,                  // op
                  `REG_ADDR_W'h4,               // ra_addr
                  `REG_ADDR_W'h2,               // rb_addr
                  2'b11                         // src_reg_used
                 );
            
            /******** SLTIU r3, r1, -4 EX Stage Test Output ********/
            ex_tb(`WORD_DATA_W'h8,              // ex_fwd_data
                  `ENABLE,                      // ex_en
                  `MEM_OP_NOP,                  // ex_mem_op
                  `WORD_DATA_W'h0,              // ex_mem_wr_data
                  `REG_ADDR_W'h3,               // ex_dst_addr
                  `ENABLE_,                     // ex_gpr_we_
                  `WORD_DATA_W'h1,              // ex_out
                  `WORD_DATA_W'h8,              // br_addr
                  `DISABLE                      // br_taken
                 );

            /******** SLTI  r3, r1, -4  MEM Stage Test Output ********/
            mem_tb(`WORD_DATA_W'h1,      // mem_fwd_data
                   `ENABLE,                     // mem_en
                   `REG_ADDR_W'h3,              // mem_dst_addr
                   `ENABLE_,                    // mem_gpr_we_
                   `WORD_DATA_W'h0              // mem_out
                  );

            $display("WB Stage ...");

            ctrl_tb(`DISABLE,                   // if_stall
                    `DISABLE,                   // id_stall
                    `DISABLE,                   // ex_stall
                    `DISABLE,                   // mem_stall
                    `DISABLE,                   // if_flush
                    `DISABLE,                   // id_flush
                    `DISABLE,                   // ex_flush
                    `DISABLE,                   // mem_flush
                    `WORD_DATA_W'h0,            // new_pc

                    `FWD_CTRL_EX,               // ra_fwd_ctrl
                    `FWD_CTRL_NONE,             // rb_fwd_ctrl
                    `DISABLE,                   // ex_ra_fwd_en
                    `DISABLE                    // ex_rb_fwd_en
                   );
        end
        # STEP begin
            $display("\n========= Clock 7 ========");
            /******** SLTU  r5, r4, r2 IF Stage Test Output ********/
            if_tb(`WORD_DATA_W'h18,              // pc
                  `WORD_DATA_W'h1c,              // if_pc
                  `WORD_DATA_W'h2232b3,          // if_insn
                  `ENABLE                        // if_en
                 );

            /******** SLT   r5, r4, r2 ID Stage Test Output ********/
            id_tb(`ENABLE,                       // id_en
                  `ALU_OP_NOP,                   // id_alu_op
                  `WORD_DATA_W'h8,               // id_alu_in_0
                  `WORD_DATA_W'hffff8004,        // id_alu_in_1
                  `CMP_OP_LT,                    // id_cmp_op
                  `WORD_DATA_W'h8,               // id_cmp_in_0
                  `WORD_DATA_W'hffff8004,        // id_cmp_in_1
                  `REG_ADDR_W'h4,                // id_ra_addr
                  `REG_ADDR_W'h2,                // id_rb_addr
                  `DISABLE,                      // id_jump_taken
                  `MEM_OP_NOP,                   // id_mem_op
                  `WORD_DATA_W'hffff8004,        // id_mem_wr_data
                  `REG_ADDR_W'h5,                // id_dst_addr
                  `ENABLE_,                      // id_gpr_we_
                  `EX_OUT_CMP,                   // id_gpr_mux_ex
                  `WORD_DATA_W'h18,              // id_gpr_wr_data

                  `ISA_OP_ALS,                   // op
                  `REG_ADDR_W'h4,                // ra_addr
                  `REG_ADDR_W'h2,                // rb_addr
                  2'b11                          // src_reg_used
                 );
            
            /******** SLLI  r4, r3, 3 EX Stage Test Output ********/
            ex_tb(`WORD_DATA_W'h0,               // ex_fwd_data
                  `ENABLE,                       // ex_en
                  `MEM_OP_NOP,                   // ex_mem_op
                  `WORD_DATA_W'h0,               // ex_mem_wr_data
                  `REG_ADDR_W'h4,                // ex_dst_addr
                  `ENABLE_,                      // ex_gpr_we_
                  `WORD_DATA_W'h8,               // ex_out
                  `WORD_DATA_W'h0,               // br_addr
                  `DISABLE                       // br_taken
                 );

            /******** SLTIU r3, r1, -4    MEM Stage Test Output ********/
            mem_tb(`WORD_DATA_W'h8,              // mem_fwd_data
                   `ENABLE,                      // mem_en
                   `REG_ADDR_W'h3,               // mem_dst_addr
                   `ENABLE_,                     // mem_gpr_we_
                   `WORD_DATA_W'h1               // mem_out
                  );

            $display("WB Stage ...");

            ctrl_tb(`DISABLE,                    // if_stall
                    `DISABLE,                    // id_stall
                    `DISABLE,                    // ex_stall
                    `DISABLE,                    // mem_stall
                    `DISABLE,                    // if_flush
                    `DISABLE,                    // id_flush
                    `DISABLE,                    // ex_flush
                    `DISABLE,                    // mem_flush
                    `WORD_DATA_W'h0,             // new_pc

                    `FWD_CTRL_MEM,               // ra_fwd_ctrl
                    `FWD_CTRL_NONE,              // rb_fwd_ctrl
                    `DISABLE,                    // ex_ra_fwd_en
                    `DISABLE                     // ex_rb_fwd_en
                   );
        end
        # STEP begin
            $display("\n========= Clock 8 ========");
            /******** ADDI r0, r0, 0 as NOP IF Stage Test Output ********/
            if_tb(`WORD_DATA_W'h1c,              // pc
                  `WORD_DATA_W'h20,              // if_pc
                  `WORD_DATA_W'h13,              // if_insn
                  `ENABLE                        // if_en
                 );

            /******** SLTU  r5, r4, r2 ID Stage Test Output ********/
            id_tb(`ENABLE,                       // id_en
                  `ALU_OP_NOP,                   // id_alu_op
                  `WORD_DATA_W'h8,               // id_alu_in_0
                  `WORD_DATA_W'hffff8004,        // id_alu_in_1
                  `CMP_OP_LTU,                   // id_cmp_op
                  `WORD_DATA_W'h8,               // id_cmp_in_0
                  `WORD_DATA_W'hffff8004,        // id_cmp_in_1
                  `REG_ADDR_W'h4,                // id_ra_addr
                  `REG_ADDR_W'h2,                // id_rb_addr
                  `DISABLE,                      // id_jump_taken
                  `MEM_OP_NOP,                   // id_mem_op
                  `WORD_DATA_W'hffff8004,        // id_mem_wr_data
                  `REG_ADDR_W'h5,                // id_dst_addr
                  `ENABLE_,                      // id_gpr_we_
                  `EX_OUT_CMP,                   // id_gpr_mux_ex
                  `WORD_DATA_W'h1c,              // id_gpr_wr_data

                  `ISA_OP_ALSI,                  // op
                  `REG_ADDR_W'h0,                // ra_addr
                  `REG_ADDR_W'h0,                // rb_addr
                  2'b01                          // src_reg_used
                 );
            
            /******** SLT   r5, r4, r2 Stage Test Output ********/
            ex_tb(`WORD_DATA_W'h1,               // ex_fwd_data
                  `ENABLE,                       // ex_en
                  `MEM_OP_NOP,                   // ex_mem_op
                  `WORD_DATA_W'hffff8004,        // ex_mem_wr_data
                  `REG_ADDR_W'h5,                // ex_dst_addr
                  `ENABLE_,                      // ex_gpr_we_
                  `WORD_DATA_W'h0,               // ex_out
                  `WORD_DATA_W'h0,               // br_addr
                  `DISABLE                       // br_taken
                 );

            /******** SLLI  r4, r3, 3 MEM Stage Test Output ********/
            mem_tb(`WORD_DATA_W'h0,              // mem_fwd_data
                   `ENABLE,                      // mem_en
                   `REG_ADDR_W'h4,               // mem_dst_addr
                   `ENABLE_,                     // mem_gpr_we_
                   `WORD_DATA_W'h8               // mem_out
                  );

            $display("WB Stage ...");

            ctrl_tb(`DISABLE,                    // if_stall
                    `DISABLE,                    // id_stall
                    `DISABLE,                    // ex_stall
                    `DISABLE,                    // mem_stall
                    `DISABLE,                    // if_flush
                    `DISABLE,                    // id_flush
                    `DISABLE,                    // ex_flush
                    `DISABLE,                    // mem_flush
                    `WORD_DATA_W'h0,             // new_pc

                    `FWD_CTRL_NONE,              // ra_fwd_ctrl
                    `FWD_CTRL_NONE,              // rb_fwd_ctrl
                    `DISABLE,                    // ex_ra_fwd_en
                    `DISABLE                     // ex_rb_fwd_en
                   );
        end
        # STEP begin
            $display("\n========= Clock 9 ========");
            /******** ADDI r0, r0, 0 as NOP IF Stage Test Output ********/
            if_tb(`WORD_DATA_W'h20,              // pc
                  `WORD_DATA_W'h24,              // if_pc
                  `WORD_DATA_W'h13,              // if_insn
                  `ENABLE                        // if_en
                 );

            /******** ADDI r0, r0, 0 as NOP ID Stage Test Output ********/
            id_tb(`ENABLE,                       // id_en
                  `ALU_OP_ADD,                   // id_alu_op
                  `WORD_DATA_W'h0,               // id_alu_in_0
                  `WORD_DATA_W'h0,               // id_alu_in_1
                  `CMP_OP_NOP,                   // id_cmp_op
                  `WORD_DATA_W'h0,               // id_cmp_in_0
                  `WORD_DATA_W'h0,               // id_cmp_in_1
                  `REG_ADDR_W'h0,                // id_ra_addr
                  `REG_ADDR_W'h0,                // id_rb_addr
                  `DISABLE,                      // id_jump_taken
                  `MEM_OP_NOP,                   // id_mem_op
                  `WORD_DATA_W'h0,               // id_mem_wr_data
                  `REG_ADDR_W'h0,                // id_dst_addr
                  `ENABLE_,                      // id_gpr_we_
                  `EX_OUT_ALU,                   // id_gpr_mux_ex
                  `WORD_DATA_W'h20,              // id_gpr_wr_data

                  `ISA_OP_ALSI,                  // op
                  `REG_ADDR_W'h0,                // ra_addr
                  `REG_ADDR_W'h0,                // rb_addr
                  2'b01                          // src_reg_used
                 );
            
            /******** SLTU  r5, r4, r2 Stage Test Output ********/
            ex_tb(`WORD_DATA_W'h0,               // ex_fwd_data
                  `ENABLE,                       // ex_en
                  `MEM_OP_NOP,                   // ex_mem_op
                  `WORD_DATA_W'hffff8004,        // ex_mem_wr_data
                  `REG_ADDR_W'h5,                // ex_dst_addr
                  `ENABLE_,                      // ex_gpr_we_
                  `WORD_DATA_W'h1,               // ex_out
                  `WORD_DATA_W'h0,               // br_addr
                  `DISABLE                       // br_taken
                 );

            /******** SLT   r5, r4, r2 MEM Stage Test Output ********/
            mem_tb(`WORD_DATA_W'h1,              // mem_fwd_data
                   `ENABLE,                      // mem_en
                   `REG_ADDR_W'h5,               // mem_dst_addr
                   `ENABLE_,                     // mem_gpr_we_
                   `WORD_DATA_W'h0               // mem_out
                  );

            $display("WB Stage ...");

            ctrl_tb(`DISABLE,                    // if_stall
                    `DISABLE,                    // id_stall
                    `DISABLE,                    // ex_stall
                    `DISABLE,                    // mem_stall
                    `DISABLE,                    // if_flush
                    `DISABLE,                    // id_flush
                    `DISABLE,                    // ex_flush
                    `DISABLE,                    // mem_flush
                    `WORD_DATA_W'h0,             // new_pc

                    `FWD_CTRL_NONE,              // ra_fwd_ctrl
                    `FWD_CTRL_NONE,              // rb_fwd_ctrl
                    `DISABLE,                    // ex_ra_fwd_en
                    `DISABLE                     // ex_rb_fwd_en
                   );
        end
        # STEP begin
            $display("\n========= Clock 10 ========");
            /******** ADDI r0, r0, 0 as NOP IF Stage Test Output ********/
            if_tb(`WORD_DATA_W'h24,              // pc
                  `WORD_DATA_W'h28,              // if_pc
                  `WORD_DATA_W'h13,              // if_insn
                  `ENABLE                        // if_en
                 );

            /******** ADDI r0, r0, 0 as NOP ID Stage Test Output ********/
            id_tb(`ENABLE,                       // id_en
                  `ALU_OP_ADD,                   // id_alu_op
                  `WORD_DATA_W'h0,               // id_alu_in_0
                  `WORD_DATA_W'h0,               // id_alu_in_1
                  `CMP_OP_NOP,                   // id_cmp_op
                  `WORD_DATA_W'h0,               // id_cmp_in_0
                  `WORD_DATA_W'h0,               // id_cmp_in_1
                  `REG_ADDR_W'h0,                // id_ra_addr
                  `REG_ADDR_W'h0,                // id_rb_addr
                  `DISABLE,                      // id_jump_taken
                  `MEM_OP_NOP,                   // id_mem_op
                  `WORD_DATA_W'h0,               // id_mem_wr_data
                  `REG_ADDR_W'h0,                // id_dst_addr
                  `ENABLE_,                      // id_gpr_we_
                  `EX_OUT_ALU,                   // id_gpr_mux_ex
                  `WORD_DATA_W'h24,              // id_gpr_wr_data

                  `ISA_OP_ALSI,                  // op
                  `REG_ADDR_W'h0,                // ra_addr
                  `REG_ADDR_W'h0,                // rb_addr
                  2'b01                          // src_reg_used
                 );
            
            /******** ADDI r0, r0, 0 Stage Test Output ********/
            ex_tb(`WORD_DATA_W'h0,               // ex_fwd_data
                  `ENABLE,                       // ex_en
                  `MEM_OP_NOP,                   // ex_mem_op
                  `WORD_DATA_W'h0,               // ex_mem_wr_data
                  `REG_ADDR_W'h0,                // ex_dst_addr
                  `ENABLE_,                      // ex_gpr_we_
                  `WORD_DATA_W'h0,               // ex_out
                  `WORD_DATA_W'h0,               // br_addr
                  `DISABLE                       // br_taken
                 );

            /******** SLTU  r5, r4, r2 MEM Stage Test Output ********/
            mem_tb(`WORD_DATA_W'h0,              // mem_fwd_data
                   `ENABLE,                      // mem_en
                   `REG_ADDR_W'h5,               // mem_dst_addr
                   `ENABLE_,                     // mem_gpr_we_
                   `WORD_DATA_W'h1               // mem_out
                  );

            $display("WB Stage ...");

            ctrl_tb(`DISABLE,                    // if_stall
                    `DISABLE,                    // id_stall
                    `DISABLE,                    // ex_stall
                    `DISABLE,                    // mem_stall
                    `DISABLE,                    // if_flush
                    `DISABLE,                    // id_flush
                    `DISABLE,                    // ex_flush
                    `DISABLE,                    // mem_flush
                    `WORD_DATA_W'h0,             // new_pc

                    `FWD_CTRL_NONE,              // ra_fwd_ctrl
                    `FWD_CTRL_NONE,              // rb_fwd_ctrl
                    `DISABLE,                    // ex_ra_fwd_en
                    `DISABLE                     // ex_rb_fwd_en
                   );
        end
        # STEP begin
            $display("\n========= Clock 11 ========");
            /******** ADDI r0, r0, 0 as NOP IF Stage Test Output ********/
            if_tb(`WORD_DATA_W'h28,              // pc
                  `WORD_DATA_W'h2c,              // if_pc
                  `WORD_DATA_W'h13,              // if_insn
                  `ENABLE                        // if_en
                 );

            /******** ADDI r0, r0, 0 as NOP ID Stage Test Output ********/
            id_tb(`ENABLE,                       // id_en
                  `ALU_OP_ADD,                   // id_alu_op
                  `WORD_DATA_W'h0,               // id_alu_in_0
                  `WORD_DATA_W'h0,               // id_alu_in_1
                  `CMP_OP_NOP,                   // id_cmp_op
                  `WORD_DATA_W'h0,               // id_cmp_in_0
                  `WORD_DATA_W'h0,               // id_cmp_in_1
                  `REG_ADDR_W'h0,                // id_ra_addr
                  `REG_ADDR_W'h0,                // id_rb_addr
                  `DISABLE,                      // id_jump_taken
                  `MEM_OP_NOP,                   // id_mem_op
                  `WORD_DATA_W'h0,               // id_mem_wr_data
                  `REG_ADDR_W'h0,                // id_dst_addr
                  `ENABLE_,                      // id_gpr_we_
                  `EX_OUT_ALU,                   // id_gpr_mux_ex
                  `WORD_DATA_W'h28,              // id_gpr_wr_data

                  `ISA_OP_ALSI,                  // op
                  `REG_ADDR_W'h0,                // ra_addr
                  `REG_ADDR_W'h0,                // rb_addr
                  2'b01                          // src_reg_used
                 );
            
            /******** ADDI r0, r0, 0 Stage Test Output ********/
            ex_tb(`WORD_DATA_W'h0,               // ex_fwd_data
                  `ENABLE,                       // ex_en
                  `MEM_OP_NOP,                   // ex_mem_op
                  `WORD_DATA_W'h0,               // ex_mem_wr_data
                  `REG_ADDR_W'h0,                // ex_dst_addr
                  `ENABLE_,                      // ex_gpr_we_
                  `WORD_DATA_W'h0,               // ex_out
                  `WORD_DATA_W'h0,               // br_addr
                  `DISABLE                       // br_taken
                 );

            /******** ADDI r0, r0, 0 MEM Stage Test Output ********/
            mem_tb(`WORD_DATA_W'h0,              // mem_fwd_data
                   `ENABLE,                      // mem_en
                   `REG_ADDR_W'h0,               // mem_dst_addr
                   `ENABLE_,                     // mem_gpr_we_
                   `WORD_DATA_W'h0               // mem_out
                  );

            $display("WB Stage ...");

            ctrl_tb(`DISABLE,                    // if_stall
                    `DISABLE,                    // id_stall
                    `DISABLE,                    // ex_stall
                    `DISABLE,                    // mem_stall
                    `DISABLE,                    // if_flush
                    `DISABLE,                    // id_flush
                    `DISABLE,                    // ex_flush
                    `DISABLE,                    // mem_flush
                    `WORD_DATA_W'h0,             // new_pc

                    `FWD_CTRL_NONE,              // ra_fwd_ctrl
                    `FWD_CTRL_NONE,              // rb_fwd_ctrl
                    `DISABLE,                    // ex_ra_fwd_en
                    `DISABLE                     // ex_rb_fwd_en
                   );
            $finish;
        end
    end

    /******** Output Waveform ********/
    initial begin
       $dumpfile("cpu.vcd");
       $dumpvars(0,if_stage, id_stage, ex_stage, mem_stage, ctrl ,gpr, spm);
    end

endmodule
