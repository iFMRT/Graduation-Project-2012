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
    input                    clk,           // Clock
    input                    reset,         // Asynchronous Reset
    /********** GPR Interface **********/
    input  [`WORD_DATA_BUS]  gpr_rd_data_0, // Read data 0
    input  [`WORD_DATA_BUS]  gpr_rd_data_1, // Read data 1
    output [`REG_ADDR_BUS]   gpr_rd_addr_0, // Read address 0
    output [`REG_ADDR_BUS]   gpr_rd_addr_1, // Read address 1

    input                    ex_en,      
    input  [`WORD_DATA_BUS]  ex_fwd_data,
    input  [`REG_ADDR_BUS]   ex_dst_addr,
    input                    ex_gpr_we_,

    input  [`WORD_DATA_BUS]  mem_fwd_data,

    input                    stall,
    input                    flush,

    /********** Forward Signal **********/
    input [`FWD_CTRL_BUS]    ra_fwd_ctrl,
    input [`FWD_CTRL_BUS]    rb_fwd_ctrl,

    /********** IF/ID Pipeline Register **********/
    input [`WORD_DATA_BUS]   if_pc,         // Program counter
    input [`WORD_DATA_BUS]   if_pc_plus4,   // Jump adn link return address
    input [`WORD_DATA_BUS]   if_insn,       // Instruction
    input                    if_en,         // Pipeline data enable
    /********** ID/EXPipeline  Register  **********/
    output                   id_en,         // Pipeline data enable
    output [`ALU_OP_BUS]     id_alu_op,     // ALU Operation
    output [`WORD_DATA_BUS]  id_alu_in_0,   // ALU input 0
    output [`WORD_DATA_BUS]  id_alu_in_1,   // ALU input 1
    output [`REG_ADDR_BUS]   id_ra_addr,
    output [`REG_ADDR_BUS]   id_rb_addr,
    output                   id_jump_taken,
    output [`MEM_OP_BUS]     id_mem_op,     // Memory Operation
    output [`WORD_DATA_BUS]  id_mem_wr_data,// Memory write data
    output [`REG_ADDR_BUS]   id_dst_addr,   // GPRwrite address
    output                   id_gpr_we_,    // GPRwrite enable
    output [`EX_OUT_SEL_BUS] id_gpr_mux_ex,
    output [`WORD_DATA_BUS]  id_gpr_wr_data,

    output [`INS_OP_BUS]     op,
    output [`REG_ADDR_BUS]   ra_addr,
    output [`REG_ADDR_BUS]   rb_addr,
    output [1:0]             src_reg_used
);

    wire [`ALU_OP_BUS]     alu_op;         // ALU Operation
    wire [`WORD_DATA_BUS]  alu_in_0;       // ALU input 0
    wire [`WORD_DATA_BUS]  alu_in_1;       // ALU input 1
    wire                   jump_taken;
   
    wire [`MEM_OP_BUS]     mem_op;         // Memory operation
    wire [`WORD_DATA_BUS]  mem_wr_data;    // Memory write data
    wire [`EX_OUT_SEL_BUS] gpr_mux_ex;     // EX stage gpr write multiplexer
    wire [`WORD_DATA_BUS]  gpr_wr_data;    // ID stage output gpr write data
    wire [`REG_ADDR_BUS]   dst_addr;       // GPR write address
    wire                   gpr_we_;        // GPR write enable

    /********** Two Operand **********/
    reg  [`WORD_DATA_BUS] ra_data;         // The first operand
    reg  [`WORD_DATA_BUS] rb_data;         // The two operand

    /********** Forward **********/
    always @(*) begin
        /* Forward Ra */
        case (ra_fwd_ctrl)
            `FWD_CTRL_EX : begin
                ra_data = ex_fwd_data;   // Forward from EX stage
            end
            `FWD_CTRL_MEM: begin
                ra_data = mem_fwd_data;  // Forward from MEM stage
            end
            default      : begin
                ra_data = gpr_rd_data_0; // Don't need forward
            end
        endcase

        /* Forward Rb */
        case (rb_fwd_ctrl)
            `FWD_CTRL_EX : begin
                rb_data = ex_fwd_data;   // Forward from EX stage
            end
            `FWD_CTRL_MEM: begin
                rb_data = mem_fwd_data;  // Forward from MEM stage
            end
            default      : begin
                rb_data = gpr_rd_data_1; // Don't need forward
            end
        endcase
    end

    decoder decoder (
        /********** IF/ID Pipeline Register **********/
        .if_pc          (if_pc),          // Program counter
        .if_pc_plus4    (if_pc_plus4),
        .if_insn        (if_insn),        // Instruction
        .if_en          (if_en),          // Pipeline data enable
        
        .ra_data        (ra_data),  // Read data 0
        .rb_data        (rb_data),  // Read data 1
        /********** GPR Interface **********/
        .gpr_rd_addr_0  (gpr_rd_addr_0),  // Read address 0
        .gpr_rd_addr_1  (gpr_rd_addr_1),  // Read address 1

        /********** Decoder Result **********/
        .alu_op         (alu_op),         // ALU Operation
        .alu_in_0       (alu_in_0),       // ALU input 0
        .alu_in_1       (alu_in_1),       // ALU input 1
        .jump_taken       (jump_taken),        // Branch taken enable

        .mem_op         (mem_op),         // Memory operation
        .mem_wr_data    (mem_wr_data),    // Memory write data
        .gpr_mux_ex     (gpr_mux_ex),     // ex stage gpr write multiplexer
        .gpr_wr_data    (gpr_wr_data),    // ID stage output gpr write data
        .dst_addr       (dst_addr),       // General purpose Register write address
        .gpr_we_        (gpr_we_),         // General purpose Register write enable
        
        .op             (op),
        .ra_addr        (ra_addr),
        .rb_addr        (rb_addr), 
        .src_reg_used   (src_reg_used)     

    );
        
    id_reg id_reg (
        /********** Clock & Reset **********/
        .clk            (clk),            // Clock
        .reset          (reset),          // Asynchronous Reset
        /********** Decode Result **********/
        .alu_op         (alu_op),         // ALU Operation
        .alu_in_0       (alu_in_0),       // ALU input 0
        .alu_in_1       (alu_in_1),       // ALU input 1
        .ra_addr        (ra_addr),
        .rb_addr        (rb_addr),
        .jump_taken       (jump_taken),        // Branch taken enable

        .mem_op         (mem_op),         // Memory operation
        .mem_wr_data    (mem_wr_data),    // Memory write data
        .dst_addr       (dst_addr),       // General purpose Register write address
        .gpr_we_        (gpr_we_),        // General purpose Register write enable
        .gpr_mux_ex     (gpr_mux_ex),
        .gpr_wr_data    (gpr_wr_data),    // ID stage output gpr write data

        .stall          (stall),          // Stall
        .flush          (flush),          // Flush
        /********** IF/ID Pipeline  Register  **********/
        .if_en          (if_en),          // Pipeline data enable
        /********** ID/EX Pipeline  Register  **********/
        .id_en          (id_en),          // Pipeline data enable
        .id_alu_op      (id_alu_op),      // ALU Operation
        .id_alu_in_0    (id_alu_in_0),    // ALU input 0
        .id_alu_in_1    (id_alu_in_1),    // ALU input 1
        .id_ra_addr     (id_ra_addr),
        .id_rb_addr     (id_rb_addr),
        .id_jump_taken    (id_jump_taken),        // Branch taken enable

        .id_mem_op      (id_mem_op),      // Memory operation
        .id_mem_wr_data (id_mem_wr_data), // Memory write data
        .id_dst_addr    (id_dst_addr),    // General purpose Register write address
        .id_gpr_we_     (id_gpr_we_),     // General purpose Register write enable
        .id_gpr_mux_ex  (id_gpr_mux_ex),
        .id_gpr_wr_data (id_gpr_wr_data)
    );
    
endmodule
