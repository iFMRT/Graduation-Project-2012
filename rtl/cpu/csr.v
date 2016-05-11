/////////////////////////////////////////////////////////////////////
// Engineer:       Leway Colin - colin4124@gmail.com               //
//                                                                 //
// Additional contributions by:                                    //
//                 Beyond Sky - fan-dave@163.com                   //
//                 Kippy Chen - 799182081@qq.com                   //
//                 Junhao Chen                                     //
//                                                                 //
// Design Name:    Control and Status Registers                    //
// Project Name:   FMRT Mini Core                                  //
// Language:       Verilog                                         //
//                                                                 //
// Description:    Control and Status Registers (CSRs).            //
//                                                                 //
/////////////////////////////////////////////////////////////////////

`include "common_defines.v"
`include "base_core_defines.v"

module cs_registers (
    input                       clk,
    input                       reset,
    input [`CSR_OP_BUS]         csr_op,
    input [`CSR_ADDR_BUS]       csr_addr,
    output reg [`WORD_DATA_BUS] csr_rd_data,
    input [`WORD_DATA_BUS]      csr_wr_data_i,
    input [`WORD_DATA_BUS]      mepc_i,
    output reg [`WORD_DATA_BUS] mepc_o,
    input [`EXP_CODE_BUS]       exp_code_i,
    input                       save_exp_code,
    input                       save_exp,
    input                       restore_exp
);


    /******** Exception Control Logic ********/
    reg [`WORD_DATA_BUS] mepc_q, mepc_n;
    reg                  mestatus_ie_q, mestatus_ie_n;
    reg                  mstatus_ie_q, mstatus_ie_n;
    reg [`EXP_CODE_BUS]  exp_code_q, exp_code_n;

    /******** CSR Update Logic ********/
    reg [`WORD_DATA_BUS] csr_wr_data;
    reg                  csr_we;

    /******** Read Logic ********/
    always @ (*) begin
        csr_rd_data = `WORD_DATA_W'hx;
        mepc_o      = mepc_q;

        case (csr_addr)
            // mstatus: always M-mode, contains IE bit
            12'h300: csr_rd_data = {29'b0, 2'b11, mstatus_ie_q};

            // mepc: exception program counter
            12'h341: csr_rd_data = mepc_q;
            // mcause: exception cause
            12'h342: csr_rd_data = {exp_code_q[5], 26'b0, exp_code_q[4:0]};

            // mcpuid: RV32I
            12'hF00: csr_rd_data = 32'h00_00_01_00;
            // mimpid: anonymous source (no allocated ID yet)
            12'hF01: csr_rd_data = 32'h00_00_80_00;

            // mestatus
            12'h7C0: csr_rd_data = {29'b0, 2'b11, mestatus_ie_q};
        endcase
    end

    /******** CSR Operation Logic ********/
    always @ (*) begin
        csr_wr_data = csr_wr_data_i;
        csr_we      = `ENABLE;

        case (csr_op)
            `CSR_OP_WRITE: csr_wr_data = csr_wr_data_i;
            `CSR_OP_SET  : csr_wr_data = csr_wr_data_i | csr_rd_data;
            `CSR_OP_CLEAR: csr_wr_data = (~csr_wr_data_i) & csr_rd_data;

            `CSR_OP_NOP  : begin
                csr_wr_data = csr_wr_data_i;
                csr_we      = `DISABLE;
            end
        endcase
    end

    /********** Write Logic **********/
    always @ (*) begin
        mstatus_ie_n  = mstatus_ie_q;
        mepc_n        = mepc_q;
        exp_code_n    = exp_code_q;
        mestatus_ie_n = mestatus_ie_q;
        case (csr_addr)
            // mstatus: only IE bit is writable
            12'h300: if (csr_we)
                mstatus_ie_n  <= #1 csr_wr_data[0];

            // mepc: exception program counter
            12'h341: if (csr_we)
                mepc_n        <= #1 csr_wr_data;
            // mcause
            12'h342: if (csr_we)
                exp_code_n    <= #1 {csr_wr_data[5], csr_wr_data[4:0]};

            // mestatus: machine exception status
            12'h7C0: if (csr_we)
                mestatus_ie_n <= #1 csr_wr_data[0];
        endcase

        // save exception
        if (save_exp) begin
            exp_code_n    = exp_code_i;
            mepc_n        = mepc_i;
            mestatus_ie_n = mstatus_ie_q;
            mstatus_ie_n  = 1'b0;
        end

        // restore after handling exception
        if (restore_exp) begin
            mstatus_ie_n = mestatus_ie_q;
        end
    end

    /******** Actual Registers ********/
    always @(posedge clk) begin
        if (reset == `ENABLE) begin
            // Reset
            mstatus_ie_q  <= #1 `DISABLE;
            mepc_q        <= #1 `WORD_DATA_W'h0;
            exp_code_q    <= #1 `EXP_CODE_W'h0;
            mestatus_ie_q <= #1 `DISABLE;
        end else begin
            // update CSRs
            mstatus_ie_q  <= #1 mstatus_ie_n;
            mepc_q        <= #1 mepc_n;
            exp_code_q    <= #1 exp_code_n;
            mestatus_ie_q <= #1 mestatus_ie_n;
        end
    end

endmodule
