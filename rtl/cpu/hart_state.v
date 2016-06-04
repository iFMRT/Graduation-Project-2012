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
    input  wire                  id_hstart,
    input  wire                  id_hkill,
    input  wire [`HART_ID_B]     id_set_hid,
    input  wire                  id_hidle,
    input  wire [`HART_ID_B]     spec_hid,
    output wire [`HART_SST_B]    get_hart_val,     // state value of id_set_hid 2: pend, 1: active, 0:idle
    output wire                  get_hart_idle,    // is hart idle 1: idle, 0: non-idle
    output reg  [`HART_STATE_B]  idle_hstate,      // 3:0

    // IF stage part
    input  wire                  i_cache_miss,
    input  wire [`HART_ID_B]     issue_hid,        // IF stage hart state 3:0
    input  wire                  i_cache_fin,      // memory access finish
    input  wire [`HART_ID_B]     i_cache_fin_hid,

    // MEM stage part
    input  wire                  d_cache_miss,
    input  wire [`HART_ID_B]     ex_hart_id,
    input  wire                  d_cache_fin,
    input  wire [`HART_ID_B]     d_cache_fin_hid,

    //_ hstu_part ____________________________________________________________//
    output reg  [`HART_STATE_B]  prim_hstate,
    output reg  [`HART_STATE_B]  acti_hstate       // 3:0
);
    // hart id => hart state
    wire [`HART_STATE_B] ic_fin_hstate;
    wire [`HART_STATE_B] dc_fin_hstate;
    decoder_n #(`HART_ID_W) ic_fin_hstate_i(i_cache_fin_hid, ic_fin_hstate);
    decoder_n #(`HART_ID_W) dc_fin_hstate_i(d_cache_fin_hid, dc_fin_hstate);

    // hart state => hart id
    wire [`HART_ID_B] prim_hid;
    hart_id_encoder  prim_id_encoder_i(prim_hstate, prim_hid);

    //_ get_hart_val(for hart control ins.) ______________________________________________________//
    bit_sel #(`HART_ID_W) idle_sel_i (idle_hstate, spec_hid, get_hart_idle);

    wire get_hart_acti;
    bit_sel #(`HART_ID_W) acti_sel_i (acti_hstate, spec_hid, get_hart_acti);
    assign get_hart_val[0] =  get_hart_acti & ~get_hart_idle;
    assign get_hart_val[1] = ~get_hart_acti & ~get_hart_idle;

    //_ hart_prim_hstate ______________________________________________________//
    wire [`HART_STATE_B] next_prim_hstate;

    minor_hart_sel next_prim_hart_sel_i (
        .minor_hstate   (next_acti_hstate & ~prim_hstate),
        .one_hot_hstate (next_prim_hstate)
    );

    always @(posedge clk) begin
        if (rst) prim_hstate <= `HART_STATE_W'b0001;
        else if (prim_hstate == `HART_STATE_W'b0000) begin
            if      (i_cache_fin) prim_hstate <= ic_fin_hstate;
            else if (d_cache_fin) prim_hstate <= dc_fin_hstate;
        end
        else if ( i_cache_miss & issue_hid  == prim_hid
               |  d_cache_miss & ex_hart_id == prim_hid
               |      id_hkill & id_set_hid == prim_hid)
            prim_hstate <= next_prim_hstate;
    end

    //_ acti_hstate ______________________________________________________//
    reg [`HART_STATE_B] next_acti_hstate;
    always @(i_cache_fin, d_cache_fin, i_cache_miss, d_cache_miss,
             issue_hid, ex_hart_id, id_hkill, id_hstart, id_hidle, id_set_hid, 
             ic_fin_hstate, dc_fin_hstate) begin
        if (i_cache_fin)  next_acti_hstate =      acti_hstate | ic_fin_hstate;
        else              next_acti_hstate =      acti_hstate;
        if (d_cache_fin)  next_acti_hstate = next_acti_hstate | dc_fin_hstate;
        else              next_acti_hstate = next_acti_hstate;
        if (i_cache_miss) next_acti_hstate[issue_hid]  = 1'b0;
        else              next_acti_hstate = next_acti_hstate;
        if (d_cache_miss) next_acti_hstate[ex_hart_id] = 1'b0;
        else              next_acti_hstate = next_acti_hstate;
        if      (id_hstart & id_hidle) next_acti_hstate[id_set_hid] = 1'b1;
        else if (id_hkill & ~id_hidle) next_acti_hstate[id_set_hid] = 1'b0;
        else              next_acti_hstate = next_acti_hstate;
    end

    always @(posedge clk) begin
        if (rst) acti_hstate <= `HART_STATE_W'b0001;
        else     acti_hstate <= next_acti_hstate;
    end

    //_ idle_hstate ______________________________________________________//
    always @(posedge clk) begin
        if (rst) idle_hstate <= `HART_STATE_W'b1110;
        else if (id_hstart) idle_hstate[id_set_hid] <= 1'b0;
        else if (id_hkill)  idle_hstate[id_set_hid] <= 1'b1;
    end
endmodule

module bit_sel #(parameter SEL_WIDTH = 2) (
    input [SEL_WIDTH**2-1:0] din,
    input [SEL_WIDTH-1:0]    sel,
    output                   dout
);
    wire [SEL_WIDTH**2-1:0] one_hot_sel;
    decoder_n #(SEL_WIDTH) sel_decoder_i (sel, one_hot_sel);
    assign dout = (din & one_hot_sel) == 0 ? 1'b0 : 1'b1;
endmodule