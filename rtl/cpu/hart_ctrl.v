/**
 * filename: hart_ctrl.v
 * author  : besky
 * time    : 2016-05-17 23:15:28
 */
`include "stddef.h"
`include "isa.h"
`include "hart_ctrl.h"
`include "hart_state.v"
`include "hart_switch.v"

module hart_ctrl (
    input  wire                  clk,
    input  wire                  rst,

    input  wire                  set_hart,
    input  wire [`HART_ID_B]     set_hart_id,
    input  wire                  set_hart_val,     // set hart state by value 1: active, 0: idle

    input  wire                  is_branch,        // conditional branch ins
    input  wire                  is_load,          // load ins
    input  wire [`HART_STATE_B]  id_hstate,

    input  wire                  i_cache_miss,
    input  wire [`HART_STATE_B]  if_hstate,        // IF stage hart state 3:0
    input  wire                  use_cache_miss,
    input  wire [`HART_STATE_B]  use_hstate,       // Used hart state 3:0, 

    input  wire                  i_cache_fin,      // memory access finish
    input  wire [`HART_STATE_B]  i_cache_fin_hstate,
    input  wire                  d_cache_fin,
    input  wire [`HART_STATE_B]  d_cache_fin_hstate,

    output wire [`HART_ID_B]     hart_issue_hid,         // 1:0
    output wire [`HART_STATE_B]  hart_issue_hstate,      // 3:0
    output wire [`HART_STATE_B]  hart_acti_hstate,       // 3:0
    output wire [`HART_STATE_B]  hart_idle_hstate        // 3:0
);
    assign hart_acti_hstate = acti_hstate;

    wire [`HART_STATE_B] set_hstate;
    decoder_n #(`HART_ID_W) hart_id_decoder_i(set_hart_id, set_hstate);
    hart_id_encoder hart_id_encoder_i(hart_issue_hstate, hart_issue_hid);

    wire [`HART_STATE_B] prim_hstate;
    wire [`HART_STATE_B] acti_hstate;

    hart_state hart_state_i (
        //_ cpu_part _________________________________________________________//
        .clk                (clk),
        .rst                (rst),

        .set_hart           (set_hart),
        .set_hstate         (set_hstate),
        .set_hart_val       (set_hart_val),

        .i_cache_miss       (i_cache_miss),
        .if_hstate          (if_hstate),
        .use_cache_miss     (use_cache_miss),
        .use_hstate         (use_hstate),

        .i_cache_fin        (i_cache_fin),
        .i_cache_fin_hstate (i_cache_fin_hstate),
        .d_cache_fin        (d_cache_fin),
        .d_cache_fin_hstate (d_cache_fin_hstate),

        .hart_idle_hstate   (hart_idle_hstate),

        //_ hstu_part ________________________________________________________//
        .prim_hstate        (prim_hstate),
        .acti_hstate        (acti_hstate)
    );


    hart_switch hart_switch_i (
        .clk                (clk),
        .rst                (rst),

        //_ cpu_part _________________________________________________________//
        .set_hart           (set_hart),
        .set_hstate         (set_hstate),
        .set_hart_val       (set_hart_val),

        .is_branch          (is_branch),
        .is_load            (is_load),
        .id_hstate          (id_hstate),

        .hart_issue_hstate  (hart_issue_hstate),

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
