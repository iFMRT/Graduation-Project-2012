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
`include "common_defines.v"
`include "l1_cache.h"
`include "l2_cache.h"

module dcache_ctrl(
    /********* Clk & Reset ********/
    input wire         clk,           // clock
    input wire         rst,           // reset
    /******** Memory part *********/
    input wire         memory_en,
    input wire         l2_en,
    input wire [27:0]  dc_addr_mem,
    input wire [27:0]  dc_addr_l2,
    input wire [20:0]  dc_tag_wd_mem,
    input wire [7:0]   dc_index_mem,
    input wire [127:0] data_wd_l2_mem,
    input wire [1:0]   offset_mem,
    input wire         dc_block0_we_mem,
    input wire         dc_block1_we_mem,
    input wire         dc_rw_mem,
    /********** CPU part **********/
    input wire [29:0]  next_addr,          // address of accessing memory
    input wire         memwrite_m,    // read / write signal of CPU
    input wire         access_mem,    // access MEM mark
    input wire [31:0]  wr_data,       // write data from CPU
    input wire [1:0]   offset_m,
    input wire         out_rdy,
    output reg [31:0]  read_data_m,   // read data of CPU
    output reg         miss_stall,    // the signal of stall caused by cache miss
    output reg         access_l2_clean,
    output reg         access_l2_dirty,
    output reg         choose_way,
    output reg [27:0]  dc_addr,
    output reg         thread_rdy,
    input  wire[31:0]  wr_data_l2,
    input  wire[31:0]  wr_data_mem,
    output reg [31:0]  wr_data_dc,
    /****** Thread choose part *****/
    input wire [1:0]   l2_thread,
    input wire [1:0]   mem_thread,
    input wire [1:0]   thread,
    output reg [1:0]   dc_thread,
    output reg         dc_busy,
    /******** D_Cache part ********/
    output reg         block0_we,     // write mark of block0
    output reg         block1_we,     // write mark of block1
    output reg         block0_re,     // read mark of block0
    output reg         block1_re,     // read mark of block1
    output reg [1:0]   offset,        // offset of dcache       
    output reg [7:0]   index,         // address of L1_cache
    output reg         drq,           // dcache request
    output reg         l2_wr_dc_en,
    input wire         data_wd_l2_en_dc,
    // d_tag
    input wire         lru,           // mark of replacing
    input wire [1:0]   thread0,       // read data of tag0
    input wire [1:0]   thread1,       // read data of tag1
    input wire [20:0]  tag0_rd,       // read data of tag0
    input wire [20:0]  tag1_rd,       // read data of tag1
    input wire [127:0] data0_rd,      // read data of data0
    input wire [127:0] data1_rd,      // read data of data1
    input wire         dirty0,        // read data of dirty0 
    input wire         dirty1,        // read data of dirty1          
    output reg [20:0]  tag_wd,        // write data of dtag
    output reg [1:0]   dc_thread_wd,  // write data of dtag
    output reg [1:0]   thread_rdy_thread,  // write data of dtag
    // d_data 
    output reg         data_wd_dc_en, // choose signal of data_wd data_wd_l2_en
    output reg [31:0]  dc_wd, 
    output reg         dc_rw,   
    output reg [127:0] dirty_data,
    output reg [20:0]  dirty_tag,        // write data of dtag
    output reg [127:0] data_wd,
    output reg [31:0]  rd_to_write_m,
    /******* L2_Cache part *******/
    input wire [20:0]  dc_tag_wd_l2,
    input wire [7:0]   dc_index_l2,
    input wire         dc_block0_we_l2,
    input wire         dc_block1_we_l2,
    input wire         dc_rw_l2,
    input wire [1:0]   offset_l2, 
    input wire         l2_busy,
    input wire         dc_en,         // busy signal of L2_cache
    input wire         l2_rdy,        // ready signal of L2_cache
    input wire         mem_wr_dc_en,
    input wire [127:0] data_wd_l2       
    );
    reg                hitway;
    reg                tagcomp_hit;
    reg                hitway0;             // the mark of choosing path0
    reg                hitway1;             // the mark of choosing path1
    reg        [2:0]   state,nextstate;     // state of control
    reg                valid,dirty;         // valid signal of tag
    reg        [19:0]  comp_addr;
    reg                thread_rdy_p;
    reg        [29:0]  addr;
    reg                access_after_sw;
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
                drq             =  `DISABLE;
                miss_stall      =  `DISABLE;
                // block0_we       =  `DISABLE;
                // block1_we       =  `DISABLE;
                // block0_re       =  `DISABLE;
                // block1_re       =  `DISABLE;
                dc_busy         =  `DISABLE;
                access_l2_clean =  `DISABLE;
                access_l2_dirty =  `DISABLE;
                // if (dc_rw == `WRITE) begin
                //     dc_thread       =  thread;
                //     dc_addr         =  next_addr[29:2];
                //     index           =  dc_addr[7:0];
                //     offset          =  next_addr[1:0];
                //     tag_wd          =  {1'b1,dc_addr[27:8]};
                //     comp_addr       =  dc_addr[27:8];
                // end 
                data_wd_dc_en   =  `DISABLE;
                if (thread_rdy_p == `ENABLE) begin
                    thread_rdy    =  `ENABLE;
                    thread_rdy_p  =  `DISABLE;
                    block0_we     =  `DISABLE;
                    block1_we     =  `DISABLE;
                    l2_wr_dc_en     =  `DISABLE;
                    thread_rdy_thread = dc_thread_wd;
                end else begin
                    thread_rdy_p  =  `DISABLE;
                    thread_rdy    =  `DISABLE;
                end
                if ((memory_en == `ENABLE && dc_addr_mem == dc_addr)||(l2_en == `ENABLE && dc_addr_l2 == dc_addr))begin
                    if(data_wd_l2_en_dc == `ENABLE) begin
                        miss_stall   = `DISABLE;  // ++++++
                        dc_busy      =  `ENABLE;  // ++++++

                        tag_wd        =  dc_tag_wd_l2;
                        index         =  dc_index_l2;
                        block0_we     =  dc_block0_we_l2;
                        block1_we     =  dc_block1_we_l2;
                        l2_wr_dc_en   =  `ENABLE;
                        data_wd       =  data_wd_l2;
                        dc_thread_wd  =  l2_thread;
                        offset        =  offset_l2;
                        if (dc_rw_l2 == `WRITE) begin
                            nextstate  = `CPU_WRITE_DC;
                            dc_wd      = wr_data_l2;
                            block0_re  = `ENABLE;
                            block1_re  = `ENABLE;
                        end else begin
                            nextstate  = `DC_IDLE;
                            thread_rdy_p  =  `ENABLE;
                        end
                        if (l2_thread == thread) begin   
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
                        end    
                    end else if (mem_wr_dc_en == `ENABLE) begin
                        miss_stall   = `DISABLE;
                        dc_busy      =  `ENABLE;

                        tag_wd        =  dc_tag_wd_mem;
                        index         =  dc_index_mem;
                        block0_we     =  dc_block0_we_mem;
                        block1_we     =  dc_block1_we_mem;
                        l2_wr_dc_en   =  `ENABLE;
                        data_wd       =  data_wd_l2_mem;
                        dc_thread_wd  =  mem_thread;
                        offset        =  offset_mem;
                        if (dc_rw_mem == `WRITE) begin
                            nextstate  = `CPU_WRITE_DC;
                            dc_wd      = wr_data_mem;
                            block0_re  = `ENABLE;
                            block1_re  = `ENABLE;
                        end else begin
                            nextstate  = `DC_IDLE;
                            thread_rdy_p  =  `ENABLE;
                            if (mem_thread == thread) begin
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
                            end  
                        end       
                    end else begin
                        nextstate  = `DC_IDLE;
                        miss_stall = `ENABLE;
                        dc_busy    = `DISABLE; // ++++++
                    end
                end else if (access_mem == `ENABLE) begin 
                    block0_re  =  `ENABLE;
                    block1_re  =  `ENABLE;
                    nextstate  =  `DC_ACCESS;  
                    dc_thread  =  thread;
                    dc_addr    =  next_addr[29:2];
                    index      =  dc_addr[7:0];
                    offset     =  next_addr[1:0];
                    tag_wd     =  {1'b1,dc_addr[27:8]};
                    comp_addr  =  dc_addr[27:8];    
                end else begin 
                    nextstate =  `DC_IDLE;
                end
            end
            `CPU_WRITE_DC:begin // Read from L2. Write to L1，then CPU write L1
                l2_wr_dc_en   =  `DISABLE;
                // if (block0_we== `ENABLE) begin
                //     case(offset)
                //         `WORD0:begin
                //             rd_to_write_m = data0_rd[31:0];
                //         end
                //         `WORD1:begin
                //             rd_to_write_m = data0_rd[63:32];
                //         end
                //         `WORD2:begin 
                //             rd_to_write_m = data0_rd[95:64];
                //         end
                //         `WORD3:begin
                //             rd_to_write_m = data0_rd[127:96];
                //         end
                //     endcase // case(offset)  
                // end else if (block1_we== `ENABLE) begin
                //     case(offset)
                //         `WORD0:begin
                //             rd_to_write_m = data1_rd[31:0];
                //         end
                //         `WORD1:begin
                //             rd_to_write_m = data1_rd[63:32];
                //         end
                //         `WORD2:begin 
                //             rd_to_write_m = data1_rd[95:64];
                //         end
                //         `WORD3:begin
                //             rd_to_write_m = data1_rd[127:96];
                //         end
                //     endcase // case(offset) 
                // end
                // dc_wd         =  wr_data;
                data_wd_dc_en =  `ENABLE; 
                thread_rdy_p  =  `ENABLE;
                // if ((memory_en == `ENABLE && dc_addr_mem == dc_addr)||(l2_en == `ENABLE && dc_addr_l2 == dc_addr))begin
                //     nextstate     =  `DC_IDLE;
                // end else 
                if (access_mem == `ENABLE) begin 
                    if(index  ==  next_addr[9:2])begin
                        block0_re       =  `ENABLE;
                        block1_re       =  `ENABLE;
                        nextstate       =  `DC_ACCESS;   
                        // dc_busy       =  `DISABLE; 
                        // miss_stall    =  `DISABLE; 
                        comp_addr       =  next_addr[29:10];
                        addr            =  next_addr;
                        l2_wr_dc_en     =  `DISABLE;
                        access_after_sw = `ENABLE;
                        offset          =  next_addr[1:0];
                    end else begin 
                        nextstate =  `DC_IDLE;
                        // dc_wd_dc  =  wr_data;

                    end   
                end else begin 
                    nextstate =  `DC_IDLE;
                end  
            end
            `DC_ACCESS:begin
                drq           =  `DISABLE;
                block0_we     =  `DISABLE;
                block1_we     =  `DISABLE;                       
                block0_re     =  `DISABLE;
                block1_re     =  `DISABLE;
                data_wd_dc_en =  `DISABLE;
                dc_rw         =  memwrite_m;
                wr_data_dc    =  wr_data;
                offset        =  offset_m;
                dc_wd         =  wr_data;
                // if (out_rdy == `ENABLE) begin
                //     offset   =    offset_m;
                // end
                if (access_after_sw == `ENABLE) begin
                    dc_thread  =  thread;
                    dc_addr    =  addr[29:2];
                    // offset     =  addr[1:0];
                    tag_wd     =  {1'b1,dc_addr[27:8]};
                    data_wd_dc_en =  `DISABLE;
                    access_after_sw = `DISABLE;
                end
                if (tagcomp_hit == `ENABLE) begin // cache hit
                    if(dc_rw == `READ) begin // read hit
                        // read l1_block ,write to cpu
                        miss_stall  =  `DISABLE;  
                        dc_busy     =  `DISABLE;                          
                        block0_re   =  `ENABLE;
                        block1_re   =  `ENABLE;
                        dc_thread   = thread;
                        if(access_mem == `ENABLE) begin
                            if ((memory_en == `ENABLE && dc_addr_mem == dc_addr)||(l2_en == `ENABLE && dc_addr_l2 == dc_addr))begin
                                miss_stall = `ENABLE;
                                nextstate  =  `DC_IDLE;
                            end else begin
                                miss_stall = `DISABLE;
                                dc_addr    =  next_addr[29:2];
                                index      =  dc_addr[7:0];
                                // offset     =  next_addr[1:0];
                                tag_wd     =  {1'b1,dc_addr[27:8]};
                                comp_addr  =  dc_addr[27:8];
                                nextstate  = `DC_ACCESS;
                            end
                        end else begin
                            nextstate  = `DC_IDLE;
                            miss_stall = `DISABLE;
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
                        dc_thread_wd   =  dc_thread;

                        case(hitway)
                            `WAY0:begin
                                block0_we = `ENABLE;
                                // case(offset)
                                //     `WORD0:begin
                                //         rd_to_write_m = data0_rd[31:0];
                                //     end
                                //     `WORD1:begin
                                //         rd_to_write_m = data0_rd[63:32];
                                //     end
                                //     `WORD2:begin 
                                //         rd_to_write_m = data0_rd[95:64];
                                //     end
                                //     `WORD3:begin
                                //         rd_to_write_m = data0_rd[127:96];
                                //     end
                                // endcase // case(offset)               
                            end // hitway == 0
                            `WAY1:begin
                                block1_we = `ENABLE;
                                // case(offset)
                                //     `WORD0:begin
                                //         rd_to_write_m = data1_rd[31:0];
                                //     end
                                //     `WORD1:begin
                                //         rd_to_write_m = data1_rd[63:32];
                                //     end
                                //     `WORD2:begin 
                                //         rd_to_write_m = data1_rd[95:64];
                                //     end
                                //     `WORD3:begin
                                //         rd_to_write_m = data1_rd[127:96];
                                //     end
                                // endcase // case(offset) 
                            end // hitway == 1
                        endcase // case(hitway)

                        dc_wd  =  wr_data;

                        if(access_mem == `ENABLE) begin
                            // miss_stall = `ENABLE;
                            dc_busy    = `ENABLE;
                            nextstate  =  `DC_IDLE;
                        end else begin
                            // miss_stall =  `DISABLE;
                            dc_busy    = `DISABLE;
                            nextstate  =  `DC_IDLE;
                        end 
                    end // end：write hit
                end else begin // cache miss
                    drq             = `ENABLE;
                    // dc_busy         = `ENABLE;
                    miss_stall   = `ENABLE;
                    access_l2_clean = `DISABLE;
                    access_l2_dirty = `DISABLE;
                    if (l2_busy == `DISABLE) begin
                        miss_stall  = `ENABLE; 
                        dc_busy     = `DISABLE;
                        if(valid == `ENABLE && dirty == `ENABLE) begin  
                            case(choose_way)
                                `WAY0:begin
                                    dirty_data = data0_rd;
                                    dirty_tag  = tag0_rd;
                                end
                                `WAY1:begin
                                    dirty_data = data1_rd;
                                    dirty_tag  = tag1_rd;
                                end
                            endcase                          
                            // dirty block of l1, write to l2
                            if(dc_en == `ENABLE) begin
                                // dc_busy    =  `DISABLE;
                                nextstate  =  `DC_IDLE;
                                // if (dc_rw == `WRITE) begin
                                //     if (access_mem == `ENABLE) begin 
                                //         miss_stall = `ENABLE;  
                                //         // dc_busy   = `ENABLE;
                                //     end else begin 
                                //         // miss_stall  = `DISABLE;
                                //         miss_stall = `ENABLE; 
                                //         // dc_busy   = `DISABLE;
                                //     end
                                // end else begin
                                //     miss_stall   =  `ENABLE;
                                //     // dc_busy   = `ENABLE;
                                // end
                                access_l2_dirty = `ENABLE;
                            end else begin 
                                nextstate   =  `WAIT_L2_BUSY_DIRTY;
                            end
                        end else if(valid == `DISABLE || dirty == `DISABLE) begin
                            if (dc_en == `ENABLE) begin
                                // dc_busy         =  `DISABLE;
                                access_l2_clean = `ENABLE;
                                nextstate  =  `DC_IDLE;
                                // if (dc_rw == `WRITE) begin
                                //     if(access_mem == `ENABLE) begin
                                //         miss_stall = `ENABLE;  
                                //         // dc_busy   = `ENABLE;    
                                //     end else begin
                                //         // miss_stall  = `DISABLE;
                                //         miss_stall  = `ENABLE;
                                //         // dc_busy   = `DISABLE;
                                //     end
                                // end else begin
                                //     miss_stall   =  `ENABLE;
                                //     // dc_busy   = `ENABLE;
                                // end
                            end else begin
                                nextstate =  `WAIT_L2_BUSY_CLEAN;
                            end   
                        end 
                    end else begin
                        dc_busy    = `ENABLE;
                        miss_stall = `DISABLE;
                    end  
                end 
            end
            `WAIT_L2_BUSY_CLEAN:begin // can not go to L2
                // dc_busy   =  `ENABLE;
                access_l2_clean = `DISABLE;
                if(dc_en == `ENABLE) begin
                    // dc_busy    =  `DISABLE;
                    miss_stall = `ENABLE;
                    nextstate  =  `DC_IDLE;
                    // if (dc_rw == `WRITE) begin
                    //     if(access_mem == `ENABLE) begin
                    //         miss_stall = `ENABLE;
                    //     end else begin
                    //         // miss_stall = `DISABLE;
                    //         miss_stall = `ENABLE;
                    //     end
                    // end else begin
                    //     miss_stall  =  `ENABLE;
                    // end
                    access_l2_clean = `ENABLE;
                end else begin
                    nextstate =  `WAIT_L2_BUSY_CLEAN;
                end
            end
            `WAIT_L2_BUSY_DIRTY:begin // can not go to L2
                // dc_busy   =  `ENABLE;
                access_l2_dirty = `DISABLE;
                if(dc_en == `ENABLE) begin
                    nextstate    =  `DC_IDLE;
                    miss_stall = `ENABLE;
                    // if (dc_rw == `WRITE) begin    
                    //     if(access_mem == `ENABLE) begin
                    //         miss_stall = `ENABLE;
                    //     end else begin
                    //         // miss_stall  = `DISABLE;
                    //         miss_stall = `ENABLE;
                    //     end
                    // end else begin
                    //     miss_stall   =  `ENABLE;
                    // end
                    // dc_busy         =  `DISABLE;
                    access_l2_dirty =  `ENABLE;
                end else begin
                    nextstate   =  `WAIT_L2_BUSY_DIRTY;
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