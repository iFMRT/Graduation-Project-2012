`include "isa.h"
`include "alu.h"
`include "cmp.h"
`include "ctrl.h"
`include "stddef.h"
`include "cpu.h"
`include "mem.h"
`include "ex_stage.h"

module id_stage (
    /********** Clock & Reset **********/
    input                   clk,           // Clock
    input                   reset,         // Asynchronous Reset
    /********** GPR Interface **********/
    input [`WORD_DATA_BUS]  gpr_rd_data_0, // Read data 0
    input [`WORD_DATA_BUS]  gpr_rd_data_1, // Read data 1
    output [`REG_ADDR_BUS]  gpr_rd_addr_0, // Read address 0
    output [`REG_ADDR_BUS]  gpr_rd_addr_1, // Read address 1

    input  wire [`WordDataBus]   ex_fwd_data,    
    input  wire [`RegAddrBus]    ex_dst_addr,    
    input  wire                  ex_gpr_we_, 

    input  wire [`WordDataBus]   mem_fwd_data, 

    input  wire                  stall,          
    input  wire                  flush,          
    output wire                  ld_hazard,      

    /********** IF/ID Pipeline Register **********/
    input [`WORD_DATA_BUS]  if_pc,         // Program counter
    input [`WORD_DATA_BUS]  if_pc_plus4,   // Jump adn link return address
    input [`WORD_DATA_BUS]  if_insn,       // Instruction
    input                   if_en,         // Pipeline data enable
    /********** ID/EXPipeline  Register  **********/
    output                  id_en,         // Pipeline data enable
    output [`ALU_OP_BUS]    id_alu_op,     // ALU Operation
    output [`WORD_DATA_BUS] id_alu_in_0,   // ALU input 0
    output [`WORD_DATA_BUS] id_alu_in_1,   // ALU input 1
    output [`MEM_OP_BUS]    id_mem_op,     // Memory Operation
    output [`WORD_DATA_BUS] id_mem_wr_data,// Memory write data
    output [`REG_ADDR_BUS]  id_dst_addr,   // GPRwrite address
    output                  id_gpr_we_,    // GPRwrite enable
    output [`EX_OUT_SEL_BUS] id_gpr_mux_ex,
    output [`WORD_DATA_BUS] id_gpr_wr_data
);

    wire [`ALU_OP_BUS]      alu_op;         // ALU Operation
    wire [`WORD_DATA_BUS]   alu_in_0;       // ALU input 0
    wire [`WORD_DATA_BUS]   alu_in_1;       // ALU input 1
    wire [`MEM_OP_BUS]      mem_op;         // Memory operation
    wire [`WORD_DATA_BUS]   mem_wr_data;    // Memory write data
    wire [`EX_OUT_SEL_BUS]     gpr_mux_ex;  // ex stage gpr write multiplexer
    wire  [`WORD_DATA_BUS]   gpr_wr_data;   // ID stage output gpr write data
    wire [`REG_ADDR_BUS]    dst_addr;       // GPR write address
    wire                    gpr_we_;        // GPR write enable

    decoder decoder (
        /********** IF/ID Pipeline Register **********/
        .if_pc          (if_pc),          // Program counter
        .if_pc_plus4    (if_pc_plus4),
        .if_insn        (if_insn),        // Instruction
        .if_en          (if_en),          // Pipeline data enable
        /********** GPR Interface **********/
        .gpr_rd_data_0  (gpr_rd_data_0),  // Read data 0
        .gpr_rd_data_1  (gpr_rd_data_1),  // Read data 1
        .gpr_rd_addr_0  (gpr_rd_addr_0),  // Read address 0
        .gpr_rd_addr_1  (gpr_rd_addr_1),  // Read address 1

        .id_en          (id_en),          // パイプラインデータの有効
        .id_dst_addr    (id_dst_addr),    // 書き込みアドレス
        .id_gpr_we_     (id_gpr_we_),     // 書き込み有効
        .id_mem_op      (id_mem_op),      // メモリオペレーション

        .ex_fwd_data    (ex_fwd_data),    // フォワーディングデータ
        .ex_dst_addr    (ex_dst_addr),    // 書き込みアドレス
        .ex_gpr_we_     (ex_gpr_we_),     // 書き込み有効

        .mem_fwd_data   (mem_fwd_data),   // フォワーディングデータ
        /********** Decoder Result **********/
        .alu_op         (alu_op),         // ALU Operation
        .alu_in_0       (alu_in_0),       // ALU input 0
        .alu_in_1       (alu_in_1),       // ALU input 1
        .mem_op         (mem_op),         // Memory operation
        .mem_wr_data    (mem_wr_data),    // Memory write data
        .gpr_mux_ex     (gpr_mux_ex),     // ex stage gpr write multiplexer
        .gpr_wr_data    (gpr_wr_data),    // ID stage output gpr write data
        .dst_addr       (dst_addr),       // General purpose Register write address
        .gpr_we_        (gpr_we_)         // General purpose Register write enable
        .ld_hazard      (ld_hazard)       // ロードハザード

    );

    id_reg id_reg (
        /********** Clock & Reset **********/
        .clk            (clk),            // Clock
        .reset          (reset),          // Asynchronous Reset
        /********** Decode Result **********/
        .alu_op         (alu_op),         // ALU Operation
        .alu_in_0       (alu_in_0),       // ALU input 0
        .alu_in_1       (alu_in_1),       // ALU input 1
        .mem_op         (mem_op),         // Memory operation
        .mem_wr_data    (mem_wr_data),    // Memory write data
        .dst_addr       (dst_addr),       // General purpose Register write address
        .gpr_we_        (gpr_we_),        // General purpose Register write enable
        .gpr_mux_ex     (gpr_mux_ex),
        .gpr_wr_data    (gpr_wr_data),    // ID stage output gpr write data

        .stall           (stall),          // ストール
        .flush          (flush),          // フラッシュ
        /********** IF/ID Pipeline  Register  **********/
        .if_en          (if_en),          // Pipeline data enable
        /********** ID/EX Pipeline  Register  **********/
        .id_en          (id_en),          // Pipeline data enable
        .id_alu_op      (id_alu_op),      // ALU Operation
        .id_alu_in_0    (id_alu_in_0),    // ALU input 0
        .id_alu_in_1    (id_alu_in_1),    // ALU input 1
        .id_mem_op      (id_mem_op),      // Memory operation
        .id_mem_wr_data (id_mem_wr_data), // Memory write data
        .id_dst_addr    (id_dst_addr),    // General purpose Register write address
        .id_gpr_we_     (id_gpr_we_),     // General purpose Register write enable
        .id_gpr_mux_ex  (id_gpr_mux_ex),
        .id_gpr_wr_data (id_gpr_wr_data)
    );

endmodule
