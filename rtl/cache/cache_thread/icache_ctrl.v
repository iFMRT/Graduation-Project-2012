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
`include "stddef.h"
`include "icache.h"

module icache_ctrl(
    /********* Clk & Reset ********/
    input              clk,              // clock
    input              rst,              // reset
    /********** CPU part **********/
    input              mem_busy,
    input      [29:0]  if_addr,          // address of fetching instruction
    input              rw,               // read / write signal of CPU
    output reg [31:0]  cpu_data,         // read data of CPU
    output reg         miss_stall,       // the signal of stall caused by cache miss
    output reg         choose_way,
    /****** Thread choose part *****/
    input      [1:0]   l2_thread,
    input      [1:0]   mem_thread,
    input      [1:0]   thread,
    output reg [1:0]   ic_thread,
    output reg         ic_busy,
    /******** I_Cache part ********/
    input              lru,              // mark of replacing
    input      [20:0]  tag0_rd,          // read data of tag0
    input      [20:0]  tag1_rd,          // read data of tag1
    input      [1:0]   thread0,          // read data of tag0
    input      [1:0]   thread1,          // read data of tag1
    input      [127:0] data0_rd,         // read data of data0
    input      [127:0] data1_rd,         // read data of data1
    input      [127:0] data_wd_l2,       // wr_data from L2 
    input      [127:0] data_wd_l2_mem,       // wr_data from L2 
    output reg         block0_re,        // read signal of block0
    output reg         block1_re,        // read signal of block1
    output reg [7:0]   index,            // address of L1_cache
    /******* L2_Cache part *******/
    input              ic_en,            // I_Cache enable signal of accessing L2_cache
    input              l2_rdy,           // ready signal of L2_cache
    input              mem_wr_ic_en,     // enable signal that MEM write I_Cache  
    output reg         irq,              // I_Cache request
    /****** IF Reg module ********/
    output reg         data_rdy          // data to CPU ready mark
    );
    reg                tagcomp_hit;
    reg                hitway0;          // the mark of choosing path0 
    reg                hitway1;          // the mark of choosing path1    
    reg        [2:0]   nextstate,state;  // state of control
    
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
                block0_re   = `ENABLE;
                block1_re   = `ENABLE;
                index       = if_addr[9:2];
                nextstate   = `IC_ACCESS;
                ic_thread   = thread;
            end
            `IC_ACCESS:begin                
                ic_busy     = `ENABLE;
                data_rdy    = `DISABLE;
                miss_stall  =  `ENABLE;
                block0_re   = `DISABLE;
                block1_re   = `DISABLE;
                irq         = `DISABLE;
                if (tagcomp_hit == `ENABLE) begin // cache hit
                    // read l1_block ,write to cpu
                    miss_stall  = `DISABLE;
                    nextstate   = `IC_ACCESS;
                    ic_thread   = thread;
                    index       = if_addr[9:2];                     
                    data_rdy    = `ENABLE;
                    block0_re   = `ENABLE;
                    block1_re   = `ENABLE;
                    if (mem_busy == `DISABLE) begin
                        if(if_addr[1:0] == 2'b11)begin
                            index       = if_addr[9:2] + 8'b1;
                        end
                    end
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
                    if (ic_en == `ENABLE) begin
                        nextstate  = `IC_ACCESS_L2;
                    end else begin
                        nextstate  = `WAIT_L2_BUSY;
                    end
                end
            end
            `IC_ACCESS_L2:begin // access L2, wait L2 reading right 
                // read l2_block ,write to l1 and cpu
                /* write l1 part */
                if(l2_rdy == `ENABLE && (l2_thread == ic_thread) && (l2_thread == thread)) begin
                    miss_stall = `DISABLE;
                    data_rdy   = `ENABLE;
                    ic_busy    = `ENABLE;
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
                    nextstate  = `WRITE_IC;
                end else if (mem_wr_ic_en == `ENABLE && (mem_thread == ic_thread) && (mem_thread == thread)) begin
                    nextstate  = `MEM_WRITE_IC;
                    /* write cpu part */ 
                    miss_stall = `DISABLE;
                    data_rdy   = `ENABLE;
                    ic_busy    = `ENABLE;
                    case(if_addr[1:0])
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
                    endcase // case(if_addr[1:0])   
                end else begin
                    miss_stall = `ENABLE;
                    ic_busy    = `DISABLE;
                    irq        = `DISABLE; 
                    data_rdy   = `DISABLE;
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
            `WRITE_IC:begin // read L2,write IC
                ic_busy    = `ENABLE;
                irq        = `DISABLE;
                nextstate  = `IC_ACCESS;
                ic_thread  = thread;
                block0_re  = `ENABLE;
                block1_re  = `ENABLE;
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
            end
            `MEM_WRITE_IC:begin // read MEM,write IC 
                ic_busy    = `ENABLE;
                irq        = `DISABLE;
                nextstate  = `IC_ACCESS;
                ic_thread  = thread;
                block0_re  = `ENABLE;
                block1_re  = `ENABLE;
                case(if_addr[1:0])
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
                endcase // case(if_addr[1:0])       
            end
        endcase      
    end

    always @(posedge clk) begin // cache control
        if (rst == `ENABLE) begin // reset
            state <= `IC_IDLE;
        end else begin
            state <= nextstate;
        end
    end
endmodule