////////////////////////////////////////////////////////////////////
// Engineer:       Kippy Chen - 799182081@qq.com                  //
//                                                                //
// Additional contributions by:                                   //
//                 Beyond Sky - fan-dave@163.com                  //
//                 Junhao Chang                                   //
//                 Leway Colin - colin4124@gmail.com              //
//                                                                //
// Design Name:    icache_ctrl                                    //
// Project Name:   FMRT Mini Core                                 //
// Language:       Verilog                                        //
//                                                                //
// Description:    Control part of I-Cache.                       //
//                                                                //
////////////////////////////////////////////////////////////////////

`timescale 1ns/1ps

/********** General header file **********/
`include "common_defines.v"
`include "base_core_defines.v"
`include "l1_cache.h"
`include "l2_cache.h"

module icache_ctrl(
    /********* Clk & Reset ********/
    input wire                   clk,              // clock
    input wire                   rst,              // reset
    /********** CPU part **********/
    input wire [`WORD_ADDR_BUS]  br_addr_ic,        // Branch target
    input wire                   br_taken,
    input wire [`L2_ADDR_BUS]    ic_addr_mem,
    input wire [`L2_ADDR_BUS]    ic_addr_l2,
    input wire                   memory_en,
    input wire                   l2_en,
    input wire                   if_stall,
    input wire [`WORD_ADDR_BUS]  if_addr,          // address of fetching instruction
    input wire                   rw,               // read / write signal of CPU
    output reg [`WORD_ADDR_BUS]  ic_addr,
    output reg [`WORD_DATA_BUS]  cpu_data,         // read data of CPU
    output reg                   miss_stall,       // the signal of stall caused by cache miss
    output reg                   choose_way,
    output reg                   thread_rdy,
    /****** Thread choose part *****/
    input wire [`THREAD_BUS]     l2_thread,
    input wire [`THREAD_BUS]     mem_thread,
    input wire [`THREAD_BUS]     thread,
    output reg [`THREAD_BUS]     ic_thread,
    output reg                   ic_busy,
    /******** I_Cache part ********/
    input wire                   lru,              // mark of replacing
    input wire [`L1_TAG_BUS]     tag0_rd,          // read data of tag0
    input wire [`L1_TAG_BUS]     tag1_rd,          // read data of tag1
    input wire [`THREAD_BUS]     thread0,          // read data of tag0
    input wire [`THREAD_BUS]     thread1,          // read data of tag1
    input wire [`L1_DATA_BUS]    data0_rd,         // read data of data0
    input wire [`L1_DATA_BUS]    data1_rd,         // read data of data1
    input wire [`L1_DATA_BUS]    data_wd_l2,       // wr_data from L2 
    input wire [`L1_DATA_BUS]    data_wd_l2_mem,   // wr_data from L2 
    // input wire [1:0]   offset,
    output reg                   block0_re,        // read signal of block0
    output reg                   block1_re,        // read signal of block1
    output reg [`L1_INDEX_BUS]   index,            // address of L1_cache
    output reg [`L1_DATA_BUS]    data_wd,          // wr_data from L2 
    output reg [`THREAD_BUS]     ic_thread_wd,
    output reg                   block0_we,
    output reg                   block1_we,
    output reg [`L1_TAG_BUS]     tag_wd,
    /******* Memory part *******/
    input wire [`L1_TAG_BUS]     ic_tag_wd_mem,
    input wire [`L1_INDEX_BUS]   ic_index_mem,
    input wire                   ic_block0_we_mem,
    input wire                   ic_block1_we_mem,
    /******* L2_Cache part *******/
    input wire                   l2_busy,
    input wire [`L1_TAG_BUS]     ic_tag_wd_l2,
    input wire [`L1_INDEX_BUS]   ic_index_l2,
    input wire                   ic_block0_we_l2,
    input wire                   ic_block1_we_l2,
    input wire                   ic_en,            // I_Cache enable signal of accessing L2_cache
    input wire                   l2_rdy,           // ready signal of L2_cache
    input wire                   mem_wr_ic_en,     // enable signal that MEM write I_Cache  
    output reg                   irq,              // I_Cache request
    /****** IF Reg module ********/
    output reg                   data_rdy          // data to CPU ready mark
    );
    reg                          tagcomp_hit;
    reg                          hitway0;          // the mark of choosing path0 
    reg                          hitway1;          // the mark of choosing path1    
    reg       [`L1_STATE_BUS]    nextstate,state;  // state of control
    wire      [`OFFSET_BUS]      offset;
    // wire      [`L1_COMP_TAG_BUS] comp_addr;
    reg                          br_taken_tmp;
    reg                          index_rdy;
    reg       [`L1_INDEX_BUS]    dc_index;
    reg                          is_l2_rdy;

    assign offset    = if_addr[1:0];
    // assign comp_addr = if_addr[29:10];

    always @(*)begin // path choose
        hitway0 = (tag0_rd[19:0] == if_addr[29:10]) & tag0_rd[20];
        hitway1 = (tag1_rd[19:0] == if_addr[29:10]) & tag1_rd[20];
        if(hitway0 == `ENABLE && ic_thread == thread0)begin
            tagcomp_hit = `ENABLE;
        end else if(hitway1 == `ENABLE && ic_thread == thread1)begin
            tagcomp_hit = `ENABLE;
        end else begin
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
                data_rdy    = `DISABLE;
                block0_we   = `DISABLE;
                block1_we   = `DISABLE;
                ic_busy     = `DISABLE;
                ic_addr     = if_addr;
                thread_rdy  = `DISABLE;
                if ((memory_en == `ENABLE && ic_addr_mem == if_addr[29:2])||(l2_en == `ENABLE && ic_addr_l2 == if_addr[29:2]))begin
                    if(l2_rdy == `ENABLE) begin
                        is_l2_rdy  = `ENABLE;
                        // tag_wd        =  ic_tag_wd_l2;
                        // index         =  ic_index_l2;
                        // block0_we     =  ic_block0_we_l2;
                        // block1_we     =  ic_block1_we_l2;
                        // data_wd       =  data_wd_l2;
                        // ic_thread_wd  =  l2_thread;
                        // if (l2_thread == thread) begin
                        //     miss_stall = `DISABLE;
                        //     thread_rdy = `ENABLE;
                        //     data_rdy   = `ENABLE;
                        //     case(offset)
                        //         `WORD0:begin
                        //             cpu_data = data_wd_l2[31:0];
                        //         end
                        //         `WORD1:begin
                        //             cpu_data = data_wd_l2[63:32];
                        //         end
                        //         `WORD2:begin 
                        //             cpu_data = data_wd_l2[95:64];
                        //         end
                        //         `WORD3:begin
                        //             cpu_data = data_wd_l2[127:96];
                        //         end
                        //     endcase // case(offset)  
                        //     dc_index   = index;
                        //     nextstate  = `WRITE_IC; 
                        // end else begin
                        //     nextstate  = `IC_IDLE;
                        // end                        
                        
                    end else if (mem_wr_ic_en == `ENABLE) begin
                        tag_wd        =  ic_tag_wd_mem;
                        index         =  ic_index_mem;
                        block0_we     =  ic_block0_we_mem;
                        block1_we     =  ic_block1_we_mem;
                        data_wd       =  data_wd_l2_mem;
                        ic_thread_wd  =  mem_thread;
                        if (mem_thread == thread) begin
                            nextstate  = `WRITE_IC;
                            /* write cpu part */ 
                            dc_index   = index;
                            miss_stall = `DISABLE;
                            thread_rdy = `ENABLE;
                            data_rdy   = `ENABLE;
                            case(offset)
                                `WORD0:begin
                                    cpu_data = data_wd_l2_mem[31:0];
                                end
                                `WORD1:begin
                                    cpu_data = data_wd_l2_mem[63:32];
                                end
                                `WORD2:begin 
                                    cpu_data = data_wd_l2_mem[95:64];
                                end
                                `WORD3:begin
                                    cpu_data = data_wd_l2_mem[127:96];
                                end
                            endcase // case(offset)   
                        end else begin
                            nextstate  = `IC_IDLE;
                        end  
                    end else begin
                        miss_stall = `ENABLE;
                        ic_busy    = `DISABLE;
                        irq        = `DISABLE; 
                        data_rdy   = `DISABLE;
                        nextstate  = `IC_IDLE;
                    end 
                end else begin
                    block0_re   = `ENABLE;
                    block1_re   = `ENABLE;
                    index       = if_addr[9:2];
                    nextstate   = `IC_ACCESS;
                    ic_thread   = thread;
                end       
            end
            `IC_ACCESS:begin                
                data_rdy    = `DISABLE;
                miss_stall  = `DISABLE;
                block0_re   = `DISABLE;
                block1_re   = `DISABLE;
                irq         = `DISABLE;
                if (tagcomp_hit == `ENABLE) begin // cache hit
                    // read l1_block ,write to cpu
                    ic_busy     = `DISABLE;
                    nextstate   = `IC_ACCESS;
                    ic_thread   = thread;                
                    data_rdy    = `ENABLE;
                    block0_re   = `ENABLE;
                    block1_re   = `ENABLE;
                    if (br_taken == `ENABLE) begin
                        br_taken_tmp = `ENABLE;
                            // if (br_taken == `ENABLE) begin
                            //     index   = br_addr_ic[9:2];
                            //     ic_addr = br_addr_ic;
                            // end else if (if_stall == `DISABLE) begin
                            //     if(offset == 2'b11)begin
                            //         index   = if_addr[9:2] + 8'b1;
                            //         ic_addr = if_addr + 30'b1;
                            //     end
                            // end else begin
                            //     index   = if_addr[9:2];
                            //     ic_addr = if_addr;
                            // end
                            // index   = if_addr[9:2];
                            // ic_addr = if_addr;
                    end else if (if_stall == `DISABLE) begin
                        index_rdy = `ENABLE;
                        // if(offset == 2'b11)begin
                        //     index   = if_addr[9:2] + 8'b1;
                        //     ic_addr = if_addr + 30'b1;
                        // end
                    end else begin
                        index   = if_addr[9:2];
                        ic_addr = if_addr;
                    end
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
                    irq        = `ENABLE; 
                    if (l2_busy == `DISABLE) begin
                        if (ic_en == `ENABLE) begin
                            nextstate  = `IC_IDLE;
                            miss_stall = `ENABLE; 
                            ic_busy    = `DISABLE;
                        end else begin
                            nextstate  = `WAIT_L2_BUSY;
                        end
                    end else begin
                        nextstate  = `WAIT_L2_BUSY;
                        ic_busy    = `ENABLE;
                        miss_stall = `DISABLE; 
                    end       
                end
            end
            `WAIT_L2_BUSY:begin
                if (l2_busy == `DISABLE) begin
                    if(ic_en == `ENABLE) begin
                        nextstate  = `IC_IDLE;
                        miss_stall = `ENABLE; 
                        ic_busy    = `DISABLE;
                    end else begin
                        nextstate   = `WAIT_L2_BUSY;
                        ic_busy     = `ENABLE;
                        miss_stall  = `DISABLE;
                    end
                end     
            end
            `WRITE_IC:begin // read L2,write IC
                miss_stall = `DISABLE;
                // ic_busy    = `ENABLE;
                irq        = `DISABLE;
                nextstate  = `IC_ACCESS;
                ic_addr    = if_addr;
                block0_we  = `DISABLE;
                block1_we  = `DISABLE;
                ic_thread  = thread;
                block0_re  = `ENABLE;
                block1_re  = `ENABLE;
                if (br_taken == `ENABLE) begin       
                    br_taken_tmp = `ENABLE;
                    // index       = br_addr_ic[9:2];  
                    // ic_addr     = br_addr_ic;           
                    // data_rdy    = `DISABLE; 
                end else begin
                    thread_rdy = `ENABLE;
                    if (if_stall == `DISABLE) begin
                        index_rdy = `ENABLE;
                        // if(offset == 2'b11)begin
                        //     index   = if_addr[9:2] + 8'b1;
                        //     ic_addr = if_addr + 30'b1;
                        // end
                    end else begin
                        index   = if_addr[9:2];
                        ic_addr = if_addr;
                    end

                    if (dc_index == if_addr[9:2]) begin
                        ic_busy = `DISABLE;
                        case(offset)
                            `WORD0:begin
                                cpu_data = data_wd[31:0];
                            end
                            `WORD1:begin
                                cpu_data = data_wd[63:32];
                            end
                            `WORD2:begin 
                                cpu_data = data_wd[95:64];
                            end
                            `WORD3:begin
                                cpu_data = data_wd[127:96];
                            end
                        endcase // case(offset) 
                    end else begin
                        ic_busy = `ENABLE;
                    end
                      


                end    
            end
        endcase    
    end
    always @(posedge ~clk) begin
        if (br_taken_tmp == `ENABLE) begin
            if (br_taken == `ENABLE) begin
                index   <= br_addr_ic[9:2];
                ic_addr <= br_addr_ic;
            end else if (if_stall == `DISABLE) begin
                if(offset == 2'b11)begin
                    index   <= if_addr[9:2] + 8'b1;
                    ic_addr <= if_addr + 30'b1;
                end else begin
                    index   <= if_addr[9:2];
                    ic_addr <= if_addr;
                end
            end else begin
                index   <= if_addr[9:2];
                ic_addr <= if_addr;
            end
            br_taken_tmp <= `DISABLE;
        end else if (index_rdy == `ENABLE) begin
            if (br_taken == `ENABLE) begin
                index   <= br_addr_ic[9:2];
                ic_addr <= br_addr_ic;
            end else if (if_stall == `DISABLE) begin
                if(offset == 2'b11)begin
                    index   <= if_addr[9:2] + 8'b1;
                    ic_addr <= if_addr + 30'b1;
                end else begin
                    index   <= if_addr[9:2];
                    ic_addr <= if_addr;
                end
            end else begin
                index   <= if_addr[9:2];
                ic_addr <= if_addr;
            end
            index_rdy <= `DISABLE;
        end 


        if (is_l2_rdy == `ENABLE) begin
            if (l2_rdy == `ENABLE) begin
                tag_wd        <=  ic_tag_wd_l2;
                index         <=  ic_index_l2;
                block0_we     <=  ic_block0_we_l2;
                block1_we     <=  ic_block1_we_l2;
                data_wd       <=  data_wd_l2;
                ic_thread_wd  <=  l2_thread;
                if (l2_thread == thread) begin
                    miss_stall <= `DISABLE;
                    thread_rdy <= `ENABLE;
                    data_rdy   <= `ENABLE;
                    case(offset)
                        `WORD0:begin
                            cpu_data <= data_wd_l2[31:0];
                        end
                        `WORD1:begin
                            cpu_data <= data_wd_l2[63:32];
                        end
                        `WORD2:begin 
                            cpu_data <= data_wd_l2[95:64];
                        end
                        `WORD3:begin
                            cpu_data <= data_wd_l2[127:96];
                        end
                    endcase // case(offset)  
                    dc_index   <= index;
                    nextstate  <= `WRITE_IC; 
                end else begin
                    nextstate  <= `IC_IDLE;
                end    
            end 
            is_l2_rdy <= `DISABLE;
        end
    end
    always @(posedge clk) begin // cache control
        if (rst == `ENABLE) begin // reset
            state    <= `IC_IDLE;
            cpu_data <= `OP_NOP;
        end else begin
            state <= nextstate;
        end
    end
endmodule