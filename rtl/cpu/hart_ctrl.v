/**
 * filename: hart_ctrl.v
 * author  : besky
 * time    : 2016-05-17 23:15:28
 */
`include "common_defines.v"
`include "isa.h"
`include "hart_ctrl.h"
// `include "hart_state.v"
// `include "hart_switch.v"

module hart_ctrl (
    input  wire                  clk,
    input  wire                  rst,

    // ID stage part
    input  wire                  id_hstart,
    input  wire                  id_hkill,
    input  wire [`HART_ID_B]     id_set_hid,
    input  wire                  id_hidle,
    input  wire [`HART_ID_B]     spec_hid,
    output wire [`HART_SST_B]    get_hart_val,      // state value of id_set_hid 2: pend, 1: active, 0:idle
    output wire                  get_hart_idle,     // is hart idle 1: idle, 0: non-idle

    input  wire                  is_branch,          // conditional branch ins
    input  wire                  is_load,            // load ins
    input  wire [`HART_ID_B]     if_hart_id,         // if_hart_id => current id stage hart id

    output wire                  hart_ic_stall,      // Need to stall pipeline (caused by i-cache miss)
    output wire                  hart_dc_stall,      // Need to stall pipeline (caused by d-cache miss)
    output wire                  hart_ic_flush,      // Need to flush pipeline (caused by i-cache miss)
    output wire                  hart_dc_flush,      // Need to flush pipeline (caused by d-cache miss)
    output wire [`HART_STATE_B]  hart_acti_hstate,   // 3:0
    output wire [`HART_STATE_B]  hart_idle_hstate,   // 3:0

    // IF stage part
    input  wire                  i_cache_miss,
    input  wire                  i_cache_fin,        // i cache access finish
    input  wire [`HART_ID_B]     i_cache_fin_hid,

    output wire [`HART_ID_B]     hart_issue_hid,     // 1:0
    output wire [`HART_STATE_B]  hart_issue_hstate,  // 3:0

    // MEM stage part
    input  wire                  d_cache_miss,
    input  wire [`HART_ID_B]     ex_hart_id,         // Used hart state 3:0
    input  wire                  d_cache_fin,
    input  wire [`HART_ID_B]     d_cache_fin_hid
);
    wire [`HART_STATE_B] prim_hstate;
    wire [`HART_STATE_B] acti_hstate; 

    assign hart_acti_hstate = acti_hstate;

    hart_id_encoder hart_id_encoder_i(hart_issue_hstate, hart_issue_hid);

    

    hart_state hart_state_i (
        //_ cpu_part _________________________________________________________//
        .clk                (clk),
        .rst                (rst),

        // ID stage part
        .id_hstart          (id_hstart),
        .id_hkill           (id_hkill),
        .id_set_hid         (id_set_hid),
        .id_hidle           (id_hidle),
        .spec_hid           (spec_hid),
        .get_hart_val       (get_hart_val),
        .get_hart_idle      (get_hart_idle),
        .idle_hstate        (hart_idle_hstate),

        // IF stage part
        .i_cache_miss       (i_cache_miss),
        .issue_hid          (hart_issue_hid),
        .i_cache_fin        (i_cache_fin),
        .i_cache_fin_hid    (i_cache_fin_hid),

        // MEM stage part
        .d_cache_miss       (d_cache_miss),
        .ex_hart_id         (ex_hart_id),
        .d_cache_fin        (d_cache_fin),
        .d_cache_fin_hid    (d_cache_fin_hid),

        //_ hstu_part ________________________________________________________//
        .prim_hstate        (prim_hstate),
        .acti_hstate        (acti_hstate),
        //_ from hart_switch ________________________________________________________//
        .hart_ic_stall      (hart_ic_stall),
        .hart_dc_stall      (hart_dc_stall) 
    );


    hart_switch hart_switch_i (
        //_ cpu_part _____________________________________________________________//
        .clk                (clk),
        .rst                (rst),

        // ID stage part
        .id_hkill           (id_hkill),
        .id_set_hid         (id_set_hid),

        .is_branch          (is_branch),
        .is_load            (is_load),
        .if_hart_id         (if_hart_id),

        .hart_ic_stall      (hart_ic_stall),
        .hart_dc_stall      (hart_dc_stall),
        .hart_ic_flush      (hart_ic_flush),
        .hart_dc_flush      (hart_dc_flush),

        // IF stage part
        .i_cache_miss       (i_cache_miss),
        .i_cache_fin        (i_cache_fin),
        .hart_issue_hstate  (hart_issue_hstate),

        // MEM stage part
        .d_cache_miss       (d_cache_miss),
        .d_cache_fin        (d_cache_fin),

        //_ hstu_part ________________________________________________________//
        .prim_hstate        (prim_hstate),
        .acti_hstate        (acti_hstate)
    );
endmodule

module minor_hart_sel (
    input  wire [`HART_STATE_B] minor_hstate,
    output reg  [`HART_STATE_B] one_hot_hstate
);
    always @(*) casez (minor_hstate)
        `HART_STATE_W'b1???: one_hot_hstate = `HART_STATE_W'b1000;
        `HART_STATE_W'b01??: one_hot_hstate = `HART_STATE_W'b0100;
        `HART_STATE_W'b001?: one_hot_hstate = `HART_STATE_W'b0010;
        `HART_STATE_W'b0001: one_hot_hstate = `HART_STATE_W'b0001;
        default            : one_hot_hstate = `HART_STATE_W'b0000;
    endcase
endmodule

module decoder_n #(parameter WIDTH = 4) (
    input  wire [WIDTH-1:0] din,
    output reg  [2**WIDTH-1:0] dout
);
    always @ (*) begin
        dout = 'b0;
        dout[din] = 1'b1;
    end
endmodule

/**
 * function: convert 4-bit hart_state to 2-bit hart_id
 */
module hart_id_encoder (
    input  wire [`HART_STATE_B] hart_state,
    output reg  [`HART_ID_B]    hart_id
);
    always @(hart_state) begin
        case (hart_state)
            4'b0001: hart_id = 2'b00;
            4'b0010: hart_id = 2'b01;
            4'b0100: hart_id = 2'b10;
            4'b1000: hart_id = 2'b11;
            default: hart_id = 2'b00;
        endcase
    end
endmodule
