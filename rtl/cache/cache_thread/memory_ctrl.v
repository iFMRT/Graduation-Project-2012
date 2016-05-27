////////////////////////////////////////////////////////////////////
// Engineer:       Kippy Chen - 799182081@qq.com                  //
//                                                                //
// Additional contributions by:                                   //
//                 Beyond Sky - fan-dave@163.com                  //
//                 Junhao Chang                                   //
//                 Leway Colin - colin4124@gmail.com              //
//                                                                //
// Design Name:    memory_ctrl                                    //
// Project Name:   FMRT Mini Core                                 //
// Language:       Verilog                                        //
//                                                                //
// Description:    Control part of I-Cache.                       //
//                                                                //
////////////////////////////////////////////////////////////////////

`timescale 1ns/1ps

/********** General header file **********/
`include "stddef.h"
`include "memory.h"
`include "l2_cache.h"

module memory_ctrl(
    /*********** Clk & Reset *********/
    input               clk,                // clock
    input               rst,                // reset
    /********* L2_Cache part *********/
    input       [27:0]  l2_addr,
    input               l2_choose_l1,
    input       [1:0]   l2_choose_way,
    input               l2_cache_rw,
    output reg          l2_block0_we_mem,       // write signal mark of cache_block0
    output reg          l2_block1_we_mem,       // write signal mark of cache_block1 
    output reg          l2_block2_we_mem,       // write signal mark of cache_block2 
    output reg          l2_block3_we_mem,       // write signal mark of cache_block3
    output reg  [8:0]   l2_index_mem,
    // l2_tag part
    input               l2_complete_w,      // complete mark of writing into l2_cache 
    input       [17:0]  l2_tag0_rd,         // read data of tag0
    input       [17:0]  l2_tag1_rd,         // read data of tag1
    input       [17:0]  l2_tag2_rd,         // read data of tag2
    input       [17:0]  l2_tag3_rd,         // read data of tag3  
    output reg  [17:0]  l2_tag_wd_mem, 
    // l2_data part
    input       [511:0] l2_data0_rd,        // read data of cache_data0
    input       [511:0] l2_data1_rd,        // read data of cache_data1
    input       [511:0] l2_data2_rd,        // read data of cache_data2
    input       [511:0] l2_data3_rd,        // read data of cache_data3
    output reg          wd_from_mem_en,     // write data from MEM enable mark 
    // l2_thread part
    input       [1:0]   l2_thread,           // read data of thread
    output reg  [1:0]   mem_thread,          // write data of thread
    /************* L1 part ***********/   
    /********* I_Cache part **********/
    output reg          mem_wr_ic_en,       // mem write icache mark
    input               ic_en,              // icache request enable mark
    output reg   [7:0]  ic_index_mem,
    output reg   [20:0] ic_tag_wd_mem,
    output reg          ic_block0_we_mem,
    output reg          ic_block1_we_mem,
    /********* D_Cache part **********/
    output reg          mem_wr_dc_en,       // mem write dcache mark
    input               dc_en,              // dcache request enable mark
    // output reg   [1:0]  dc_thread_wd,
    output reg   [7:0]  dc_index_mem,
    output reg   [20:0] dc_tag_wd_mem,
    output reg          dc_block0_we_mem,
    output reg          dc_block1_we_mem,
    output reg  [127:0] data_wd_l2_mem,         // write data to L1 from L2   
    output reg          data_wd_l2_en_mem,      // write data to L1 from L2 enable mark 
    /********** memory part **********/
    input               access_mem_clean,
    input               access_mem_dirty,
    output reg          mem_access_complete,
    output reg          memory_busy,
    output reg          ic_en_mem,
    output reg          dc_en_mem,
    input               mem_complete_w,     // complete mark of writing into MEM
    input               mem_complete_r,     // complete mark of reading from MEM
    input       [511:0] mem_rd,             // read data of MEM
    output reg  [511:0] mem_wd,             // write data of MEM
    output reg  [25:0]  mem_addr,           // address of memory
    output reg          mem_we,             // mark of writing to memory
    output reg          mem_re              // mark of reading from memory
    );
    reg         [2:0]   nextstate,state;    // state of l2_icache
    reg         [27:0]  l2_addr_mem;        // address of accessing L2
    reg                 l2_cache_rw_mem;
    reg                 l2_choose_l1_mem;
    reg                 choose_way;
    always @(*) begin
        /*State Control Part*/
        case(state)
        	`MEM_IDLE:begin
        		mem_access_complete = `DISABLE; 
                l2_cache_rw_mem  = l2_cache_rw;
                mem_thread       = l2_thread;
        		memory_busy      = `DISABLE;
                l2_addr_mem      = l2_addr;
                l2_index_mem     = l2_addr_mem[7:0];
                l2_choose_l1_mem = l2_choose_l1;
                ic_en_mem        = ic_en;
                dc_en_mem        = dc_en;
                l2_tag_wd_mem    = {1'b1,l2_addr_mem[27:11]};
                choose_way       = l2_choose_way;
        		if(access_mem_clean == `ENABLE)begin
        			nextstate    = `WRITE_TO_L2_CLEAN;
        			/* Write l2 part */ 
                    mem_re       = `ENABLE;
                    mem_addr     = l2_addr_mem[27:2];
        		end else if(access_mem_dirty == `ENABLE)begin
        			// memory_busy  = `ENABLE;
        			mem_we       = `ENABLE; 
        			nextstate    = `WRITE_MEM;
                    case(choose_way)
                        `L2_WAY0:begin
                            mem_wd      = l2_data0_rd;
                            mem_addr    = {l2_tag0_rd[16:0],l2_addr_mem[10:2]};  
                        end
                        `L2_WAY1:begin
                            mem_wd      = l2_data1_rd;
                            mem_addr    = {l2_tag1_rd[16:0],l2_addr_mem[10:2]};
                        end
                        `L2_WAY2:begin
                            mem_wd      = l2_data2_rd;
                            mem_addr    = {l2_tag2_rd[16:0],l2_addr_mem[10:2]};
                        end
                        `L2_WAY3:begin
                            mem_wd      = l2_data3_rd;
                            mem_addr    = {l2_tag3_rd[16:0],l2_addr_mem[10:2]};
                        end
                    endcase
        		end else begin
        			nextstate = `MEM_IDLE;
        		end
        	end
            `READ_MEM:begin // read mem to l2. 
                if (mem_complete_r == `ENABLE) begin
                    mem_re          = `DISABLE;
                    // l2_dirty_wd_mem = 1'b0;
                    wd_from_mem_en  = `ENABLE;
                    // Protect write enable correctly.
                    l2_block0_we_mem = `DISABLE;
                    l2_block1_we_mem = `DISABLE; 
                    l2_block2_we_mem = `DISABLE;
                    l2_block3_we_mem = `DISABLE;  
                    case(choose_way)
                        `L2_WAY0:begin
                            l2_block0_we_mem = `ENABLE;
                        end
                        `L2_WAY1:begin
                            l2_block1_we_mem = `ENABLE;
                        end
                        `L2_WAY2:begin
                            l2_block2_we_mem = `ENABLE;
                        end
                        `L2_WAY3:begin
                            l2_block3_we_mem = `ENABLE;
                        end
                    endcase
                    // decide whether write into l1 meanwhile or not.
                    if (l2_cache_rw_mem == `READ) begin
                        /* write l1 part */ 
                        nextstate     = `WRITE_TO_L2_DIRTY_R;
                        data_wd_l2_en_mem = `ENABLE;
                        case(l2_addr_mem[1:0])
                            `WORD0:begin
                                data_wd_l2_mem = mem_rd[127:0];
                            end
                            `WORD1:begin
                                data_wd_l2_mem = mem_rd[255:128];
                            end
                            `WORD2:begin
                                data_wd_l2_mem = mem_rd[383:256];
                            end
                            `WORD3:begin
                                data_wd_l2_mem = mem_rd[511:384];
                            end
                        endcase // case(l2_addr_mem[1:0])
                        if (ic_en_mem == `ENABLE) begin
                            // ic_thread_wd = mem_thread;
                            ic_block0_we_mem = `DISABLE;
                            ic_block1_we_mem = `DISABLE;
                            ic_tag_wd_mem    = {1'b1,l2_addr_mem[27:8]};
                            ic_index_mem     = l2_addr_mem[7:0];
                            case(l2_choose_l1_mem)
                                `WAY0:begin
                                    ic_block0_we_mem = `ENABLE;
                                end
                                `WAY1:begin
                                    ic_block1_we_mem = `ENABLE;
                                end
                            endcase         
                        end
                        if (dc_en_mem == `ENABLE) begin  
                            mem_wr_dc_en     = `ENABLE;                        
                            dc_tag_wd_mem    = {1'b1,l2_addr_mem[27:8]};
                            // dc_thread_wd     = mem_thread;
                            dc_index_mem     = l2_addr_mem[7:0];
                            // dc_dirty_wd  =  1'b0;
                            dc_block0_we_mem = `DISABLE;
                            dc_block1_we_mem = `DISABLE;
                            case(l2_choose_l1_mem)
                                `WAY0:begin
                                    dc_block0_we_mem = `ENABLE;
                                end
                                `WAY1:begin
                                    dc_block1_we_mem = `ENABLE;
                                end
                            endcase 
                        end
                    end else begin
                        nextstate    = `WRITE_TO_L2_DIRTY_W;
                    end
                end 
            end
            `WRITE_MEM:begin // load block of L2 with dirty to mem,then read mem to l2.                 
                memory_busy  = `ENABLE;
                if (mem_complete_w == `ENABLE) begin
                    mem_we    = `DISABLE;
                    /* read mem and write l2 part */ 
                    mem_addr  = l2_addr_mem[27:2];
                    mem_re    = `ENABLE; 
                    nextstate = `READ_MEM;
                end
            end
            `WRITE_TO_L2_CLEAN:begin // write into l2_cache from memory 
                memory_busy  = `ENABLE;
                // Protect write enable correctly.
                l2_block0_we_mem   = `DISABLE;
                l2_block1_we_mem   = `DISABLE; 
                l2_block2_we_mem   = `DISABLE;
                l2_block3_we_mem   = `DISABLE;
                ic_block0_we_mem   = `DISABLE;
                ic_block1_we_mem   = `DISABLE;
                dc_block0_we_mem   = `DISABLE;
                dc_block1_we_mem   = `DISABLE;
                if (mem_complete_r == `ENABLE) begin
                    nextstate          = `COMPLETE_WRITE_CLEAN;
                    mem_re             = `DISABLE;
                    // l2_dirty_wd_mem    = 1'b0;
                    wd_from_mem_en     = `ENABLE;
                    case(choose_way)
                        `L2_WAY0:begin
                            l2_block0_we_mem = `ENABLE;
                        end
                        `L2_WAY1:begin
                            l2_block1_we_mem = `ENABLE;
                        end
                        `L2_WAY2:begin
                            l2_block2_we_mem = `ENABLE;
                        end
                        `L2_WAY3:begin
                            l2_block3_we_mem = `ENABLE;
                        end
                    endcase
                    /* Write l1 part */ 
                    if (ic_en_mem == `ENABLE) begin
                        // ic_thread_wd = mem_thread;
                        mem_wr_ic_en = `ENABLE;
                        ic_tag_wd_mem    = {1'b1,l2_addr_mem[27:8]};
                        ic_index_mem     = l2_addr_mem[7:0];
                        case(l2_choose_l1_mem)
                            `WAY0:begin
                                ic_block0_we_mem = `ENABLE;
                            end
                            `WAY1:begin
                                ic_block1_we_mem = `ENABLE;
                            end
                        endcase         
                    end
                    if (dc_en_mem == `ENABLE) begin                           
                        // dc_thread_wd = mem_thread;
                        mem_wr_dc_en = `ENABLE;
                        dc_tag_wd_mem    = {1'b1,l2_addr_mem[27:8]};
                        dc_index_mem     = l2_addr_mem[7:0];
                        // dc_dirty_wd  =  1'b0;
                        case(l2_choose_l1_mem)
                            `WAY0:begin
                                dc_block0_we_mem = `ENABLE;
                            end
                            `WAY1:begin
                                dc_block1_we_mem = `ENABLE;
                            end
                        endcase 
                    end
                    data_wd_l2_en_mem = `ENABLE;
                    case(l2_addr_mem[1:0])
                        `WORD0:begin
                            data_wd_l2_mem = mem_rd[127:0];
                        end
                        `WORD1:begin
                            data_wd_l2_mem = mem_rd[255:128];
                        end
                        `WORD2:begin
                            data_wd_l2_mem = mem_rd[383:256];
                        end
                        `WORD3:begin
                            data_wd_l2_mem = mem_rd[511:384];
                        end
                    endcase // case(l2_addr_mem[1:0])
                end
            end
            `COMPLETE_WRITE_CLEAN:begin
                //  disable write signal correctly.
                ic_block0_we_mem   = `DISABLE;
                ic_block1_we_mem   = `DISABLE;
                dc_block0_we_mem   = `DISABLE;
                dc_block1_we_mem   = `DISABLE;
                data_wd_l2_en_mem  = `DISABLE;
                if(l2_complete_w == `ENABLE)begin
                    //Initial signal after using
                    l2_block0_we_mem   = `DISABLE;
                    l2_block1_we_mem   = `DISABLE; 
                    l2_block2_we_mem   = `DISABLE;
                    l2_block3_we_mem   = `DISABLE; 
                    wd_from_mem_en = `DISABLE;
                    mem_wr_dc_en   = `DISABLE;
                    mem_wr_ic_en   = `DISABLE;  
                    data_wd_l2_en_mem  = `DISABLE;
                    // nextstate      = `MEM_IDLE;
                    mem_access_complete = `ENABLE;   
                    memory_busy     = `DISABLE;   
                    mem_thread   = l2_thread;
                    l2_addr_mem  = l2_addr;
                    l2_index_mem = l2_addr_mem[7:0];
                    l2_choose_l1_mem = l2_choose_l1;
                    ic_en_mem    = ic_en;
                    dc_en_mem    = dc_en;    
                    l2_tag_wd_mem     = {1'b1,l2_addr_mem[27:11]}; 
                    l2_cache_rw_mem = l2_cache_rw;
                    choose_way       = l2_choose_way;
                    // l2_thread_wd_mem = mem_thread;     
                    if(access_mem_clean == `ENABLE)begin
                        // memory_busy  = `ENABLE;
                        nextstate = `WRITE_TO_L2_CLEAN;
                        /* Write l2 part */ 
                        mem_re    = `ENABLE;
                        mem_addr  = l2_addr_mem[27:2];
                        mem_access_complete = `DISABLE; 
                    end else if(access_mem_dirty == `ENABLE)begin
                        // memory_busy  = `ENABLE;
                        mem_we    = `ENABLE; 
                        nextstate = `WRITE_MEM;
                        mem_access_complete = `DISABLE; 
                        case(choose_way)
                            `L2_WAY0:begin
                                mem_wd      = l2_data0_rd;
                                mem_addr    = {l2_tag0_rd[16:0],l2_addr_mem[10:2]};  
                            end
                            `L2_WAY1:begin
                                mem_wd      = l2_data1_rd;
                                mem_addr    = {l2_tag1_rd[16:0],l2_addr_mem[10:2]};
                            end
                            `L2_WAY2:begin
                                mem_wd      = l2_data2_rd;
                                mem_addr    = {l2_tag2_rd[16:0],l2_addr_mem[10:2]};
                            end
                            `L2_WAY3:begin
                                mem_wd      = l2_data3_rd;
                                mem_addr    = {l2_tag3_rd[16:0],l2_addr_mem[10:2]};
                            end
                        endcase
                    end else begin
                        nextstate = `MEM_IDLE;
                    end                      
                end
            end
            `WRITE_TO_L2_DIRTY_R:begin // write into l2_cache from memory 
                ic_block0_we_mem = `DISABLE;
                ic_block1_we_mem = `DISABLE;
                dc_block0_we_mem = `DISABLE;
                dc_block1_we_mem = `DISABLE;
                data_wd_l2_en_mem  = `DISABLE;
                if(l2_complete_w == `ENABLE)begin
                    //Initial signal after using
                    wd_from_mem_en = `DISABLE;  
                    l2_block0_we_mem   = `DISABLE;
                    l2_block1_we_mem   = `DISABLE;
                    l2_block2_we_mem   = `DISABLE;
                    l2_block3_we_mem   = `DISABLE;
                    // nextstate      = `MEM_IDLE;
                    mem_access_complete = `ENABLE;     
                    memory_busy     = `DISABLE;   
                    mem_thread   = l2_thread;
                    l2_addr_mem  = l2_addr;
                    l2_index_mem = l2_addr_mem[7:0];
                    l2_choose_l1_mem = l2_choose_l1;
                    ic_en_mem    = ic_en;
                    dc_en_mem    = dc_en;    
                    l2_tag_wd_mem     = {1'b1,l2_addr_mem[27:11]};
                    l2_cache_rw_mem = l2_cache_rw;
                    choose_way       = l2_choose_way;
                    // l2_thread_wd_mem = mem_thread;      
                    if(access_mem_clean == `ENABLE)begin
                        // memory_busy  = `ENABLE;
                        nextstate = `WRITE_TO_L2_CLEAN;
                        /* Write l2 part */ 
                        mem_re    = `ENABLE;
                        mem_addr  = l2_addr_mem[27:2];
                        mem_access_complete = `DISABLE; 
                    end else if(access_mem_dirty == `ENABLE)begin
                        // memory_busy  = `ENABLE;
                        mem_we    = `ENABLE; 
                        nextstate = `WRITE_MEM;
                        mem_access_complete = `DISABLE; 
                        case(choose_way)
                            `L2_WAY0:begin
                                mem_wd      = l2_data0_rd;
                                mem_addr    = {l2_tag0_rd[16:0],l2_addr_mem[10:2]};  
                            end
                            `L2_WAY1:begin
                                mem_wd      = l2_data1_rd;
                                mem_addr    = {l2_tag1_rd[16:0],l2_addr_mem[10:2]};
                            end
                            `L2_WAY2:begin
                                mem_wd      = l2_data2_rd;
                                mem_addr    = {l2_tag2_rd[16:0],l2_addr_mem[10:2]};
                            end
                            `L2_WAY3:begin
                                mem_wd      = l2_data3_rd;
                                mem_addr    = {l2_tag3_rd[16:0],l2_addr_mem[10:2]};
                            end
                        endcase
                    end else begin
                        nextstate = `MEM_IDLE;
                    end                               
                end
            end
            `WRITE_TO_L2_DIRTY_W:begin // write into l2_cache from memory 
                if(l2_complete_w == `ENABLE)begin
                    // write dirty block of l1 into l2_cache 
                    mem_access_complete = `ENABLE;   
                    wd_from_mem_en = `DISABLE; 
                    // nextstate      = `MEM_IDLE;
                    // Protect write enable correctly.
                    l2_block0_we_mem   = `DISABLE;
                    l2_block1_we_mem   = `DISABLE;
                    l2_block2_we_mem   = `DISABLE;
                    l2_block3_we_mem   = `DISABLE;   
                    memory_busy     = `DISABLE;   
                    mem_thread   = l2_thread;
                    l2_addr_mem  = l2_addr;
                    l2_index_mem = l2_addr_mem[7:0];
                    l2_choose_l1_mem = l2_choose_l1;
                    ic_en_mem    = ic_en;
                    dc_en_mem    = dc_en;   
                    // l2_thread_wd_mem = mem_thread;  
                    l2_tag_wd_mem     = {1'b1,l2_addr_mem[27:11]};     
                    l2_cache_rw_mem = l2_cache_rw;
                    choose_way       = l2_choose_way;
                    if(access_mem_clean == `ENABLE)begin
                        // memory_busy  = `ENABLE;
                        nextstate = `WRITE_TO_L2_CLEAN;
                        /* Write l2 part */ 
                        mem_re    = `ENABLE;
                        mem_addr  = l2_addr_mem[27:2];
                        mem_access_complete = `DISABLE; 
                    end else if(access_mem_dirty == `ENABLE)begin
                        // memory_busy  = `ENABLE;
                        mem_we    = `ENABLE; 
                        nextstate = `WRITE_MEM;
                        mem_access_complete = `DISABLE; 
                        case(choose_way)
                            `L2_WAY0:begin
                                mem_wd      = l2_data0_rd;
                                mem_addr    = {l2_tag0_rd[16:0],l2_addr_mem[10:2]};  
                            end
                            `L2_WAY1:begin
                                mem_wd      = l2_data1_rd;
                                mem_addr    = {l2_tag1_rd[16:0],l2_addr_mem[10:2]};
                            end
                            `L2_WAY2:begin
                                mem_wd      = l2_data2_rd;
                                mem_addr    = {l2_tag2_rd[16:0],l2_addr_mem[10:2]};
                            end
                            `L2_WAY3:begin
                                mem_wd      = l2_data3_rd;
                                mem_addr    = {l2_tag3_rd[16:0],l2_addr_mem[10:2]};
                            end
                        endcase
                    end else begin
                        nextstate = `MEM_IDLE;
                    end                        
                end
            end
            default:nextstate = `MEM_IDLE;
        endcase        
    end
    always @(posedge clk) begin // cache control
        if (rst == `ENABLE) begin
            state <= `MEM_IDLE;
        end else begin   
            state <= nextstate;
        end
    end
endmodule