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
    output reg          memory_en,
    /********* L2_Cache part *********/
    input               l2_busy,
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
    output reg          wd_from_l1_en_mem,     // write data from MEM 
    // l2_thread part
    input       [1:0]   l2_thread,           // read data of thread
    output reg  [1:0]   mem_thread,          // write data of thread
    /************* L1 part ***********/   
    /********* I_Cache part **********/
    output reg          mem_wr_ic_en,       // mem write icache mark
    input               ic_en,              // icache request enable mark
    output reg   [27:0] ic_addr_mem,     
    input        [27:0] ic_addr_l2,
    output reg   [7:0]  ic_index_mem,
    output reg   [20:0] ic_tag_wd_mem,
    output reg          ic_block0_we_mem,
    output reg          ic_block1_we_mem,
    /********* D_Cache part **********/
    input               w_complete,
    output reg          mem_wr_dc_en,       // mem write dcache mark
    input               read_en, 
    input               dc_en,              // dcache request enable mark
    output reg   [7:0]  dc_index_mem,
    output reg   [20:0] dc_tag_wd_mem,
    output reg          dc_block0_we_mem,
    output reg          dc_block1_we_mem,
    output reg  [127:0] data_wd_l2_mem,         // write data to L1 from L2   
    output reg          data_wd_l2_en_mem,      // write data to L1 from L2 enable mark 
    output reg          dc_rw_mem,
    // output reg          data_wd_dc_en, // choose signal of data_wd
    input       [31:0]  dc_wd_l2,
    output reg  [31:0]  dc_wd_mem,
    input       [127:0] rd_to_l2,
    output reg  [127:0] rd_to_l2_mem,
    input       [27:0]  dc_addr_l2,
    output reg  [27:0]  dc_addr_mem,
    output reg          l2_choose_l1_read,
    output reg  [1:0]   mem_thread_read,
    output reg          dc_rw_read,
    output reg  [31:0]  dc_wd_read,
    output reg  [27:0]  dc_addr_read,
    input       [1:0]   dc_offset_l2,
    output reg  [1:0]   dc_offset_mem,
    /********** memory part **********/
    input               dc_rw,
    input               access_mem_clean,
    input               access_mem_dirty,
    output reg          thread_rdy,
    output reg  [1:0]   offset_mem,
    output reg          read_l2_en,
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
                // initial READ_MEM  write L1 enable signals
                mem_wr_ic_en      = `DISABLE; 
                mem_wr_dc_en      = `DISABLE; 
                ic_block0_we_mem  = `DISABLE;
                ic_block1_we_mem  = `DISABLE;
                dc_block0_we_mem  = `DISABLE;
                dc_block1_we_mem  = `DISABLE;
                data_wd_l2_en_mem = `DISABLE;
                // initial READ_MEM write L2 enable signals
                wd_from_mem_en    = `DISABLE;  
                l2_block0_we_mem  = `DISABLE;
                l2_block1_we_mem  = `DISABLE;
                l2_block2_we_mem  = `DISABLE;
                l2_block3_we_mem  = `DISABLE;    
                memory_busy       = `DISABLE;   
                // 
                memory_en        = `DISABLE;
                read_l2_en       = `DISABLE; 
                dc_block0_we_mem = `DISABLE;
                dc_block1_we_mem = `DISABLE;
                thread_rdy       = `DISABLE; 
                mem_wr_ic_en     = `DISABLE; 
                mem_wr_dc_en     = `DISABLE; 
                l2_cache_rw_mem  = l2_cache_rw;
                mem_thread       = l2_thread;
        		memory_busy      = `DISABLE;
                l2_addr_mem      = l2_addr;
                offset_mem       = l2_addr_mem[1:0];
                l2_index_mem     = l2_addr_mem[7:0];
                l2_choose_l1_mem = l2_choose_l1;
                ic_en_mem        = ic_en;
                dc_en_mem        = dc_en | read_en;
                l2_tag_wd_mem    = {1'b1,l2_addr_mem[27:11]};
                choose_way       = l2_choose_way;
                dc_rw_mem        = dc_rw;
                dc_wd_mem        = dc_wd_l2;
                rd_to_l2_mem     = rd_to_l2;
                ic_addr_mem      = ic_addr_l2;
                dc_addr_mem      = dc_addr_l2;
                dc_offset_mem    = dc_offset_l2;
        		if(access_mem_clean == `ENABLE)begin
        			memory_en    = `ENABLE;
                    nextstate    = `READ_MEM;
        			/* Write l2 part */ 
                    mem_re       = `ENABLE;
                    mem_addr     = l2_addr_mem[27:2];
        		end else if(access_mem_dirty == `ENABLE)begin
        			memory_en    = `ENABLE;
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
            `WRITE_MEM:begin // load block of L2 with dirty to mem,then read mem to l2.                 
                thread_rdy       = `DISABLE; 
                dc_block0_we_mem = `DISABLE;
                dc_block1_we_mem = `DISABLE;
                read_l2_en       = `DISABLE;
                memory_busy      = `ENABLE;
                if (mem_complete_w == `ENABLE) begin
                    mem_we    = `DISABLE;
                    /* read mem and write l2 part */ 
                    mem_addr  = l2_addr_mem[27:2];
                    mem_re    = `ENABLE; 
                    nextstate = `READ_MEM;
                end
            end
            `READ_MEM:begin // read mem to l2. 
                thread_rdy         = `DISABLE; 
                dc_block0_we_mem   = `DISABLE;
                dc_block1_we_mem   = `DISABLE;
                read_l2_en         = `DISABLE;
                if (mem_complete_r == `ENABLE) begin
                    mem_re          = `DISABLE;
                    wd_from_mem_en  = `ENABLE;
                    offset_mem      = l2_addr_mem[1:0];
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
                            mem_wr_ic_en     = `ENABLE; 
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
                            nextstate     = `MEM_IDLE;      
                        end
                        if (dc_en_mem == `ENABLE) begin                       
                            dc_tag_wd_mem    = {1'b1,l2_addr_mem[27:8]};
                            dc_index_mem     = l2_addr_mem[7:0];
                            dc_block0_we_mem = `DISABLE;
                            dc_block1_we_mem = `DISABLE;
                            mem_wr_dc_en     = `ENABLE;
                            case(l2_choose_l1_mem)
                                `WAY0:begin
                                    dc_block0_we_mem = `ENABLE;
                                end
                                `WAY1:begin
                                    dc_block1_we_mem = `ENABLE;
                                end
                            endcase 
                            nextstate    = `MEM_IDLE;
                        end
                    end else begin
                        // DC dirty,write L2 miss,L2 dirty,write to MEM,read MEM,write L2,then L1 write L2
                        nextstate         = `READ_NEW_L2;
                        wd_from_l1_en_mem = `ENABLE;
                        dc_wd_read        = dc_wd_mem;
                        l2_choose_l1_read = l2_choose_l1_mem;
                        mem_thread_read   = mem_thread;
                        dc_rw_read        = dc_rw_mem;
                        dc_addr_read      = dc_addr_mem;
                    end
                end 
            end
            `READ_NEW_L2:begin
                wd_from_mem_en     = `DISABLE;
                memory_busy        = `DISABLE;
                wd_from_l1_en_mem  = `DISABLE;
                //Initial signal after using
                l2_block0_we_mem   = `DISABLE;
                l2_block1_we_mem   = `DISABLE;
                l2_block2_we_mem   = `DISABLE;
                l2_block3_we_mem   = `DISABLE;
                read_l2_en         = `ENABLE;
                if (l2_busy == `DISABLE) begin
                    l2_cache_rw_mem  = l2_cache_rw;
                    mem_thread       = l2_thread;
                    l2_addr_mem      = l2_addr;
                    offset_mem       = l2_addr_mem[1:0];
                    l2_index_mem     = l2_addr_mem[7:0];
                    l2_choose_l1_mem = l2_choose_l1;
                    ic_en_mem        = ic_en;
                    dc_en_mem        = dc_en | read_en;
                    l2_tag_wd_mem    = {1'b1,l2_addr_mem[27:11]};
                    choose_way       = l2_choose_way;
                    dc_rw_mem        = dc_rw;
                    dc_wd_mem        = dc_wd_l2;
                    rd_to_l2_mem     = rd_to_l2;
                    dc_addr_mem      = dc_addr_l2;
                    memory_en        = `DISABLE;
                    dc_offset_mem    = dc_offset_l2;
                    ic_addr_mem      = ic_addr_l2;
                    if(access_mem_clean == `ENABLE)begin
                        memory_en        = `ENABLE;
                        nextstate    = `READ_MEM;
                        /* Write l2 part */ 
                        mem_re       = `ENABLE;
                        mem_addr     = l2_addr_mem[27:2];
                    end else if(access_mem_dirty == `ENABLE)begin
                        memory_en        = `ENABLE;
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
                end else begin
                    nextstate  = `READ_NEW_L2;
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