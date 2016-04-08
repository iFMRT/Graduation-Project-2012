/*
 -- ============================================================================
 -- FILE NAME   : dcache_ctrl.v
 -- DESCRIPTION : data_cache 
 -- ----------------------------------------------------------------------------
 -- Date:2016/3/17         Coding_by:kippy
 -- ============================================================================
*/

`timescale 1ns/1ps

/********** General header file **********/
`include "stddef.h"
`include "dcache.h"

module dcache_ctrl(
    input              clk,           // clock
    input              rst,           // reset
    /* CPU part */
    input      [31:0]  addr,      // address of fetching instruction
    input      [31:0]  wr_data_m,
    input              memwrite_m,    // read / write signal of CPU
    input              access_mem,
    input              access_mem_ex,
    output reg [31:0]  read_data_m,   // read data of CPU
    output reg         miss_stall,    // the signal of stall caused by cache miss
    /* L1_cache part */
    input              lru,           // mark of replacing
    input      [20:0]  tag0_rd,       // read data of tag0
    input      [20:0]  tag1_rd,       // read data of tag1
    input      [127:0] data0_rd,      // read data of data0
    input      [127:0] data1_rd,      // read data of data1
    input              dirty0,
    input              dirty1,
    output reg         dirty_wd,
    output reg         dirty0_rw,
    output reg         dirty1_rw,
    output reg [127:0] data_wd_dc,
    output reg         tag0_rw,       // read / write signal of L1_tag0
    output reg         tag1_rw,       // read / write signal of L1_tag1
    output     [20:0]  tag_wd,        // write data of L1_tag
    output reg         data_wd_dc_en, // choose signal of data_wd
    output reg         hitway,        // path hit mark            
    output reg         data0_rw,      // read / write signal of data0
    output reg         data1_rw,      // read / write signal of data1
    output     [7:0]   index,         // address of L1_cache
    output reg [127:0] data_rd,       // read data of L1_cache's data
    /* L2_cache part */
    input              l2_complete,
    input              l2_busy,       // busy signal of L2_cache
    input              l2_rdy,        // ready signal of L2_cache
    input              complete,      // complete op writing to L1
    output reg         drq,           // icache request
    output reg [31:0]  l2_addr, 
    output reg [8:0]   l2_index,
    output reg         l2_cache_rw    // l2_cache read/write signal
    );

    wire       [1:0]   offset;              // offset of block
    reg                hitway0;             // the mark of choosing path0
    reg                hitway1;             // the mark of choosing path1
    // reg                hitway;
    reg                tagcomp_hit;         // tag hit mark
    reg                choose_way;          // the way of L1 we choose to replace
    reg        [2:0]   state,nextstate;               // state of control
    wire               valid0,valid1;
    reg                valid,dirty;               // valid signal of tag
    reg        [127:0] data_wd_dc_copy;
    reg        [127:0] data_rd_copy;
    reg        [31:0]  read_data_m_copy;
    assign valid0        = tag0_rd[20];
    assign valid1        = tag1_rd[20];
    assign index         = addr[11:4];
    assign offset        = addr[3:2];
    // assign byte_offset   = addr[1:0];
    assign tag_wd        = {1'b1,addr [31:12]};  // 写入 tag，valid恒为 1。

    always @(*)begin // path choose
        hitway0 = (tag0_rd[19:0] == addr[31:12]) & valid0;
        hitway1 = (tag1_rd[19:0] == addr[31:12]) & valid1;
        if(hitway0 == `ENABLE)begin
            tagcomp_hit  = `ENABLE;
            hitway       = `WAY0;
            data_rd_copy = data0_rd;
        end else if(hitway1 == `ENABLE)begin
            tagcomp_hit  = `ENABLE;
            hitway       = `WAY1;
            data_rd_copy = data1_rd;
        end else begin
            tagcomp_hit  = `DISABLE;
        end
        case(offset)
            `WORD0:begin
                data_wd_dc_copy  = {data_rd_copy[127:32],wr_data_m};
                read_data_m_copy = data_rd_copy[31:0];
            end
            `WORD1:begin
                data_wd_dc_copy  = {data_rd_copy[127:64],wr_data_m,data_rd_copy[31:0]};
                read_data_m_copy = data_rd_copy[63:32];
            end
            `WORD2:begin
                data_wd_dc_copy  = {data_rd_copy[127:96],wr_data_m,data_rd_copy[63:0]};
                read_data_m_copy = data_rd_copy[95:64];
            end
            `WORD3:begin
                data_wd_dc_copy  = {wr_data_m,data_rd_copy[95:0]};
                read_data_m_copy = data_rd_copy[127:96];
            end
        endcase // case(offset) 
    end

    // if cache miss ,the way of L1 we choose to replace.
    always @(*) begin
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

        case(choose_way)
            `WAY0:begin
                valid = valid0;
                dirty = dirty0;
            end
            `WAY1:begin
                valid = valid1;
                dirty = dirty1;
            end
        endcase
    end
    always @(*) begin
        case(state)
            `L1_IDLE:begin
                if (access_mem == `ENABLE || access_mem_ex == `ENABLE) begin 
                    nextstate =  `L1_ACCESS;
                end else begin 
                    nextstate =  `L1_IDLE;
                end
            end
            `L1_ACCESS:begin
                if (tagcomp_hit == `ENABLE) begin // cache hit
                    if(memwrite_m == `READ) begin // read hit
                        miss_stall  =  `DISABLE;
                        if(access_mem_ex == `ENABLE) begin
                            nextstate   =  `L1_ACCESS;
                        end else begin
                            nextstate   =  `L1_IDLE;
                        end
                        read_data_m =  read_data_m_copy;
                    end else if (memwrite_m == `WRITE) begin  // begin: write hit
                        miss_stall     =  `DISABLE;
                        nextstate      =  `WRITE_HIT;
                        dirty_wd       =  1'b1;
                        data_wd_dc_en  =  `ENABLE;
                        data_wd_dc     =  data_wd_dc_copy;
                        case(hitway)
                            `WAY0:begin
                                data0_rw  =  `WRITE;
                                dirty0_rw =  `WRITE;
                                tag0_rw   =  `WRITE;
                            end // hitway == 0
                            `WAY1:begin
                                data1_rw  =  `WRITE;
                                dirty1_rw =  `WRITE;
                                tag1_rw   =  `WRITE;
                            end // hitway == 1
                        endcase // case(hitway) 
                    end // end：write hit
                end else begin // cache miss
                    miss_stall =  `ENABLE; 
                    if(valid == `ENABLE && dirty == `ENABLE) begin 
                            if(l2_busy == `ENABLE) begin
                                nextstate       =  `WAIT_L2_BUSY_DIRTY;
                            end else begin 
                                l2_cache_rw =  memwrite_m; 
                                drq         =  `ENABLE;
                                nextstate   =  `WRITE_L2;
                            end
                            case(choose_way)
                                `WAY0:begin
                                    data_rd    =  data0_rd;
                                    l2_index   =  {tag0_rd[2:0],index[7:2]}; // old index of L2
                                    l2_addr    =  {tag0_rd[19:0],index,4'b0};
                                    // l2_data_wd_dc =  data_rd0;  
                                end
                                `WAY1:begin
                                    data_rd    =  data1_rd;
                                    l2_addr    =  {tag1_rd[19:0],index,4'b0};
                                    l2_index   =  {tag1_rd[2:0],index[7:2]}; // old index of L2
                                end
                            endcase
                    end else if(l2_busy == `ENABLE && (valid == `DISABLE || dirty == `DISABLE)) begin
                        nextstate    =  `WAIT_L2_BUSY_CLEAN;
                    end else if(l2_busy == `DISABLE && (valid == `DISABLE || dirty == `DISABLE)) begin
                        drq      =  `ENABLE;
                        l2_addr  =  addr;
                        l2_index =  addr[14:6]; 
                        nextstate    =  `L2_ACCESS;
                    end 
                end 
            end
            `L2_ACCESS:begin // access L2, wait L2 hit,choose replacement block's signal of L1
                //  L2 hit. Write to L1,read from L2
                if(l2_rdy == `ENABLE)begin
                    nextstate    =  `WRITE_L1;
                    dirty_wd =  1'b0;
                    case(choose_way)
                        `WAY0:begin
                            data0_rw  =  `WRITE;
                            tag0_rw   =  `WRITE;
                            // dirty0_wd =  1'b0;
                            dirty0_rw =  `WRITE;
                        end
                        `WAY1:begin
                            data1_rw  =  `WRITE;
                            tag1_rw   =  `WRITE;
                            // dirty1_wd =  1'b0;
                            dirty1_rw =  `WRITE;
                        end
                    endcase  
                end else begin
                    nextstate  =  `L2_ACCESS;
                end         
            end
            `WAIT_L2_BUSY_CLEAN:begin
                if(l2_busy == `ENABLE) begin
                    nextstate    =  `WAIT_L2_BUSY_CLEAN;
                end else begin
                    drq      =  `ENABLE;
                    l2_addr  =  addr;
                    l2_index =  addr[14:6]; 
                    nextstate    =  `L2_ACCESS;
                end
            end
            `WAIT_L2_BUSY_DIRTY:begin
                if(l2_busy == `ENABLE) begin
                    nextstate       =  `WAIT_L2_BUSY_DIRTY;
                end else begin
                    l2_cache_rw =  memwrite_m; 
                    drq         =  `ENABLE;
                    nextstate       =  `WRITE_L2;
                end
            end
            `WRITE_L1:begin // Write to L1,read from L2
                if(complete == `ENABLE)begin
                    drq        =  `DISABLE;
                    data0_rw   =  `READ;
                    data1_rw   =  `READ;
                    tag0_rw    =  `READ;
                    tag1_rw    =  `READ;
                    dirty0_rw  =  `READ;
                    dirty1_rw  =  `READ;
                    nextstate      =  `L1_ACCESS;
                end else begin
                    nextstate      =  `WRITE_L1;
                end        
            end
             `WRITE_HIT:begin // Write to L1,read from CPU
                if(complete == `ENABLE)begin
                    data_wd_dc_en =  `DISABLE;
                    data0_rw   =  `READ;
                    data1_rw   =  `READ;
                    tag0_rw    =  `READ;
                    tag1_rw    =  `READ;
                    dirty0_rw  =  `READ;
                    dirty1_rw  =  `READ;
                    if(access_mem_ex == `ENABLE) begin
                        nextstate  =  `L1_ACCESS;
                    end else begin
                        nextstate  =  `L1_IDLE;
                    end
                end else begin
                    nextstate  =  `WRITE_HIT;
                end        
            end
            `WRITE_L2:begin // load dirty block to L2
                if (l2_complete == `ENABLE) begin
                    l2_cache_rw =  `READ;  
                    l2_addr     =  addr;
                    l2_index    =  addr[14:6]; // new index of L2
                    nextstate   =  `L2_ACCESS;
                end else begin
                    nextstate   =  `WRITE_L2;
                end
            end
        endcase
    end
    always @(posedge clk) begin // cache control
        if (rst == `ENABLE) begin // reset
            state       <=  `L1_IDLE;
            data0_rw    <=  `READ;
            data1_rw    <=  `READ;                    
            tag0_rw     <=  `READ;
            tag1_rw     <=  `READ;
            dirty0_rw   <=  `READ;
            dirty1_rw   <=  `READ;
            miss_stall  <=  `DISABLE;
            l2_cache_rw <=  `READ;
        end else begin
            state  <= nextstate;
        end
    end
endmodule