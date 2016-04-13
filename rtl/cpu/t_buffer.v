//---------------------------------------------------------------------------------
// FILENAME: t_buffer.v
// DESCRIPTION: target address buffer of branch pridect unit
// AUTHOR: cjh
// TIME: 2016-03-27 14:51:05 
//==================================================================================

`include "brap.h"
`include "stddef.h"

module t_buffer(

	input 	wire 					clk,		// clock

	/****** from pipeling and tage branch pridect about branch pridect ******/
	input 	wire[`WORD_DATA_BUS] 	pc,			// pc of if stage
	input	wire					is_hit,		// to mark next pc from ex stage is same with excuting pc in id stage
	input	wire[`WORD_DATA_BUS]	tar_addr,	// target address to write in ram

	/****** output the data of ram ******/
	output 	reg[`WORD_DATA_BUS] 	tar_data,	// output the data of ram
	output	reg						tar_en 		// the tar data is enable
	);

	wire[`TargetRamBus]		write_data,block0_data,block1_data,block2_data,block3_data;
	wire[`PlruRamBus]		plru_data,write_plru;
	wire[`RamAddressBus] 	ram_addr;						// read address
	wire[`TagBus] 	tag = pc[`PcTag];						// tag to chooce one block
	wire[`TagBus] 	block0_tag = block0_data[`DataTag];		// tag of block0
	wire[`TagBus] 	block1_tag = block1_data[`DataTag];		// tag of block1
	wire[`TagBus]	block2_tag = block2_data[`DataTag];		// tag of block2
	wire[`TagBus]	block3_tag = block3_data[`DataTag];		// tag of block3
	wire[`TarEnBus]	block0_tar_en = block0_data[`DataTaren];		
	wire[`TarEnBus]	block1_tar_en = block1_data[`DataTaren];
	wire[`TarEnBus]	block2_tar_en = block2_data[`DataTaren];
	wire[`TarEnBus]	block3_tar_en = block3_data[`DataTaren];
	wire[`TargetAddrBus]	block0_tar = block0_tar_en[`DarenTar];
	wire[`TargetAddrBus] 	block1_tar = block1_tar_en[`DarenTar];
	wire[`TargetAddrBus] 	block2_tar = block2_tar_en[`DarenTar];
	wire[`TargetAddrBus] 	block3_tar = block3_tar_en[`DarenTar];
	wire	block0_en = block0_tar_en[0];
	wire	block1_en = block1_tar_en[0];
	wire	block2_en = block2_tar_en[0];
	wire	block3_en = block3_tar_en[0];
		
	t_ram #(54,9,512) t_ram0( 								// block0
		.clk 			(clk),
		.ram_addr		(ram_addr),
		.wr 			(block0_wr),
		.wd 			(write_data),
		.rd 			(block0_data)
		);

	t_ram #(54,9,512) t_ram1( 								// block1
		.clk 			(clk),
		.ram_addr		(ram_addr),
		.wr				(block1_wr),
		.wd 			(write_data),
		.rd 			(block1_data)
		);

	t_ram #(54,9,512) t_ram2( 								// block2
		.clk 			(clk),
		.ram_addr		(ram_addr),
		.wr				(block2_wr),
		.wd 			(write_data),
		.rd 			(block2_data)
		);

	t_ram #(54,9,512) t_ram3( 								// block3
		.clk 			(clk),
		.ram_addr		(ram_addr),
		.wr 			(block3_wr),
		.wd 			(write_data),
		.rd 		 	(block3_data)
		);

	t_ram #(3,9,512) plru_ram( 								// clock plru
		.clk 			(clk),
		.ram_addr		(ram_addr),
		.wr 			(we_plru),
		.wd 			(write_plru),
		.rd 	 		(plru_data)
		);
	assign 	we_plru = ~is_hit;

	flush_ram	flush_ram( 									// ram flush contral unit
		/****** input *******/
		.is_hit			(is_hit),
		.pc				(pc),
		.tar_addr		(tar_addr),
		.block0_tag		(block0_tag),
		.block1_tag		(block1_tag),
		.block2_tag		(block2_tag),
		.block3_tag		(block3_tag),
		.plru_data		(plru_data),

		/****** output ******/
		.ram_addr		(ram_addr),
		.write_data		(write_data),
		.write_plru 	(write_plru),
		.block0_wr		(block0_wr),
		.block1_wr		(block1_wr),
		.block2_wr		(block2_wr),
		.block3_wr		(block3_wr)
		);

	always @(*) begin

		case (tag)
			block0_tag:begin 						// if block0 tag == tag,output block0 
				tar_data = block0_tar;
				tar_en = block0_en;
			end

			block1_tag:begin 						// if block1 tag == tag,output block1
				tar_data = block1_tar;
				tar_en = block1_en;
			end

			block2_tag:begin 						// if block2 tag == tag,output block2
				tar_data = block2_tar;
				tar_en = block2_en;
			end

			block3_tag:begin 						// if block3 tag == tag,output block3
				tar_data = block3_tar;
				tar_en = block3_en;
			end

			default:begin
				tar_data = 32'b0;
				tar_en = `DISABLE;
			end
		endcase
	end
endmodule

module t_ram #(parameter WORD = 54,
	parameter ADDRESS = 9,
	parameter RAM = 512)
	(input 	wire				clk,			// clock
	input 	wire[ADDRESS-1:0]	ram_addr,		// read address
	input 	wire				wr,				// is write
	input 	wire[WORD-1:0]		wd,				// write data
	output 	wire[WORD-1:0]		rd);			// read data

	reg [WORD-1:0] ram [RAM-1:0];  // t_buffer is a ram

	/******		read data from ram 		******/
	assign rd = (wr === `ENABLE) ? wd : ram[ram_addr];

	/****** 	write data to ram 		******/
	always @(posedge clk && wr == `ENABLE) begin
		ram [ram_addr] <= wd;
	end

endmodule

module flush_ram(

	/******		from pipling 	 ******/
	input	wire 						is_hit, 		// if branch predict hit
	input	wire[`WORD_DATA_BUS]		pc,			// pc of the branch instruction
	input	wire[`TargetAddrBus]		tar_addr,		// branch target address

	/****** 	from ram output 	******/
	input	wire[`TagBus]		block0_tag,		// the data from block0
	input	wire[`TagBus]		block1_tag,		// the data from block1
	input	wire[`TagBus]		block2_tag,		// the data from block2
	input	wire[`TagBus]		block3_tag,		// the data from block3
	input	wire[`PlruRamBus]	plru_data,		// the data from plur

	/****** 	write to ram 		******/
	output	wire[`RamAddressBus]		ram_addr,		// ram write address
	output	wire[`TargetRamBus] 		write_data,		// the data to write to ram
	output	reg[`PlruRamBus]		write_plru,		// to write to PLRU
	output	reg						block0_wr,		// to write to block0
	output 	reg						block1_wr,		// to write to block1
	output	reg						block2_wr,		// to write to block2
	output	reg						block3_wr		// to write to block3
	);
	
	assign ram_addr = pc[`PcAddress];
	assign write_data = {pc[`PcTag],tar_addr,1'b1};

	always @(pc or is_hit) begin
		block0_wr = `DISABLE;
		block1_wr = `DISABLE;
		block2_wr = `DISABLE;
		block3_wr = `DISABLE;

		if(is_hit == `DISABLE) begin

			case (pc [`PcTag])
				block0_tag:begin 								// update block0
					write_plru = {plru_data[2],2'b11};			// change the plru to x11
					block0_wr = `ENABLE;						// block0 write is enable
				end

				block1_tag:begin 								// update block1
					write_plru = {plru_data[2],2'b01};			// change the plru to x01
					block1_wr = `ENABLE;						// block1 write is enable
				end

				block2_tag:begin 								// update block2
					write_plru = {1'b1,plru_data[1],1'b0};		// change the plru to 1x0
					block2_wr = `ENABLE;						// block2 write is enable
				end

				block3_tag:begin 								// update block3
					write_plru = {1'b0,plru_data[1],1'b0};		// change the plru to 0x0
					block3_wr = `ENABLE;						// block3 write is enable

				end

				default:begin

					if (plru_data[0] === 1'b1) begin 				// update block2 or block3

						if (plru_data[2] === 1'b1) begin 			// update block3
							write_plru = {1'b0,plru_data[1],1'b0};	// change the plru to 0x0
							block3_wr = `ENABLE;					// block3 write is enable
						end else begin 								// update block2
							write_plru = {1'b1,plru_data[1],1'b0};	// change the plru to 1x0
							block2_wr = `ENABLE;					// block2 write is enable
						end
						
					end else begin 								// update block0 or block1

						if (plru_data[1] === 1'b1) begin 		// update block1
							write_plru = {plru_data[2],2'b01};	// change the plru to x01
							block1_wr = `ENABLE;				// block1 write is enable
						end else begin 							// update block0
							write_plru = {plru_data[2],2'b11};	// change the plru to x11
							block0_wr = `ENABLE;				// block0 write is enable
						end

					end

				end
			endcase
		end
	end

endmodule 		

