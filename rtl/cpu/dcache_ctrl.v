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
    // input      [31:0]  addr,          // address of accessing memory
    input      [29:0]  addr,          // address of accessing memory
    // input      [31:0]  wr_data_m,
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
    // output to L1_cache  
    output reg         dirty_wd,
    output reg         dirty0_rw,
    output reg         dirty1_rw,
    output reg         wr0_en0,
    output reg         wr0_en1,
    output reg         wr0_en2,
    output reg         wr0_en3,
    output reg         wr1_en0,
    output reg         wr1_en1,
    output reg         wr1_en2,
    output reg         wr1_en3,
    output     [1:0]   offset,          
    // output reg [127:0] data_wd_dc,
    output reg         tag0_rw,       // read / write signal of L1_tag0
    output reg         tag1_rw,       // read / write signal of L1_tag1
    output     [20:0]  tag_wd,        // write data of L1_tag
    output reg         data_wd_dc_en, // choose signal of data_wd
    output reg         hitway,        // path hit mark            
    // output reg         data0_rw,      // read / write signal of data0
    // output reg         data1_rw,      // read / write signal of data1
    output     [7:0]   index,         // address of L1_cache
    output reg [127:0] rd_to_l2,      // read data of L1_cache's data
    /* L2_cache part */
    input              l2_complete,
    input              l2_busy,       // busy signal of L2_cache
    input              l2_rdy,        // ready signal of L2_cache
    input              mem_wr_dc_en,
    input              complete,      // complete op writing to L1
    input      [127:0] data_wd_l2,    // ++++++++++++++++++++
    output reg         drq,           // dcache request
    output reg         dc_rw_en,      // enable signal of writing dcache 
    // output reg [31:0]  l2_addr, 
    output reg [27:0]  l2_addr,
    output reg         l2_cache_rw    // l2_cache read/write signal
    );

    // wire       [1:0]   offset;           // offset of block
    reg                hitway0;             // the mark of choosing path0
    reg                hitway1;             // the mark of choosing path1
    // reg                hitway;
    reg                tagcomp_hit;         // tag hit mark
    reg                choose_way;          // the way of L1 we choose to replace
    reg        [3:0]   state,nextstate;     // state of control
    wire               valid0,valid1;
    reg                valid,dirty;         // valid signal of tag

    assign valid0        = tag0_rd[20];
    assign valid1        = tag1_rd[20];
    // assign index         = addr[11:4];
    // assign offset        = addr[3:2];
    // assign tag_wd        = {1'b1,addr [31:12]};  // 写入 tag，valid恒为 1。
    assign index         = addr[9:2];
    assign offset        = addr[1:0];
    assign tag_wd        = {1'b1,addr[29:10]};  // 写入 tag，valid恒为 1。

    always @(*)begin // path choose
        // hitway0 = (tag0_rd[19:0] == addr[31:12]) & valid0;
        // hitway1 = (tag1_rd[19:0] == addr[31:12]) & valid1;
        hitway0 = (tag0_rd[19:0] == addr[29:10]) & valid0;
        hitway1 = (tag1_rd[19:0] == addr[29:10]) & valid1;
        if(hitway0 == `ENABLE)begin
            tagcomp_hit  = `ENABLE;
            hitway       = `WAY0;
        end else if(hitway1 == `ENABLE)begin
            tagcomp_hit  = `ENABLE;
            hitway       = `WAY1;
        end else begin
            tagcomp_hit  = `DISABLE;
        end

        // if cache miss ,the way of L1 we choose to replace.
        if (valid0 === 1'b1) begin
            if (valid1 === 1'b1) begin
                if(lru !== 1'b1) begin
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
                if(valid0 === 1'bx) begin
                    valid = `DISABLE;
                end else begin
                    valid = valid0;
                end
                if(dirty0 === 1'bx) begin
                    dirty = `DISABLE;
                end else begin
                    dirty = dirty0;
                end 
            end
            `WAY1:begin
                if(valid1 === 1'bx) begin
                    valid = `DISABLE;
                end else begin
                    valid = valid1;
                end
                if(dirty1 === 1'bx) begin
                    dirty = `DISABLE;
                end else begin
                    dirty = dirty1;
                end 
            end
        endcase
    end

    always @(*) begin
        tag0_rw    = `READ;
        tag1_rw    = `READ;
        dirty0_rw  = `READ;
        dirty1_rw  = `READ;
        wr0_en0    = `READ;
        wr0_en1    = `READ;
        wr0_en2    = `READ;
        wr0_en3    = `READ;
        wr1_en0    = `READ;
        wr1_en1    = `READ;
        wr1_en2    = `READ;
        wr1_en3    = `READ;
        if(rst == `ENABLE) begin
            // data0_rw    =  `READ;
            // data1_rw    =  `READ;                    
            miss_stall  =  `DISABLE;
            l2_cache_rw =  `READ;
            dc_rw_en    = `DISABLE;
        end
        case(state)
            `DC_IDLE:begin
                if (access_mem == `ENABLE || access_mem_ex == `ENABLE) begin 
                    nextstate =  `DC_ACCESS;
                end else begin 
                    nextstate =  `DC_IDLE;
                end
            end
            `DC_ACCESS:begin
                dc_rw_en  = `DISABLE;
                if (tagcomp_hit == `ENABLE) begin // cache hit
                    if(memwrite_m == `READ) begin // read hit
                        // read l1_block ,write to cpu
                        miss_stall  =  `DISABLE;
                        if(access_mem_ex == `ENABLE) begin
                            nextstate   =  `DC_ACCESS;
                        end else begin
                            nextstate   =  `DC_IDLE;
                        end
                        case(hitway)
                            `WAY0:begin
                                case(offset)
                                    `WORD0:begin
                                        read_data_m = data0_rd[31:0];
                                    end
                                    `WORD1:begin
                                        read_data_m = data0_rd[63:32];
                                    end
                                    `WORD2:begin 
                                        read_data_m = data0_rd[95:64];
                                    end
                                    `WORD3:begin
                                        read_data_m = data0_rd[127:96];
                                    end
                                endcase // case(offset)  
                            end
                            `WAY1:begin
                                case(offset)
                                    `WORD0:begin
                                        read_data_m = data1_rd[31:0];
                                    end
                                    `WORD1:begin
                                        read_data_m = data1_rd[63:32];
                                    end
                                    `WORD2:begin 
                                        read_data_m = data1_rd[95:64];
                                    end
                                    `WORD3:begin
                                        read_data_m = data1_rd[127:96];
                                    end
                                endcase // case(offset)  
                            end
                        endcase
                        // read_data_m =  read_data_m_copy;
                    end else if (memwrite_m == `WRITE) begin  // begin: write hit
                        // cpu data write to l1
                        miss_stall     =  `ENABLE;
                        nextstate      =  `WRITE_HIT;
                        dirty_wd       =  1'b1;
                        data_wd_dc_en  =  `ENABLE;
                        // data_wd_dc     =  data_wd_dc_copy;
                        case(hitway)
                            `WAY0:begin
                                // data0_rw  =  `WRITE;
                                dirty0_rw =  `WRITE;
                                tag0_rw   =  `WRITE;
                                case(offset)
                                    `WORD0:begin
                                        wr0_en0 = `WRITE;
                                    end
                                    `WORD1:begin
                                        wr0_en1 = `WRITE;
                                    end
                                    `WORD2:begin
                                        wr0_en2 = `WRITE;
                                    end
                                    `WORD3:begin
                                        wr0_en3 = `WRITE;
                                    end
                                endcase
                            end // hitway == 0
                            `WAY1:begin
                                // data1_rw  =  `WRITE;
                                dirty1_rw =  `WRITE;
                                tag1_rw   =  `WRITE;
                                case(offset)
                                    `WORD0:begin
                                        wr1_en0 = `ENABLE;
                                    end
                                    `WORD1:begin
                                        wr1_en1 = `ENABLE;
                                    end
                                    `WORD2:begin
                                        wr1_en2 = `ENABLE;
                                    end
                                    `WORD3:begin
                                        wr1_en3 = `ENABLE;
                                    end
                                endcase
                            end // hitway == 1
                        endcase // case(hitway) 
                    end // end：write hit
                end else begin // cache miss
                    miss_stall =  `ENABLE; 
                    if(valid == `ENABLE && dirty == `ENABLE) begin 
                        // dirty block of l1, write to l2
                        if(l2_busy == `ENABLE) begin
                            nextstate   =  `WAIT_L2_BUSY_DIRTY;
                        end else begin 
                            l2_cache_rw =  `WRITE; 
                            drq         =  `ENABLE;
                            nextstate   =  `DC_WRITE_L2;
                        end
                        case(choose_way)
                            `WAY0:begin
                                rd_to_l2   =  data0_rd;
                                // l2_addr    =  {tag0_rd[19:0],index,4'b0};
                                l2_addr    =  {tag0_rd[19:0],index};
                            end
                            `WAY1:begin
                                rd_to_l2   =  data1_rd;
                                // l2_addr    =  {tag1_rd[19:0],index,4'b0};
                                l2_addr    =  {tag1_rd[19:0],index};
                            end
                        endcase
                    end else if(l2_busy == `ENABLE && (valid == `DISABLE || dirty == `DISABLE)) begin
                        nextstate    =  `WAIT_L2_BUSY_CLEAN;
                    end else if(l2_busy == `DISABLE && (valid == `DISABLE || dirty == `DISABLE)) begin
                        drq       =  `ENABLE;
                        // l2_addr   =  addr; 
                        l2_addr   =  addr[29:2]; 
                        nextstate =  `DC_ACCESS_L2;
                    end 
                end 
            end
            `DC_ACCESS_L2:begin // access L2, wait L2 hit,choose replacement block's signal of L1
                // l2 hit(l2_rdy), read l2_block ,write to l1
                // l2 miss(mem_wr_dc_en), read mem_block ,write to l1 and l2     
                if(l2_rdy == `ENABLE || mem_wr_dc_en == `ENABLE)begin
                    // wr signal is `READ in MEM stage,read l2_block ,write to l1 and cpu
                    // wr signal is `WRITE in MEM stage,read l2_block ,write to l1
                    /* write l1 part */ 
                    dc_rw_en  = `ENABLE;
                    // nextstate =  `WRITE_L1;
                    dirty_wd  =  1'b0;
                    case(choose_way)
                        `WAY0:begin
                            // data0_rw  =  `WRITE;
                            tag0_rw   = `WRITE;
                            dirty0_rw = `WRITE;
                            wr0_en0   = `WRITE;
                            wr0_en1   = `WRITE;
                            wr0_en2   = `WRITE;
                            wr0_en3   = `WRITE;
                        end
                        `WAY1:begin
                            // data1_rw  =  `WRITE;
                            tag1_rw   = `WRITE;
                            dirty1_rw = `WRITE;
                            wr1_en0   = `WRITE;
                            wr1_en1   = `WRITE;
                            wr1_en2   = `WRITE;
                            wr1_en3   = `WRITE;
                        end
                    endcase 
                    /* write cpu part */ 
                    if (memwrite_m == `READ) begin
                        nextstate =  `WRITE_DC_R;
                        case(offset)
                            `WORD0:begin
                                read_data_m = data_wd_l2[31:0];
                            end
                            `WORD1:begin
                                read_data_m = data_wd_l2[63:32];
                            end
                            `WORD2:begin 
                                read_data_m = data_wd_l2[95:64];
                            end
                            `WORD3:begin
                                read_data_m = data_wd_l2[127:96];
                            end
                        endcase // case(offset) 
                    end else begin
                        nextstate =  `WRITE_DC_W;
                    end
                end else begin
                    nextstate  =  `DC_ACCESS_L2;
                end
                        
            end
            `WAIT_L2_BUSY_CLEAN:begin
                if(l2_busy == `ENABLE) begin
                    nextstate =  `WAIT_L2_BUSY_CLEAN;
                end else begin
                    drq       =  `ENABLE;
                    // l2_addr   =  addr;
                    l2_addr   =  addr[29:2]; 
                    nextstate =  `DC_ACCESS_L2;
                end
            end
            `WAIT_L2_BUSY_DIRTY:begin
                if(l2_busy == `ENABLE) begin
                    nextstate       =  `WAIT_L2_BUSY_DIRTY;
                end else begin
                    l2_cache_rw =  `WRITE; 
                    drq         =  `ENABLE;
                    nextstate   =  `DC_WRITE_L2;
                end
            end
            `WRITE_DC_R:begin // Write to L1,read from L2
                if(complete == `ENABLE)begin
                    drq        =  `DISABLE;
                    // data0_rw   =  `READ;
                    // data1_rw   =  `READ;
                    // tag0_rw    =  `READ;
                    // tag1_rw    =  `READ;
                    // dirty0_rw  =  `READ;
                    // dirty1_rw  =  `READ;
                    // wr0_en0    = `READ;
                    // wr0_en1    = `READ;
                    // wr0_en2    = `READ;
                    // wr0_en3    = `READ;
                    // wr1_en0    = `READ;
                    // wr1_en1    = `READ;
                    // wr1_en2    = `READ;
                    // wr1_en3    = `READ;
                    miss_stall  =  `DISABLE;
                    if(access_mem_ex == `ENABLE) begin
                        nextstate   =  `DC_ACCESS;
                    end else begin
                        nextstate   =  `DC_IDLE;
                    end
                end else begin
                    nextstate  =  `WRITE_DC_R;
                end        
            end
            `WRITE_DC_W:begin // Write to L1,read from L2
                if(complete == `ENABLE)begin
                    drq        =  `DISABLE;
                    // data0_rw   =  `READ;
                    // data1_rw   =  `READ;
                    // tag0_rw    =  `READ;
                    // tag1_rw    =  `READ;
                    // dirty0_rw  =  `READ;
                    // dirty1_rw  =  `READ;
                    // wr0_en0    = `READ;
                    // wr0_en1    = `READ;
                    // wr0_en2    = `READ;
                    // wr0_en3    = `READ;
                    // wr1_en0    = `READ;
                    // wr1_en1    = `READ;
                    // wr1_en2    = `READ;
                    // wr1_en3    = `READ;
                    nextstate  =  `DC_ACCESS;
                end else begin
                    nextstate  =  `WRITE_DC_W;
                end        
            end
             `WRITE_HIT:begin // Write to L1,read from CPU
                if(complete == `ENABLE)begin
                    data_wd_dc_en =  `DISABLE;
                    // tag0_rw    =  `READ;
                    // tag1_rw    =  `READ;
                    // dirty0_rw  =  `READ;
                    // dirty1_rw  =  `READ;
                    // wr0_en0    =  `READ;
                    // wr0_en1    =  `READ;
                    // wr0_en2    =  `READ;
                    // wr0_en3    =  `READ;
                    // wr1_en0    =  `READ;
                    // wr1_en1    =  `READ;
                    // wr1_en2    =  `READ;
                    // wr1_en3    =  `READ;
                    miss_stall  =  `DISABLE;
                    if(access_mem_ex == `ENABLE) begin
                        nextstate  =  `DC_ACCESS;
                    end else begin
                        nextstate  =  `DC_IDLE;
                    end
                end else begin
                    nextstate  =  `WRITE_HIT;
                end        
            end
            `DC_WRITE_L2:begin // load dirty block to L2
                if (l2_complete == `ENABLE) begin
                    l2_cache_rw =  `READ;  
                    // l2_addr     =  addr;
                    l2_addr   =  addr[29:2]; 
                    nextstate   =  `DC_ACCESS_L2;
                end else begin
                    nextstate   =  `DC_WRITE_L2;
                end
            end
            default:nextstate = `DC_IDLE;
        endcase       
    end
    always @(posedge clk) begin // cache control
        if (rst == `ENABLE) begin // reset
            state  <=  `DC_IDLE;
        end else begin
            state  <= nextstate;
        end
    end
endmodule