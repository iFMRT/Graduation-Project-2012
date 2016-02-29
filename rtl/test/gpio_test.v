/******** Time scale ********/
`timescale 1ns/1ps

`include "stddef.h"

`include "gpio.h"

module gpio_test;
    /********** Clock & Rest **********/
    reg                     clk;     // Clock
    reg                     reset;   // Rest
    /********** Bus Interface **********/
    reg                     cs_;     // Chip selection
    reg                     as_;     // Address strobe
    reg                     rw;      // Read / Write
    reg  [`GPIO_ADDR_BUS]   addr;    // Address
    reg  [`WORD_DATA_BUS]   wr_data; // Write data
    wire [`WORD_DATA_BUS]   rd_data; // Read data
    wire                    rdy_;    // Ready
    /********** General Purpose Input/Output **********/
`ifdef GPIO_IN_CH    // Input Port Implementation
    reg  [`GPIO_IN_CH-1:0]  gpio_in; // Input Port?Control Register 0?
`endif
`ifdef GPIO_OUT_CH   // Output Port Implementation
    wire [`GPIO_OUT_CH-1:0] gpio_out;// Output Port ?Control Register1?
`endif
`ifdef GPIO_IO_CH    // Input/Output Port Implementation
    wire [`GPIO_IO_CH-1:0]  gpio_io; // Input/Output Port ?Control Register2?
`endif

    /******** Define Simulation Loop********/
    parameter             STEP = 10;

    /******** Generate Clock ********/
    always #(STEP / 2) begin
        clk <= ~clk;
    end

    assign clk_ = ~clk;

    reg  [`GPIO_IO_CH-1:0] gpio_io_in;
    reg                    gpio_io_oe; // Output enable
    assign gpio_io = ( gpio_io_oe == `GPIO_DIR_IN ) ? gpio_io_in : `GPIO_IO_CH'bz;

    gpio gpio(
        /********** Clock & Rest **********/
        .clk        (clk),      // Clock
        .reset      (reset),    // Rest
        /********** Bus Interface **********/
        .cs_        (cs_),      // Chip selection
        .as_        (as_),      // Address strobe
        .rw         (rw),       // Read / Write
        .addr       (addr),     // Address
        .wr_data    (wr_data),  // Write data
        .rd_data    (rd_data),  // Read data
        .rdy_       (rdy_),     // Ready
        /********** General Purpose Input/Output **********/
        .gpio_in    (gpio_in),  // Input Port  (Control Register 0)
        .gpio_out   (gpio_out), // Output Port (Control Register1)
        .gpio_io    (gpio_io)
    );


    task gpio_tb;
        input [`WORD_DATA_BUS]   _rd_data;  // Read data
        input                    _rdy_;     // Ready
        input [`GPIO_OUT_CH-1:0] _gpio_out; // Output Port (Control Register1)
        input [`GPIO_IO_CH-1:0]  _gpio_io;  // Input/Output Port (Control Register2)

        begin
            if( (rd_data  === _rd_data)  &&
                (rdy_     === _rdy_)     &&
                (gpio_out === _gpio_out) &&
                (gpio_io  === _gpio_io )
              ) begin
                $display("Test Succeeded !");
            end else begin
                $display("Test Failed !");
            end
        end
    endtask

    /******** Test Case ********/
    initial begin
        # 0 begin
            clk        <= 1'h1;
            reset      <= `ENABLE;
            gpio_io_oe <= `GPIO_DIR_OUT;
        end
        # (STEP * 3/4)
        # STEP begin
            /******** Initialize Test Output ********/
            $display("= Initialize Reset =");
            gpio_tb(`WORD_DATA_W'h0,         // rd_data
                    `DISABLE_,               // rdy_
                    `GPIO_OUT_CH'h0,         // gpio_out
                    `GPIO_IO_CH'bz           // gpio_io
            );

            reset   <= `DISABLE;
            cs_     <= `ENABLE_;
            as_     <= `ENABLE_;
            rw      <= `READ;
            addr    <= `GPIO_ADDR_IN_DATA;
            gpio_in <= `GPIO_IN_CH'ha;

        end
        # STEP begin
            $display("==== Clock  1 ====");
            /******** Read from GPIO Input Port Test Output ********/
            gpio_tb(`WORD_DATA_W'ha,         // rd_data
                    `ENABLE_,                // rdy_
                    `GPIO_OUT_CH'h0,         // gpio_out
                    `GPIO_IO_CH'bz           // gpio_io
            );

            rw      <= `WRITE;
            addr    <= `GPIO_ADDR_OUT_DATA;
            wr_data <= `WORD_DATA_W'h56;
        end
        #STEP begin
            /******** Write to GPIO Output Port Test Output ********/
            $display("==== Clock  2 ====");
            gpio_tb(`WORD_DATA_W'h0,         // rd_data
                    `ENABLE_,                // rdy_
                    `GPIO_OUT_CH'h56,        // gpio_out
                    `GPIO_IO_CH'bz           // gpio_io
            );

            rw      <= `READ;
            addr    <= `GPIO_ADDR_OUT_DATA;
        end
        #STEP begin
            /******** Read from GPIO Output Port Test Output ********/
            $display("==== Clock  3 ====");
            gpio_tb(`WORD_DATA_W'h56,        // rd_data
                    `ENABLE_,                // rdy_
                    `GPIO_OUT_CH'h56,        // gpio_out
                    `GPIO_IO_CH'bz           // gpio_io
            );

            addr       <= `GPIO_ADDR_IO_DATA;
            gpio_io_in <= `GPIO_IO_CH'h24;
            gpio_io_oe <= `GPIO_DIR_IN;

        end
        #STEP begin
            /******** Read from GPIO Input/Output Port Input Test Output ********/
            $display("==== Clock  4 ====");
            gpio_tb(`WORD_DATA_W'h24,        // rd_data
                    `ENABLE_,                // rdy_
                    `GPIO_OUT_CH'h56,        // gpio_out
                    `GPIO_IO_CH'h24          // gpio_io
            );

            rw         <= `WRITE;
            wr_data    <= `WORD_DATA_W'h59;
            gpio_io_oe <= `GPIO_DIR_OUT;
        end
        #STEP begin
            /******** Write to GPIO Input/Output Port Test Output ********/
            $display("==== Clock  5 ====");
            gpio_tb(`WORD_DATA_W'h0,         // rd_data
                    `ENABLE_,                // rdy_
                    `GPIO_OUT_CH'h56,        // gpio_out
                    `GPIO_IO_CH'bz           // gpio_io
            );

            addr    <= `GPIO_ADDR_IO_DIR;
            wr_data <= `GPIO_IO_CH'hffff;
        end
        #STEP begin
            /******** Set GPIO Input/Output Direction to Output Test Output ********/
            $display("==== Clock 6 ====");
            gpio_tb(`WORD_DATA_W'h0,         // rd_data
                    `ENABLE_,                // rdy_
                    `GPIO_OUT_CH'h56,        // gpio_out
                    `GPIO_IO_CH'h59          // gpio_io
            );

            rw <= `READ;
            addr <= `GPIO_ADDR_IO_DATA;
        end
        #STEP begin
            /******** Read from GPIO Input/Output Po Output Test Output ********/
            $display("==== Clock 7 ====");
            gpio_tb(`WORD_DATA_W'h59,        // rd_data
                    `ENABLE_,                // rdy_
                    `GPIO_OUT_CH'h56,        // gpio_out
                    `GPIO_IO_CH'h59          // gpio_io
            );

            $finish;
        end

    end

    /******** Output Waveform ********/
    initial begin
       $dumpfile("gpio.vcd");
       $dumpvars(0, gpio);
    end

endmodule
