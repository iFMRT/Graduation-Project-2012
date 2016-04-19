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
    // input      [31:0]  if_addr,       // address of fetching instruction
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
    output     [20:0]  tag_wd,        // write data of L1_tag
    output reg         block0_rw,     // read / write signal of block0
    output reg         block1_rw,     // read / write signal of block1
    output     [7:0]   index,         // address of L1_cache
    /* L2_cache part */
    input              ic_en,         // icache enable signal of accessing L2_cache
    input              l2_rdy,        // ready signal of L2_cache
    input              complete,      // complete op writing to L1
    input              mem_wr_ic_en,
    output reg         irq,           // icache request
    output reg         ic_rw_en,      // enable signal of writing icache 
    // output reg [31:0]  l2_addr,
    output     [27:0]  l2_addr,
    output             l2_cache_rw,
    /* if_reg part */
    output reg         data_rdy       // tag hit mark
    );
    reg                tagcomp_hit;
    reg                hitway0;          // the mark of choosing path0 
    reg                hitway1;          // the mark of choosing path1    
    reg        [1:0]   nextstate,state;  // state of control
    reg                choose_way;

    assign index       = if_addr[9:2];
    assign l2_addr     = if_addr[29:2];
    assign l2_cache_rw = rw;
    assign tag_wd = {1'b1,if_addr[29:10]};
    
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
                if(lru == 1'b0) begin
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
        block0_rw = `READ;
        block1_rw = `READ;
        if( (state == `IC_ACCESS_L2 && (l2_rdy == `ENABLE || mem_wr_ic_en == `ENABLE))
           || (state == `WRITE_IC && complete == `DISABLE))begin
            case(choose_way)
                `WAY0:begin
                    block0_rw = `WRITE;
                end
                `WAY1:begin
                    block1_rw = `WRITE;
                end
            endcase
        end
        if(rst == `ENABLE) begin
            miss_stall  = `DISABLE;
            irq         = `DISABLE;
            data_rdy    = `DISABLE;
            ic_rw_en    = `DISABLE;
        end
        case(state)
            `IC_ACCESS:begin
                ic_rw_en    = `DISABLE;
                data_rdy    = `DISABLE;
                if ( rw == `READ && tagcomp_hit == `ENABLE) begin // cache hit
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
                    if(ic_en == `ENABLE) begin
                        nextstate   = #1 `IC_ACCESS_L2;
                    end else begin
                        nextstate   = #1 `WAIT_L2_BUSY;
                    end
                end 
            end
            `IC_ACCESS_L2:begin // access L2, wait L2 reading right 
                // read l2_block ,write to l1 and cpu
                /* write l1 part */
                ic_rw_en   = `ENABLE;
                if(l2_rdy == `ENABLE || mem_wr_ic_en == `ENABLE)begin
                    nextstate  = `WRITE_IC;
                    ////////////////////////////
                    /*enable WRITE signal part*/
                    ////////////////////////////
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
                    ///////////////////////////
                    /*enable READ signal part*/
                    ///////////////////////////
                    irq        = `DISABLE;
                    miss_stall = `DISABLE;
                    nextstate  = `IC_ACCESS;
                end else begin
                    nextstate  = `WRITE_IC;
                end
                        
            end
            default:nextstate = `IC_ACCESS;
        endcase      
    end

    always @(posedge clk) begin // cache control
        if (rst == `ENABLE) begin // reset
            state <= `IC_ACCESS;
        end else begin
            state <= nextstate;
        end
    end

endmodule