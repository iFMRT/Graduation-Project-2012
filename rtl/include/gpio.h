`ifndef __GPIO_HEADER__
   `define __GPIO_HEADER__

	/********** Ports Definition **********/
	`define GPIO_IN_CH		   4	    // Input Ports
	`define GPIO_OUT_CH		   18	    // Output Ports
	`define GPIO_IO_CH		   16	    // Input/Output Ports

	/********** Bus **********/
	`define GPIO_ADDR_BUS		 1:0	  // Address Bus
	`define GPIO_ADDR_W		   2	    // Address Width
	`define GPIO_ADDR_LOC		 1:0	  // Address Location

	/********** Address Mapping **********/
	`define GPIO_ADDR_IN_DATA  2'h0 // Control Register 0: Input Port
	`define GPIO_ADDR_OUT_DATA 2'h1 // Control Register 1: Output Port
	`define GPIO_ADDR_IO_DATA  2'h2 // Control Register 2: Input Output Port
	`define GPIO_ADDR_IO_DIR   2'h3 // Control Register 3: Input Output Direction

	/********** Input/Output Direction **********/
	`define GPIO_DIR_IN		   1'b0   // Input
	`define GPIO_DIR_OUT	   1'b1   // Output

`endif
