`include "stddef.h"

`include "gpio.h"

module gpio (
    /********** Clock & Rest **********/
    input  wire                     clk,     // Clock
    input  wire                     reset,   // Rest
    /********** Bus Interface **********/
    input  wire                     cs_,     // Chip selection
    input  wire                     as_,     // Address strobe
    input  wire                     rw,      // Read / Write
    input  wire [`GPIO_ADDR_BUS]    addr,    // Address
    input  wire [`WORD_DATA_BUS]    wr_data, // Write data
    output reg  [`WORD_DATA_BUS]    rd_data, // Read data
    output reg                      rdy_     // Ready
    /********** General Purpose Input/Output **********/
`ifdef GPIO_IN_CH    // Input Port Implementation
    , input wire [`GPIO_IN_CH-1:0]  gpio_in  // Input Port（Control Register 0）
`endif
`ifdef GPIO_OUT_CH   // Output Port Implementation
    , output reg [`GPIO_OUT_CH-1:0] gpio_out // Output Port （Control Register1）
`endif
`ifdef GPIO_IO_CH    // Input/Output Port Implementation
    , inout wire [`GPIO_IO_CH-1:0]  gpio_io  // Input/Output Port （Control Register2）
`endif
);

`ifdef GPIO_IO_CH    // Input/Output Port Control 
    /********** Input Signal **********/
    wire [`GPIO_IO_CH-1:0]          io_in;   // Input Data
    reg  [`GPIO_IO_CH-1:0]          io_out;  // Output Data
    reg  [`GPIO_IO_CH-1:0]          io_dir;  // Input/Output  Direction（Control Register3）
    reg  [`GPIO_IO_CH-1:0]          io;      // Input/Output 
    integer                         i;       // Iterator
   
    /********** Input/Output Signal assignment **********/
    assign io_in       = gpio_io;            // Input Data
    assign gpio_io     = io;                 // Input/Output 

    /********** Input/Output  Direction Control  **********/
    always @(*) begin
        for (i = 0; i < `GPIO_IO_CH; i = i + 1) begin : IO_DIR
            io[i] = (io_dir[i] == `GPIO_DIR_IN) ? 1'bz : io_out[i];
        end
    end

`endif
   
    /********** GPIO Control  **********/
    always @(posedge clk or `RESET_EDGE reset) begin
        if (reset == `RESET_ENABLE) begin
            /* Asynchronous Rest */
            rd_data  <= #1 `WORD_DATA_W'h0;
            rdy_     <= #1 `DISABLE_;
`ifdef GPIO_OUT_CH   // Output Port Rest
            gpio_out <= #1 {`GPIO_OUT_CH{`LOW}};
`endif
`ifdef GPIO_IO_CH    // Input/Output Port Rest
            io_out   <= #1 {`GPIO_IO_CH{`LOW}};
            io_dir   <= #1 {`GPIO_IO_CH{`GPIO_DIR_IN}};
`endif
        end else begin
            /* Ready Generation */
            if ((cs_ == `ENABLE_) && (as_ == `ENABLE_)) begin
                rdy_     <= #1 `ENABLE_;
            end else begin
                rdy_     <= #1 `DISABLE_;
            end 
            /* Read  Access */
            if ((cs_ == `ENABLE_) && (as_ == `ENABLE_) && (rw == `READ)) begin
                case (addr)
`ifdef GPIO_IN_CH   // Input Port Read 
                    `GPIO_ADDR_IN_DATA  : begin // Control Register 0
                        rd_data  <= #1 {{`WORD_DATA_W-`GPIO_IN_CH{1'b0}}, 
                                        gpio_in};
                    end
`endif
`ifdef GPIO_OUT_CH  // Output Port Read 
                    `GPIO_ADDR_OUT_DATA : begin // Control Register 1
                        rd_data  <= #1 {{`WORD_DATA_W-`GPIO_OUT_CH{1'b0}}, 
                                        gpio_out};
                    end
`endif
`ifdef GPIO_IO_CH   // Input/Output Port Read 
                    `GPIO_ADDR_IO_DATA  : begin // Control Register 2
                        rd_data  <= #1 {{`WORD_DATA_W-`GPIO_IO_CH{1'b0}}, 
                                        io_in};
                     end
                    `GPIO_ADDR_IO_DIR   : begin // Control Register 3
                        rd_data  <= #1 {{`WORD_DATA_W-`GPIO_IO_CH{1'b0}}, 
                                        io_dir};
                    end
`endif
                endcase
            end else begin
                rd_data  <= #1 `WORD_DATA_W'h0;
            end
            /* Write Access */
            if ((cs_ == `ENABLE_) && (as_ == `ENABLE_) && (rw == `WRITE)) begin
                case (addr)
`ifdef GPIO_OUT_CH  // Write to Output Port
                    `GPIO_ADDR_OUT_DATA : begin // Control Register 1
                        gpio_out <= #1 wr_data[`GPIO_OUT_CH-1:0];
                    end
`endif
`ifdef GPIO_IO_CH   // Write to Input/Output Port
                    `GPIO_ADDR_IO_DATA  : begin // Control Register 2
                        io_out   <= #1 wr_data[`GPIO_IO_CH-1:0];
                     end
                    `GPIO_ADDR_IO_DIR   : begin // Control Register 3
                        io_dir   <= #1 wr_data[`GPIO_IO_CH-1:0];
                    end
`endif
                endcase
            end
        end
    end

endmodule
