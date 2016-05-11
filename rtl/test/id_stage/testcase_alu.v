/******** Test Case ********/
initial begin

    # STEP begin
        $display("\n========= Clock 2 ========");
        id_stage_tb(
            `REG_ADDR_W'h0,                  // gpr_rs1_addr
            `REG_ADDR_W'h0,                  // gpr_rs2_addr
            `CSR_OP_NOP,                     // csr_op
            `CSR_ADDR_W'h0,                  // csr_addr
            `WORD_DATA_W'h0,                 // csr_wr_data
            `DISABLE,                        // id_is_jalr
            `EXP_CODE_W'0,                   // id_exp_code
            `WORD_DATA_W'h0,                 // id_pc
            `ENABLE,                         // id_en
            `ALU_OP_ADD,                     // id_alu_op
            `WORD_DATA_W'h0,                 // id_alu_in_0
            `WORD_DATA_W'h4,                 // id_alu_in_1
            `CMP_OP_NOP,                     // id_cmp_op
            `WORD_DATA_W'h0,                 // id_cmp_in_0
            `WORD_DATA_W'h4,                 // id_cmp_in_1
            `DISABLE,                        // id_jump_taken
            `MEM_OP_NOP,                     // id_mem_op
            `WORD_DATA_W'h4,                 // id_mem_wr_data
            `WORD_ADDR_W'h3,                 // id_rd_addr
            `ENABLE_,                        // id_gpr_we_
            `EX_OUT_ALU,                     // id_ex_out_sel
            `WORD_DATA_W'h0,                 // id_gpr_wr_data
            `DISABLE,                        // is_eret
            `OP_ALSI,                        // op
            `REG_ADDR_W'h0,                  // id_rs1_addr
            `REG_ADDR_W'h0,                  // id_rs2_addr
            `REG_ADDR_W'h0,                  // rs1_addr
            `REG_ADDR_W'h0,                  // rs2_addr
            2'b0                             // src_reg_used
        );
        end

end