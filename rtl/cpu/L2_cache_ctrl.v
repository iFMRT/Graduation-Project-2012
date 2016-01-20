/*
 -- ============================================================================
 -- FILE NAME   : L2_cache_ctrl.v
 -- DESCRIPTION : 二级指令高速缓存器控制
 -- ----------------------------------------------------------------------------
 -- Date:2016/1/16         Coding_by:kippy
 -- ============================================================================
*/

`timescale 1ns/1ps

/********** General header file **********/
`include "stddef.h"
`include "icache.h"

module L2_cache_ctrl(
    // read
    input               clk,                // clock
    input               rst,                // reset
    /* CPU part */
    input       [31:0]  if_addr,            // address of fetching instruction
    input               rw,                 // read / write signal of CPU
    output reg          L2_miss_stall,      // miss caused by L2C miss
    /*cache part*/
    input               irq,                // icache request
    input               complete,           // complete mark of writing into L1C
    input               L2_complete,        // complete mark of writing into L2C
    input       [2:0]   PLUR,               // the number of replacing mark
//  input               drq,                 // dcache request
    input       [18:0]  L2_tag0_rd,         // read data of tag0
    input       [18:0]  L2_tag1_rd,         // read data of tag1
    input       [18:0]  L2_tag2_rd,         // read data of tag2
    input       [18:0]  L2_tag3_rd,         // read data of tag3
    output reg          L2_busy,
    input       [511:0] L2_data0_rd,        // read data of cache_data0
    input       [511:0] L2_data1_rd,        // read data of cache_data1
    input       [511:0] L2_data2_rd,        // read data of cache_data2
    input       [511:0] L2_data3_rd,        // read data of cache_data3
    output reg  [127:0] data_wd,            // write data to L1_IC
    output reg          L2_tag0_rw,         // read / write signal of tag0
    output reg          L2_tag1_rw,         // read / write signal of tag1
    output reg          L2_tag2_rw,         // read / write signal of tag0
    output reg          L2_tag3_rw,         // read / write signal of tag1
    output      [16:0]  L2_tag_wd,          // write data of tag0
    output reg          L2_rdy,
    output reg          L2_data0_rw,        // the mark of cache_data0 write signal 
    output reg          L2_data1_rw,        // the mark of cache_data1 write signal 
    output reg          L2_data2_rw,        // the mark of cache_data2 write signal 
    output reg          L2_data3_rw,        // the mark of cache_data3 write signal 
    output      [8:0]   L2_index,           // address of cache
    /*memory part*/
    output reg  [25:0]  mem_addr,           // address of memory
    output reg          mem_rw              // read / write signal of memory
    );
    wire        [1:0]   offset;             // offset of block
    reg                 hitway;             // path hit mark
    reg                 hitway0;            // the mark of choosing path0 
    reg                 hitway1;            // the mark of choosing path1
    reg                 hitway2;            // the mark of choosing path0 
    reg                 hitway3;            // the mark of choosing path1
    reg                 tagcomp_hit;        // tag hit mark
    reg         [2:0]   state;              // state of L2_icache
    reg                 clk_tmp;            // temporary clk
    assign L2_index   = if_addr [14:6];
    assign offset     = if_addr [5:4];
    assign L2_tag_wd  = if_addr [31:15];
    always @(*)begin // path choose
        hitway0 = (L2_tag0_rd[16:0] == if_addr[31:15]) & L2_tag0_rd[18];
        hitway1 = (L2_tag1_rd[16:0] == if_addr[31:15]) & L2_tag1_rd[18];
        hitway2 = (L2_tag2_rd[16:0] == if_addr[31:15]) & L2_tag2_rd[18];
        hitway3 = (L2_tag3_rd[16:0] == if_addr[31:15]) & L2_tag3_rd[18];
        if(hitway0 == `ENABLE)begin
            tagcomp_hit = `ENABLE;
            hitway      = `WAY0;
        end else if(hitway1 == `ENABLE) begin
            tagcomp_hit = `ENABLE;
            hitway      = `WAY1;
        end else if(hitway2 == `ENABLE) begin
            tagcomp_hit = `ENABLE;
            hitway      = `WAY2;
        end else if(hitway3 == `ENABLE) begin
            tagcomp_hit = `ENABLE;
            hitway      = `WAY3;
        end else begin
            tagcomp_hit = `DISABLE;
        end
    end
    always @(*) begin
        clk_tmp = #1 clk;
    end
    always @(posedge clk_tmp) begin // cache control
        if(rst == `ENABLE) begin // reset
            state  <= `L2_IDLE;
        end else begin
            case(state)
                `L2_IDLE:begin
                    L2_busy     <= `DISABLE;
                    L2_rdy      <= `DISABLE;
                    L2_tag0_rw  <= rw;
                    L2_tag1_rw  <= rw;
                    L2_tag2_rw  <= rw;
                    L2_tag3_rw  <= rw;
                    L2_data0_rw <= rw;
                    L2_data1_rw <= rw;
                    L2_data2_rw <= rw;
                    L2_data3_rw <= rw;
                    if (irq == `ENABLE) begin  // 先不考虑drq
                        state   <= `ACCESS_L2;
                    end    
                end
                `ACCESS_L2:begin
                    L2_busy     <= `ENABLE;
                    if ( rw == `READ && tagcomp_hit == `ENABLE) begin // cache hit
                        L2_miss_stall <= `DISABLE;
                        state         <= `WRITE_L1;
                        L2_rdy        <= `ENABLE;
                        case(hitway)
                            `WAY0:begin
                                case(offset)
                                    `WORD0:begin
                                        data_wd <= L2_data0_rd[127:0];
                                    end
                                    `WORD1:begin
                                        data_wd <= L2_data0_rd[255:128];
                                    end
                                    `WORD2:begin
                                        data_wd <= L2_data0_rd[383:256];
                                    end
                                    `WORD3:begin
                                        data_wd <= L2_data0_rd[511:384];
                                    end
                                endcase // case(offset)  
                            end // hitway == 0
                            `WAY1:begin
                                case(offset)
                                    `WORD0:begin
                                        data_wd <= L2_data1_rd[127:0];
                                    end
                                    `WORD1:begin
                                        data_wd <= L2_data1_rd[255:128];
                                    end
                                    `WORD2:begin
                                        data_wd <= L2_data1_rd[383:256];
                                    end
                                    `WORD3:begin
                                        data_wd <= L2_data1_rd[511:384];
                                    end
                                endcase // case(offset)  
                            end // hitway == 1
                            `WAY2:begin
                                case(offset)
                                    `WORD0:begin
                                        data_wd <= L2_data2_rd[127:0];
                                    end
                                    `WORD1:begin
                                        data_wd <= L2_data2_rd[255:128];
                                    end
                                    `WORD2:begin
                                        data_wd <= L2_data2_rd[383:256];
                                    end
                                    `WORD3:begin
                                        data_wd <= L2_data2_rd[511:384];
                                    end
                                endcase // case(offset)  
                            end // hitway == 2
                            `WAY3:begin
                                case(offset)
                                    `WORD0:begin
                                        data_wd <= L2_data3_rd[127:0];
                                    end
                                    `WORD1:begin
                                        data_wd <= L2_data3_rd[255:128];
                                    end
                                    `WORD2:begin
                                        data_wd <= L2_data3_rd[383:256];
                                    end
                                    `WORD3:begin
                                        data_wd <= L2_data3_rd[511:384];
                                    end
                                endcase // case(offset)  
                            end // hitway == 3
                        endcase // case(hitway) 
                    end else begin // cache miss
                        L2_miss_stall <= `ENABLE;
                        mem_rw        <= rw;
                        mem_addr      <= if_addr[31:6];
                        state         <= `WRITE_L2;
                        if (L2_tag0_rd[18] == `ENABLE) begin
                            if (L2_tag1_rd[18] == `ENABLE) begin
                                if (L2_tag2_rd[18] == `ENABLE) begin
                                    if (L2_tag3_rd[18] == `ENABLE) begin
                                        if (PLUR[0] == 1'b0) begin
                                            if (PLUR[1] == 1'b0) begin
                                                L2_data0_rw <= `WRITE;
                                                L2_tag0_rw  <= `WRITE;
                                            end else begin // PLUR[1:0] = 2'b00
                                                L2_data1_rw <= `WRITE;
                                                L2_tag1_rw  <= `WRITE;
                                            end // PLUR[1:0] = 2'b01
                                        end else if (PLUR[2] == 1'b0) begin
                                            L2_data2_rw <= `WRITE;
                                            L2_tag2_rw  <= `WRITE;
                                        end else begin// PLUR[0][2] = 2'b01
                                            L2_data3_rw <= `WRITE;
                                            L2_tag3_rw  <= `WRITE;
                                        end // PLUR[2][0] = 2'b11
                                    end else begin
                                        L2_data3_rw <= `WRITE;
                                        L2_tag3_rw  <= `WRITE;
                                    end // else:L2_tag3_rd[18] == `DISABLE
                                end else begin
                                    L2_data2_rw <= `WRITE;
                                    L2_tag2_rw  <= `WRITE;
                                end // else:L2_tag2_rd[18] == `DISABLE
                            end else begin 
                                L2_data1_rw <= `WRITE;
                                L2_tag1_rw  <= `WRITE;
                            end // else:L2_tag1_rd[18] == `DISABLE
                        end else begin
                            L2_data0_rw <= `WRITE;
                            L2_tag0_rw  <= `WRITE;
                        end // else:L2_tag0_rd[18] == `DISABLE
                    end 
                end
                `WRITE_L1:begin
                    if(complete == `ENABLE)begin
                        state <= `L2_IDLE;
                    end else begin
                        state <= `WRITE_L1;
                    end
                end
                `WRITE_L2:begin // 等待L2返回指令块 
                    if(L2_complete == `ENABLE)begin
                        state       <= `ACCESS_L2;
                        L2_tag0_rw  <= rw;
                        L2_tag1_rw  <= rw;
                        L2_tag2_rw  <= rw;
                        L2_tag3_rw  <= rw;
                        L2_data0_rw <= rw;
                        L2_data1_rw <= rw;
                        L2_data2_rw <= rw;
                        L2_data3_rw <= rw;                        
                    end else begin
                        state       <= `WRITE_L2;
                    end
                end
            endcase
        end // else:rst != `ENABLE
    end
endmodule


