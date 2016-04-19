/*
 -- ============================================================================
 -- FILE NAME   : ctrl.v
 -- DESCRIPTION : Control Module
 -- ----------------------------------------------------------------------------
 -- Date：2015/12/29
 -- ============================================================================
*/
`timescale 1ns/1ps

/********** Header file **********/
`include "isa.h"
`include "alu.h"
`include "cmp.h"
`include "ctrl.h"
`include "stddef.h"
`include "cpu.h"
`include "mem.h"
`include "ex_stage.h"

/********** module **********/
module ctrl (
    /********* pipeline control signals ********/
    input                         rst,
    //  State of Pipeline
    input  wire                   if_busy,      // IF busy mark // miss stall of if_stage
    input  wire                   br_taken,    // branch hazard mark
//  input  wire                   br_flag,      // branch instruction flag
    input  wire                   mem_busy,     // MEM busy mark // miss stall of mem_stage

    /********** Data Forward **********/
    input      [1:0]             src_reg_used,
    // LOAD Hazard
    input wire                   id_en,          // Pipeline Register enable
    input wire [`REG_ADDR_BUS]   id_dst_addr,    // GPR write address
    input wire                   id_gpr_we_,     // GPR write enable
    input wire [`MEM_OP_BUS]     id_mem_op,      // Mem operation

    input wire [`INS_OP_BUS]     op, 
    input wire [`REG_ADDR_BUS]   ra_addr,
    input wire [`REG_ADDR_BUS]   rb_addr,
    // LOAD STORE Forward
    input wire [`REG_ADDR_BUS]   id_ra_addr,
    input wire [`REG_ADDR_BUS]   id_rb_addr,

    input wire                   ex_en,          // Pipeline Register enable
    input wire [`REG_ADDR_BUS]   ex_dst_addr,    // GPR write address
    input wire                   ex_gpr_we_,     // GPR write enable
    input wire [`MEM_OP_BUS]     ex_mem_op,      // Mem operation

    // Stall Signal
    output wire                  if_stall,     // IF stage stall
    output wire                  id_stall,     // ID stage stall
    output wire                  ex_stall,     // EX stage stall
    output wire                  mem_stall,    // MEM stage stall
    // Flush Signal
    output wire                  if_flush,     // IF stage flush
    output wire                  id_flush,     // ID stage flush
    output wire                  ex_flush,     // EX stage flush
    output wire                  mem_flush,    // MEM stage flush
    output wire [`WORD_DATA_BUS] new_pc,        // New program counter

    // Forward from EX stage

    /********** Forward Output **********/
    output reg [`FWD_CTRL_BUS]   ra_fwd_ctrl,
    output reg [`FWD_CTRL_BUS]   rb_fwd_ctrl,
    output reg                   ex_ra_fwd_en,
    output reg                   ex_rb_fwd_en
);

    reg     ld_hazard;       // LOAD hazard
    wire    stall;
    /********** pipeline control **********/
    // stall
    // assign if_stall  = ld_hazard;
    // assign id_stall  = `DISABLE;
    // assign ex_stall  = `DISABLE;
    // assign mem_stall = `DISABLE;
    
    assign stall     = if_busy | mem_busy;
    assign if_stall  = stall   | ld_hazard;
    assign id_stall  = stall;
    assign ex_stall  = stall;
    assign mem_stall = stall;

    // flush
    assign if_flush  = `DISABLE;
    assign id_flush  = ld_hazard | br_taken;
    assign ex_flush  = `DISABLE;
    assign mem_flush = `DISABLE;
//  reg    flush;
//  assign if_flush  = flush | br_taken;
//  assign id_flush  = flush | ld_hazard | br_taken;
//  assign ex_flush  = flush;
//  assign mem_flush = flush;

    assign new_pc = `WORD_DATA_W'h0;
//  always @(*) begin
//     /* default */
//     new_pc = `WORD_DATA_W'h0;

//     flush  = `DISABLE;
//  end

    /********** Forward **********/
    always @(*) begin
        if (rst == `ENABLE) begin
            ld_hazard = `DISABLE;
        end
        /* Forward Ra */
        if( (id_en           == `ENABLE)  &&
            (id_gpr_we_      == `ENABLE_) &&
            (src_reg_used[0] == 1'b1)     &&   // use ra register
            (ra_addr         != 1'b0)     &&   // r0 always is 0, no need to forward
            (id_dst_addr     == ra_addr)
        ) begin
        
            ra_fwd_ctrl = `FWD_CTRL_EX;   // Forward from EX stage

        end else if (
            (ex_en           == `ENABLE)  &&
            (ex_gpr_we_      == `ENABLE_) &&
            (src_reg_used[0] == 1'b1)     &&   // use ra register
            (ra_addr         != 1'b0)     &&   // r0 always is 0, no need to forward
            (ex_dst_addr     == ra_addr)
        ) begin

            ra_fwd_ctrl = `FWD_CTRL_MEM;       // Forward from MEM stage

        end else begin

            ra_fwd_ctrl = `FWD_CTRL_NONE; // Don't need forward

        end

        /* LOAD in MEM and STORE in EX may need forward */
        if ((ex_en           == `ENABLE)  &&
            (ex_gpr_we_      == `ENABLE_) &&
            (ex_mem_op[3]    == 1'b1)     &&  // Check LOAD  in MEM, LOAD  Mem Op 1XXX
            (id_mem_op[3:2]  == 2'b01)    &&  // Check STORE in EX, STORE Mem Op 01XX
            (id_ra_addr      != 1'b0)     &&   // r0 always is 0, no need to forward
            (ex_dst_addr     == id_ra_addr)
        ) begin
            ex_ra_fwd_en = `ENABLE;
        end else begin
            ex_ra_fwd_en = `DISABLE;
        end

        /* Forward Rb */
        if ((id_en           == `ENABLE)    &&
            (id_gpr_we_      == `ENABLE_)   &&
            (src_reg_used[1] == 1'b1)       &&  // use rb register
            (rb_addr         != 1'b0)     &&   // r0 always is 0, no need to forward
            (id_dst_addr     == rb_addr)
        ) begin

            rb_fwd_ctrl = `FWD_CTRL_EX;   // Forward from EX stage

        end else if (
            (ex_en           == `ENABLE)    &&
            (ex_gpr_we_      == `ENABLE_)   &&
            (src_reg_used[1] == 1'b1)       &&  // use rb register
            (rb_addr         != 1'b0)     &&   // r0 always is 0, no need to forward
            (ex_dst_addr     == rb_addr)
        ) begin

            rb_fwd_ctrl = `FWD_CTRL_MEM;  // Forward from MEM stage


        end else begin

            rb_fwd_ctrl  = `FWD_CTRL_NONE ;    // Don't need forward

        end

        /* LOAD in MEM and STORE in EX may need forward */
        if ((ex_en           == `ENABLE)  &&
            (ex_gpr_we_      == `ENABLE_) &&
            (ex_mem_op[3]    == 1'b1)     &&  // Check LOAD  in MEM, LOAD  Mem Op 1XXX
            (id_mem_op[3:2]  == 2'b01)    &&  // Check STORE in EX, STORE Mem Op 01XX
            (id_rb_addr      != 1'b0)     &&   // r0 always is 0, no need to forward
            (ex_dst_addr     == id_rb_addr)
        ) begin
            ex_rb_fwd_en = `ENABLE;
        end else begin
            ex_rb_fwd_en = `DISABLE;
        end

    end

    // /********** Check Load hazard **********/
    always @(*) begin
        if ((id_en        == `ENABLE)         &&
            (id_gpr_we_   == `ENABLE_)        &&   // load must enable id_gpr_we_
            (id_mem_op[3] == 1'b1)            &&   // Check load in EX
            (
                (op != `ISA_OP_ST) || 
                ( (op  == `ISA_OP_ST)  && (id_dst_addr == ra_addr) )         
            )                                 &&   // store in ID may need stall
            (
                ( (src_reg_used[0] == 1'b1) && (id_dst_addr == ra_addr) ) ||
                ( (src_reg_used[1] == 1'b1) && (id_dst_addr == rb_addr) ) 
            )
                  
        ) begin 
            ld_hazard = `ENABLE;  // Need Load hazard
        end else begin
            ld_hazard = `DISABLE; // Don't nedd Load hazard
        end
    end

endmodule
