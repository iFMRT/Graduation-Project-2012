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
    input      [127:0] data_wd_l2,    // ++++++++++++++++++++
    // output to L1_cache
    output reg         tag0_rw,       // read / write signal of L1_tag0
    output reg         tag1_rw,       // read / write signal of L1_tag1
    output reg [20:0]  tag_wd,        // write data of L1_tag
    output reg         data0_rw,      // read / write signal of data0
    output reg         data1_rw,      // read / write signal of data1
    output     [7:0]   index,         // address of L1_cache
    /* L2_cache part */
    input              l2_busy,       // busy signal of L2_cache
    input              l2_rdy,        // ready signal of L2_cache
    input              complete,      // complete op writing to L1
    input              mem_wr_ic_en,
    output reg         irq,           // icache request
    output reg         ic_rw_en,      // enable signal of writing icache 
    // output reg [31:0]  l2_addr,
    output reg [27:0]  l2_addr,
    output reg         l2_cache_rw,
    /* if_reg part */
    output reg         data_rdy       // tag hit mark
    );
    reg                tagcomp_hit;
    wire       [1:0]   offset;        // offset of block
    reg                hitway0;          // the mark of choosing path0 
    reg                hitway1;          // the mark of choosing path1    
    reg        [1:0]   nextstate,state;  // state of control
    wire               valid0,valid1;    // valid signal of tag
    reg                choose_way;
    // reg        [127:0] data_rd;          // read data of data
    // reg        [31:0]  cpu_data_copy;
    
    assign valid0        = tag0_rd[20];
    assign valid1        = tag1_rd[20];
    assign index         = if_addr[9:2];
    assign offset        = if_addr[1:0];
    // assign index         = if_addr[11:4];
    // assign offset        = if_addr[3:2];

    always @(*)begin // path choose
        // hitway0 = (tag0_rd[19:0] == if_addr[31:12]) & valid0;
        // hitway1 = (tag1_rd[19:0] == if_addr[31:12]) & valid1;
        hitway0 = (tag0_rd[19:0] == if_addr[29:10]) & valid0;
        hitway1 = (tag1_rd[19:0] == if_addr[29:10]) & valid1;
        if(hitway0 == `ENABLE)begin
            tagcomp_hit = `ENABLE;
            // data_rd     = data0_rd;
        end
        else if(hitway1 == `ENABLE)begin
            tagcomp_hit = `ENABLE;
            // data_rd     = data1_rd;
        end
        else begin
            tagcomp_hit = `DISABLE;
        end
        // case(offset)
        //     `WORD0:begin
        //         cpu_data_copy = data_rd[31:0];
        //     end
        //     `WORD1:begin
        //         cpu_data_copy = data_rd[63:32];
        //     end
        //     `WORD2:begin
        //         cpu_data_copy = data_rd[95:64];
        //     end
        //     `WORD3:begin
        //         cpu_data_copy = data_rd[127:96];
        //     end
        // endcase // case(offset)  
        if (valid0 == 1'b1) begin
            if (valid1 == 1'b1) begin
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
        if(rst == `ENABLE) begin
            data0_rw    = `READ;
            data1_rw    = `READ;                    
            tag0_rw     = `READ;
            tag1_rw     = `READ;
            miss_stall  = `DISABLE;
            irq         = `DISABLE;
            data_rdy    = `DISABLE;
            ic_rw_en    = `DISABLE;
        end
        case(state)
            `IC_ACCESS:begin
                ic_rw_en  = `DISABLE;
                data_rdy  = `DISABLE;
                if ( rw == `READ && tagcomp_hit == `ENABLE) begin // cache hit
                    // read l1_block ,write to cpu
                    miss_stall  = `DISABLE;
                    nextstate   = `IC_ACCESS;
                    data_rdy    = `ENABLE;
                    if (hitway0 == `ENABLE) begin
                        case(offset)
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
                        endcase // case(offset)   
                    end else if (hitway1 == `ENABLE) begin
                        case(offset)
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
                        endcase // case(offset)   
                    end
                end else begin // cache miss
                    miss_stall = `ENABLE;  
                    if(l2_busy == `ENABLE) begin
                        nextstate   = `WAIT_L2_BUSY;
                    end else begin
                        irq         = `ENABLE;
                        l2_cache_rw = rw;
                        // l2_addr     = if_addr;
                        l2_addr     = if_addr[29:2];
                        nextstate   = `IC_ACCESS_L2;
                    end
                end 
            end
            `IC_ACCESS_L2:begin // access L2, wait L2 reading right 
                // read l2_block ,write to l1 and cpu
                /* write l1 part */
                ic_rw_en   = `ENABLE;
                if(l2_rdy == `ENABLE || mem_wr_ic_en == `ENABLE)begin
                    nextstate  = `WRITE_IC;
                    // tag_wd = {1'b1,if_addr[31:12]};
                    tag_wd = {1'b1,if_addr[29:10]};
                    case(choose_way)
                        `WAY0:begin
                            data0_rw  = `WRITE;
                            tag0_rw   = `WRITE;
                        end
                        `WAY1:begin
                            data1_rw  = `WRITE;
                            tag1_rw   = `WRITE;
                        end
                    endcase
                    /* write cpu part */ 
                    data_rdy    = `ENABLE;
                    case(offset)
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
                    endcase // case(offset)            
                end else begin
                    nextstate  = `IC_ACCESS_L2;
                end
            end
            `WAIT_L2_BUSY:begin
                if(l2_busy == `ENABLE) begin
                    nextstate   = `WAIT_L2_BUSY;
                end else begin
                    irq         = `ENABLE;
                    // l2_addr     = if_addr;
                    l2_addr     = if_addr[29:2];
                    l2_cache_rw = rw;
                    nextstate   = `IC_ACCESS_L2;
                end
            end
            `WRITE_IC:begin // 使用L2返回的指令块填充IC
                if(complete == `ENABLE)begin
                    irq        = `DISABLE;
                    miss_stall = `DISABLE;
                    nextstate  = `IC_ACCESS;
                    data0_rw   = `READ;
                    data1_rw   = `READ;                    
                    tag0_rw    = `READ;
                    tag1_rw    = `READ;
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