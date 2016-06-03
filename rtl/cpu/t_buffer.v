//---------------------------------------------------------------------------------
// FILENAME: t_buffer.v
// DESCRIPTION: target address buffer of branch pridect unit
// AUTHOR: cjh
// TIME: 2016-03-27 14:51:05 
//==================================================================================

`timescale 1ns/1ps
`include "brap.h"
`include "stddef.h"

module t_buffer(

    input   wire                    clk,        // clock

    /****** from pipeling and tage branch pridect about branch pridect ******/
    input   wire[`WORD_DATA_BUS]    pc,         // pc of if stage
    input   wire                    update,     // to mark next pc from ex stage is same with excuting pc in id stage
    input   wire[`WORD_DATA_BUS]    tar_addr,   // target address to write in ram
    input   wire[`TagBus]           block0_tag_id,  // block0 tag from id_reg
    input   wire[`TagBus]           block1_tag_id,  // block1 tag from id_reg
    input   wire[`TagBus]           block2_tag_id,  // block2 tag from id_reg
    input   wire[`TagBus]           block3_tag_id,  // block3_tag from id_reg
    input   wire[`PlruRamBus]       plru_data_id,   // plru_data from id_reg

    /****** output the data of ram ******/
    output  wire[`WORD_DATA_BUS]    tar_data,   // output the data of ram
    output  wire                    tar_en,     // the tar data is enable
    output  wire[`TagBus]           block0_tag, // block0 tag to if_reg
    output  wire[`TagBus]           block1_tag, // block1 tag to if_reg
    output  wire[`TagBus]           block2_tag, // block2 tag to if_reg
    output  wire[`TagBus]           block3_tag, // block3 tag to if_reg
    output  wire[`PlruRamBus]       plru_data   // plru data to if_reg
);
    wire plru_update,block0_wr,block1_wr,block2_wr,block3_wr;
    wire[`TargetRamBus]     write_data,block0_data,block1_data,block2_data,block3_data;
    wire[`PlruRamBus]       write_plru,plru_in;
    wire[`RamAddressBus]    ram_addr = pc[`PcAddress];                          // read address
    wire[`TagBus]   tag = pc[`PcTag];                           // tag to chooce one block
    assign  block0_tag = block0_data[`DataTag];         // tag of block0
    assign  block1_tag = block1_data[`DataTag];         // tag of block1
    assign  block2_tag = block2_data[`DataTag];         // tag of block2
    assign  block3_tag = block3_data[`DataTag];         // tag of block3

    wire[`TargetAddrBus]    block0_tar = block0_data[`DataTar];
    wire[`TargetAddrBus]    block1_tar = block1_data[`DataTar];
    wire[`TargetAddrBus]    block2_tar = block2_data[`DataTar];
    wire[`TargetAddrBus]    block3_tar = block3_data[`DataTar];

    wire    block0_en = block0_data[0];
    wire    block1_en = block1_data[0];
    wire    block2_en = block2_data[0];
    wire    block3_en = block3_data[0];


    assign write_data = {pc[`PcTag],tar_addr,1'b1};

        
    ram9x54 t_ram0(                                 // block0
        .clk            (clk),
        .ram_addr       (ram_addr),
        .wd             (write_data),
        .rden           (`ENABLE),
        .wr             (block0_wr),
        .rd             (block0_data)
        );

    ram9x54 t_ram1(                                 // block1
        .clk            (clk),
        .ram_addr       (ram_addr),
        .wd             (write_data),
        .rden           (`ENABLE),
        .wr             (block1_wr),
        .rd             (block1_data)
        );

    ram9x54 t_ram2(                                 // block2
        .clk            (clk),
        .ram_addr       (ram_addr),
        .wd             (write_data),
        .rden           (`ENABLE),
        .wr             (block2_wr),
        .rd             (block2_data)
        );

    ram9x54 t_ram3(                                 // block3
        .clk            (clk),
        .ram_addr       (ram_addr),
        .wd             (write_data),
        .rden           (`ENABLE),
        .wr             (block3_wr),
        .rd             (block3_data)
        );

    ram9x3 plru_ram(                                // block0
        .clk            (clk),
        .ram_addr       (ram_addr),
        .wd             (plru_in),
        .rden           (`ENABLE),
        .wr             (plru_update),
        .rd             (plru_data)
        );


    flush_ram   flush_ram(                                  // ram flush contral unit
        /****** input *******/
        .update             (update),
        .pc                 (pc),
        .block0_tag_id      (block0_tag_id),
        .block1_tag_id      (block1_tag_id),
        .block2_tag_id      (block2_tag_id),
        .block3_tag_id      (block3_tag_id),
        .plru_data_id       (plru_data_id),

        /****** output ******/
        .write_plru     (write_plru),
        .block0_wr      (block0_wr),
        .block1_wr      (block1_wr),
        .block2_wr      (block2_wr),
        .block3_wr      (block3_wr)
        );

    ram_out     ram_out(
        .tag            (tag),
        .update         (update),
        .block0_tar     (block0_tar),
        .block1_tar     (block1_tar),
        .block2_tar     (block2_tar),
        .block3_tar     (block3_tar),
        .block0_en      (block0_en),
        .block1_en      (block1_en),
        .block2_en      (block2_en),
        .block3_en      (block3_en),
        .block0_tag     (block0_tag),
        .block1_tag     (block1_tag),
        .block2_tag     (block2_tag),
        .block3_tag     (block3_tag),
        .plru_data      (plru_data),

        .tar_data       (tar_data),
        .tar_en         (tar_en),
        .plru_in        (plru_in),
        .plru_update    (plru_update)
        );


endmodule

module flush_ram(

    /******     from pipling     ******/
    input   wire                        update,     // if branch predict hit
    input   wire[`WORD_DATA_BUS]        pc,         // pc of the branch instruction

    /******     from id_reg     ******/
    input   wire[`TagBus]       block0_tag_id,          // the data from block0
    input   wire[`TagBus]       block1_tag_id,          // the data from block1
    input   wire[`TagBus]       block2_tag_id,          // the data from block2
    input   wire[`TagBus]       block3_tag_id,          // the data from block3
    input   wire[`PlruRamBus]   plru_data_id,           // the data from plur

    /******     write to ram        ******/
    output  reg[`PlruRamBus]        write_plru,     // to write to PLRU
    output  reg                     block0_wr,      // to write to block0
    output  reg                     block1_wr,      // to write to block1
    output  reg                     block2_wr,      // to write to block2
    output  reg                     block3_wr       // to write to block3
);
    
    
    always @(*) begin
        block0_wr = `DISABLE;
        block1_wr = `DISABLE;
        block2_wr = `DISABLE;
        block3_wr = `DISABLE;

        if(update == `ENABLE) begin

            case (pc [`PcTag])
                block0_tag_id:begin                                 // update block0
                    write_plru = {plru_data_id[2],2'b11};           // change the plru to x11
                    block0_wr = `ENABLE;                        // block0 write is enable
                end

                block1_tag_id:begin                                 // update block1
                    write_plru = {plru_data_id[2],2'b01};           // change the plru to x01
                    block1_wr = `ENABLE;                        // block1 write is enable
                end

                block2_tag_id:begin                                 // update block2
                    write_plru = {1'b1,plru_data_id[1],1'b0};       // change the plru to 1x0
                    block2_wr = `ENABLE;                        // block2 write is enable
                end

                block3_tag_id:begin                                 // update block3
                    write_plru = {1'b0,plru_data_id[1],1'b0};       // change the plru to 0x0
                    block3_wr = `ENABLE;                        // block3 write is enable

                end

                default:begin

                    if (plru_data_id[0] === 1'b1) begin                 // update block2 or block3

                        if (plru_data_id[2] === 1'b1) begin             // update block3
                            write_plru = {1'b0,plru_data_id[1],1'b0};   // change the plru to 0x0
                            block3_wr = `ENABLE;                    // block3 write is enable
                        end else begin                              // update block2
                            write_plru = {1'b1,plru_data_id[1],1'b0};   // change the plru to 1x0
                            block2_wr = `ENABLE;                    // block2 write is enable
                        end
                        
                    end else begin                              // update block0 or block1

                        if (plru_data_id[1] === 1'b1) begin         // update block1
                            write_plru = {plru_data_id[2],2'b01};   // change the plru to x01
                            block1_wr = `ENABLE;                // block1 write is enable
                        end else begin                          // update block0
                            write_plru = {plru_data_id[2],2'b11};   // change the plru to x11
                            block0_wr = `ENABLE;                // block0 write is enable
                        end

                    end

                end
            endcase
        end
    end

endmodule       

module ram_out(
    input wire[`TagBus]                 tag,
    input wire                          update,
    input wire[`WORD_DATA_BUS]          block0_tar,
    input wire[`WORD_DATA_BUS]          block1_tar,
    input wire[`WORD_DATA_BUS]          block2_tar,
    input wire[`WORD_DATA_BUS]          block3_tar,
    input wire                          block0_en,
    input wire                          block1_en,
    input wire                          block2_en,
    input wire                          block3_en,
    input wire[`TagBus]                 block0_tag,
    input wire[`TagBus]                 block1_tag,
    input wire[`TagBus]                 block2_tag,
    input wire[`TagBus]                 block3_tag,
    input wire[`PlruRamBus]             plru_data,
    input wire[`PlruRamBus]             write_plru,

    output reg[`WORD_DATA_BUS]          tar_data,
    output reg                          tar_en,
    output reg                          plru_update,
    output reg[`PlruRamBus]             plru_in
);
    
    always @(*) begin
        if(~update)begin
            case (tag)
                block0_tag:begin                        // if block0 tag == tag,output block0 
                    plru_in <= {plru_data[2],2'b11};
                    plru_update <= `ENABLE;
                    tar_data <= block0_tar;
                    tar_en <= block0_en;
                end

                block1_tag:begin                        // if block1 tag == tag,output block1
                    plru_in <= {plru_data[2],2'b01};
                    plru_update <= `ENABLE;
                    tar_data <= block1_tar;
                    tar_en <= block1_en;
                end

                block2_tag:begin                        // if block2 tag == tag,output block2
                    plru_in <= {1'b1,plru_data[1],1'b0};
                    plru_update <= `ENABLE;
                    tar_data <= block2_tar;
                    tar_en <= block2_en;
                end

                block3_tag:begin                        // if block3 tag == tag,output block3
                    plru_in <= {1'b0,plru_data[1],1'b0};
                    plru_update <= `ENABLE;
                    tar_data <= block3_tar;
                    tar_en <= block3_en;
                end

                default:begin
                    plru_in <= 3'b0;
                    plru_update <= `DISABLE;
                    tar_data <= 32'b0;
                    tar_en <= `DISABLE;
                end
            endcase     
        end else begin
            plru_in <= write_plru;
            plru_update <= `ENABLE;
            tar_data <= 32'b0;
            tar_en <= `DISABLE;
        end

    end
endmodule