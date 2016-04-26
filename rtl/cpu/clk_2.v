`timescale 1ns/1ps

`include "stddef.h"

module clk_2(
    input        clk,    // clock
    input        rst,    // reset
    output reg   clk_2,  // two divided-frequency clock
    output reg   clk_4   // four divided-frequency clock
    );

	always @(posedge clk) begin
		if (rst == `ENABLE) begin
			clk_2 = `LOW;
			clk_4 = `LOW;
		end else begin
			clk_2 = ~clk_2;
		end
	end
endmodule