`timescale 1ns/1ps

`include "stddef.h"

module clk_4(
    input        clk_2,  // two divided-frequency clock 
    input        rst,    // reset
    output reg   clk_4   // four divided-frequency clock
    );

	always @(posedge clk_2) begin
		if (rst == `ENABLE) begin
			clk_4 = `LOW;
		end else begin
			clk_4 = ~clk_4;
		end
	end
endmodule