////////////////////////////////////////////////////////////////////
// Engineer:       Leway Colin - colin4124@gmail.com               //
//                                                                 //
// Additional contributions by:                                    //
//                 Beyond Sky - fan-dave@163.com                   //
//                 Kippy Chen - 799182081@qq.com                   //
//                 Junhao Chen                                     //
//                                                                 //
// Design Name:    Main controller                                 //
// Project Name:   FMRT Mini Core                                  //
// Language:       Verilog                                         //
//                                                                 //
// Description:    Including core controller, stall controller,    //
//                 and exception controller.                       //
//                                                                 //
/////////////////////////////////////////////////////////////////////

`include "common_defines.v"
`include "base_core_defines.v"

module ctrl (
    /********* pipeline control signals ********/
    //  State of Pipeline
    input wire                  br_taken,    // branch hazard mark

    /********** Data Forward **********/
    input wire [1:0]            src_reg_used,

    // from ID stage
    input wire                  is_eret,

    // LOAD Hazard
    input wire                  id_en,       // Pipeline Register enable
    input wire [`REG_ADDR_BUS]  id_rd_addr, // GPR write address
    input wire                  id_gpr_we_,  // GPR write enable
    input wire [`MEM_OP_BUS]    id_mem_op,   // Mem operation

    input wire [`INSN_OP_BUS]   op,
    input wire [`REG_ADDR_BUS]  rs1_addr,
    input wire [`REG_ADDR_BUS]  rs2_addr,
    // LOAD STORE Forward
    input wire [`REG_ADDR_BUS]  id_rs1_addr,
    input wire [`REG_ADDR_BUS]  id_rs2_addr,

    input wire                  ex_en,       // Pipeline Register enable
    input wire [`REG_ADDR_BUS]  ex_rd_addr, // GPR write address
    input wire                  ex_gpr_we_,  // GPR write enable
    input wire [`MEM_OP_BUS]    ex_mem_op,   // Mem operation

    // from MEM stage
    input wire [`WORD_DATA_BUS] mem_pc,
    input wire                  mem_en,
    input wire [`EXP_CODE_BUS]  mem_exp_code,

    // from CSR
    input wire [`WORD_DATA_BUS] mepc_i,

    // to CSR
    output reg [`WORD_DATA_BUS] mepc_o,
    output reg [`EXP_CODE_BUS]  exp_code,
    output reg                  save_exp,
    output reg                  restore_exp,

    // Stall Signal
    output wire                 if_stall,    // IF stage stall
    output wire                 id_stall,    // ID stage stall
    output wire                 ex_stall,    // EX stage stall
    output wire                 mem_stall,   // MEM stage stall
    // Flush Signal
    output wire                 if_flush,    // IF stage flush
    output wire                 id_flush,    // ID stage flush
    output wire                 ex_flush,    // EX stage Flush
    output wire                 mem_flush,   // MEM stage flush
    output reg [`WORD_DATA_BUS] new_pc,      // New program counter

    // Forward from EX stage

    /********** Forward Output **********/
    output reg [`FWD_CTRL_BUS]  rs1_fwd_ctrl,
    output reg [`FWD_CTRL_BUS]  rs2_fwd_ctrl,
    output reg                  ex_rs1_fwd_en,
    output reg                  ex_rs2_fwd_en
);

    reg     ld_hazard;       // LOAD hazard

    /********** pipeline control **********/
    // stall
    assign if_stall  = ld_hazard;
    assign id_stall  = `DISABLE;
    assign ex_stall  = `DISABLE;
    assign mem_stall = `DISABLE;

    // flush
    reg    flush, eret_flush;
    assign if_flush  = flush | eret_flush;
    assign id_flush  = flush | ld_hazard | br_taken;
    assign ex_flush  = flush;
    assign mem_flush = flush;

    /********** Forward **********/
    always @(*) begin
        /* Forward Ra */
        if( (id_en           == `ENABLE)  &&
            (id_gpr_we_      == `ENABLE_) &&
            (src_reg_used[0] == 1'b1)     &&   // use ra register
            (rs1_addr         != 1'b0)     &&   // r0 always is 0, no need to forward
            (id_rd_addr     == rs1_addr)
        ) begin
            rs1_fwd_ctrl = `FWD_CTRL_EX;        // Forward from EX stage
        end else if (
            (ex_en           == `ENABLE)  &&
            (ex_gpr_we_      == `ENABLE_) &&
            (src_reg_used[0] == 1'b1)     &&   // use ra register
            (rs1_addr         != 1'b0)     &&   // r0 always is 0, no need to forward
            (ex_rd_addr     == rs1_addr)
        ) begin
            rs1_fwd_ctrl = `FWD_CTRL_MEM;       // Forward from MEM stage
        end else begin
            rs1_fwd_ctrl = `FWD_CTRL_NONE;      // Don't need forward
        end

        /* LOAD in MEM and STORE in EX may need forward */
        if ((ex_en           == `ENABLE)  &&
            (ex_gpr_we_      == `ENABLE_) &&
            (ex_mem_op[3]    == 1'b1)     &&   // Check LOAD  in MEM, LOAD  Mem Op 1XXX
            (id_mem_op[3:2]  == 2'b01)    &&   // Check STORE in EX, STORE Mem Op 01XX
            (id_rs1_addr      != 1'b0)     &&   // r0 always is 0, no need to forward
            (ex_rd_addr     == id_rs1_addr)
        ) begin
            ex_rs1_fwd_en = `ENABLE;
        end else begin
            ex_rs1_fwd_en = `DISABLE;
        end

        /* Forward Rb */
        if ((id_en           == `ENABLE)  &&
            (id_gpr_we_      == `ENABLE_) &&
            (src_reg_used[1] == 1'b1)     && // use rb register
            (rs2_addr         != 1'b0)     &&   // r0 always is 0, no need to forward
            (id_rd_addr     == rs2_addr)
        ) begin
            rs2_fwd_ctrl = `FWD_CTRL_EX;        // Forward from EX stage
        end else if (
            (ex_en           == `ENABLE)  &&
            (ex_gpr_we_      == `ENABLE_) &&
            (src_reg_used[1] == 1'b1)     && // use rb register
            (rs2_addr         != 1'b0)     &&   // r0 always is 0, no need to forward
            (ex_rd_addr     == rs2_addr)
        ) begin
            rs2_fwd_ctrl = `FWD_CTRL_MEM;       // Forward from MEM stage
        end else begin
            rs2_fwd_ctrl  = `FWD_CTRL_NONE ;    // Don't need forward
        end

        /* LOAD in MEM and STORE in EX may need forward */
        if ((ex_en           == `ENABLE)  &&
            (ex_gpr_we_      == `ENABLE_) &&
            (ex_mem_op[3]    == 1'b1)     &&   // Check LOAD  in MEM, LOAD  Mem Op 1XXX
            (id_mem_op[3:2]  == 2'b01)    &&   // Check STORE in EX, STORE Mem Op 01XX
            (id_rs2_addr     != 1'b0)     &&   // r0 always is 0, no need to forward
            (ex_rd_addr     == id_rs2_addr)
        ) begin
            ex_rs2_fwd_en = `ENABLE;
        end else begin
            ex_rs2_fwd_en = `DISABLE;
        end

    end

    /********** Check Load hazard **********/
    always @(*) begin
        if ((id_en        == `ENABLE)         &&
            (id_gpr_we_   == `ENABLE_)        &&   // load must enable id_gpr_we_
            (id_mem_op[3] == 1'b1)            &&   // Check load in EX
            (   (op    != `OP_ST) ||
                ( (op  == `OP_ST)  && (id_rd_addr == rs1_addr) )
            )                                 &&   // store in ID may need stall
            (   ( (src_reg_used[0] == 1'b1) && (id_rd_addr == rs1_addr) ) ||
                ( (src_reg_used[1] == 1'b1) && (id_rd_addr == rs2_addr) )
            )
        ) begin
            ld_hazard = `ENABLE;  // Need Load hazard
        end else begin
            ld_hazard = `DISABLE; // Don't nedd Load hazard
        end
    end

    /********** Exception Controller **********/
    always @(*) begin
        /* Default */
        new_pc      = `WORD_ADDR_W'h0;
        flush       = `DISABLE;
        save_exp    = `DISABLE;
        exp_code    = `EXP_NO_EXP;
        mepc_o      = `WORD_DATA_W'h0;
        restore_exp = `DISABLE;
        eret_flush  = `DISABLE;

        if (mem_en == `ENABLE) begin
            if (mem_exp_code != `EXP_NO_EXP) begin // Exception occur
                new_pc   = `EXP_ENTRY_ADDR;        // Unified entry address
                flush    = `ENABLE;
                save_exp = `ENABLE;
                exp_code = mem_exp_code;
                mepc_o   = mem_pc;
            end else if (is_eret) begin            // EXRT instruction
                new_pc      = mepc_i;
                restore_exp = `ENABLE;
                eret_flush  = `ENABLE;
            end
        end
    end

endmodule
