////////////////////////////////////////////////////////////////////
// Engineer:       Leway Colin - colin4124@gmail.com              //
//                                                                //
// Additional contributions by:                                   //
//                 Beyond Sky - fan-dave@163.com                  //
//                 Junhao Chen                                    //
//                 Kippy Chen - 799182081@qq.com                  //
//                                                                //
// Design Name:    Scratch Pad Memory                             //
// Project Name:   FMRT Mini Core                                 //
// Language:       Verilog                                        //
//                                                                //
// Description:    Dual Port RAM for instructions and Data.       //
//                                                                //
////////////////////////////////////////////////////////////////////

`include "common_defines.v"
`include "base_core_defines.v"

module spm (
    input wire         clk,            // Clock
    /********** Port A: IF Stage **********/
    input wire [11:0]  if_spm_addr,    // Address
	  input wire         if_spm_as_,     // Address Strobe
	  input wire         if_spm_rw,      // Read/Write
	  input wire [31:0]  if_spm_wr_data, // Write data
	  output wire [31:0] if_spm_rd_data, // Read data
	/********** Port B: MEM Stage **********/
	  input wire [11:0]  mem_spm_addr,   // Address
	  input wire         mem_spm_as_,    // Address Strobe
	  input wire         mem_spm_rw,     // Read/Write
	  input wire [31:0]  mem_spm_wr_data,// Write data
	  output wire [31:0] mem_spm_rd_data // Read data
);

    /********** Internal Signal **********/
    reg           wea;	          // Port A Write enable
    reg           web;	          // Port  B Write Enable

    /********** Generate Write Enable Signal **********/
    always @(*) begin
	  	  /* Generate Port A Write Enable Signal */
	  	  if ((if_spm_as_ == `ENABLE_) && (if_spm_rw == `WRITE)) begin
	    	    wea = `ENABLE;	          // Write enable
	  	  end else begin
	          wea = `DISABLE;         // Write disable
	  	  end
	  	  /* Generate Port B Write Enable Signal */
	  	if ((mem_spm_as_ == `ENABLE_) && (mem_spm_rw == `WRITE)) begin
	        web = `ENABLE;	        // Write enable
	  	end else begin
	        web = `DISABLE;         // Write disable
	  	end
	  end

	/********** Simulate FPGA Block RAM: dpram_sim **********/
	dpram_sim x_s3e_dpram (
		/********** Port A: IF Stage **********/
		.clock_a   (clk),			        // Clock
		.address_a (if_spm_addr),     // Address
		.data_a    (if_spm_wr_data),  // Write data (Not Connected)
		.wren_a    (wea),			        // Write enable A (Disable)
		.q_a       (if_spm_rd_data),  // Read data
		/********** Port B: MEM Stage **********/
		.clock_b   (clk),			        // Clock
		.address_b (mem_spm_addr),	  // Address
		.data_b    (mem_spm_wr_data), // Write data
		.wren_b    (web),			        // Write enable
		.q_b       (mem_spm_rd_data)  // Read data
	);

endmodule
