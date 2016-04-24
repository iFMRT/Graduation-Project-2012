/*
 -- ============================================================================
 -- FILE NAME   : 
 -- DESCRIPTION : 指令高速缓存器控制
 -- ----------------------------------------------------------------------------
 -- Date:2016/1/15         Coding_by:kippy
 -- ============================================================================
*/

`timescale 1ns/1ps

/********** General header file **********/
`include "stddef.h"
`include "icache.h"

module icache_ctrl(
    input              clk,           // clock
    input              rst,           // reset
    /* CPU part */
    input      [29:0]  if_addr,       // address of fetching instruction
    input              rw,            // read / write signal of CPU
    output reg [31:0]  cpu_data,      // read data of CPU
    output reg         miss_stall,    // the signal of stall caused by cache miss
    /* L1_cache part */
    input              lru,           // mark of replacing
    input      [20:0]  tag0_rd,       // read data of tag0
    input      [20:0]  tag1_rd,       // read data of tag1
    input      [127:0] data0_rd,      // read data of data0
    input      [127:0] data1_rd,      // read data of data1
    input      [127:0] data_wd_l2,     
    // output to L1_cache
    output reg [20:0]  tag_wd,        // write data of L1_tag
    output reg         block0_we,     // write signal of block0
    output reg         block1_we,     // write signal of block1
    output reg         block0_re,     // read signal of block0
    output reg         block1_re,     // read signal of block1
    output reg [7:0]   index,         // address of L1_cache
    /* L2_cache part */
    input              ic_en,         // icache enable signal of accessing L2_cache
    input              l2_rdy,        // ready signal of L2_cache
    input              complete,      // complete op writing to L1
    input              mem_wr_ic_en,
    output reg         irq,           // icache request
    output reg         ic_rw_en,      // enable signal of writing icache 
    output reg [27:0]  l2_addr,
    output             l2_cache_rw,
    /* if_reg part */
    output reg         data_rdy       // tag hit mark
    );
    reg                tagcomp_hit;
    reg                hitway0;          // the mark of choosing path0 
    reg                hitway1;          // the mark of choosing path1    
    reg        [2:0]   nextstate,state;  // state of control
    reg                choose_way;

    assign l2_cache_rw = rw;
    
    always @(*)begin // path choose
        hitway0 = (tag0_rd[19:0] == if_addr[29:10]) & tag0_rd[20];
        hitway1 = (tag1_rd[19:0] == if_addr[29:10]) & tag1_rd[20];
        if(hitway0 == `ENABLE)begin
            tagcomp_hit = `ENABLE;
        end
        else if(hitway1 == `ENABLE)begin
            tagcomp_hit = `ENABLE;
        end
        else begin
            tagcomp_hit = `DISABLE;
        end

        if (tag0_rd[20] == 1'b1) begin
            if (tag1_rd[20] == 1'b1) begin
                if(lru != 1'b1) begin
                    choose_way = `WAY0;
                end else begin
                    choose_way = `WAY1;
                end                    
            end else begin
                choose_way = `WAY1;
            end
        end else begin
            choose_way = `WAY0;
        end          
    end

    always @(*) begin 
        case(state)
            `IC_IDLE:begin
                miss_stall  = `DISABLE;
                ic_rw_en    = `DISABLE;
                data_rdy    = `DISABLE;
                block0_re   = `ENABLE;
                block1_re   = `ENABLE;
                nextstate   = `IC_ACCESS;
                index       = if_addr[9:2];
                l2_addr     = if_addr[29:2];
                tag_wd      = {1'b1,if_addr[29:10]};
            end
            `IC_ACCESS:begin                
                index       = if_addr[9:2];
                l2_addr     = if_addr[29:2];
                tag_wd      = {1'b1,if_addr[29:10]};
                data_rdy    = `DISABLE;
                if (tagcomp_hit == `ENABLE) begin // cache hit
                    // read l1_block ,write to cpu
                    miss_stall  = `DISABLE;
                    nextstate   = `IC_ACCESS;
                    data_rdy    = `ENABLE;
                    if (hitway0 == `ENABLE) begin
                        case(if_addr[1:0])
                            `WORD0:begin
                                cpu_data = data0_rd[31:0];
                            end
                            `WORD1:begin
                                cpu_data = data0_rd[63:32];
                            end
                            `WORD2:begin
                                cpu_data = data0_rd[95:64];
                            end
                            `WORD3:begin
                                cpu_data = data0_rd[127:96];
                            end
                        endcase // case(if_addr[1:0])   
                    end else if (hitway1 == `ENABLE) begin
                        case(if_addr[1:0])
                            `WORD0:begin
                                cpu_data = data1_rd[31:0];
                            end
                            `WORD1:begin
                                cpu_data = data1_rd[63:32];
                            end
                            `WORD2:begin
                                cpu_data = data1_rd[95:64];
                            end
                            `WORD3:begin
                                cpu_data = data1_rd[127:96];
                            end
                        endcase // case(if_addr[1:0])   
                    end
                end else begin // cache miss
                    miss_stall = `ENABLE; 
                    irq        = `ENABLE; 
                    nextstate  = `IC_ACCESS_L2;
                end 
            end
            `IC_ACCESS_L2:begin // access L2, wait L2 reading right 
                // read l2_block ,write to l1 and cpu
                if(ic_en == `ENABLE) begin
                    /* write l1 part */
                    ic_rw_en   = `ENABLE;
                    if(l2_rdy == `ENABLE || mem_wr_ic_en == `ENABLE)begin
                        miss_stall = `DISABLE;
                        nextstate  = `WRITE_IC;
                        case(choose_way)
                            `WAY0:begin
                                block0_we = `ENABLE;
                            end
                            `WAY1:begin
                                block1_we = `ENABLE;
                            end
                        endcase
                        /* write cpu part */ 
                        data_rdy    = `ENABLE;
                        case(if_addr[1:0])
                            `WORD0:begin
                                cpu_data = data_wd_l2[31:0];
                            end
                            `WORD1:begin
                                cpu_data = data_wd_l2[63:32];
                            end
                            `WORD2:begin 
                                cpu_data = data_wd_l2[95:64];
                            end
                            `WORD3:begin
                                cpu_data = data_wd_l2[127:96];
                            end
                        endcase // case(if_addr[1:0])            
                    end else begin
                        nextstate  = `IC_ACCESS_L2;
                    end
                end else begin
                    nextstate   = `WAIT_L2_BUSY;
                end    
            end
            `WAIT_L2_BUSY:begin
                if(ic_en == `ENABLE) begin
                    nextstate   = `IC_ACCESS_L2;
                end else begin
                    nextstate   = `WAIT_L2_BUSY;
                end
            end
            `WRITE_IC:begin // 使用L2返回的指令块填充IC
                if(complete == `ENABLE)begin
                    block0_we  = `DISABLE;
                    block1_we  = `DISABLE;
                    irq        = `DISABLE;
                    nextstate  = `IC_ACCESS;
                    case(if_addr[1:0])
                        `WORD0:begin
                            cpu_data = data_wd_l2[31:0];
                        end
                        `WORD1:begin
                            cpu_data = data_wd_l2[63:32];
                        end
                        `WORD2:begin 
                            cpu_data = data_wd_l2[95:64];
                        end
                        `WORD3:begin
                            cpu_data = data_wd_l2[127:96];
                        end
                    endcase // case(if_addr[1:0])  
                end else begin
                    nextstate  = `WRITE_IC;
                end      
            end
        endcase      
    end

    always @(posedge clk) begin // cache control
        if (rst == `ENABLE) begin // reset
            state <= `IC_IDLE;
        end else begin
            state <= nextstate;
        end
    end
endmodule