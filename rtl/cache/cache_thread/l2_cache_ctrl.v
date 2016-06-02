////////////////////////////////////////////////////////////////////
// Engineer:       Kippy Chen - 799182081@qq.com                  //
//                                                                //
// Additional contributions by:                                   //
//                 Beyond Sky - fan-dave@163.com                  //
//                 Junhao Chang                                   //
//                 Leway Colin - colin4124@gmail.com              //
//                                                                //
// Design Name:    l2_cache_ctrl                                  //
// Project Name:   FMRT Mini Core                                 //
// Language:       Verilog                                        //
//                                                                //
// Description:    Control part of I-Cache.                       //
//                                                                //
////////////////////////////////////////////////////////////////////
`timescale 1ns/1ps

/********** General header file **********/
`include "stddef.h"
`include "l2_cache.h"

module l2_cache_ctrl(
    /*********** Clk & Reset *********/
    input               clk,                // clock
    input               rst,                // reset
    input               mem_busy,
    input               dc_rw,             // read / write signal of CPU
    output reg          thread_rdy,
    output reg          l2_en,
    /********* L2_Cache part *********/
    output reg  [27:0]  l2_addr,
    output reg          l2_cache_rw,
    input               access_l2_clean,
    input               access_l2_dirty,
    output reg          access_mem_clean,
    output reg          access_mem_dirty,
    output reg  [127:0] rd_to_l2,
    output reg  [8:0]   l2_index,           // l2_index of l2_cache
    output reg  [1:0]   offset,             // l2_offset of block
    output reg          l2_choose_l1,
    output reg  [1:0]   choose_way,          
    output reg          l2_rdy,             // ready mark
    output reg          l2_busy,            // busy mark
    output reg          l2_block0_we,       // write signal mark of cache_block0
    output reg          l2_block1_we,       // write signal mark of cache_block1 
    output reg          l2_block2_we,       // write signal mark of cache_block2 
    output reg          l2_block3_we,       // write signal mark of cache_block3
    output reg          l2_block0_re,       // read signal mark of cache_block0 
    output reg          l2_block1_re,       // read signal mark of cache_block1 
    output reg          l2_block2_re,       // read signal mark of cache_block2 
    output reg          l2_block3_re,       // read signal mark of cache_block3 
    // l2_tag part
    input               l2_complete_w,      // complete mark of writing into l2_cache 
    input               l2_complete_r,      // complete mark of reading from l2_cache 
    input       [2:0]   plru,               // the number of replacing mark
    input       [17:0]  l2_tag0_rd,         // read data of tag0
    input       [17:0]  l2_tag1_rd,         // read data of tag1
    input       [17:0]  l2_tag2_rd,         // read data of tag2
    input       [17:0]  l2_tag3_rd,         // read data of tag3   
    output reg  [17:0]  l2_tag_wd,          // write data of tag    
    // l2_dirty part
    input               l2_dirty0,          // read data of dirty0
    input               l2_dirty1,          // read data of dirty1
    input               l2_dirty2,          // read data of dirty2
    input               l2_dirty3,          // read data of dirty3
    // l2_data part
    input       [511:0] l2_data0_rd,        // read data of cache_data0
    input       [511:0] l2_data1_rd,        // read data of cache_data1
    input       [511:0] l2_data2_rd,        // read data of cache_data2
    input       [511:0] l2_data3_rd,        // read data of cache_data3
    output reg          wd_from_l1_en,      // write data from L1 enable mark 
    // thread part
    input       [1:0]   ic_thread,
    input       [1:0]   dc_thread,
    input       [1:0]   mem_thread,
    output reg  [1:0]   l2_thread,           // read data of thread
    input       [1:0]   l2_thread0,          // read data of thread0
    input       [1:0]   l2_thread1,          // read data of thread1
    input       [1:0]   l2_thread2,          // read data of thread2
    input       [1:0]   l2_thread3,          // read data of thread3
    output reg  [1:0]   l2_thread_wd,  
    /********* I_Cache part **********/
    input               irq,                // icache request
    input               ic_choose_way,
    input       [29:0]  ic_addr,            // address of fetching instruction
    output reg  [27:0]  ic_addr_l2,         // address of fetching instruction
    output reg          ic_en,              // icache request enable mark
    output reg   [7:0]  ic_index,
    output reg   [20:0] ic_tag_wd,
    output reg          ic_block0_we,
    output reg          ic_block1_we,
    output reg          data_wd_l2_en_dc,
    /********* D_Cache part **********/
    input               drq,                // dcache request
    input               dc_choose_way,
    input       [27:0]  dc_addr,         // address of fetching instruction
    output reg          dc_en,              // dcache request enable mark 
    output reg          read_en,
    output reg  [7:0]   dc_index,
    output reg  [20:0]  dc_tag_wd,
    output reg          dc_block0_we,
    output reg          dc_block1_we,
    input       [127:0] data0_rd,
    input       [127:0] data1_rd,
    input       [20:0]  tag0_rd,
    input       [20:0]  tag1_rd,
    output reg          data_wd_dc_en_l2, // choose signal of data_wd
    input       [31:0]  dc_wd,
    output reg  [31:0]  dc_wd_l2, 
    output reg  [27:0]  dc_addr_l2,
    input       [1:0]   dc_offset,
    output reg  [1:0]   dc_offset_l2,
    /************* L1 part ***********/
    output reg  [127:0] data_wd_l2,         // write data to L1 from L2   
    output reg          data_wd_l2_en,      // write data to L1 from L2 enable mark 
    /********** memory part **********/
    input               l2_block0_we_mem,
    input               l2_block1_we_mem,
    input               l2_block2_we_mem,
    input               l2_block3_we_mem,
    input               wd_from_mem_en,wd_from_l1_en_mem,
    input       [1:0]   offset_mem,
    input       [127:0] rd_to_l2_mem,
    input       [511:0] mem_rd,
    input       [8:0]   l2_index_mem,
    input       [17:0]  l2_tag_wd_mem,
    input               l2_choose_l1_read,
    input       [1:0]   mem_thread_read,
    input               dc_rw_read,
    input       [31:0]  dc_wd_read,
    input       [27:0]  dc_addr_read,
    input               read_l2_en,
    output reg  [511:0] l2_data_wd_mem,
    output reg          mem_wr_l2_en,
    output reg          dc_rw_l2,
    input               memory_busy
    );
    reg                 tagcomp_hit;
    reg         [1:0]   hitway;             // hit mark
    reg                 hitway0;            // the mark of choosing path0 
    reg                 hitway1;            // the mark of choosing path1
    reg                 hitway2;            // the mark of choosing path0 
    reg                 hitway3;            // the mark of choosing path1
    reg         [2:0]   nextstate;
    reg         [2:0]   state;              // state of l2_icache
    reg                 valid;              // valid mark
    reg                 dirty;              // dirty mark
    reg                 l2_block0_we_mem_l2;
    reg                 l2_block1_we_mem_l2;
    reg                 l2_block2_we_mem_l2;
    reg                 l2_block3_we_mem_l2;
    reg         [511:0] l2_data_wd_mem_l2;
    reg         [127:0] rd_to_l2_mem_l2;
    reg         [8:0]   l2_index_mem_l2;
    reg         [1:0]   l2_thread_wd_mem;
    reg         [17:0]  l2_tag_wd_mem_l2;
    reg         [1:0]   offset_mem_l2;
    reg                 r_m_w_l2_en,wd_fr_l1_en_mem_l2;
    always @(*) begin // path choose
        hitway0 = (l2_tag0_rd[16:0] == l2_addr[27:11]) & l2_tag0_rd[17];
        hitway1 = (l2_tag1_rd[16:0] == l2_addr[27:11]) & l2_tag1_rd[17];
        hitway2 = (l2_tag2_rd[16:0] == l2_addr[27:11]) & l2_tag2_rd[17];
        hitway3 = (l2_tag3_rd[16:0] == l2_addr[27:11]) & l2_tag3_rd[17];
        
        if(hitway0 == `ENABLE && l2_thread == l2_thread0)begin
            tagcomp_hit  = `ENABLE;
            hitway       = `L2_WAY0;
        end else if(hitway1 == `ENABLE && l2_thread == l2_thread1) begin
            tagcomp_hit  = `ENABLE;
            hitway       = `L2_WAY1;
        end else if(hitway2 == `ENABLE && l2_thread == l2_thread2) begin
            tagcomp_hit  = `ENABLE;
            hitway       = `L2_WAY2;
        end else if(hitway3 == `ENABLE && l2_thread == l2_thread3) begin
            tagcomp_hit  = `ENABLE;
            hitway       = `L2_WAY3;
        end else begin
            tagcomp_hit  = `DISABLE;
        end

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
        // change 
        if (wd_from_mem_en == `ENABLE) begin
            l2_block0_we_mem_l2 = l2_block0_we_mem;
            l2_block1_we_mem_l2 = l2_block1_we_mem;
            l2_block2_we_mem_l2 = l2_block2_we_mem;
            l2_block3_we_mem_l2 = l2_block3_we_mem;
            l2_data_wd_mem_l2   = mem_rd;
            l2_index_mem_l2     = l2_index_mem;
            l2_tag_wd_mem_l2    = l2_tag_wd_mem;
            r_m_w_l2_en         = `ENABLE;
            l2_thread_wd_mem    = mem_thread;
            wd_fr_l1_en_mem_l2  = wd_from_l1_en_mem;
            rd_to_l2_mem_l2     = rd_to_l2_mem;
            offset_mem_l2       = offset_mem;
        end
        
        /*State Control Part*/
        case(state)
            `L2_IDLE:begin
                data_wd_l2_en = `DISABLE;
                ic_block0_we  = `DISABLE;
                ic_block1_we  = `DISABLE;
                // reset signals
                mem_wr_l2_en     = `DISABLE; 
                l2_en            = `DISABLE;
                thread_rdy       = `DISABLE;
                l2_rdy           = `DISABLE;
                data_wd_dc_en_l2 = `DISABLE;                
                dc_block0_we     = `DISABLE;
                dc_block1_we     = `DISABLE;
                l2_busy          = `DISABLE;                
                access_mem_clean = `DISABLE;
                access_mem_dirty = `DISABLE;
                // initial enable signal
                ic_en            = `DISABLE;
                dc_en            = `DISABLE;
                read_en          = `DISABLE;
                l2_block0_re     = `DISABLE;
                l2_block1_re     = `DISABLE; 
                l2_block2_re     = `DISABLE;
                l2_block3_re     = `DISABLE;
                if (read_l2_en == `ENABLE) begin
                    l2_en         = `ENABLE;
                    nextstate     = `ACCESS_L2;
                    l2_block0_re  = `ENABLE;
                    l2_block1_re  = `ENABLE; 
                    l2_block2_re  = `ENABLE;
                    l2_block3_re  = `ENABLE;
                    read_en       = `ENABLE;
                    l2_addr       = dc_addr_read;
                    offset        = l2_addr[1:0]; 
                    l2_cache_rw   = `READ;
                    l2_choose_l1  = l2_choose_l1_read;
                    l2_thread     = mem_thread_read;
                    dc_rw_l2      = dc_rw_read;
                    dc_wd_l2      = dc_wd_read;
                    dc_index      = l2_addr[7:0];
                    l2_index      = l2_addr[10:2];
                    l2_tag_wd     = {1'b1,l2_addr[27:11]};  
                end else if(r_m_w_l2_en == `ENABLE)begin
                    r_m_w_l2_en    = `DISABLE;
                    l2_block0_we   = l2_block0_we_mem_l2;
                    l2_block1_we   = l2_block1_we_mem_l2;
                    l2_block2_we   = l2_block2_we_mem_l2;
                    l2_block3_we   = l2_block3_we_mem_l2;
                    l2_data_wd_mem = l2_data_wd_mem_l2;
                    l2_index       = l2_index_mem_l2;
                    l2_thread_wd   = l2_thread_wd_mem;
                    l2_tag_wd      = l2_tag_wd_mem_l2;
                    mem_wr_l2_en   = `ENABLE; 
                    nextstate      = `MEM_WRITE_L2;
                    offset         = offset_mem_l2; 
                end else if (irq == `ENABLE) begin  
                    l2_en         = `ENABLE;
                    nextstate     = `ACCESS_L2;
                    ic_en         = `ENABLE;
                    l2_block0_re  = `ENABLE;
                    l2_block1_re  = `ENABLE; 
                    l2_block2_re  = `ENABLE;
                    l2_block3_re  = `ENABLE;
                    ic_addr_l2    = ic_addr[29:2];
                    l2_choose_l1  = ic_choose_way;
                    l2_thread     = ic_thread;
                    l2_cache_rw   =  `READ;                   
                    if (mem_busy == `DISABLE && ic_addr[1:0] == 2'b11) begin
                        l2_addr   =  ic_addr[29:2] + 2'b1;
                    end else begin
                        l2_addr   =  ic_addr[29:2];
                    end    
                    l2_index      = l2_addr[10:2];
                    offset        = l2_addr[1:0];
                    l2_tag_wd     = {1'b1,l2_addr[27:11]};    
                end else if (drq == `ENABLE) begin  
                    l2_en         = `ENABLE;
                    nextstate     = `ACCESS_L2;
                    dc_en         = `ENABLE;
                    l2_block0_re  = `ENABLE;
                    l2_block1_re  = `ENABLE; 
                    l2_block2_re  = `ENABLE;
                    l2_block3_re  = `ENABLE;
                    dc_addr_l2    = dc_addr;
                    l2_choose_l1  = dc_choose_way;
                    l2_thread     = dc_thread;
                    dc_rw_l2      = dc_rw;
                    dc_wd_l2      = dc_wd;
                    dc_index      = l2_addr[7:0];
                    dc_offset_l2  = dc_offset;
                    if (access_l2_clean == `ENABLE) begin
                        l2_cache_rw =  `READ;
                        l2_addr     =  dc_addr;
                    end else if (access_l2_dirty == `ENABLE) begin
                        l2_cache_rw = `WRITE; 
                        case(choose_way)
                            `WAY0:begin
                                rd_to_l2   =  data0_rd;
                                l2_addr    =  {tag0_rd[19:0],dc_addr[7:0]};
                            end
                            `WAY1:begin
                                rd_to_l2   =  data1_rd;
                                l2_addr    =  {tag1_rd[19:0],dc_addr[7:0]};
                            end
                        endcase
                    end
                    l2_index         = l2_addr[10:2];
                    offset           = l2_addr[1:0];
                    l2_tag_wd        = {1'b1,l2_addr[27:11]}; 
                end else begin
                    nextstate    = `L2_IDLE;
                end  
            end
            `MEM_WRITE_L2:begin
                thread_rdy    = `ENABLE;
                l2_rdy        = `DISABLE;
                data_wd_l2_en = `DISABLE;
                ic_block0_we  = `DISABLE;
                ic_block1_we  = `DISABLE;
                dc_block0_we  = `DISABLE;
                dc_block1_we  = `DISABLE;
                l2_busy       = `ENABLE;
                if(l2_complete_w == `ENABLE)begin
                    mem_wr_l2_en  = `DISABLE; 
                    if (wd_fr_l1_en_mem_l2 == `ENABLE) begin
                        rd_to_l2      = rd_to_l2_mem_l2;
                        wd_from_l1_en = `ENABLE;
                        nextstate     = `L1_WRITE_L2;
                        l2_busy       = `ENABLE;
                    end else begin
                        wd_from_l1_en = `DISABLE;
                        l2_block0_we  = `READ;
                        l2_block1_we  = `READ;
                        l2_block2_we  = `READ;
                        l2_block3_we  = `READ;
                        // initial signals
                        l2_en         = `DISABLE;
                        l2_busy       = `DISABLE;
                        ic_en         = `DISABLE;
                        dc_en         = `DISABLE;
                        read_en       = `DISABLE;
                        l2_block0_re  = `DISABLE;
                        l2_block1_re  = `DISABLE; 
                        l2_block2_re  = `DISABLE;
                        l2_block3_re  = `DISABLE;
                        if (read_l2_en == `ENABLE) begin
                            l2_en         = `ENABLE;
                            nextstate     = `ACCESS_L2;
                            l2_block0_re  = `ENABLE;
                            l2_block1_re  = `ENABLE; 
                            l2_block2_re  = `ENABLE;
                            l2_block3_re  = `ENABLE;
                            read_en       = `ENABLE;
                            l2_addr       = dc_addr_read;
                            l2_cache_rw   = `READ;
                            l2_choose_l1  = l2_choose_l1_read;
                            l2_thread     = mem_thread_read;
                            dc_rw_l2      = dc_rw_read;
                            dc_wd_l2      = dc_wd_read;
                            dc_index      = l2_addr[7:0];
                            l2_index      = l2_addr[10:2];
                            offset        = l2_addr[1:0];
                            l2_tag_wd     = {1'b1,l2_addr[27:11]}; 
                        end else if(r_m_w_l2_en == `ENABLE)begin
                            r_m_w_l2_en    = `DISABLE;
                            l2_block0_we   = l2_block0_we_mem_l2;
                            l2_block1_we   = l2_block1_we_mem_l2;
                            l2_block2_we   = l2_block2_we_mem_l2;
                            l2_block3_we   = l2_block3_we_mem_l2;
                            l2_data_wd_mem = l2_data_wd_mem_l2;
                            l2_index       = l2_index_mem_l2;
                            l2_thread_wd   = l2_thread_wd_mem;
                            l2_tag_wd      = l2_tag_wd_mem_l2;
                            mem_wr_l2_en   = `ENABLE; 
                            nextstate      = `MEM_WRITE_L2;
                            offset         = offset_mem_l2;
                        end else if (irq == `ENABLE) begin  
                            l2_en         = `ENABLE;
                            nextstate     = `ACCESS_L2;
                            ic_en         = `ENABLE;
                            l2_block0_re  = `ENABLE;
                            l2_block1_re  = `ENABLE; 
                            l2_block2_re  = `ENABLE;
                            l2_block3_re  = `ENABLE;
                            ic_addr_l2    = ic_addr[29:2];
                            l2_choose_l1  = ic_choose_way;
                            l2_thread     = ic_thread;
                            l2_cache_rw   =  `READ;                   
                            if (mem_busy == `DISABLE && ic_addr[1:0] == 2'b11) begin
                                l2_addr   =  ic_addr[29:2] + 2'b1;
                            end else begin
                                l2_addr   =  ic_addr[29:2];
                            end    
                            l2_index      = l2_addr[10:2];
                            offset        = l2_addr[1:0];
                            l2_tag_wd     = {1'b1,l2_addr[27:11]};    
                        end else if (drq == `ENABLE) begin  
                            l2_en         = `ENABLE;
                            nextstate     = `ACCESS_L2;
                            dc_en         = `ENABLE;
                            l2_block0_re  = `ENABLE;
                            l2_block1_re  = `ENABLE; 
                            l2_block2_re  = `ENABLE;
                            l2_block3_re  = `ENABLE;
                            dc_addr_l2    = dc_addr;
                            l2_choose_l1  = dc_choose_way;
                            l2_thread     = dc_thread;
                            dc_rw_l2      = dc_rw;
                            dc_wd_l2      = dc_wd;
                            dc_index      = l2_addr[7:0];
                            dc_offset_l2  = dc_offset;
                            if (access_l2_clean == `ENABLE) begin
                                l2_cache_rw =  `READ;
                                l2_addr     =  dc_addr;
                            end else if (access_l2_dirty == `ENABLE) begin
                                l2_cache_rw = `WRITE; 
                                case(choose_way)
                                    `WAY0:begin
                                        rd_to_l2   =  data0_rd;
                                        l2_addr    =  {tag0_rd[19:0],dc_addr[7:0]};
                                    end
                                    `WAY1:begin
                                        rd_to_l2   =  data1_rd;
                                        l2_addr    =  {tag1_rd[19:0],dc_addr[7:0]};
                                    end
                                endcase
                            end
                            l2_index     = l2_addr[10:2];
                            offset       = l2_addr[1:0];
                            l2_tag_wd    = {1'b1,l2_addr[27:11]}; 
                        end else begin
                            nextstate    = `L2_IDLE;
                        end
                    end
                end
            end
            `L1_WRITE_L2:begin
                l2_busy  = `ENABLE;
                if (l2_complete_w == `ENABLE) begin
                    wd_from_l1_en = `DISABLE;
                    l2_block0_we  = `READ;
                    l2_block1_we  = `READ;
                    l2_block2_we  = `READ;
                    l2_block3_we  = `READ;
                    // initial signals
                    l2_en         = `DISABLE;
                    l2_busy       = `DISABLE;
                    ic_en         = `DISABLE;
                    dc_en         = `DISABLE;
                    read_en       = `DISABLE;
                    l2_block0_re  = `DISABLE;
                    l2_block1_re  = `DISABLE; 
                    l2_block2_re  = `DISABLE;
                    l2_block3_re  = `DISABLE;
                    if (read_l2_en == `ENABLE) begin
                        l2_en         = `ENABLE;
                        nextstate     = `ACCESS_L2;
                        l2_block0_re  = `ENABLE;
                        l2_block1_re  = `ENABLE; 
                        l2_block2_re  = `ENABLE;
                        l2_block3_re  = `ENABLE;
                        read_en       = `ENABLE;
                        l2_addr       = dc_addr_read;
                        l2_cache_rw   = `READ;
                        l2_choose_l1  = l2_choose_l1_read;
                        l2_thread     = mem_thread_read;
                        dc_rw_l2      = dc_rw_read;
                        dc_wd_l2      = dc_wd_read;
                        dc_index      = l2_addr[7:0];
                        l2_index      = l2_addr[10:2];
                        offset        = l2_addr[1:0];
                        l2_tag_wd     = {1'b1,l2_addr[27:11]}; 
                    end else if(r_m_w_l2_en == `ENABLE)begin
                        r_m_w_l2_en    = `DISABLE;
                        l2_block0_we   = l2_block0_we_mem_l2;
                        l2_block1_we   = l2_block1_we_mem_l2;
                        l2_block2_we   = l2_block2_we_mem_l2;
                        l2_block3_we   = l2_block3_we_mem_l2;
                        l2_data_wd_mem = l2_data_wd_mem_l2;
                        l2_index       = l2_index_mem_l2;
                        l2_thread_wd   = l2_thread_wd_mem;
                        l2_tag_wd      = l2_tag_wd_mem_l2;
                        mem_wr_l2_en   = `ENABLE; 
                        nextstate      = `MEM_WRITE_L2;
                        offset         = offset_mem_l2;
                    end else if (irq  == `ENABLE) begin  
                        l2_en         = `ENABLE;
                        nextstate     = `ACCESS_L2;
                        ic_en         = `ENABLE;
                        l2_block0_re  = `ENABLE;
                        l2_block1_re  = `ENABLE; 
                        l2_block2_re  = `ENABLE;
                        l2_block3_re  = `ENABLE;
                        ic_addr_l2    = ic_addr[29:2];
                        l2_choose_l1  = ic_choose_way;
                        l2_thread     = ic_thread;
                        l2_cache_rw   =  `READ;                   
                        if (mem_busy == `DISABLE && ic_addr[1:0] == 2'b11) begin
                            l2_addr   =  ic_addr[29:2] + 2'b1;
                        end else begin
                            l2_addr   =  ic_addr[29:2];
                        end    
                        l2_index      = l2_addr[10:2];
                        offset        = l2_addr[1:0];
                        l2_tag_wd     = {1'b1,l2_addr[27:11]};    
                    end else if (drq == `ENABLE) begin  
                        l2_en         = `ENABLE;
                        nextstate     = `ACCESS_L2;
                        dc_en         = `ENABLE;
                        l2_block0_re  = `ENABLE;
                        l2_block1_re  = `ENABLE; 
                        l2_block2_re  = `ENABLE;
                        l2_block3_re  = `ENABLE;
                        dc_addr_l2    = dc_addr;
                        l2_choose_l1  = dc_choose_way;
                        l2_thread     = dc_thread;
                        dc_rw_l2      = dc_rw;
                        dc_wd_l2      = dc_wd;
                        dc_index      = l2_addr[7:0];
                        dc_offset_l2  = dc_offset;
                        if (access_l2_clean == `ENABLE) begin
                            l2_cache_rw =  `READ;
                            l2_addr     =  dc_addr;
                        end else if (access_l2_dirty == `ENABLE) begin
                            l2_cache_rw = `WRITE; 
                            case(choose_way)
                                `WAY0:begin
                                    rd_to_l2   =  data0_rd;
                                    l2_addr    =  {tag0_rd[19:0],dc_addr[7:0]};
                                end
                                `WAY1:begin
                                    rd_to_l2   =  data1_rd;
                                    l2_addr    =  {tag1_rd[19:0],dc_addr[7:0]};
                                end
                            endcase
                        end
                        l2_index     = l2_addr[10:2];
                        offset       = l2_addr[1:0];
                        l2_tag_wd    = {1'b1,l2_addr[27:11]}; 
                    end else begin
                        nextstate    = `L2_IDLE;
                    end
                end
            end
            `ACCESS_L2:begin
                thread_rdy       = `DISABLE;
                access_mem_clean = `DISABLE;
                access_mem_dirty = `DISABLE;
                l2_busy          = `ENABLE;
                ic_block0_we     = `DISABLE;
                ic_block1_we     = `DISABLE;
                dc_block0_we     = `DISABLE;
                dc_block1_we     = `DISABLE;
                l2_block0_we     = `DISABLE;
                l2_block1_we     = `DISABLE; 
                l2_block2_we     = `DISABLE;
                l2_block3_we     = `DISABLE;
                l2_rdy           = `DISABLE;
                data_wd_l2_en    = `DISABLE; 
                wd_from_l1_en    = `DISABLE;
                // protect
                l2_block0_re     = `ENABLE;
                l2_block1_re     = `ENABLE; 
                l2_block2_re     = `ENABLE;
                l2_block3_re     = `ENABLE;
                if (l2_complete_r == `ENABLE) begin
                    l2_block0_re  = `DISABLE;
                    l2_block1_re  = `DISABLE; 
                    l2_block2_re  = `DISABLE;
                    l2_block3_re  = `DISABLE;
                    if ( l2_cache_rw == `READ && tagcomp_hit == `ENABLE) begin 
                        // Read l2_block ,write to l1                        
                        if (ic_en == `ENABLE) begin
                            ic_tag_wd        = {1'b1,l2_addr[27:8]};
                            ic_index         = l2_addr[7:0];
                            data_wd_l2_en = `ENABLE;
                            case(l2_choose_l1)
                                `WAY0:begin
                                    ic_block0_we = `ENABLE;
                                end
                                `WAY1:begin
                                    ic_block1_we = `ENABLE;
                                end
                            endcase  
                            l2_rdy    = `ENABLE;   
                            nextstate = `L2_IDLE;  
                        end
                        if (dc_en == `ENABLE || read_en == `ENABLE) begin                           
                            dc_tag_wd    = {1'b1,l2_addr[27:8]};
                            data_wd_l2_en_dc = `ENABLE;
                            case(l2_choose_l1)
                                `WAY0:begin
                                    dc_block0_we = `ENABLE;
                                end
                                `WAY1:begin
                                    dc_block1_we = `ENABLE;
                                end
                            endcase 
                            nextstate = `L2_IDLE; 
                        end
                        case(hitway)
                            `L2_WAY0:begin 
                                case(offset)
                                    `WORD0:begin
                                        data_wd_l2 = l2_data0_rd[127:0];
                                    end
                                    `WORD1:begin
                                        data_wd_l2 = l2_data0_rd[255:128];
                                    end
                                    `WORD2:begin
                                        data_wd_l2 = l2_data0_rd[383:256];
                                    end
                                    `WORD3:begin
                                        data_wd_l2 = l2_data0_rd[511:384];
                                    end
                                endcase // case(offset)
                            end
                            `L2_WAY1:begin  
                                case(offset)
                                    `WORD0:begin
                                        data_wd_l2 = l2_data1_rd[127:0];
                                    end
                                    `WORD1:begin
                                        data_wd_l2 = l2_data1_rd[255:128];
                                    end
                                    `WORD2:begin
                                        data_wd_l2 = l2_data1_rd[383:256];
                                    end
                                    `WORD3:begin
                                        data_wd_l2 = l2_data1_rd[511:384];
                                    end
                                endcase // case(offset)
                            end
                            `L2_WAY2:begin 
                                case(offset)
                                    `WORD0:begin
                                        data_wd_l2 = l2_data2_rd[127:0];
                                    end
                                    `WORD1:begin
                                        data_wd_l2 = l2_data2_rd[255:128];
                                    end
                                    `WORD2:begin
                                        data_wd_l2 = l2_data2_rd[383:256];
                                    end
                                    `WORD3:begin
                                        data_wd_l2 = l2_data2_rd[511:384];
                                    end
                                endcase // case(offset)
                            end
                            `L2_WAY3:begin
                                case(offset)
                                    `WORD0:begin
                                        data_wd_l2 = l2_data3_rd[127:0];
                                    end
                                    `WORD1:begin
                                        data_wd_l2 = l2_data3_rd[255:128];
                                    end
                                    `WORD2:begin
                                        data_wd_l2 = l2_data3_rd[383:256];
                                    end
                                    `WORD3:begin
                                        data_wd_l2 = l2_data3_rd[511:384];
                                    end
                                endcase // case(offset)
                            end
                        endcase  

                    end else if( l2_cache_rw == `WRITE && tagcomp_hit == `ENABLE) begin // write hit
                        // Write dirty block of l1 into l2_cache
                        nextstate     = `L2_WRITE_HIT;
                        wd_from_l1_en = `ENABLE;
                        l2_thread_wd  = l2_thread;
                        // Protect write enable correctly.
                        case(hitway)
                            `L2_WAY0:begin
                                l2_block0_we = `ENABLE;
                            end // hitway == 00
                            `L2_WAY1:begin
                                l2_block1_we = `ENABLE;
                            end // hitway == 01
                            `L2_WAY2:begin
                                l2_block2_we = `ENABLE;
                            end // hitway == 10
                            `L2_WAY3:begin
                                l2_block3_we = `ENABLE;
                            end // hitway == 11
                        endcase // case(hitway) 
                    end else if (tagcomp_hit == `DISABLE)begin // cache miss
                        if (memory_busy == `DISABLE) begin
                            nextstate = `L2_IDLE;
                            l2_busy   = `DISABLE;
                        end else begin
                            nextstate = `MEM_BUSY;
                            l2_busy   = `ENABLE;
                        end
                        // Read mem_block ,write to l1 and l2
                        if (valid == `DISABLE || dirty == `DISABLE) begin
                            access_mem_clean = `ENABLE;
                            /* Write l2 part */ 
                        end else if(valid == `ENABLE && dirty == `ENABLE) begin 
                            access_mem_dirty = `ENABLE;
                            // Write dirty block of l2 to mem
                        end
                    end
                end else begin
                    nextstate = `ACCESS_L2;
                end
            end
            `MEM_BUSY:begin
                l2_busy   = `ENABLE;
                if (memory_busy == `ENABLE) begin
                    nextstate = `MEM_BUSY;
                end else begin
                    nextstate = `L2_IDLE;
                    l2_busy   = `DISABLE;
                end
            end
            `L2_WRITE_HIT:begin // write L1 into l2_cache
                if(l2_complete_w == `ENABLE)begin
                    // Read l2 to l1
                    l2_cache_rw   = `READ;  
                    l2_addr       = dc_addr_l2; 
                    l2_index      = l2_addr[10:2];
                    offset        = l2_addr[1:0];
                    // Initial signal after using
                    wd_from_l1_en = `DISABLE;  
                    nextstate     = `ACCESS_L2;  
                    l2_block0_we  = `DISABLE;
                    l2_block1_we  = `DISABLE;
                    l2_block2_we  = `DISABLE;
                    l2_block3_we  = `DISABLE;
                    l2_block0_re  = `ENABLE;
                    l2_block1_re  = `ENABLE; 
                    l2_block2_re  = `ENABLE;
                    l2_block3_re  = `ENABLE;                                   
                end
            end
            default:nextstate = `L2_IDLE;
        endcase        
    end
    always @(posedge clk) begin // cache control
        if (rst == `ENABLE) begin
            state <= `L2_IDLE;
        end else begin   
            state <= nextstate;
        end
    end
endmodule