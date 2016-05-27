/**
 * filename: hart_state.v
 * module  : hart state unit
 * author  : besky
 * time    : 2016-05-25 20:29:59
 */
`include "stddef.h"
`include "isa.h"
`include "hart_ctrl.h"

module hart_state (
    //_ cpu_part _____________________________________________________________//
    input  wire                  clk,
    input  wire                  rst,

    // ID stage part
    input  wire                  hstart,
    input  wire                  hkill,
    input  wire [`HART_STATE_B]  set_hart_id,
    output wire [`HART_SST_B]    get_hart_val,     // state value of set_hart_id 2: pend, 1: active, 0:idle
    output wire                  get_hart_idle,    // is hart idle 1: idle, 0: non-idle
    output reg  [`HART_STATE_B]  idle_hstate,      // 3:0

    // IF stage part
    input  wire                  i_cache_miss,
    input  wire [`HART_STATE_B]  if_hstate,        // IF stage hart state 3:0
    input  wire                  i_cache_fin,      // memory access finish
    input  wire [`HART_STATE_B]  i_cache_fin_hstate,

    // MEM stage part
    input  wire                  use_cache_miss,
    input  wire [`HART_STATE_B]  use_hstate,       // Used hart state 3:0, 
    input  wire                  d_cache_fin,
    input  wire [`HART_STATE_B]  d_cache_fin_hstate,

    //_ hstu_part ____________________________________________________________//
    output reg  [`HART_STATE_B]  prim_hstate,
    output reg  [`HART_STATE_B]  acti_hstate       // 3:0
);

    //_ get_hart_val(for hart control ins.) ______________________________________________________//
    assign get_hart_idle = idle_hstate[set_hart_id];
    assign get_hart_val[0] =  acti_hstate[set_hart_id] & ~get_hart_idle;
    assign get_hart_val[1] = ~acti_hstate[set_hart_id] & ~get_hart_idle;


    //_ hart_prim_hstate ______________________________________________________//
    wire [`HART_STATE_B] next_prim_hstate;

    minor_hart_sel next_prim_hart_sel_i (
        .minor_hstate   (next_acti_hstate & ~prim_hstate),
        .one_hot_hstate (next_prim_hstate)
    );

    always @(posedge clk) begin
        if (rst) prim_hstate <= `HART_STATE_W'b0001;
        else if (prim_hstate == `HART_STATE_W'b0000) begin
            if      (i_cache_fin) prim_hstate <= i_cache_fin_hstate;
            else if (d_cache_fin) prim_hstate <= d_cache_fin_hstate;
        end
        else if (  i_cache_miss & if_hstate   == prim_hstate
               | use_cache_miss & use_hstate  == prim_hstate
               |          hkill & set_hart_id == prim_hstate)
            prim_hstate <= next_prim_hstate;
    end

    //_ acti_hstate ______________________________________________________//
    reg [`HART_STATE_B] next_acti_hstate;
    always @(i_cache_fin, d_cache_fin, i_cache_miss, use_cache_miss,
             if_hstate, use_hstate, hstart, set_hart_id) begin
        if (i_cache_fin)    next_acti_hstate =      acti_hstate | i_cache_fin_hstate;
        else                next_acti_hstate =      acti_hstate;
        if (d_cache_fin)    next_acti_hstate = next_acti_hstate | d_cache_fin_hstate;
        else                next_acti_hstate = next_acti_hstate;
        if (i_cache_miss)   next_acti_hstate = next_acti_hstate & ~if_hstate;
        else                next_acti_hstate = next_acti_hstate;
        if (use_cache_miss) next_acti_hstate = next_acti_hstate & ~use_hstate;
        else                next_acti_hstate = next_acti_hstate;
        if      (hstart & get_hart_idle) next_acti_hstate[set_hart_id] = 1'b1;
        else if (hkill & ~get_hart_idle) next_acti_hstate[set_hart_id] = 1'b0;
        else                next_acti_hstate = next_acti_hstate;
    end

    always @(posedge clk) begin
        if (rst) acti_hstate <= `HART_STATE_W'b0001;
        else     acti_hstate <= next_acti_hstate;
    end

    //_ idle_hstate ______________________________________________________//
    always @(posedge clk) begin
        if (rst) idle_hstate <= `HART_STATE_W'b1110;
        else if (hstart) idle_hstate[set_hart_id] <= 1'b0;
        else if (hkill)  idle_hstate[set_hart_id] <= 1'b1;
    end
endmodule
