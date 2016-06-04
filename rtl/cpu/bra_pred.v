//----------------------------------------------------------------------------------
// FILENAME: bra_pred.v
// DESCRIPTION: branch predictor unit (a tage branch predictor)
// AUTHOR: cjh
// TIME: 2016-04-14 19:15:07 
//==================================================================================

`timescale 1ns/1ps

`include "brap.h"
`include "stddef.h"

module bra_pred(
    /****** from pipeline ******/
    input   wire                    clk,            // clock
    input   wire                    reset,          // reset
    input   wire[`WORD_DATA_BUS]    pc,             // current pc
    input   wire[`WORD_DATA_BUS]    id_pc,          // the pc from id_reg
    input   wire[`WORD_DATA_BUS]    tar_pc,         // the branch target pc from ex
    input   wire[`WORD_DATA_BUS]    pre_pc,         
    input   wire                    bran_en,        // ex stage that branch taken
    input   wire                    stall_if,       // the stall signal of if reg
    input   wire                    flush_if,       // the flush signal of if reg
    input   wire                    stall_id,       // the stall signal of id reg
    input   wire                    flush_id,       // the flush signal of id reg
    input   wire                    pip_tr_bran,
    input   wire[`CMP_OP_BUS]       id_cmp_op,
    input   wire                    id_gpr_we_,
    input   wire                    id_jump_taken,
    input   wire[`HART_ID_B]        thread_num,
    /****** output to pipeline to change the next pc ******/
    output  wire[`WORD_DATA_BUS]    bran_addr,
    output  wire[`WORD_DATA_BUS]    pr_tar_data,    // a pc to if stage to jump
    output  wire                    pr_br_en,       // the target data is enable
    output  wire                    pr_pip_flush    // flush pipeline regists
);
    
    wire tar_en,bl0_m_id,bl1_u_id,bl2_u_id,bl3_u_id,pre_u_id,bl0_m_data,bl1_u_data,bl2_u_data,bl3_u_data;
    wire bl1_wr_update,bl2_wr_update,bl3_wr_update,bl1_wr_di,bl2_wr_di,bl3_wr_di,bl1_u_if,bl2_u_if,bl3_u_if;
    wire pre_u_if,bl0_m_if,pre_u,tr_bran_if,tr_bran_id,is_branch;
    wire[`HitBlockBus]  hit_block_if,hit_block_id,pr_hit_block;
    wire[`PreCouBus]    counter_id,bl0_coun_id,bl0_coun_data,bl1_coun_data,bl2_coun_data,bl3_coun_data;
    wire[`PreCouBus]    bl0_coun_if,counter_if,pre_counter,bl1_coun_divid,bl2_coun_divid,bl3_coun_divid;
    wire[`Bl0DataBus]   bl0_rd;
    wire[`BlDataBus]    bl1_rd,bl2_rd,bl3_rd;
    wire[`WORD_DATA_BUS]tar_addr_if,tar_addr_id,pre_pc_if,pre_pc_id;
    wire[39:0]          br_his;
    wire[`Bl0AddrBus]   bl0_addr_if,bl0_addr_id;
    wire[`BlAddrBus]    bl1_addr_if,bl2_addr_if,bl3_addr_if,bl1_addr_id,bl2_addr_id,bl3_addr_id;
    wire[`PreTagBus]    bl1_tag_if,bl1_tag_id,bl2_tag_if,bl2_tag_id,bl3_tag_if,bl3_tag_id;
    wire[`TagBus]       block0_tag,block1_tag,block2_tag,block3_tag,block0_tag_if,block1_tag_if,block2_tag_if;
    wire[`TagBus]       block3_tag_if,block0_tag_id,block1_tag_id,block2_tag_id,block3_tag_id;
    wire[`PlruRamBus]   plru_data,plru_data_if,plru_data_id;
    reg                 tar_update;
    reg[`WORD_DATA_BUS] target_pc;

    wire[`PreTagBus]    bl1_tag = bl1_rd[`RdTag];       // block1 tag
    wire[`PreTagBus]    bl2_tag = bl2_rd[`RdTag];       // block2 tag
    wire[`PreTagBus]    bl3_tag = bl3_rd[`RdTag];       // block3 tag

    wire[`PreCouBus]    bl0_counter = bl0_rd[`RdCounter];   // block0 counter
    wire[`PreCouBus]    bl1_counter = bl1_rd[`RdCounter];   // block1 counter
    wire[`PreCouBus]    bl2_counter = bl2_rd[`RdCounter];   // block2 counter
    wire[`PreCouBus]    bl3_counter = bl3_rd[`RdCounter];   // block3 counter

    wire        bl0_m = bl0_rd[0];      // block0 m
    wire        bl1_u = bl1_rd[0];      // block1 useful
    wire        bl2_u = bl2_rd[0];      // block2 useful
    wire        bl3_u = bl3_rd[0];      // block3 useful

    wire[`Bl0AddrBus] bl0_addr_pr = pc[`PcBl0Addr1] ^ pc[`PcBl0Addr2];                  // bl0 address to read 
    wire[`BlAddrBus] bl1_addr_pr = pc[`PcBlAddr1] ^ pc[`PcBlAddr2] ^ br_his[9:0];       // bl1 address to read
    wire[`BlAddrBus] bl2_addr_pr = bl1_addr_pr ^ br_his[19:10];                         // bl2 address to read
    wire[`BlAddrBus] bl3_addr_pr = bl2_addr_pr ^ br_his[29:20] ^ br_his[39:30];         // bl3 address to read

    wire bl0_wr;
    wire bl1_wr = bl1_wr_update | bl1_wr_di;
    wire bl2_wr = bl2_wr_update | bl2_wr_di;
    wire bl3_wr = bl3_wr_update | bl3_wr_di;

    wire[`Bl0AddrBus] bl0_addr = bl0_wr ? bl0_addr_id : bl0_addr_pr;    // if write enable,the address--
    wire[`BlAddrBus] bl1_addr = bl1_wr ? bl1_addr_id : bl1_addr_pr;     // --is write address,else the--
    wire[`BlAddrBus] bl2_addr = bl2_wr ? bl2_addr_id : bl2_addr_pr;     // --address is read address。
    wire[`BlAddrBus] bl3_addr = bl3_wr ? bl3_addr_id : bl3_addr_pr; 

    wire[`Bl0DataBus] bl0_wd = {bl0_coun_data,bl0_m_data};
    wire[`BlDataBus] bl1_wd = {bl1_tag_id,bl1_coun_data|bl1_coun_divid,bl1_u_data};
    wire[`BlDataBus] bl2_wd = {bl2_tag_id,bl2_coun_data|bl2_coun_divid,bl2_u_data};
    wire[`BlDataBus] bl3_wd = {bl3_tag_id,bl3_coun_data|bl3_coun_divid,bl3_u_data};

    wire[`PreTagBus] bl1_tag_pr = pc[31:24] ^ pc[9:2] ^ br_his[7:0];
    wire[`PreTagBus] bl2_tag_pr = bl1_tag_pr ^ br_his[17:10];
    wire[`PreTagBus] bl3_tag_pr = bl2_tag_pr ^ br_his[27:20] ^ br_his[37:30];

    assign pr_br_en = tar_en & pre_counter[1];  
    assign is_branch = ((id_cmp_op != `CMP_OP_NOP) && id_gpr_we_) || id_jump_taken;
    assign bran_addr = (bran_en === 1'b1) ? tar_pc : (id_pc + 32'd4);
    reg[32:0] br_num,miss_num;

    always @(*) begin
        if(bran_en && tar_pc !== pre_pc_id) begin
            target_pc <= id_pc;
            tar_update <= `ENABLE;
        end else begin
            target_pc <= pc;
            tar_update <= `DISABLE;
        end
    end
    initial begin
        #10
        br_num = 0;
        miss_num = 0;
    end
  /*  always @(negedge clk)begin
        if(is_branch)begin
            br_num = br_num + 1;
             $display("branch number = %d",br_num);
            if(pr_pip_flush)begin
                miss_num = miss_num + 1;
                 $display("miss number = %d",miss_num);
            end
        end
    end */
    
    ram12x3 block0(                     // predictor block0 ram
        .clk            (clk),
        .ram_addr       (bl0_addr),
        .wd             (bl0_wd),
        .rden           (`ENABLE),
        .wr             (bl0_wr),
        .rd             (bl0_rd)
    );

    ram10x11 block1(                    // predictor block1 ram
        .clk            (clk),
        .ram_addr       (bl1_addr),
        .wd             (bl1_wd),
        .rden           (`ENABLE),
        .wr             (bl1_wr),
        .rd             (bl1_rd)
    );

    ram10x11 block2(                    // predictor block2 ram
        .clk            (clk),
        .ram_addr       (bl2_addr),
        .wd             (bl2_wd),
        .rden           (`ENABLE),
        .wr             (bl2_wr),
        .rd             (bl2_rd)
    );

    ram10x11 block3(                    // predictor block3 ram
        .clk            (clk),
        .ram_addr       (bl3_addr),
        .wd             (bl3_wd),
        .rden           (`ENABLE),
        .wr             (bl3_wr),
        .rd             (bl3_rd)
    );

    t_buffer t_buffer(                          // target address buffer
        .clk            (clk),
        .pc             (target_pc),
        .update         (tar_update),
        .tar_addr       (tar_pc),
        .block0_tag_id  (block0_tag_id),
        .block1_tag_id  (block1_tag_id),
        .block2_tag_id  (block2_tag_id),
        .block3_tag_id  (block3_tag_id),
        .plru_data_id   (plru_data_id),
        .tar_data       (pr_tar_data),
        .tar_en         (tar_en),
        .block0_tag     (block0_tag),
        .block1_tag     (block1_tag),
        .block2_tag     (block2_tag),
        .block3_tag     (block3_tag),
        .plru_data      (plru_data)
    );

    pre_update  up_module(                      // update the four blocks
        .is_branch      (is_branch),
        .bran_en        (bran_en),              // mark if branch taken
        .counter_id     (counter_id),           // the counter that predict the branch
        .bl0_coun_id    (bl0_coun_id),          // counter from block0
        .hit_block_id   (hit_block_id),         // which block predict the branch
        .bl0_m_id       (bl0_m_id),             // block0 m from id reg
        .pre_u_id       (pre_u_id),             // predict block u from id reg
        .bl0_m_data     (bl0_m_data),           // m bit to write to block0
        .bl1_u_data     (bl1_u_data),           // u bit to write to block1
        .bl2_u_data     (bl2_u_data),           // u bit to write to block2
        .bl3_u_data     (bl3_u_data),           // u bit to write to block3
        .bl0_coun_data  (bl0_coun_data),        // counter to write to block0
        .bl1_coun_data  (bl1_coun_data),        // counter to write to block1
        .bl2_coun_data  (bl2_coun_data),        // counter to write to block2
        .bl3_coun_data  (bl3_coun_data),        // counter to write to block3
        .bl0_wr_update  (bl0_wr),               // block0 write enable
        .bl1_wr_update  (bl1_wr_update),        // block1 write enable
        .bl2_wr_update  (bl2_wr_update),        // block2 write enable
        .bl3_wr_update  (bl3_wr_update)         // block3 write enable
    );

    pre_divid div_module(                       // divide module
        .is_branch      (is_branch),            // the instruction is a branch one
        .counter_id     (counter_id),           // the counter that predict the branch
        .bran_en        (bran_en),              // mark if branch taken
        .hit_block_id   (hit_block_id),         // which block predict the branch
        .bl1_u_id       (bl1_u_id),             // u bit of block1 from pipeline
        .bl2_u_id       (bl2_u_id),             // u bit of block2 from pipeline
        .bl3_u_id       (bl3_u_id),             // u bit of block3 from pipeline
        .bl1_wr_di      (bl1_wr_di),            // block1 write enable
        .bl2_wr_di      (bl2_wr_di),            // block2 write enable
        .bl3_wr_di      (bl3_wr_di),            // block3 write enable
        .bl1_coun_divid (bl1_coun_divid),       // counter to write to block1
        .bl2_coun_divid (bl2_coun_divid),       // counter to write to block2
        .bl3_coun_divid (bl3_coun_divid)        // counter to write to block3
    );

    sh_reg sh_reg(                              // shift regist to store branch history
        .thread_num     (thread_num),
        .clk            (clk),
        .reset          (reset),                
        .en             (is_branch),
        .counter        (bran_en),
        .sh_data        (br_his)
    );

    pre_pip_reg pre_if_reg(             // the if_reg of pipline to store some data of branch predictor
        .clk            (~clk),
        .reset          (reset),
        .stall          (stall_if),
        .flush          (flush_if),

        .pr_hit_block   (pr_hit_block),
        .bl0_counter    (bl0_counter),
        .bl1_u          (bl1_u),
        .bl2_u          (bl2_u),
        .bl3_u          (bl3_u),
        .pre_u          (pre_u),
        .bl0_addr_pr    (bl0_addr_pr),
        .bl1_addr_pr    (bl1_addr_pr),
        .bl2_addr_pr    (bl2_addr_pr),
        .bl3_addr_pr    (bl3_addr_pr),
        .pr_tar_data    (pr_tar_data),
        .pre_counter    (pre_counter),
        .bl0_m          (bl0_m),
        .bl1_tag        (bl1_tag),
        .bl2_tag        (bl2_tag),
        .bl3_tag        (bl3_tag),
        .block0_tag     (block0_tag),
        .block1_tag     (block1_tag),
        .block2_tag     (block2_tag),
        .block3_tag     (block3_tag),
        .plru_data      (plru_data),
        .pip_tr_bran    (pip_tr_bran),
        .pre_pc         (pre_pc),

        .hit_block_if   (hit_block_if),
        .bl0_coun_if    (bl0_coun_if),
        .bl1_u_if       (bl1_u_if),
        .bl2_u_if       (bl2_u_if),
        .bl3_u_if       (bl3_u_if),
        .pre_u_if       (pre_u_if),
        .bl0_addr_if    (bl0_addr_if),
        .bl1_addr_if    (bl1_addr_if),
        .bl2_addr_if    (bl2_addr_if),
        .bl3_addr_if    (bl3_addr_if),
        .tar_addr_if    (tar_addr_if),
        .counter_if     (counter_if),
        .bl0_m_if       (bl0_m_if),
        .bl1_tag_if     (bl1_tag_if),
        .bl2_tag_if     (bl2_tag_if),
        .bl3_tag_if     (bl3_tag_if),
        .block0_tag_if  (block0_tag_if),
        .block1_tag_if  (block1_tag_if),
        .block2_tag_if  (block2_tag_if),
        .block3_tag_if  (block3_tag_if),
        .plru_data_if   (plru_data_if),
        .tr_bran_if     (tr_bran_if),
        .pre_pc_if      (pre_pc_if)
    );

    pre_pip_reg pre_id_reg(                 // the id_reg of pipline to store some data of branch predictor
        .clk            (~clk),
        .reset          (reset),
        .stall          (stall_id),
        .flush          (flush_id),

        .pr_hit_block   (hit_block_if),
        .bl0_counter    (bl0_coun_if),
        .bl1_u          (bl1_u_if),
        .bl2_u          (bl2_u_if),
        .bl3_u          (bl3_u_if),
        .pre_u          (pre_u_if),
        .bl0_addr_pr    (bl0_addr_if),
        .bl1_addr_pr    (bl1_addr_if),
        .bl2_addr_pr    (bl2_addr_if),
        .bl3_addr_pr    (bl3_addr_if),
        .pr_tar_data    (tar_addr_if),
        .pre_counter    (counter_if),
        .bl0_m          (bl0_m_if),
        .bl1_tag        (bl1_tag_if),
        .bl2_tag        (bl2_tag_if),
        .bl3_tag        (bl3_tag_if),
        .block0_tag     (block0_tag_if),
        .block1_tag     (block1_tag_if),
        .block2_tag     (block2_tag_if),
        .block3_tag     (block3_tag_if),
        .plru_data      (plru_data_if),
        .pip_tr_bran    (pip_tr_bran),
        .pre_pc         (pre_pc),

        .hit_block_if   (hit_block_id),
        .bl0_coun_if    (bl0_coun_id),
        .bl1_u_if       (bl1_u_id),
        .bl2_u_if       (bl2_u_id),
        .bl3_u_if       (bl3_u_id),
        .pre_u_if       (pre_u_id),
        .bl0_addr_if    (bl0_addr_id),
        .bl1_addr_if    (bl1_addr_id),
        .bl2_addr_if    (bl2_addr_id),
        .bl3_addr_if    (bl3_addr_id),
        .tar_addr_if    (tar_addr_id),
        .counter_if     (counter_id),
        .bl0_m_if       (bl0_m_id),
        .bl1_tag_if     (bl1_tag_id),
        .bl2_tag_if     (bl2_tag_id),
        .bl3_tag_if     (bl3_tag_id),
        .block0_tag_if  (block0_tag_id),
        .block1_tag_if  (block1_tag_id),
        .block2_tag_if  (block2_tag_id),
        .block3_tag_if  (block3_tag_id),
        .plru_data_if   (plru_data_id),
        .tr_bran_if     (tr_bran_id),
        .pre_pc_if      (pre_pc_id)
    );

    bp_out bp_out(                      // a logic block to output
        .bl3_tag        (bl3_tag),
        .bl2_tag        (bl2_tag),
        .bl1_tag        (bl1_tag),
        .bl3_tag_pr     (bl3_tag_pr),
        .bl2_tag_pr     (bl2_tag_pr),
        .bl1_tag_pr     (bl1_tag_pr),
        .bl3_wr         (bl3_wr),
        .bl2_wr         (bl2_wr),
        .bl1_wr         (bl1_wr),
        .bl0_wr         (bl0_wr),
        .bl3_counter    (bl3_counter),
        .bl2_counter    (bl2_counter),
        .bl1_counter    (bl1_counter),
        .bl0_counter    (bl0_counter),
        .bl3_u          (bl3_u),
        .bl2_u          (bl2_u),
        .bl1_u          (bl1_u),

        .pre_counter    (pre_counter),
        .pr_hit_block   (pr_hit_block),
        .pre_u          (pre_u)
);
    reg_flush reg_flush(            // mark contral hazard
        .pre_pc_id      (pre_pc_id),
        .tar_pc         (tar_pc),
        .bran_en        (bran_en),
        .tr_bran_id     (tr_bran_id),

        .pr_pip_flush   (pr_pip_flush)
);
    
endmodule

/****** shift regist ******/
module sh_reg(
    input wire[1:0]         thread_num, // thread_number
    input wire              clk,        // clock
    input wire              reset,      // reset
    input wire              en,         // shift enable
    input wire              counter,    // input number
    output wire[39:0]       sh_data     // output data
);

    reg[39:0]   sh_reg[3:0];
    always @(negedge clk) begin
        if(reset) begin
            sh_reg[0] = 40'd0;
            sh_reg[1] = 40'd0;
            sh_reg[2] = 40'd0;
            sh_reg[3] = 40'd0;
        end else if(en) begin
            sh_reg[thread_num] <= {sh_reg[thread_num][38:0],counter};       // shift left 1 bit
        end
    end

    assign sh_data = sh_reg[thread_num];


endmodule
        
module pre_update(
    /****** if the branch predict is true ******/
    input wire                  is_branch,
    input wire                  bran_en,        // branch taken
    input wire[`PreCouBus]      counter_id,     // the counter from pipeline regist
    input wire[`PreCouBus]      bl0_coun_id,    // bl0_coun_id from pipeline regist
    input wire[`HitBlockBus]    hit_block_id,   // mark the block who predict the branch
    input wire                  bl0_m_id,       // block0 m from id reg
    input wire                  pre_u_id,       // predict block u from id reg

    output wire                 bl0_m_data,     // the m data in block0 when update
    output wire                 bl1_u_data,     // the use bit in block1 when update
    output wire                 bl2_u_data,     // the use bit in block2 when update
    output wire                 bl3_u_data,     // the use bit in block3 when update
    output wire[`PreCouBus]     bl0_coun_data,  // the counter date in block0 to update
    output wire[`PreCouBus]     bl1_coun_data,  // the counter date in block1 to update
    output wire[`PreCouBus]     bl2_coun_data,  // the counter date in block2 to update
    output wire[`PreCouBus]     bl3_coun_data,  // the counter date in block3 to update
    output wire                 bl0_wr_update,  // block0 write signal from update
    output wire                 bl1_wr_update,  // block1 write signal from update
    output wire                 bl2_wr_update,  // block2 write signal from update
    output wire                 bl3_wr_update   // block3 write signal from update
);

    wire    bl0_wr_coun,bl1_wr_coun,bl2_wr_coun;
    wire    bl3_wr_coun,bl0_wr_um,bl1_wr_um,bl2_wr_um,bl3_wr_um,u_input;
    wire    coun_update;
    wire[`PreCouBus] coun_input;

    update_coun up_coun(                // to update counter
        .is_branch      (is_branch),
        .bran_en        (bran_en),
        .counter_id     (counter_id),

        .coun_update    (coun_update),
        .coun_input     (coun_input)
    );

    update_um up_um(                    // to update u bit and m bit
        .bl0_coun_id    (bl0_coun_id),
        .counter_id     (counter_id),
        .hit_block_id   (hit_block_id),
        .bran_en        (bran_en),  
        .pre_u_id       (pre_u_id),
        .bl0_m_id       (bl0_m_id),
        .bl0_wr_um      (bl0_wr_um),
        .bl1_wr_um      (bl1_wr_um),
        .bl2_wr_um      (bl2_wr_um),
        .bl3_wr_um      (bl3_wr_um),
        .u_input        (u_input),
        .bl0_m_data     (bl0_m_data)
    );

    bl_wr bl_wr(                        // to provide write signal
        .hit_block_id   (hit_block_id),
        .coun_update    (coun_update),
        .coun_input     (coun_input),
        .u_input        (u_input),
        .bl0_wr_coun    (bl0_wr_coun),
        .bl1_wr_coun    (bl1_wr_coun),
        .bl2_wr_coun    (bl2_wr_coun),
        .bl3_wr_coun    (bl3_wr_coun),
        .bl0_coun_data  (bl0_coun_data),
        .bl1_coun_data  (bl1_coun_data),
        .bl2_coun_data  (bl2_coun_data),
        .bl3_coun_data  (bl3_coun_data),
        .bl1_u_data     (bl1_u_data),
        .bl2_u_data     (bl2_u_data),
        .bl3_u_data     (bl3_u_data)
    );

        assign bl0_wr_update = bl0_wr_coun | bl0_wr_um;
        assign bl1_wr_update = bl1_wr_coun | bl1_wr_um;
        assign bl2_wr_update = bl2_wr_coun | bl2_wr_um;
        assign bl3_wr_update = bl3_wr_coun | bl3_wr_um;

endmodule


/****** block write in counter update module ******/
module bl_wr(
    input wire[`HitBlockBus]    hit_block_id,       // mark the block predict branch
    input wire                  coun_update,        // counter need write
    input wire[`PreCouBus]      coun_input,         // counter write data
    input wire                  u_input,            // u bit write data

    output reg                  bl0_wr_coun,        // block0 write counter enable
    output reg                  bl1_wr_coun,        // block1 write counter enable
    output reg                  bl2_wr_coun,        // block2 write counter enable
    output reg                  bl3_wr_coun,        // block3 write counter enable
    output reg[`PreCouBus]      bl0_coun_data,      // block0 write counter data
    output reg[`PreCouBus]      bl1_coun_data,      // block1 write counter data
    output reg[`PreCouBus]      bl2_coun_data,      // block2 write counter data
    output reg[`PreCouBus]      bl3_coun_data,      // block3 write counter data
    output reg                  bl1_u_data,         // block1 write u bit data
    output reg                  bl2_u_data,         // block2 write u bit data
    output reg                  bl3_u_data          // block3 write u bit data
);

    always @(*) begin
        bl0_wr_coun = `DISABLE;
        bl1_wr_coun = `DISABLE;
        bl2_wr_coun = `DISABLE;
        bl3_wr_coun = `DISABLE;
        bl0_coun_data = 2'b00;
        bl1_coun_data = 2'b00;
        bl2_coun_data = 2'b00;
        bl3_coun_data = 2'b00;
        bl1_u_data = 1'b0;
        bl2_u_data = 1'b0;
        bl3_u_data = 1'b0;
        case(hit_block_id)
            `HIT_BLOCK0:begin
                bl0_wr_coun = coun_update;
                bl0_coun_data = coun_input;
            end
            `HIT_BLOCK1:begin
                bl1_wr_coun = coun_update;
                bl1_coun_data = coun_input;
                bl1_u_data = u_input;
            end
            `HIT_BLOCK2:begin
                bl2_wr_coun = coun_update;
                bl2_coun_data = coun_input;
                bl2_u_data = u_input;
            end
            `HIT_BLOCK3:begin
                bl3_wr_coun = coun_update;
                bl3_coun_data = coun_input;
                bl3_u_data = u_input;
            end
            default:begin
                bl0_wr_coun = `DISABLE;
                bl1_wr_coun = `DISABLE;
                bl2_wr_coun = `DISABLE;
                bl3_wr_coun = `DISABLE;
            end
        endcase
    end

endmodule

/****** update u and m ******/
module update_um(
    input wire[`PreCouBus]      bl0_coun_id,        // block0 counter from id_reg
    input wire[`PreCouBus]      counter_id,         // pridect counter from id_reg
    input wire[`HitBlockBus]    hit_block_id,       // hit block from id_reg
    input wire                  bran_en,            // EX stage true that branch taken
    input wire                  pre_u_id,           // u bit of predicted space
    input wire                  bl0_m_id,           // m bit of the same address in module0

    output reg                  bl0_wr_um,          // block0 write enable of um
    output reg                  bl1_wr_um,          // block1 write enable of um
    output reg                  bl2_wr_um,          // block2 write enable of um
    output reg                  bl3_wr_um,          // block3 write enable of um
    output reg                  u_input,            // u bit data to update
    output reg                  bl0_m_data          // m bit data to update
);


    always @(*) begin
        if(bl0_coun_id[1] !== counter_id[1] && hit_block_id != `HIT_BLOCK0) begin
            if(counter_id[1] == bran_en)begin 
            // predict is true but block0 predict false
                u_input <= 1'b1;
                bl0_m_data <= 1'b1;
            end 
            else begin
            // predict is false but block0 predict true
                u_input <= 1'b0;
                bl0_m_data <= 1'b0;
            end
            
            case(hit_block_id)
                `HIT_BLOCK1:begin
                    bl0_wr_um <= `DISABLE;
                    bl1_wr_um <= `ENABLE;
                    bl2_wr_um <= `DISABLE;
                    bl3_wr_um <= `DISABLE;
                end
                `HIT_BLOCK2:begin
                    bl0_wr_um <= `DISABLE;
                    bl1_wr_um <= `DISABLE;
                    bl2_wr_um <= `ENABLE;
                    bl3_wr_um <= `DISABLE;
                end
                `HIT_BLOCK3:begin
                    bl0_wr_um <= `DISABLE;
                    bl1_wr_um <= `DISABLE;
                    bl2_wr_um <= `DISABLE;
                    bl3_wr_um <= `ENABLE;
                end
                default:begin
                    bl0_wr_um <= `DISABLE;
                    bl1_wr_um <= `DISABLE;
                    bl2_wr_um <= `DISABLE;
                    bl3_wr_um <= `DISABLE;
                end
            endcase

        end else begin
            u_input = pre_u_id;
            bl0_m_data = bl0_m_id;
            bl0_wr_um = `DISABLE;
            bl1_wr_um = `DISABLE;
            bl2_wr_um = `DISABLE;
            bl3_wr_um = `DISABLE;

        end
    end

endmodule

module update_coun(
    input wire              is_branch,          // the instruction is a branch instruction
    input wire              bran_en,            // branch taken
    input wire[`PreCouBus]  counter_id,         // counter of predicted place

    output reg              coun_update,        // update enable
    output reg[`PreCouBus]  coun_input          // counter update data
);

    /****** update counter ******/
    always@(*) begin
        if(is_branch)begin
            if(bran_en)begin                        // branch taken
                if(counter_id === 2'd3) begin           // the counter is max
                    coun_update <= `DISABLE;            // update block is pridected block
                    coun_input <= counter_id;           // counter is not updated
                end 
                else if(counter_id === 2'bxx) begin     // block0 reset
                    coun_update <= `ENABLE;
                    coun_input <= 2'b10;    
                end 
                else begin                          // update
                    coun_update <= `ENABLE;
                    coun_input <= counter_id + 1;
                end
            end else begin                          // branch not taken
                if(counter_id === 2'd0) begin           // the counter is min
                    coun_update <= `DISABLE;
                    coun_input <= counter_id;
                end 
                else if(counter_id == 2'bxx) begin  // block0 reset
                    coun_update <= `ENABLE;
                    coun_input <= 2'b01;
                end 
                else begin                          // update
                    coun_update <= `ENABLE;
                    coun_input <= counter_id - 1;
                end
            end
        end else begin
            coun_update <= `DISABLE;
            coun_input <= 2'b00;
        end
    end

endmodule

/****** divid module logic ******/
module pre_divid(
    input wire              is_branch,      // instruction is a branch instruction
    input wire[`PreCouBus]  counter_id,     // the counter from id regist
    input wire              bran_en,        // branch taken
    input wire[`HitBlockBus] hit_block_id,  // mark the block who predict the branch
    input wire              bl1_u_id,       // block1 usable from pipeline
    input wire              bl2_u_id,       // block2 usable from pipeline
    input wire              bl3_u_id,       // block3 usable from pipeline

    output reg              bl1_wr_di,      // block1 write from di
    output reg              bl2_wr_di,      // block2 write from di
    output reg              bl3_wr_di,      // block3 write from di
    output reg[`PreCouBus]  bl1_coun_divid, // the counter write to block1
    output reg[`PreCouBus]  bl2_coun_divid, // the counter write to block2
    output reg[`PreCouBus]  bl3_coun_divid // the counter write to block3
);

    reg[`PreCouBus] coun_divid;

    always @(*) begin
        if(bran_en) begin
            coun_divid <= 2'b10;
        end else begin
            coun_divid <= 2'b01;
        end
    end
    
    always @(*) begin
        if((is_branch == 1) && (counter_id[1] != bran_en)) begin        // false predict
            case(hit_block_id)
                `HIT_BLOCK0:begin                           // block0 predict
                    if(bl1_u_id !== 1'b1) begin   
                        bl1_wr_di <= `ENABLE;
                        bl2_wr_di <= `DISABLE;
                        bl3_wr_di <= `DISABLE;
                        bl1_coun_divid <= coun_divid;
                        bl2_coun_divid <= 3'b0;
                        bl3_coun_divid <= 3'b0;
                    end else if(bl2_u_id !== 1'b1) begin
                        bl1_wr_di <= `DISABLE;
                        bl2_wr_di <= `ENABLE;
                        bl3_wr_di <= `DISABLE;
                        bl1_coun_divid <= 3'b0;
                        bl2_coun_divid <= coun_divid;
                        bl3_coun_divid <= 3'b0;
                    end else if(bl3_u_id !== 1'b1) begin
                        bl1_wr_di <= `DISABLE;
                        bl2_wr_di <= `DISABLE;
                        bl3_wr_di <= `ENABLE;
                        bl1_coun_divid <= 3'b0;
                        bl2_coun_divid <= 3'b0;
                        bl3_coun_divid <= coun_divid;
                    end else begin
                        bl1_wr_di <= `ENABLE;
                        bl2_wr_di <= `DISABLE;
                        bl3_wr_di <= `DISABLE;
                        bl1_coun_divid <= coun_divid;
                        bl2_coun_divid <= 3'b0;
                        bl3_coun_divid <= 3'b0;
                    end
                end
                `HIT_BLOCK1:begin                           // block1 predict
                    if(bl2_u_id !== 1'b1) begin
                        bl1_wr_di <= `DISABLE;
                        bl2_wr_di <= `ENABLE;
                        bl3_wr_di <= `DISABLE;
                        bl1_coun_divid <= 3'b0;
                        bl2_coun_divid <= coun_divid;
                        bl3_coun_divid <= 3'b0;
                    end else if(bl3_u_id !== 1'b1) begin
                        bl1_wr_di <= `DISABLE;
                        bl2_wr_di <= `DISABLE;
                        bl3_wr_di <= `ENABLE;
                        bl1_coun_divid <= 3'b0;
                        bl2_coun_divid <= 3'b0;
                        bl3_coun_divid <= coun_divid;
                    end else begin
                        bl1_wr_di <= `DISABLE;
                        bl2_wr_di <= `ENABLE;
                        bl3_wr_di <= `DISABLE;
                        bl1_coun_divid <= 3'b0;
                        bl2_coun_divid <= coun_divid;
                        bl3_coun_divid <= 3'b0;
                    end
                end
                `HIT_BLOCK2:begin                           // block2 predict
                    bl1_wr_di <= `DISABLE;
                    bl2_wr_di <= `DISABLE;
                    bl3_wr_di <= `ENABLE;
                    bl1_coun_divid <= 3'b0;
                    bl2_coun_divid <= 3'b0;
                    bl3_coun_divid <= coun_divid;
                end
                default:begin
                    bl1_wr_di <= `DISABLE;
                    bl2_wr_di <= `DISABLE;
                    bl3_wr_di <= `DISABLE; 
                    bl1_coun_divid <= 3'b0;
                    bl2_coun_divid <= 3'b0;
                    bl3_coun_divid <= 3'b0;
                end
            endcase
        end else begin
            bl1_wr_di <= `DISABLE;
            bl2_wr_di <= `DISABLE;
            bl3_wr_di <= `DISABLE; 
            bl1_coun_divid <= 3'b0;
            bl2_coun_divid <= 3'b0;
            bl3_coun_divid <= 3'b0;
        end

    end

endmodule

module bp_out(
    input wire[`PreTagBus]  bl3_tag,
    input wire[`PreTagBus]  bl2_tag,
    input wire[`PreTagBus]  bl1_tag,
    input wire[`PreTagBus]  bl3_tag_pr,
    input wire[`PreTagBus]  bl2_tag_pr,
    input wire[`PreTagBus]  bl1_tag_pr,
    input wire              bl3_wr,
    input wire              bl2_wr,
    input wire              bl1_wr,
    input wire              bl0_wr,
    input wire[`PreCouBus]  bl3_counter,
    input wire[`PreCouBus]  bl2_counter,
    input wire[`PreCouBus]  bl1_counter,
    input wire[`PreCouBus]  bl0_counter,
    input wire              bl3_u,
    input wire              bl2_u,
    input wire              bl1_u,

    output reg[`PreCouBus]  pre_counter,
    output reg[`HitBlockBus]pr_hit_block,
    output reg              pre_u
);
    always @(*) begin                                       // to output

        if (bl3_tag === bl3_tag_pr && bl3_wr == `DISABLE) begin
            pre_counter = bl3_counter;              // block3 hit
            pr_hit_block = `HIT_BLOCK3;
            pre_u = bl3_u;
        end
        else if (bl2_tag === bl2_tag_pr && bl2_wr == `DISABLE) begin            // block2 hit
            pre_counter = bl2_counter;
            pr_hit_block = `HIT_BLOCK2;
            pre_u = bl2_u;
        end
        else if (bl1_tag === bl1_tag_pr && bl1_wr == `DISABLE) begin            // block1 hit
            pre_counter = bl1_counter;
            pr_hit_block = `HIT_BLOCK1;
            pre_u = bl1_u;
        end
        else begin                                          // block0 pridect
            pre_u = 1'b0;
            pr_hit_block = `HIT_BLOCK0;             
            if(bl0_wr == `DISABLE) begin
                if(bl0_counter[1] === 1 || bl0_counter[1] === 0) begin
                    pre_counter = bl0_counter;
                end else begin
                    pre_counter = 2'b01;
                end
            end else begin
                pre_counter = 2'b01;
            end
        end

    end

endmodule

module reg_flush(
    input wire[`WORD_DATA_BUS]  pre_pc_id,          // the pc from id stage
    input wire[`WORD_DATA_BUS]  tar_pc,         // the pc that ex provite
    input wire                  bran_en,        // ex true branch taken
    input wire                  tr_bran_id,     // predictor predict branch taken

    output reg                  pr_pip_flush    // next pc is error
);

    always @(*) begin
        if (bran_en ) begin
            if(tr_bran_id !== 1'b1 || pre_pc_id !== tar_pc) begin
                pr_pip_flush = `ENABLE;    // predict succesful, needn't flush pipeline
            end else begin
                pr_pip_flush = `DISABLE;
            end
        end else begin

            if(tr_bran_id === 1'b1) begin
                pr_pip_flush = `ENABLE;     // false predict, and flush pipeline 
            end else begin
                pr_pip_flush = `DISABLE;
            end
        end
    end

endmodule

module pre_pip_reg(
    input wire                  clk,            // clock
    input wire                  reset,          // reset
    input wire                  stall,          // stall
    input wire                  flush,          // flush

    input wire[`HitBlockBus]    pr_hit_block,
    input wire[`PreCouBus]      bl0_counter,    // block0 counter
    input wire                  bl1_u,          // block1 u
    input wire                  bl2_u,          // block2 u
    input wire                  bl3_u,          // block3 u
    input wire                  pre_u,          // predict block u
    input wire[`Bl0AddrBus]     bl0_addr_pr,    // block0 address
    input wire[`BlAddrBus]      bl1_addr_pr,    // block1 address
    input wire[`BlAddrBus]      bl2_addr_pr,    // block2 address
    input wire[`BlAddrBus]      bl3_addr_pr,    // block3 address
    input wire[`WORD_DATA_BUS]  pr_tar_data,    // target data
    input wire[`PreCouBus]      pre_counter,    // predict block counter
    input wire                  bl0_m,          // block0 m
    input wire[`PreTagBus]      bl1_tag,        // block1 tag of predictor
    input wire[`PreTagBus]      bl2_tag,        // block2 tag of predictor
    input wire[`PreTagBus]      bl3_tag,        // block3 tag of predictor
    input wire[`TagBus]         block0_tag,     // block0 tag of BTB
    input wire[`TagBus]         block1_tag,     // block1 tag of BTB
    input wire[`TagBus]         block2_tag,     // block2 tag of BTB
    input wire[`TagBus]         block3_tag,     // block3 tag of BTB
    input wire[`PlruRamBus]     plru_data,      // plru data of BTB
    input wire                  pip_tr_bran,    // pipline true branch taken from if stage
    input wire[`WORD_DATA_BUS]  pre_pc,

    output reg[`HitBlockBus]    hit_block_if,
    output reg[`PreCouBus]      bl0_coun_if,    // block0 counter
    output reg                  bl1_u_if,       // block1 u
    output reg                  bl2_u_if,       // block2 u
    output reg                  bl3_u_if,       // block3 u
    output reg                  pre_u_if,       // predict block u
    output reg[`Bl0AddrBus]     bl0_addr_if,    // block0 address
    output reg[`BlAddrBus]      bl1_addr_if,    // block1 address
    output reg[`BlAddrBus]      bl2_addr_if,    // block2 address
    output reg[`BlAddrBus]      bl3_addr_if,    // block3 address
    output reg[`WORD_DATA_BUS]  tar_addr_if,    // terget data
    output reg[`PreCouBus]      counter_if,     // predict block counter
    output reg                  bl0_m_if,       // block0 m
    output reg[`PreTagBus]      bl1_tag_if,     // block1 tag of predictor
    output reg[`PreTagBus]      bl2_tag_if,     // block2 tag of predictor
    output reg[`PreTagBus]      bl3_tag_if,     // block3 tag of predictor
    output reg[`TagBus]         block0_tag_if,  // block0 tag of BTB
    output reg[`TagBus]         block1_tag_if,  // block1 tag of BTB
    output reg[`TagBus]         block2_tag_if,  // block2 tag of BTB
    output reg[`TagBus]         block3_tag_if,  // block3 tag of BTB
    output reg[`PlruRamBus]     plru_data_if,   // plru data of BTB
    output reg                  tr_bran_if,         // branch taken from if stage
    output reg[`WORD_DATA_BUS]  pre_pc_if
);
    
    always @(posedge clk) begin
        if(reset == `ENABLE) begin
            /****** reset ******/
            hit_block_if <= 2'b00;
            bl0_coun_if <= 2'b00;
            bl1_u_if <= 1'b0;
            bl2_u_if <= 1'b0;
            bl3_u_if <= 1'b0;
            pre_u_if <= 1'b0;
            bl0_addr_if <= 12'b0;
            bl1_addr_if <= 10'b0;
            bl2_addr_if <= 10'b0;
            bl3_addr_if <= 10'b0;
            tar_addr_if <= 32'b0;
            counter_if <= 2'b00;
            bl0_m_if <= 1'b0;
            bl1_tag_if <= 8'b0;
            bl2_tag_if <= 8'b0;
            bl3_tag_if <= 8'b0;
            block0_tag_if <= 21'b0;
            block1_tag_if <= 21'b0;
            block2_tag_if <= 21'b0;
            block3_tag_if <= 21'b0;
            plru_data_if <= 3'b0;
            tr_bran_if <= 1'b0;
            pre_pc_if  <= 32'b0;
        end else begin
            /****** update ******/
            if(stall == `DISABLE) begin
                if(flush == `ENABLE) begin
                    /**** flush ****/
                    hit_block_if <= 2'b00;
                    bl0_coun_if <= 2'b00;
                    bl1_u_if <= 1'b0;
                    bl2_u_if <= 1'b0;
                    bl3_u_if <= 1'b0;
                    pre_u_if <= 1'b0;
                    bl0_addr_if <= 12'b0;
                    bl1_addr_if <= 10'b0;
                    bl2_addr_if <= 10'b0;
                    bl3_addr_if <= 10'b0;
                    tar_addr_if <= 32'b0;
                    counter_if <= 2'b0;
                    bl0_m_if <= 1'b0;
                    bl1_tag_if <= 8'b0;
                    bl2_tag_if <= 8'b0;
                    bl3_tag_if <= 8'b0;
                    block0_tag_if <= 21'b0;
                    block1_tag_if <= 21'b0;
                    block2_tag_if <= 21'b0;
                    block3_tag_if <= 21'b0;
                    plru_data_if <= 3'b0;
                    tr_bran_if <= 1'b0;
                    pre_pc_if  <= 32'b0;
                end else begin
                    /**** update ****/
                    hit_block_if <= pr_hit_block;
                    bl0_coun_if <= bl0_counter;
                    bl1_u_if <= bl1_u;
                    bl2_u_if <= bl2_u;
                    bl3_u_if <= bl3_u;
                    pre_u_if <= pre_u;
                    bl0_addr_if <= bl0_addr_pr;
                    bl1_addr_if <= bl1_addr_pr;
                    bl2_addr_if <= bl2_addr_pr;
                    bl3_addr_if <= bl3_addr_pr;
                    tar_addr_if <= pr_tar_data;
                    counter_if <= pre_counter;
                    bl0_m_if <= bl0_m;
                    bl1_tag_if <= bl1_tag;
                    bl2_tag_if <= bl2_tag;
                    bl3_tag_if <= bl3_tag;
                    block0_tag_if <= block0_tag;
                    block1_tag_if <= block1_tag;
                    block2_tag_if <= block2_tag;
                    block3_tag_if <= block3_tag;
                    plru_data_if <= plru_data;
                    tr_bran_if <= pip_tr_bran;
                    pre_pc_if <= pre_pc;
                end
            end
        end
    end
endmodule