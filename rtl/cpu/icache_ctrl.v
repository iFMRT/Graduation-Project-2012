/*
 -- ============================================================================
 -- FILE NAME   : icache_ctrl.v
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
    input      [31:0]  if_addr,       // address of fetching instruction
    input              rw,            // read / write signal of CPU
    output reg [31:0]  cpu_data,      // read data of CPU
    output reg         miss_stall,    // the signal of stall caused by cache miss
    /* L1_cache part */
    input              lru,           // mark of replacing
    input      [20:0]  tag0_rd,       // read data of tag0
    input      [20:0]  tag1_rd,       // read data of tag1
    input      [127:0] data0_rd,      // read data of data0
    input      [127:0] data1_rd,      // read data of data1
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
    output reg         irq,           // icache request
    output reg [8:0]   l2_index,
    output reg [31:0]  l2_addr,
    output reg         l2_cache_rw,
    /* if_reg part */
    output reg         data_rdy    // tag hit mark
    );
    reg                tagcomp_hit;
    wire       [1:0]   offset;           // offset of block
    reg                hitway;           // path hit mark
    reg                hitway0;          // the mark of choosing path0 
    reg                hitway1;          // the mark of choosing path1    
    reg        [2:0]   state;            // state of control
    wire               valid0,valid1;    // valid signal of tag
    reg                clk_tmp;          // temporary clk   
    reg        [127:0] data_rd;          // read data of data
    reg        [31:0]  cpu_data_copy;
    
    assign valid0        = tag0_rd[20];
    assign valid1        = tag1_rd[20];
    assign index         = if_addr [11:4];
    assign offset        = if_addr [3:2];
    // assign tag_wd        = if_addr [31:12]; 

    always @(*)begin // path choose
        hitway0 = (tag0_rd[19:0] == if_addr[31:12]) & valid0;
        hitway1 = (tag1_rd[19:0] == if_addr[31:12]) & valid1;
        if(hitway0 == `ENABLE)begin
            tagcomp_hit = `ENABLE;
            hitway      = `WAY0;
            data_rd     = data0_rd;
        end
        else if(hitway1 == `ENABLE)begin
            tagcomp_hit = `ENABLE;
            hitway      = `WAY1;
            data_rd     = data1_rd;
        end
        else begin
            tagcomp_hit = `DISABLE;
        end
        case(offset)
            `WORD0:begin
                cpu_data_copy = data_rd[31:0];
            end
            `WORD1:begin
                cpu_data_copy = data_rd[63:32];
            end
            `WORD2:begin
                cpu_data_copy = data_rd[95:64];
            end
            `WORD3:begin
                cpu_data_copy = data_rd[127:96];
            end
        endcase // case(offset)  
    end

    always @(*) begin
        clk_tmp = #1 clk;
    end

    always @(posedge clk_tmp) begin // cache control
        if (rst == `ENABLE) begin // reset
            state       <= `L1_IDLE;
            data0_rw    <= `READ;
            data1_rw    <= `READ;                    
            tag0_rw     <= `READ;
            tag1_rw     <= `READ;
            miss_stall  <= `DISABLE;
            irq         <= `DISABLE;
            data_rdy    <= `DISABLE;
        end else begin
            case(state)
                `L1_IDLE:begin
                    state     <= `L1_ACCESS;
                end
                `L1_ACCESS:begin
                    data_rdy  <= `DISABLE;
                    if ( rw == `READ && tagcomp_hit == `ENABLE) begin // cache hit
                        miss_stall  <= `DISABLE;
                        state       <= `L1_ACCESS;
                        data_rdy    <= `ENABLE;
                        cpu_data    <= cpu_data_copy;
                        // case(hitway)
                        //     `WAY0:begin
                        //         data0_rw  <= `READ;
                        //         case(offset)
                        //             `WORD0:begin
                        //                 cpu_data <= data0_rd[31:0];
                        //             end
                        //             `WORD1:begin
                        //                 cpu_data <= data0_rd[63:32];
                        //             end
                        //             `WORD2:begin
                        //                 cpu_data <= data0_rd[95:64];
                        //             end
                        //             `WORD3:begin
                        //                 cpu_data <= data0_rd[127:96];
                        //             end
                        //         endcase // case(offset)  
                        //     end // hitway == 0
                        //     `WAY1:begin
                        //         data1_rw  <= `READ;
                        //         case(offset)
                        //             `WORD0:begin
                        //                 cpu_data <= data1_rd[31:0];
                        //             end
                        //             `WORD1:begin
                        //                 cpu_data <= data1_rd[63:32];
                        //             end
                        //             `WORD2:begin
                        //                 cpu_data <= data1_rd[95:64];
                        //             end
                        //             `WORD3:begin
                        //                 cpu_data <= data1_rd[127:96];
                        //             end
                        //         endcase // case(offset)  
                        //     end // hitway == 1
                        // endcase // case(hitway) 
                    end else begin // cache miss
                        miss_stall = `ENABLE;  
                        if(l2_busy == `ENABLE) begin
                            state       <= `WAIT_L2_BUSY;
                        end else begin
                            irq         <= `ENABLE;
                            l2_cache_rw <= rw;
                            l2_index    <= if_addr[14:6];
                            l2_addr     <= if_addr;
                            state       <= `L2_ACCESS;
                        end
                    end 
                end
                `L2_ACCESS:begin // access L2, wait L2 reading right 
                    if(l2_rdy == `ENABLE)begin
                        state  <= `WRITE_IC;
                        tag_wd <= {1'b1,if_addr[31:12]};
                        if (valid0 == 1'b1) begin
                            if (valid1 == 1'b1) begin
                                if(lru == 1'b0) begin
                                    data0_rw  <= `WRITE;
                                    tag0_rw   <= `WRITE;
                                end else begin
                                    data1_rw  <= `WRITE;
                                    tag1_rw   <= `WRITE;
                                end                    
                            end else begin
                                data1_rw  <= `WRITE;
                                tag1_rw   <= `WRITE;
                            end
                        end else begin
                            data0_rw  <= `WRITE;
                            tag0_rw   <= `WRITE;
                        end            
                    end else begin
                        state  <= `L2_ACCESS;
                    end
                end
                `WAIT_L2_BUSY:begin
                    if(l2_busy == `ENABLE) begin
                        state    <= `WAIT_L2_BUSY;
                    end else begin
                        irq      <= `ENABLE;
                        l2_index <= if_addr[14:6];
                        l2_addr  <= if_addr;
                        l2_cache_rw <= rw;
                        state    <= `L2_ACCESS;
                    end
                end
                `WRITE_IC:begin // 使用L2返回的指令块填充IC
                    if(complete == `ENABLE)begin
                        irq        <= `DISABLE;
                        miss_stall <= `DISABLE;
                        state      <= `L1_ACCESS;
                        data0_rw   <= `READ;
                        data1_rw   <= `READ;                    
                        tag0_rw    <= `READ;
                        tag1_rw    <= `READ;
                    end else begin
                        state      <= `WRITE_IC;
                    end
                            
                end
            endcase
        end
    end

endmodule


