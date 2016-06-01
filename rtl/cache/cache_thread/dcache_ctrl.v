////////////////////////////////////////////////////////////////////
// Engineer:       Kippy Chen - 799182081@qq.com                  //
//                                                                //
// Additional contributions by:                                   //
//                 Beyond Sky - fan-dave@163.com                  //
//                 Junhao Chang                                   //
//                 Leway Colin - colin4124@gmail.com              //
//                                                                //
// Design Name:    dcache_ctrl                                    //
// Project Name:   FMRT Mini Core                                 //
// Language:       Verilog                                        //
//                                                                //
// Description:    Control part of D-Cache.                       //
//                                                                //
////////////////////////////////////////////////////////////////////

`timescale 1ns/1ps

/********** General header file **********/
`include "stddef.h"
`include "dcache.h"

module dcache_ctrl(
    /********* Clk & Reset ********/
    input              clk,           // clock
    input              rst,           // reset
    /******** Memory part *********/
    input              memory_en,
    input              l2_en,
    input      [27:0]  dc_addr_mem,
    input      [27:0]  dc_addr_l2,
    /********** CPU part **********/
    // input      [31:0]  addr,          // address of accessing memory
    input      [29:0]  next_addr,          // address of accessing memory
    input              memwrite_m,    // read / write signal of CPU
    input              access_mem,    // access MEM mark
    input      [31:0]  wr_data,       // write data from CPU
    input              out_rdy,
    // input      [1:0]   store_op,
    output reg [31:0]  read_data_m,   // read data of CPU
    output reg         miss_stall,    // the signal of stall caused by cache miss
    output reg         access_l2_clean,
    output reg         access_l2_dirty,
    output reg         choose_way,
    output reg [27:0]  dc_addr,
    /****** Thread choose part *****/
    input      [1:0]   l2_thread,
    input      [1:0]   mem_thread,
    input      [1:0]   thread,
    output reg [1:0]   dc_thread,
    output reg         dc_busy,
    /******** D_Cache part ********/
    output reg         block0_we,     // write mark of block0
    output reg         block1_we,     // write mark of block1
    output reg         block0_re,     // read mark of block0
    output reg         block1_re,     // read mark of block1
    output reg [1:0]   offset,        // offset of dcache
    output reg         tagcomp_hit,   // hit mark of dcache
    output reg         hitway,        // path hit mark            
    output reg [7:0]   index,         // address of L1_cache
    output reg         drq,           // dcache request
    // d_tag
    input              lru,           // mark of replacing
    input      [1:0]   thread0,       // read data of tag0
    input      [1:0]   thread1,       // read data of tag1
    input      [20:0]  tag0_rd,       // read data of tag0
    input      [20:0]  tag1_rd,       // read data of tag1
    input      [127:0] data0_rd,      // read data of data0
    input      [127:0] data1_rd,      // read data of data1
    input              dirty0,        // read data of dirty0 
    input              dirty1,        // read data of dirty1          
    output reg [20:0]  tag_wd,        // write data of dtag
    // d_data 
    output reg         data_wd_dc_en, // choose signal of data_wd
    output reg [31:0]  dc_wd, 
    output reg         dc_rw,   
    /******* L2_Cache part *******/
    // input              l2_idle,
    input              l2_busy,
    input              dc_en,         // busy signal of L2_cache
    input              l2_rdy,        // ready signal of L2_cache
    input              mem_wr_dc_en,
    input      [127:0] data_wd_l2_mem,
    input      [127:0] data_wd_l2     
    );
    reg                hitway0;             // the mark of choosing path0
    reg                hitway1;             // the mark of choosing path1
    reg        [2:0]   state,nextstate;     // state of control
    reg                valid,dirty;         // valid signal of tag
    reg        [19:0]  comp_addr;
    always @(*)begin // path choose
        hitway0 = (tag0_rd[19:0] == comp_addr) & tag0_rd[20];
        hitway1 = (tag1_rd[19:0] == comp_addr) & tag1_rd[20];
        if(hitway0 == `ENABLE  && dc_thread == thread0)begin
            tagcomp_hit  = `ENABLE;
            hitway       = `WAY0;
        end else if(hitway1 == `ENABLE  && dc_thread == thread1)begin
            tagcomp_hit  = `ENABLE;
            hitway       = `WAY1;
        end else begin
            tagcomp_hit  = `DISABLE;
        end

        // if cache miss ,the way of L1 we choose to replace.
        if (tag0_rd[20] === 1'b1) begin
            if (tag1_rd[20] === 1'b1) begin
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
                if(tag0_rd[20] === 1'bx) begin
                    valid = `DISABLE;
                end else begin
                    valid = tag0_rd[20];
                end
                if(dirty0 === 1'bx) begin
                    dirty = `DISABLE;
                end else begin
                    dirty = dirty0;
                end 
            end
            `WAY1:begin
                if(tag1_rd[20] === 1'bx) begin
                    valid = `DISABLE;
                end else begin
                    valid = tag1_rd[20];
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
        case(state)
            `DC_IDLE:begin
                drq        =  `DISABLE;
                miss_stall =  `DISABLE;
                block0_we  =  `DISABLE;
                block1_we  =  `DISABLE;
                block0_re  =  `DISABLE;
                block1_re  =  `DISABLE;
                dc_busy    =  `DISABLE;
                if (access_mem == `ENABLE) begin 
                    if ((memory_en == `ENABLE && dc_addr_mem == dc_addr)||(l2_en == `ENABLE && dc_addr_l2 == dc_addr))begin
                        miss_stall = `ENABLE;
                        nextstate  =  `DC_IDLE;
                    end else begin
                        block0_re  =  `ENABLE;
                        block1_re  =  `ENABLE;
                        nextstate  =  `DC_ACCESS;   
                        dc_busy    =  `ENABLE; 
                        dc_thread  =  thread;
                        dc_addr    =  next_addr[29:2];
                        index      =  dc_addr[7:0];
                        offset     =  next_addr[1:0];
                        tag_wd     =  {1'b1,dc_addr[27:8]};
                        comp_addr  =  dc_addr[27:8];
                        data_wd_dc_en =  `DISABLE;
                    end               
                end else begin 
                    nextstate  =  `DC_IDLE;
                end
            end
            `DC_ACCESS:begin
                miss_stall    =  `ENABLE;
                drq           =  `DISABLE;
                block0_we     =  `DISABLE;
                block1_we     =  `DISABLE;                       
                block0_re     =  `DISABLE;
                block1_re     =  `DISABLE;
                data_wd_dc_en =  `DISABLE;
                dc_wd         =  wr_data;
                dc_rw         =  memwrite_m;
                // dc_choose_way = choose_way;
                if (tagcomp_hit == `ENABLE) begin // cache hit
                    if(dc_rw == `READ) begin // read hit
                        // read l1_block ,write to cpu
                        miss_stall  =  `DISABLE;                            
                        block0_re   =  `ENABLE;
                        block1_re   =  `ENABLE;
                        dc_thread   = thread;
                        if (out_rdy == `ENABLE) begin
                            if(access_mem == `ENABLE) begin
                                if ((memory_en == `ENABLE && dc_addr_mem == dc_addr)||(l2_en == `ENABLE && dc_addr_l2 == dc_addr))begin
                                    miss_stall = `ENABLE;
                                    nextstate  =  `DC_IDLE;
                                end else begin
                                    dc_addr    =  next_addr[29:2];
                                    index      =  dc_addr[7:0];
                                    offset     =  next_addr[1:0];
                                    tag_wd     =  {1'b1,dc_addr[27:8]};
                                    comp_addr  =  dc_addr[27:8];
                                    nextstate  = `DC_ACCESS;
                                end
                            end else begin
                                nextstate  = `DC_IDLE;
                            end
                        end  else begin
                            nextstate   =  `DC_ACCESS;
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
                    end else if (dc_rw == `WRITE) begin  // begin: write hit
                        // cpu data write to l1
                        data_wd_dc_en  =  `ENABLE;
                        case(hitway)
                            `WAY0:begin
                                block0_we = `ENABLE;
                            end // hitway == 0
                            `WAY1:begin
                                block1_we = `ENABLE;
                            end // hitway == 1
                        endcase // case(hitway) 
                        if(access_mem == `ENABLE) begin
                            miss_stall = `ENABLE;
                            nextstate  =  `DC_IDLE;
                        end else begin
                            miss_stall =  `DISABLE;
                            nextstate  =  `DC_IDLE;
                        end 
                    end // end：write hit
                end else begin // cache miss
                    miss_stall      = `ENABLE; 
                    drq             = `ENABLE;
                    dc_busy         = `ENABLE;
                    access_l2_clean = `DISABLE;
                    access_l2_dirty = `DISABLE;
                    if (l2_busy == `DISABLE) begin
                        if(valid == `ENABLE && dirty == `ENABLE) begin 
                            // dirty block of l1, write to l2
                            if(dc_en == `ENABLE) begin
                                dc_busy         =  `DISABLE;
                                if (dc_rw == `WRITE) begin
                                    miss_stall  = `DISABLE;
                                    if (access_mem == `ENABLE) begin 
                                        miss_stall = `ENABLE;
                                        nextstate  =  `DC_IDLE;    
                                    end else begin 
                                        nextstate  =  `DC_IDLE;
                                    end
                                end else begin
                                    nextstate    =  `DC_ACCESS_L2;
                                    miss_stall   =  `ENABLE;
                                end
                                access_l2_dirty = `ENABLE;
                            end else begin 
                                nextstate   =  `WAIT_L2_BUSY_DIRTY;
                            end
                        end else if(valid == `DISABLE || dirty == `DISABLE) begin
                            if (dc_en == `ENABLE) begin
                                dc_busy         =  `DISABLE;
                                access_l2_clean = `ENABLE;
                                // nextstate =  `DC_ACCESS_L2;
                                if (dc_rw == `WRITE) begin
                                    miss_stall  = `DISABLE;
                                    if(access_mem == `ENABLE) begin
                                        miss_stall = `ENABLE;
                                        nextstate  =  `DC_IDLE;
                                    end else begin
                                        nextstate  =  `DC_IDLE;
                                    end
                                end else begin
                                    nextstate    =  `DC_ACCESS_L2;
                                    miss_stall   =  `ENABLE;
                                end
                            end else begin
                                nextstate =  `WAIT_L2_BUSY_CLEAN;
                            end   
                        end
                    end   
                end 
            end
            `WAIT_L2_BUSY_CLEAN:begin // can not go to L2
                dc_busy   =  `ENABLE;
                access_l2_clean = `DISABLE;
                if(dc_en == `ENABLE) begin
                    dc_busy         =  `DISABLE;
                    if (dc_rw == `WRITE) begin
                        miss_stall  = `DISABLE;
                        if(access_mem == `ENABLE) begin
                            miss_stall = `ENABLE;
                            nextstate  =  `DC_IDLE;
                        end else begin
                            nextstate  =  `DC_IDLE;
                        end
                    end else begin
                        nextstate    =  `DC_ACCESS_L2;
                        miss_stall   =  `ENABLE;
                    end
                    access_l2_clean = `ENABLE;
                end else begin
                    nextstate =  `WAIT_L2_BUSY_CLEAN;
                end
            end
            `WAIT_L2_BUSY_DIRTY:begin // can not go to L2
                dc_busy   =  `ENABLE;
                access_l2_dirty = `DISABLE;
                if(dc_en == `ENABLE) begin
                    if (dc_rw == `WRITE) begin
                        miss_stall  = `DISABLE;
                        if(access_mem == `ENABLE) begin
                            miss_stall = `ENABLE;
                            nextstate  =  `DC_IDLE;
                        end else begin
                            nextstate  = `DC_IDLE;
                        end
                    end else begin
                        nextstate    =  `DC_ACCESS_L2;
                        miss_stall   =  `ENABLE;
                    end
                    dc_busy         =  `DISABLE;
                    access_l2_dirty =  `ENABLE;
                end else begin
                    nextstate   =  `WAIT_L2_BUSY_DIRTY;
                end
            end
            `DC_ACCESS_L2:begin // access L2, wait L2 hit,choose replacement block's signal of L1
                drq             = `DISABLE;
                access_l2_clean = `DISABLE;
                access_l2_dirty = `DISABLE;
                // l2 hit(l2_rdy), read l2_block ,write to l1
                // l2 miss(mem_wr_dc_en), read mem_block ,write to l1 and l2     
                // wr signal is `READ in MEM stage,read l2_block ,write to l1 and cpu
                // wr signal is `WRITE in MEM stage,read l2_block ,write to l1
                /* write l1 part */ 
                /* write cpu part */ 
                if(l2_rdy == `ENABLE && (l2_thread == dc_thread) && (l2_thread == thread)) begin
                    dc_busy   =  `ENABLE;
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
                end else if (mem_wr_dc_en == `ENABLE && (mem_thread == dc_thread) && (mem_thread == thread)) begin
                    dc_busy   =  `ENABLE;
                    nextstate =  `WRITE_DC_R;
                    case(offset)
                        `WORD0:begin
                            read_data_m = data_wd_l2_mem[31:0];
                        end
                        `WORD1:begin
                            read_data_m = data_wd_l2_mem[63:32];
                        end
                        `WORD2:begin 
                            read_data_m = data_wd_l2_mem[95:64];
                        end
                        `WORD3:begin
                            read_data_m = data_wd_l2_mem[127:96];
                        end
                    endcase // case(offset) 
                end else begin
                    nextstate  =  `DC_ACCESS_L2;
                end                    
            end
            `WRITE_DC_R:begin // Read from L2.Write to L1 & CPU
                miss_stall  =  `DISABLE;
                block0_we   =  `DISABLE;
                block1_we   =  `DISABLE;
                dc_busy     =  `DISABLE;
                if(access_mem == `ENABLE) begin
                    if ((memory_en == `ENABLE && dc_addr_mem == dc_addr)||(l2_en == `ENABLE && dc_addr_l2 == dc_addr))begin
                        miss_stall = `ENABLE;
                        nextstate  =  `DC_IDLE;
                    end else begin
                        dc_addr    =  next_addr[29:2];
                        index      =  dc_addr[7:0];
                        offset     =  next_addr[1:0];
                        tag_wd     =  {1'b1,dc_addr[27:8]};
                        comp_addr  =  dc_addr[27:8];
                        nextstate  =  `DC_ACCESS;
                        dc_thread  =  thread;
                        block0_re  =  `ENABLE;
                        block1_re  =  `ENABLE;
                        dc_busy    =  `ENABLE;
                    end
                end else begin
                    nextstate  =  `DC_IDLE;
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