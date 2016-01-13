/*
 -- ============================================================================
 -- FILE NAME   : icache.v
 -- DESCRIPTION : 指令高速缓存器
 -- ----------------------------------------------------------------------------
 -- Date:2016/1/8         Coding_by:kippy
 -- ============================================================================
*/

/********** General header file **********/
`include "stddef.h"

module icache(
    input               rst,        // reset
    /* CPU part */
    input       [31:0]  if_addr,    // address of fetching instruction
    input               rw,         // read / write signal of CPU
    input       [31:0]  wd,         // write data of CPU
    output reg  [31:0]  cpu_data,   // read data of CPU
    output reg          miss_stall, // the signal of stall caused by cache miss
    /*cache part*/
    input               valid,      // the mark if cache is valid
    input       [19:0]  tag_rd,     // read data of tag
    input       [127:0] cache_rd,   // read data of cache
    output reg          cache_rw,   // read / write signal of cache
    output reg  [19:0]  tag_wd,     // write data of tag
    output reg  [7:0]   index,      // address of cache
    /*memory part*/
    output reg  [27:0]  mem_addr,   // address of memory
    output reg          mem_rw      // read / write signal of memory
    );
    reg         [1:0]   offset;     // offset of block
    reg                 hit_read;   // cache hit of reading

    /********* reset *********/
    always @(posedge rst) begin
        if (rst == `ENABLE) begin
            cpu_data   <= 32'b0;
            miss_stall <= `DISABLE;
            cache_rw   <= `READ;
            tag_wd     <= 20'b0;
            index      <= 8'b0;
            mem_addr   <= 28'b0;
            mem_rw     <= `READ;
            offset     <= 2'b0;
            hit_read   <= `DISABLE;
        end
    end
    /********* control *********/
    always @(*) begin
        if (rst == `DISABLE) begin
            index    = if_addr [11:4];
            tag_wd   = if_addr [31:12];
            offset   = if_addr [3:2];
            cache_rw = rw; 
        end
    end
    always @(*) begin
        if (rst == `DISABLE) begin
            if ( rw == `READ && tag_rd == if_addr[31:12] && valid == `ENABLE ) begin
                hit_read <=  `ENABLE;
            end else begin
                hit_read <= `DISABLE;
            end 
            begin
                if ( hit_read == `DISABLE ) begin
                    mem_addr   <= if_addr[31:4];
                    mem_rw     <= rw;
                    miss_stall <= `ENABLE;
                    cache_rw   <= `WRITE;
                end
                else begin
                    cache_rw   <= `READ;
                    miss_stall <= `DISABLE;
                    case(offset)
                        2'd0:begin
                            cpu_data <= cache_rd[31:0];
                        end
                        2'd1:begin
                            cpu_data <= cache_rd[63:32];
                        end
                        2'd2:begin
                            cpu_data <= cache_rd[95:64];
                        end
                        2'd3:begin
                            cpu_data <= cache_rd[127:96];
                        end
                    endcase
                end  
            end                      
        end
    end
endmodule


