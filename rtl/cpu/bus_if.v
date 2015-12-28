`include "stddef.h"
`include "cpu.h"

module bus_if (
    /********** Clock & Reset **********/
    // input             clk,         // clock
    // input             reset,       // Asynchronous Reset
    /********** Pipeline Control Signal **********/
    input             stall,       // Stall
    input             flush,       // Flush signal
    // output reg        busy,        // Bus busy signal
    /************* CPU Interface *************/
    input [29:0]      addr,        // Address
    input             as_,         // Address strobe
    input             rw,          // Read/Write
    input [31:0]      wr_data,     // Write data
    output reg [31:0] rd_data,     // Read data
    /************* SPM Interface *************/
    input [31:0]      spm_rd_data,
    output [29:0]     spm_addr,
    output reg        spm_as_,
    output            spm_rw,
    output [31:0]     spm_wr_data
    /********** Bus Interface **********/
    // input  wire [`WordDataBus] bus_rd_data,    // Read data
    // input  wire                bus_rdy_,       // ready
    // input  wire                bus_grnt_,      // Grant
    // output reg                 bus_req_,       // Request
    // output reg  [`WordAddrBus] bus_addr,       // Addresee
    // output reg                 bus_as_,        // Address Strobe
    // output reg                 bus_rw,         // Read/Write
    // output reg  [`WordDataBus] bus_wr_data     // Write data
);
    
    /********** Internal Signal **********/
    // reg  [`BusIfStateBus]      state;          // Bus interface state
    // reg  [`WordDataBus]        rd_buf;         // Read buffer
    // wire [`BusSlaveIndexBus]   s_index;        // Bus slave index

    /********** Generate Bus Slave Index **********/
    // assign s_index     = addr[`BusSlaveIndexLoc];


    /********** Output Assignment **********/
    assign spm_addr    = addr;
    assign spm_rw      = rw;
    assign spm_wr_data = wr_data;

    /********* Memory Access Control *********/
    always @(*) begin
        /* Memory Access */
        if ((flush == `DISABLE) &&
            (stall == `DISABLE) &&
            (as_ == `ENABLE_)
           ) begin
            spm_as_ = `ENABLE_;

            if (rw == `READ) begin  // Read Access
                rd_data    = spm_rd_data;
            end
        end else begin
            /* Default Value */
            rd_data = 32'h0;
            spm_as_ = `DISABLE_;
        end
    end

    /********** Control Bus Interface State **********/ 
   // always @(posedge clk or `RESET_EDGE reset) begin
   //      if (reset == `RESET_ENABLE) begin
   //          /* Asynchronous Reset */
   //          state       <= #1 `BUS_IF_STATE_IDLE;
   //          bus_req_    <= #1 `DISABLE_;
   //          bus_addr    <= #1 `WORD_ADDR_W'h0;
   //          bus_as_     <= #1 `DISABLE_;
   //          bus_rw      <= #1 `READ;
   //          bus_wr_data <= #1 `WORD_DATA_W'h0;
   //          rd_buf      <= #1 `WORD_DATA_W'h0;
   //      end else begin
   //          /* Bus Interface State */
   //          case (state)
   //              `BUS_IF_STATE_IDLE   : begin // Idle
   //                  /* Memory Access */
   //                  if ((flush == `DISABLE) && (as_ == `ENABLE_)) begin 
   //                      /* Select Access Target */
   //                      if (s_index != `BUS_SLAVE_1) begin // Access bus
   //                          state       <= #1 `BUS_IF_STATE_REQ;
   //                          bus_req_    <= #1 `ENABLE_;
   //                          bus_addr    <= #1 addr;
   //                          bus_rw      <= #1 rw;
   //                          bus_wr_data <= #1 wr_data;
   //                      end
   //                  end
   //              end
   //              `BUS_IF_STATE_REQ    : begin // Request bus
   //                  /* Waitting for Bus Grant */
   //                  if (bus_grnt_ == `ENABLE_) begin // Request Bus Permission
   //                      state       <= #1 `BUS_IF_STATE_ACCESS;
   //                      bus_as_     <= #1 `ENABLE_;
   //                  end
   //              end
   //              `BUS_IF_STATE_ACCESS : begin // Access bus
   //                  /* Disable  Address Strobe*/
   //                  bus_as_     <= #1 `DISABLE_;
   //                  /* Waitting for Ready Signal */
   //                  if (bus_rdy_ == `ENABLE_) begin  // Ready signal available
   //                      bus_req_    <= #1 `DISABLE_;
   //                      bus_addr    <= #1 `WORD_ADDR_W'h0;
   //                      bus_rw      <= #1 `READ;
   //                      bus_wr_data <= #1 `WORD_DATA_W'h0;
   //                      /* Save Read Data */
   //                      if (bus_rw == `READ) begin  // Read access
   //                          rd_buf      <= #1 bus_rd_data;
   //                      end
   //                      /* Check Stall */
   //                      if (stall == `ENABLE) begin // Stall occur
   //                          state       <= #1 `BUS_IF_STATE_STALL;
   //                      end else begin              // Stall don't occur
   //                          state       <= #1 `BUS_IF_STATE_IDLE;
   //                      end
   //                  end
   //              end
   //              `BUS_IF_STATE_STALL  : begin // Stall
   //                  /* Check Stall */
   //                  if (stall == `DISABLE) begin    // Remove stall
   //                      state       <= #1 `BUS_IF_STATE_IDLE;
   //                  end
   //              end
   //          endcase
   //      end
   //  end
endmodule
