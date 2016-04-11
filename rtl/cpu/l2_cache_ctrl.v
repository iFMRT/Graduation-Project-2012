/*
 -- ============================================================================
 -- FILE NAME   : l2_cache_ctrl.v
 -- DESCRIPTION : 二级指令高速缓存器控制 
 -- ----------------------------------------------------------------------------
 -- Date:2016/1/16         Coding_by:kippy
 -- ============================================================================
*/

`timescale 1ns/1ps

/********** General header file **********/
`include "stddef.h"
`include "l2_cache.h"

module l2_cache_ctrl(
    // read
    input               clk,                // clock
    input               rst,                // reset
    /* CPU part */
    input       [31:0]  l2_addr_ic,            // address of fetching instruction
    input               l2_cache_rw_ic,        // read / write signal of CPU
    input       [31:0]  l2_addr_dc,            // address of fetching instruction
    input               l2_cache_rw_dc,        // read / write signal of CPU
    output reg          l2_miss_stall,      // miss caused by l2C miss
    output      [8:0]   l2_index,
    /*cache part*/
    input               irq,                // icache request
    input               drq,
    input               complete,           // complete mark of writing into L1C
    input       [127:0] data_rd,            // read data from L1
    output reg  [127:0] data_wd_l2,         // write data to L1    
    output reg          data_wd_l2_en,
    /*l2_cache part*/
    input               l2_complete,        // complete mark of writing into L2C 
    output reg          l2_rdy,
    output reg          l2_busy,
    // l2_tag part
    input       [2:0]   plru,               // the number of replacing mark
    input       [17:0]  l2_tag0_rd,         // read data of tag0
    input       [17:0]  l2_tag1_rd,         // read data of tag1
    input       [17:0]  l2_tag2_rd,         // read data of tag2
    input       [17:0]  l2_tag3_rd,         // read data of tag3
    output reg          l2_tag0_rw,         // read / write signal of tag0
    output reg          l2_tag1_rw,         // read / write signal of tag1
    output reg          l2_tag2_rw,         // read / write signal of tag0
    output reg          l2_tag3_rw,         // read / write signal of tag1
    output reg  [17:0]  l2_tag_wd,          // write data of tag0    
    // l2_data part
    input       [511:0] l2_data0_rd,        // read data of cache_data0
    input       [511:0] l2_data1_rd,        // read data of cache_data1
    input       [511:0] l2_data2_rd,        // read data of cache_data2
    input       [511:0] l2_data3_rd,        // read data of cache_data3
    output reg  [511:0] l2_data_wd,   
    output reg          l2_data0_rw,        // the mark of cache_data0 write signal 
    output reg          l2_data1_rw,        // the mark of cache_data1 write signal 
    output reg          l2_data2_rw,        // the mark of cache_data2 write signal 
    output reg          l2_data3_rw,        // the mark of cache_data3 write signal    
    // l2_dirty part
    output reg          l2_dirty_wd,
    output reg          l2_dirty0_rw,
    output reg          l2_dirty1_rw,
    output reg          l2_dirty2_rw,
    output reg          l2_dirty3_rw,
    input               l2_dirty0,
    input               l2_dirty1,
    input               l2_dirty2,
    input               l2_dirty3,
    /*memory part*/
    input               mem_complete,  
    input       [511:0] mem_rd,
    output reg  [511:0] mem_wd,
    output reg  [25:0]  mem_addr,           // address of memory
    output reg          mem_rw              // read / write signal of memory
    );
    wire        [1:0]   offset;             // offset of block
    reg         [1:0]   hitway;
    reg                 hitway0;            // the mark of choosing path0 
    reg                 hitway1;            // the mark of choosing path1
    reg                 hitway2;            // the mark of choosing path0 
    reg                 hitway3;            // the mark of choosing path1
    reg                 tagcomp_hit;        // tag hit mark
    reg         [2:0]   nextstate,state;              // state of l2_icache
    reg         [1:0]   choose_way;
    reg                 valid;
    reg                 dirty;
    reg        [511:0]  l2_data_rd;
    reg        [127:0]  data_wd_l2_copy;
    reg        [511:0]  l2_data_wd_copy;
    reg        [31:0]  l2_addr;            // address of fetching instruction
    reg                l2_cache_rw;        // read / write signal of CPU      

    assign l2_index   = l2_addr[14:6];
    assign offset     = l2_addr[5:4];
    always @(*)begin // path choose
        if(irq == `ENABLE) begin
            l2_addr = l2_addr_ic;
            l2_cache_rw = l2_cache_rw_ic;
        end else if(drq == `ENABLE)begin 
            l2_addr = l2_addr_dc;
            l2_cache_rw = l2_cache_rw_dc;
        end
        hitway0 = (l2_tag0_rd[16:0] == l2_addr[31:15]) & l2_tag0_rd[17];
        hitway1 = (l2_tag1_rd[16:0] == l2_addr[31:15]) & l2_tag1_rd[17];
        hitway2 = (l2_tag2_rd[16:0] == l2_addr[31:15]) & l2_tag2_rd[17];
        hitway3 = (l2_tag3_rd[16:0] == l2_addr[31:15]) & l2_tag3_rd[17];
        
        if(hitway0 == `ENABLE)begin
            tagcomp_hit  = `ENABLE;
            hitway       = `L2_WAY0;
            l2_data_rd   = l2_data0_rd;
        end else if(hitway1 == `ENABLE) begin
            tagcomp_hit  = `ENABLE;
            hitway       = `L2_WAY1;
            l2_data_rd   = l2_data1_rd;
        end else if(hitway2 == `ENABLE) begin
            tagcomp_hit  = `ENABLE;
            hitway       = `L2_WAY2;
            l2_data_rd   = l2_data2_rd;
        end else if(hitway3 == `ENABLE) begin
            tagcomp_hit  = `ENABLE;
            hitway       = `L2_WAY3;
            l2_data_rd   = l2_data3_rd;
        end else begin
            tagcomp_hit  = `DISABLE;
        end
        case(offset)
            `WORD0:begin
                data_wd_l2_copy = l2_data_rd[127:0];
                l2_data_wd_copy = {l2_data_rd[511:128],data_rd};
            end
            `WORD1:begin
                data_wd_l2_copy = l2_data_rd[255:128];
                l2_data_wd_copy = {l2_data_rd[511:256],data_rd,l2_data_rd[127:0]};
            end
            `WORD2:begin
                data_wd_l2_copy = l2_data_rd[383:256];
                l2_data_wd_copy = {l2_data_rd[511:384],data_rd,l2_data_rd[255:0]};
            end
            `WORD3:begin
                data_wd_l2_copy = l2_data_rd[511:384];
                l2_data_wd_copy = {data_rd,l2_data_rd[383:0]}; 
            end
        endcase // case(offset)  
       // cache miss, replacement policy
        if (l2_tag0_rd[17] === `ENABLE) begin
            if (l2_tag1_rd[17] === `ENABLE) begin
                if (l2_tag2_rd[17] === `ENABLE) begin
                    if (l2_tag3_rd[17] === `ENABLE) begin
                        if (plru[0] !== 1'b1) begin
                            if (plru[1] !== 1'b1) begin
                                choose_way = `L2_WAY0;
                            end else begin // plru[1:0] = 2'b00
                                choose_way = `L2_WAY1;
                            end // plru[1:0] = 2'b01
                        end else if (plru[2] !== 1'b1) begin
                            choose_way = `L2_WAY2;
                        end else begin// plru[0][2] = 2'b01
                            choose_way = `L2_WAY3;
                        end // plru[2][0] = 2'b11
                    end else begin
                        choose_way = `L2_WAY3;
                    end // else:l2_tag3_rd[17] == `DISABLE
                end else begin
                    choose_way = `L2_WAY2;
                end // else:l2_tag2_rd[17] == `DISABLE
            end else begin 
                choose_way = `L2_WAY1;
            end // else:l2_tag1_rd[17] == `DISABLE
        end else begin
            choose_way = `L2_WAY0;
        end // else:l2_tag0_rd[17] == `DISABLE
      
        case(choose_way)
            `L2_WAY0:begin
                if(l2_tag0_rd[17] === 1'bx) begin
                    valid = `DISABLE;
                end else begin
                    valid = l2_tag0_rd[17];
                end
                if (l2_dirty0 === 1'bx) begin
                    valid = `DISABLE;
                end else begin
                    dirty = l2_dirty0;
                end   
            end
            `L2_WAY1:begin
                if(l2_tag1_rd[17] === 1'bx) begin
                    valid = `DISABLE;
                end else begin
                    valid = l2_tag1_rd[17];
                end
                if (l2_dirty1 === 1'bx) begin
                    valid = `DISABLE;
                end else begin
                    dirty = l2_dirty1;
                end 
            end
            `L2_WAY2:begin
                if(l2_tag2_rd[17] === 1'bx) begin
                    valid = `DISABLE;
                end else begin
                    valid = l2_tag2_rd[17];
                end
                if (l2_dirty2 === 1'bx) begin
                    valid = `DISABLE;
                end else begin
                    dirty = l2_dirty2;
                end
            end
            `L2_WAY3:begin
                if(l2_tag3_rd[17] === 1'bx) begin
                    valid = `DISABLE;
                end else begin
                    valid = l2_tag3_rd[17];
                end
                if (l2_dirty3 === 1'bx) begin
                    valid = `DISABLE;
                end else begin
                    dirty = l2_dirty3;
                end
            end
        endcase   
    end

    always @(*) begin
        case(state)
            `L2_IDLE:begin
                l2_busy       = `DISABLE;
                l2_rdy        = `DISABLE;
                l2_tag0_rw    = `READ;
                l2_tag1_rw    = `READ;
                l2_tag2_rw    = `READ;
                l2_tag3_rw    = `READ;
                l2_data0_rw   = `READ;
                l2_data1_rw   = `READ;
                l2_data2_rw   = `READ;
                l2_data3_rw   = `READ;
                l2_dirty0_rw  = `READ;
                l2_dirty1_rw  = `READ;
                l2_dirty2_rw  = `READ;
                l2_dirty3_rw  = `READ;
                l2_miss_stall = `DISABLE;
                if (irq || drq == `ENABLE) begin  
                    nextstate   = `ACCESS_L2;
                end else begin
                    nextstate   = `L2_IDLE;
                end    
            end
            `ACCESS_L2:begin
                l2_busy     = `ENABLE;
                // read hit
                if ( l2_cache_rw == `READ && tagcomp_hit == `ENABLE) begin 
                    l2_miss_stall = `DISABLE;
                    // nextstate     = `WRITE_L1;
                    l2_rdy        = `ENABLE;
                    data_wd_l2_en = `ENABLE;
                    data_wd_l2    = data_wd_l2_copy;
                    if(complete == `ENABLE)begin
                        l2_rdy  = `DISABLE;
                        l2_busy = `DISABLE;
                        data_wd_l2_en = `DISABLE;
                        nextstate   = `L2_IDLE;
                    end else begin
                        nextstate   = `ACCESS_L2;
                    end
                end else if( l2_cache_rw == `WRITE && tagcomp_hit == `ENABLE) begin // write hit
                    l2_miss_stall = `DISABLE;
                    nextstate         = `L2_WRITE_HIT;
                    l2_dirty_wd   = 1'b1;
                    l2_tag_wd     = {1'b1,l2_addr[31:15]};
                    l2_data_wd    = l2_data_wd_copy;
                    case(hitway)
                        `L2_WAY0:begin
                            l2_data0_rw  = `WRITE;
                            l2_dirty0_rw = `WRITE;
                            l2_tag0_rw   = `WRITE;
                        end // hitway == 00
                        `L2_WAY1:begin
                            l2_data1_rw  = `WRITE;
                            l2_dirty1_rw = `WRITE;
                            l2_tag1_rw   = `WRITE;
                        end // hitway == 01
                        `L2_WAY2:begin
                            l2_data2_rw  = `WRITE;
                            l2_dirty2_rw = `WRITE;
                            l2_tag2_rw   = `WRITE;
                        end // hitway == 10
                        `L2_WAY3:begin
                            l2_data3_rw  = `WRITE;
                            l2_dirty3_rw = `WRITE;
                            l2_tag3_rw   = `WRITE;
                        end // hitway == 11
                    endcase // case(hitway) 
                end else begin // cache miss
                    l2_miss_stall = `ENABLE;
                    // mem to l2
                    if (valid == `DISABLE || dirty == `DISABLE) begin
                        mem_rw        = `READ;
                        mem_addr      = l2_addr[31:6];
                        nextstate     = `WRITE_TO_L2;
                        l2_dirty_wd   = 1'b0;
                        l2_tag_wd     = {1'b1,l2_addr[31:15]};
                        l2_data_wd    = mem_rd;
                        case(choose_way)
                            `L2_WAY0:begin
                                l2_data0_rw  = `WRITE;
                                l2_tag0_rw   = `WRITE;
                                l2_dirty0_rw = `WRITE;
                            end
                            `L2_WAY1:begin
                                l2_data1_rw  = `WRITE;
                                l2_tag1_rw   = `WRITE;
                                l2_dirty1_rw = `WRITE;
                            end
                            `L2_WAY2:begin
                                l2_data2_rw  = `WRITE;
                                l2_tag2_rw   = `WRITE;
                                l2_dirty2_rw = `WRITE;
                            end
                            `L2_WAY3:begin
                                l2_data3_rw  = `WRITE;
                                l2_tag3_rw   = `WRITE;
                                l2_dirty3_rw = `WRITE;
                            end
                        endcase
                    end else if(valid == `ENABLE && dirty == `ENABLE) begin 
                        nextstate  = `WRITE_MEM;
                        mem_rw = l2_cache_rw; 
                        case(choose_way)
                            `L2_WAY0:begin
                                // l2_data0_rw = `READ;
                                // l2_tag0_rw  = `READ;
                                mem_wd      = l2_data0_rd;
                                mem_addr    = {l2_tag0_rd[16:0],l2_addr[14:6]};
                            end
                            `L2_WAY1:begin
                                // l2_data1_rw = `READ;
                                // l2_tag1_rw  = `READ;
                                mem_wd      = l2_data1_rd;
                                mem_addr    = {l2_tag1_rd[16:0],l2_addr[14:6]};
                            end
                            `L2_WAY2:begin
                                // l2_data2_rw = `READ;
                                // l2_tag2_rw  = `READ;
                                mem_wd      = l2_data2_rd;
                                mem_addr    = {l2_tag2_rd[16:0],l2_addr[14:6]}; 
                            end
                            `L2_WAY3:begin
                                // l2_data3_rw = `READ;
                                // l2_tag3_rw  = `READ;
                                mem_wd      = l2_data3_rd;
                                mem_addr    = {l2_tag3_rd[16:0],l2_addr[14:6]};
                            end
                        endcase
                    end
                end
            end
            // `WRITE_L1:begin  // L2 to L1
            //     if(complete == `ENABLE)begin
            //         l2_rdy  = `DISABLE;
            //         l2_busy = `DISABLE;
            //         data_wd_l2_en = `DISABLE;
            //         nextstate   = `L2_IDLE;
            //     end else begin
            //         nextstate   = `WRITE_L1;
            //     end
            // end
            `WRITE_TO_L2:begin // write into l2_cache from memory 
                if(l2_complete == `ENABLE)begin
                    l2_tag0_rw   =  `READ;
                    l2_tag1_rw   =  `READ;
                    l2_tag2_rw   =  `READ;
                    l2_tag3_rw   =  `READ;
                    l2_data0_rw  =  `READ;
                    l2_data1_rw  =  `READ;
                    l2_data2_rw  =  `READ;
                    l2_data3_rw  =  `READ;  
                    l2_dirty0_rw =  `READ;
                    l2_dirty1_rw =  `READ; 
                    l2_dirty2_rw =  `READ;
                    l2_dirty3_rw =  `READ;
                    nextstate  =  `ACCESS_L2;                                         
                end else begin
                    nextstate  =  `WRITE_TO_L2;
                end
            end
            `L2_WRITE_HIT:begin // write into l2_cache from L1 
                if(l2_complete == `ENABLE)begin
                    l2_tag0_rw   =  `READ;
                    l2_tag1_rw   =  `READ;
                    l2_tag2_rw   =  `READ;
                    l2_tag3_rw   =  `READ;
                    l2_data0_rw  =  `READ;
                    l2_data1_rw  =  `READ;
                    l2_data2_rw  =  `READ;
                    l2_data3_rw  =  `READ;  
                    l2_dirty0_rw =  `READ;
                    l2_dirty1_rw =  `READ; 
                    l2_dirty2_rw =  `READ;
                    l2_dirty3_rw =  `READ;
                    if (irq || drq == `ENABLE) begin
                        nextstate   = `ACCESS_L2;
                     end else begin
                        l2_busy = `DISABLE;
                        nextstate   =  `L2_IDLE;
                     end                                      
                end else begin
                    nextstate =  `L2_WRITE_HIT;
                end
            end
            `WRITE_MEM:begin // load block of L2 with dirty to mem.                     
                if (mem_complete == `ENABLE) begin
                    mem_addr     = l2_addr[31:6];
                    mem_rw       = `READ; 
                    nextstate        = `WRITE_TO_L2;
                    l2_dirty_wd  = 1'b0;
                    l2_tag_wd    = {1'b1,l2_addr[31:15]};
                    l2_data_wd   = mem_rd;
                    case(choose_way)
                        `L2_WAY0:begin
                            l2_data0_rw  = `WRITE;
                            l2_tag0_rw   = `WRITE;
                            l2_dirty0_rw = `WRITE;
                        end
                        `L2_WAY1:begin
                            l2_data1_rw  = `WRITE;
                            l2_tag1_rw   = `WRITE;
                            l2_dirty1_rw = `WRITE;
                        end
                        `L2_WAY2:begin
                            l2_data2_rw  = `WRITE;
                            l2_tag2_rw   = `WRITE;
                            l2_dirty2_rw = `WRITE;
                        end
                        `L2_WAY3:begin
                            l2_data3_rw  = `WRITE;
                            l2_tag3_rw   = `WRITE;
                            l2_dirty3_rw = `WRITE;
                        end
                    endcase
                end else begin
                    nextstate = `WRITE_MEM;
                end
            end
        endcase        
    end
    always @(posedge clk) begin // cache control
        if (rst == `ENABLE) begin
            state         <= `L2_IDLE;
        end else begin   
            state <= nextstate;
        end
    end
endmodule


