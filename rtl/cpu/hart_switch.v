/**
 * filename: hart_switch.v
 * module  : hart switch unit
 * author  : besky
 * time    : 2016-05-25 20:28:55
 */
`include "stddef.h"
`include "isa.h"
`include "hart_ctrl.h"

module hart_switch (
    //_ cpu_part _____________________________________________________________//
    input  wire                  clk,
    input  wire                  rst,

    // ID stage part
    input  wire                  id_hkill,
    input  wire [`HART_ID_B]     id_set_hid,

    input  wire                  is_branch,        // conditional branch ins
    input  wire                  is_load,          // load ins
    input  wire [`HART_ID_B]     if_hart_id,

    output wire                  hart_ic_stall,    // Need to stall pipeline
    output wire                  hart_dc_stall,    // Need to stall pipeline
    output wire                  hart_ic_flush,    // Need to flush pipeline
    output wire                  hart_dc_flush,    // Need to flush pipeline

    // IF stage part
    input  wire                  i_cache_miss,
    input  wire                  i_cache_fin,        // i cache access finish
    output reg  [`HART_STATE_B]  hart_issue_hstate,      // 3:0

    // MEM stage part
    input  wire                  d_cache_miss,
    input  wire                  d_cache_fin,

    //_ hstu_part ____________________________________________________________//
    input  wire [`HART_STATE_B]  prim_hstate,
    input  wire [`HART_STATE_B]  acti_hstate
);
    wire [`HART_STATE_B] set_hstate;
    wire [`HART_STATE_B] ids_hstate;
    decoder_n #(`HART_ID_W) set_hstate_i(id_set_hid, set_hstate);
    decoder_n #(`HART_ID_W) ids_hstate_i(if_hart_id, ids_hstate);    // current ID stage hart state

    //_ pipeline stall _______________________________________________________//
    wire no_more_active;
    wire [`HART_STATE_B] ah;
    assign ah = acti_hstate;
    assign no_more_active = ~(ah[0] + ah[1] + ah[2]) +     // 1: only one or none active hart 0: two or more active harts
                            ~(ah[0] + ah[1] + ah[3]) +
                            ~(ah[0] + ah[2] + ah[3]) +
                            ~(ah[1] + ah[2] + ah[3]);
    // wire hart_ic_stall;    // i cache miss and need to stall
    // wire hart_dc_stall;    // d cache miss and need to stall
    assign hart_ic_stall = no_more_active & i_cache_miss & ~d_cache_fin;
    assign hart_dc_stall = no_more_active & d_cache_miss & ~i_cache_fin;

    //_ pipeline flush _______________________________________________________//
    assign hart_ic_flush = ~no_more_active & i_cache_miss;
    assign hart_dc_flush = ~no_more_active & d_cache_miss;

    //_ minor_hstate _________________________________________________________//
    wire [`HART_STATE_B] minor_hstate;
    wire [`HART_STATE_B] one_hot_hstate;

    assign minor_hstate = acti_hstate & ~prim_hstate;

    minor_hart_sel minor_hart_sel_i (
        .minor_hstate   (minor_hstate),
        .one_hot_hstate (one_hot_hstate)
    );

    //_ hart_issue_hstate _____________________________________________________//
    reg  [`HART_STATE_B] issue_hstate;    // last issue hart state
    wire [`HART_STATE_B] shifted_issue_hstate;

    cyclic_right_shifter cyclic_right_shifter_i(issue_hstate, shifted_issue_hstate);

    always @(*) begin
        if      (id_hkill & set_hstate == prim_hstate)
                                                          hart_issue_hstate = one_hot_hstate;
        else if (acti_hstate == `HART_STATE_W'b1111)      hart_issue_hstate = shifted_issue_hstate;
        else if (   minor_hstate == `HART_STATE_W'b0000)  hart_issue_hstate = prim_hstate;
        else if (is_branch & ids_hstate == prim_hstate)   hart_issue_hstate = one_hot_hstate;
        else if (  is_load & ids_hstate == prim_hstate)   hart_issue_hstate = one_hot_hstate;
        else if (issue_minor &  issue_twice)              hart_issue_hstate = minor_hstate;
        else if (issue_minor & ~issue_twice)              hart_issue_hstate = ~issue_hstate & minor_hstate;
        else                                              hart_issue_hstate = prim_hstate;
    end
    always @(posedge clk) begin
        if (rst) issue_hstate <= `HART_STATE_W'b0000;
        else     issue_hstate <= hart_issue_hstate;
    end

    reg                  issue_minor;
    reg                  issue_twice;
    wire                 issue_two_ins;
    assign issue_two_ins = acti_hstate == `HART_STATE_W'b0111
                         | acti_hstate == `HART_STATE_W'b1011
                         | acti_hstate == `HART_STATE_W'b1101
                         | acti_hstate == `HART_STATE_W'b1110;
    always @(posedge clk) begin
        if (rst) issue_minor <= 0;
        else if (is_load   & ids_hstate == prim_hstate
               | is_branch & ids_hstate == prim_hstate & issue_two_ins)
            issue_minor <= 1;
        else issue_minor <= 0;
    end
    always @(posedge clk) begin
        if (rst) issue_twice <= 1'b0;
        else if (is_load & (minor_hstate == `HART_STATE_W'b0001
                          | minor_hstate == `HART_STATE_W'b0010
                          | minor_hstate == `HART_STATE_W'b0100
                          | minor_hstate == `HART_STATE_W'b1000)
                ) 
            issue_twice <= 1'b1;
        else issue_twice <= 1'b0;
    end

endmodule

/**
 * function: cyclic shift right 1-bit to generate next interleaving hart_state
 */
module cyclic_right_shifter (
    input  wire [`HART_STATE_B] din,
    output reg  [`HART_STATE_B] dout
);
    always @(*) begin
        if (din >> 1 == 0) dout = {1'b1, 3'b0};
        else               dout = din >> 1;
    end
endmodule
