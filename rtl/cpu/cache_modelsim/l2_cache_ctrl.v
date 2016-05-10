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
    /********* L2_Cache part *********/
    output      [8:0]   l2_index,           // l2_index of l2_cache
    output      [1:0]   offset,             // l2_offset of block
    output reg          tagcomp_hit,        // hit mark
    output reg          l2_rdy,             // ready mark
    // output reg          l2_busy,            // busy mark
    output reg          l2_block0_we,       // write signal mark of cache_block0
    output reg          l2_block1_we,       // write signal mark of cache_block1 
    output reg          l2_block2_we,       // write signal mark of cache_block2 
    output reg          l2_block3_we,       // write signal mark of cache_block3
    output reg          l2_block0_re,       // read signal mark of cache_block0 
    output reg          l2_block1_re,       // read signal mark of cache_block1 
    output reg          l2_block2_re,       // read signal mark of cache_block2 
    output reg          l2_block3_re,       // read signal mark of cache_block3 
    // l2_tag part
    input               l2_complete,        // complete mark of writing into l2_cache 
    input       [2:0]   plru,               // the number of replacing mark
    input       [17:0]  l2_tag0_rd,         // read data of tag0
    input       [17:0]  l2_tag1_rd,         // read data of tag1
    input       [17:0]  l2_tag2_rd,         // read data of tag2
    input       [17:0]  l2_tag3_rd,         // read data of tag3
    output      [17:0]  l2_tag_wd,          // write data of tag    
    // l2_data part
    input       [511:0] l2_data0_rd,        // read data of cache_data0
    input       [511:0] l2_data1_rd,        // read data of cache_data1
    input       [511:0] l2_data2_rd,        // read data of cache_data2
    input       [511:0] l2_data3_rd,        // read data of cache_data3
    output reg          wd_from_l1_en,      // write data from L1 enable mark 
    output reg          wd_from_mem_en,     // write data from MEM enable mark 
    // l2_dirty part
    input               l2_dirty0,          // read data of dirty0
    input               l2_dirty1,          // read data of dirty1
    input               l2_dirty2,          // read data of dirty2
    input               l2_dirty3,          // read data of dirty3
    output reg          l2_dirty_wd,        // write data of dirty
    /********* I_Cache part **********/
    input               irq,                // icache request
    input               ic_rw_en,           // icache write enable mark
    input               complete_ic,        // complete mark of writing into icache
    input       [27:0]  l2_addr_ic,         // address of fetching instruction
    input               l2_cache_rw_ic,     // read / write signal of CPU
    output reg          mem_wr_ic_en,       // mem write icache mark
    output reg          ic_en,              // icache request enable mark
    /********* D_Cache part **********/
    input               drq,                // dcache request
    input               dc_rw_en,           // dcache write enable mark
    input               complete_dc,        // complete mark of writing into dcache
    input       [27:0]  l2_addr_dc,         // address of accessing memory
    input               l2_cache_rw_dc,     // read / write signal of CPU    
    output reg          mem_wr_dc_en,       // mem write dcache mark
    output reg          dc_en,              // dcache request enable mark
    /************* L1 part ***********/
    output reg  [127:0] data_wd_l2,         // write data to L1 from L2   
    output reg          data_wd_l2_en,      // write data to L1 from L2 enable mark 
    /********** memory part **********/
    input               mem_complete,       // complete mark of writing into MEM
    input       [511:0] mem_rd,             // read data of MEM
    output reg  [511:0] mem_wd,             // write data of MEM
    output reg  [25:0]  mem_addr,           // address of memory
    output reg          mem_rw              // read / write signal of memory
    );

    reg         [1:0]   hitway;             // hit mark
    reg                 hitway0;            // the mark of choosing path0 
    reg                 hitway1;            // the mark of choosing path1
    reg                 hitway2;            // the mark of choosing path0 
    reg                 hitway3;            // the mark of choosing path1
    reg         [2:0]   nextstate,state;    // state of l2_icache
    reg         [1:0]   choose_way;         // the number of choosing way 
    reg                 valid;              // valid mark
    reg                 dirty;              // dirty mark
    reg        [27:0]   l2_addr;            // address of accessing L2
    reg                 l2_cache_rw;        // read / write signal of CPU      
    reg                 complete;           // complete mark of L1

    assign l2_index  = l2_addr[10:2];
    assign offset    = l2_addr[1:0];
    assign l2_tag_wd = {1'b1,l2_addr[27:11]};

    always @(*) begin // path choose
        if(ic_rw_en == `ENABLE) begin
            complete    = complete_ic;
        end else if(dc_rw_en == `ENABLE)begin 
            complete    = complete_dc;
        end

        if(ic_en == `ENABLE) begin
            l2_addr     = l2_addr_ic;
            l2_cache_rw = l2_cache_rw_ic;
        end else if(dc_en == `ENABLE)begin 
            l2_addr     = l2_addr_dc;
            l2_cache_rw = l2_cache_rw_dc;
        end

        hitway0 = (l2_tag0_rd[16:0] == l2_addr[27:11]) & l2_tag0_rd[17];
        hitway1 = (l2_tag1_rd[16:0] == l2_addr[27:11]) & l2_tag1_rd[17];
        hitway2 = (l2_tag2_rd[16:0] == l2_addr[27:11]) & l2_tag2_rd[17];
        hitway3 = (l2_tag3_rd[16:0] == l2_addr[27:11]) & l2_tag3_rd[17];
        
        if(hitway0 == `ENABLE)begin
            tagcomp_hit  = `ENABLE;
            hitway       = `L2_WAY0;
        end else if(hitway1 == `ENABLE) begin
            tagcomp_hit  = `ENABLE;
            hitway       = `L2_WAY1;
        end else if(hitway2 == `ENABLE) begin
            tagcomp_hit  = `ENABLE;
            hitway       = `L2_WAY2;
        end else if(hitway3 == `ENABLE) begin
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
    end

    always @(*) begin
        /*State Control Part*/
        case(state)
            `L2_IDLE:begin
                l2_block0_re  = `ENABLE;
                l2_block1_re  = `ENABLE; 
                l2_block2_re  = `ENABLE;
                l2_block3_re  = `ENABLE;
                if (irq == `ENABLE) begin  
                    nextstate     = `ACCESS_L2;
                    ic_en         = `ENABLE;
                end else if (drq == `ENABLE) begin  
                    nextstate     = `ACCESS_L2;
                    dc_en         = `ENABLE;
                end else begin
                    nextstate  = `L2_IDLE;
                end    
            end
            `ACCESS_L2:begin
                // l2_busy = `ENABLE;
                // Read hit
                if ( l2_cache_rw == `READ && tagcomp_hit == `ENABLE) begin 
                    // Read l2_block ,write to l1
                    l2_rdy        = `ENABLE;
                    data_wd_l2_en = `ENABLE;
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
                    if(complete == `ENABLE)begin
                        l2_rdy        = `DISABLE;
                        // l2_busy = `DISABLE;
                        ic_en         = `DISABLE;
                        dc_en         = `DISABLE;
                        data_wd_l2_en = `DISABLE;
                        if (irq == `ENABLE) begin  
                            nextstate  = `ACCESS_L2;
                            ic_en      = `ENABLE;
                        end else if (drq == `ENABLE) begin  
                            nextstate  = `ACCESS_L2;
                            dc_en      = `ENABLE;
                        end else begin
                            nextstate   = `L2_IDLE;
                        end
                    end else begin
                        nextstate   = `ACCESS_L2;
                    end
                end else if( l2_cache_rw == `WRITE && tagcomp_hit == `ENABLE) begin // write hit
                    // Write dirty block of l1 into l2_cache
                    nextstate     = `L2_WRITE_HIT;
                    l2_dirty_wd   = 1'b1;
                    wd_from_l1_en = `ENABLE;
                    // Protect write enable correctly.
                    l2_block0_we  = `DISABLE;
                    l2_block1_we  = `DISABLE; 
                    l2_block2_we  = `DISABLE;
                    l2_block3_we  = `DISABLE;
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
                end else begin // cache miss
                    // Read mem_block ,write to l1 and l2
                    if (valid == `DISABLE || dirty == `DISABLE) begin
                        /* Write l2 part */ 
                        mem_rw         = `READ;
                        mem_addr       = l2_addr[27:2];
                        nextstate      = `WRITE_TO_L2_CLEAN;
                        l2_dirty_wd    = 1'b0;
                        wd_from_mem_en = `ENABLE;
                        // Protect write enable correctly.
                        l2_block0_we   = `DISABLE;
                        l2_block1_we   = `DISABLE; 
                        l2_block2_we   = `DISABLE;
                        l2_block3_we   = `DISABLE;
                        case(choose_way)
                            `L2_WAY0:begin
                                l2_block0_we = `ENABLE;
                            end
                            `L2_WAY1:begin
                                l2_block1_we = `ENABLE;
                            end
                            `L2_WAY2:begin
                                l2_block2_we = `ENABLE;
                            end
                            `L2_WAY3:begin
                                l2_block3_we = `ENABLE;
                            end
                        endcase
                        /* Write l1 part */ 
                        data_wd_l2_en = `ENABLE;
                        case(offset)
                            `WORD0:begin
                                data_wd_l2 = mem_rd[127:0];
                            end
                            `WORD1:begin
                                data_wd_l2 = mem_rd[255:128];
                            end
                            `WORD2:begin
                                data_wd_l2 = mem_rd[383:256];
                            end
                            `WORD3:begin
                                data_wd_l2 = mem_rd[511:384];
                            end
                        endcase // case(offset)
                        if (dc_en == `ENABLE) begin
                            mem_wr_dc_en = `ENABLE;
                        end
                        if (ic_en == `ENABLE) begin
                            mem_wr_ic_en = `ENABLE; 
                        end
                    end else if(valid == `ENABLE && dirty == `ENABLE) begin 
                        // Write dirty block of l2 to mem
                        nextstate  = `WRITE_MEM;
                        mem_rw     = `WRITE; 
                        case(choose_way)
                            `L2_WAY0:begin
                                mem_wd      = l2_data0_rd;
                                mem_addr    = {l2_tag0_rd[16:0],l2_addr[10:2]};  
                            end
                            `L2_WAY1:begin
                                mem_wd      = l2_data1_rd;
                                mem_addr    = {l2_tag1_rd[16:0],l2_addr[10:2]};
                            end
                            `L2_WAY2:begin
                                mem_wd      = l2_data2_rd;
                                mem_addr    = {l2_tag2_rd[16:0],l2_addr[10:2]};
                            end
                            `L2_WAY3:begin
                                mem_wd      = l2_data3_rd;
                                mem_addr    = {l2_tag3_rd[16:0],l2_addr[10:2]};
                            end
                        endcase
                    end
                end
            end
            `WRITE_MEM:begin // load block of L2 with dirty to mem,then read mem to l2.                 
                if (mem_complete == `ENABLE) begin
                    /* read mem and write l2 part */ 
                    mem_addr       = l2_addr[27:2];
                    mem_rw         = `READ; 
                    l2_dirty_wd    = 1'b0;
                    wd_from_mem_en = `ENABLE;
                    // Protect write enable correctly.
                    l2_block0_we   = `DISABLE;
                    l2_block1_we   = `DISABLE; 
                    l2_block2_we   = `DISABLE;
                    l2_block3_we   = `DISABLE;
                    case(choose_way)
                        `L2_WAY0:begin
                            l2_block0_we = `ENABLE;
                        end
                        `L2_WAY1:begin
                            l2_block1_we = `ENABLE;
                        end
                        `L2_WAY2:begin
                            l2_block2_we = `ENABLE;
                        end
                        `L2_WAY3:begin
                            l2_block3_we = `ENABLE;
                        end
                    endcase
                    // decide whether write into l1 meanwhile or not.
                    if (l2_cache_rw == `READ) begin
                        /* write l1 part */ 
                        nextstate    = `WRITE_TO_L2_DIRTY_R;
                        data_wd_l2_en = `ENABLE;
                        case(offset)
                            `WORD0:begin
                                data_wd_l2 = mem_rd[127:0];
                            end
                            `WORD1:begin
                                data_wd_l2 = mem_rd[255:128];
                            end
                            `WORD2:begin
                                data_wd_l2 = mem_rd[383:256];
                            end
                            `WORD3:begin
                                data_wd_l2 = mem_rd[511:384];
                            end
                        endcase // case(offset)
                        if (dc_en == `ENABLE) begin
                            mem_wr_dc_en = `ENABLE;
                        end
                        if (ic_en == `ENABLE) begin
                            mem_wr_ic_en = `ENABLE; 
                        end 
                    end else begin
                        nextstate    = `WRITE_TO_L2_DIRTY_W;
                    end
                        
                end else begin
                    nextstate = `WRITE_MEM;
                end
            end
            `WRITE_TO_L2_CLEAN:begin // write into l2_cache from memory 
                if(l2_complete == `ENABLE)begin
                    //Initial signal after using
                    l2_block0_we   = `DISABLE;
                    l2_block1_we   = `DISABLE; 
                    l2_block2_we   = `DISABLE;
                    l2_block3_we   = `DISABLE; 
                    wd_from_mem_en = `DISABLE;
                    mem_wr_dc_en   = `DISABLE;
                    mem_wr_ic_en   = `DISABLE;  
                    // l2_busy        = `DISABLE;
                    ic_en          = `DISABLE;
                    dc_en          = `DISABLE;
                    data_wd_l2_en  = `DISABLE;
                    if (irq == `ENABLE) begin  
                        nextstate  = `ACCESS_L2;
                        ic_en      = `ENABLE;
                    end else if (drq == `ENABLE) begin  
                        nextstate  = `ACCESS_L2;
                        dc_en      = `ENABLE;
                    end else begin
                        nextstate  = `L2_IDLE;
                    end                                        
                end else begin
                    nextstate  =  `WRITE_TO_L2_CLEAN;
                end
            end
            `WRITE_TO_L2_DIRTY_R:begin // write into l2_cache from memory 
                if(l2_complete == `ENABLE)begin
                    //Initial signal after using
                    wd_from_mem_en = `DISABLE;  
                    // l2_busy        = `DISABLE; 
                    ic_en          = `DISABLE;
                    dc_en          = `DISABLE;
                    l2_block0_we   = `DISABLE;
                    l2_block1_we   = `DISABLE;
                    l2_block2_we   = `DISABLE;
                    l2_block3_we   = `DISABLE;
                    if (l2_cache_rw == `READ) begin
                        mem_wr_dc_en  = `DISABLE;
                        mem_wr_ic_en  = `DISABLE;
                        data_wd_l2_en = `DISABLE; 
                    end
                    if (irq == `ENABLE) begin  
                        nextstate  = `ACCESS_L2;
                        ic_en      = `ENABLE;
                    end else if (drq == `ENABLE) begin  
                        nextstate  = `ACCESS_L2;
                        dc_en      = `ENABLE;
                    end else begin
                        nextstate  = `L2_IDLE;
                    end                                         
                end else begin
                    nextstate  =  `WRITE_TO_L2_DIRTY_R;
                end
            end
            `WRITE_TO_L2_DIRTY_W:begin // write into l2_cache from memory 
                if(l2_complete == `ENABLE)begin
                    // write dirty block of l1 into l2_cache 
                    wd_from_mem_en = `DISABLE; 
                    nextstate      = `L2_WRITE_HIT;
                    l2_dirty_wd    = 1'b1;
                    wd_from_l1_en  = `ENABLE;
                    // Protect write enable correctly.
                    l2_block0_we   = `DISABLE;
                    l2_block1_we   = `DISABLE;
                    l2_block2_we   = `DISABLE;
                    l2_block3_we   = `DISABLE;
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
                end else begin
                    nextstate  =  `WRITE_TO_L2_DIRTY_W;
                end
            end
            `L2_WRITE_HIT:begin // write L1 into l2_cache
                if(l2_complete == `ENABLE)begin
                    // Read l2 to l1
                    // Initial signal after using
                    wd_from_l1_en = `DISABLE;  
                    nextstate     = `ACCESS_L2;  
                    l2_block0_we  = `DISABLE;
                    l2_block1_we  = `DISABLE;
                    l2_block2_we  = `DISABLE;
                    l2_block3_we  = `DISABLE;                                   
                end else begin
                    nextstate =  `L2_WRITE_HIT;
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