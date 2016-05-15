/******** Test Case ********/
initial begin

    # STEP begin
        $display("\n========= Clock 2 ========");
        cpu_top_tb(
            `WORD_DATA_W'h0,                 // gpr_rs1_data
            `WORD_DATA_W'hx,                 // gpr_rs2_data
            `REG_ADDR_W'h0,                  // gpr_rs1_addr
            `REG_ADDR_W'h1,                  // gpr_rs2_addr
            `REG_ADDR_W'h0,                  // mem_rd_addr
            `WORD_DATA_W'h0                  // mem_out
        );
        end

    # STEP begin
        $display("\n========= Clock 3 ========");
        cpu_top_tb(
            `WORD_DATA_W'h0,                 // gpr_rs1_data
            `WORD_DATA_W'hx,                 // gpr_rs2_data
            `REG_ADDR_W'h0,                  // gpr_rs1_addr
            `REG_ADDR_W'd2,                  // gpr_rs2_addr
            `REG_ADDR_W'h0,                  // mem_rd_addr
            `WORD_DATA_W'h0                  // mem_out
        );
        end

    # STEP begin
        $display("\n========= Clock 4 ========");
        cpu_top_tb(
            `WORD_DATA_W'dx,                 // gpr_rs1_data
            `WORD_DATA_W'dx,                 // gpr_rs2_data
            `REG_ADDR_W'd26,                 // gpr_rs1_addr
            `REG_ADDR_W'd27,                 // gpr_rs2_addr
            `REG_ADDR_W'h0,                  // mem_rd_addr
            `WORD_DATA_W'h0                  // mem_out
        );
        end

    # STEP begin
        $display("\n========= Clock 5 ========");
        cpu_top_tb(
            `WORD_DATA_W'd1025,              // gpr_rs1_data
            `WORD_DATA_W'dx,                 // gpr_rs2_data
            `REG_ADDR_W'd26,                 // gpr_rs1_addr
            `REG_ADDR_W'd4,                  // gpr_rs2_addr
            `REG_ADDR_W'd26,                 // mem_rd_addr
            `WORD_DATA_W'd1025               // mem_out
        );
        end

    # STEP begin
        $display("\n========= Clock 6 ========");
        cpu_top_tb(
            `WORD_DATA_W'd0,                 // gpr_rs1_data
            `WORD_DATA_W'dx,                 // gpr_rs2_data
            `REG_ADDR_W'd0,                  // gpr_rs1_addr
            `REG_ADDR_W'd20,                 // gpr_rs2_addr
            `REG_ADDR_W'd27,                 // mem_rd_addr
            `WORD_DATA_W'd2                  // mem_out
        );
        end

    # STEP begin
        $display("\n========= Clock 7 ========");
        cpu_top_tb(
            `WORD_DATA_W'd2,                 // gpr_rs1_data
            `WORD_DATA_W'd1025,              // gpr_rs2_data
            `REG_ADDR_W'd27,                 // gpr_rs1_addr
            `REG_ADDR_W'd26,                 // gpr_rs2_addr
            `REG_ADDR_W'd12,                 // mem_rd_addr
            `WORD_DATA_W'd20                 // mem_out
        );
        end

    # STEP begin
        $display("\n========= Clock 8 ========");
        cpu_top_tb(
            `WORD_DATA_W'd0,                 // gpr_rs1_data
            `WORD_DATA_W'd0,                 // gpr_rs2_data
            `REG_ADDR_W'd0,                  // gpr_rs1_addr
            `REG_ADDR_W'd0,                  // gpr_rs2_addr
            `REG_ADDR_W'd27,                 // mem_rd_addr
            `WORD_DATA_W'd1029               // mem_out
        );
        end

    # STEP begin
        $display("\n========= Clock 9 ========");
        cpu_top_tb(
            `WORD_DATA_W'd1025,              // gpr_rs1_data
            `WORD_DATA_W'd1025,              // gpr_rs2_data
            `REG_ADDR_W'd26,                 // gpr_rs1_addr
            `REG_ADDR_W'd26,                 // gpr_rs2_addr
            `REG_ADDR_W'd0,                  // mem_rd_addr
            `WORD_DATA_W'd20                 // mem_out
        );
        end

    # STEP begin
        $display("\n========= Clock 10 ========");
        cpu_top_tb(
            `WORD_DATA_W'd1025,              // gpr_rs1_data
            `WORD_DATA_W'dx,                 // gpr_rs2_data
            `REG_ADDR_W'd26,                 // gpr_rs1_addr
            `REG_ADDR_W'd3,                  // gpr_rs2_addr
            `REG_ADDR_W'd0,                  // mem_rd_addr
            `WORD_DATA_W'd0                  // mem_out
        );
        end

    # STEP begin
        $display("\n========= Clock 11 ========");
        cpu_top_tb(
            `WORD_DATA_W'd1025,              // gpr_rs1_data
            `WORD_DATA_W'dx,                 // gpr_rs2_data
            `REG_ADDR_W'd26,                 // gpr_rs1_addr
            `REG_ADDR_W'd3,                  // gpr_rs2_addr
            `REG_ADDR_W'd0,                  // mem_rd_addr
            `WORD_DATA_W'd0                  // mem_out
        );
        end

    # STEP begin
        $display("\n========= Clock 12 ========");
        cpu_top_tb(
            `WORD_DATA_W'd1025,              // gpr_rs1_data
            `WORD_DATA_W'd1029,              // gpr_rs2_data
            `REG_ADDR_W'd26,                 // gpr_rs1_addr
            `REG_ADDR_W'd27,                 // gpr_rs2_addr
            `REG_ADDR_W'd3,                  // mem_rd_addr
            `WORD_DATA_W'd0                  // mem_out
        );
        end

    # STEP begin
        $display("\n========= Clock 13 ========");
        cpu_top_tb(
            `WORD_DATA_W'd0,                 // gpr_rs1_data
            `WORD_DATA_W'hx,                 // gpr_rs2_data
            `REG_ADDR_W'd0,                  // gpr_rs1_addr
            `REG_ADDR_W'd14,                 // gpr_rs2_addr
            `REG_ADDR_W'd27,                 // mem_rd_addr
            `WORD_DATA_W'd1                  // mem_out
        );
        end

    # STEP begin
        $display("\n========= Clock 14 ========");
        cpu_top_tb(
            `WORD_DATA_W'd1025,              // gpr_rs1_data
            `WORD_DATA_W'hx,                 // gpr_rs2_data
            `REG_ADDR_W'd26,                 // gpr_rs1_addr
            `REG_ADDR_W'd28,                 // gpr_rs2_addr
            `REG_ADDR_W'd30,                 // mem_rd_addr
            `WORD_DATA_W'd1025               // mem_out
        );
        end

    # STEP begin
        $display("\n========= Clock 15 ========");
        cpu_top_tb(
            `WORD_DATA_W'd1,                 // gpr_rs1_data
            `WORD_DATA_W'd1026,              // gpr_rs2_data
            `REG_ADDR_W'd27,                 // gpr_rs1_addr
            `REG_ADDR_W'd29,                 // gpr_rs2_addr
            `REG_ADDR_W'd29,                 // mem_rd_addr
            `WORD_DATA_W'd1026               // mem_out
        );
        end

    # STEP begin
        $display("\n========= Clock 16 ========");
        cpu_top_tb(
            `WORD_DATA_W'h1,                 // gpr_rs1_data
            `WORD_DATA_W'd1025,              // gpr_rs2_data
            `REG_ADDR_W'd27,                 // gpr_rs1_addr
            `REG_ADDR_W'd30,                 // gpr_rs2_addr
            `REG_ADDR_W'd28,                 // mem_rd_addr
            `WORD_DATA_W'd14                 // mem_out
        );
        end

    # STEP begin
        $display("\n========= Clock 17 ========");
        cpu_top_tb(
            `WORD_DATA_W'd1025,              // gpr_rs1_data
            `WORD_DATA_W'dx,                 // gpr_rs2_data
            `REG_ADDR_W'd26,                 // gpr_rs1_addr
            `REG_ADDR_W'd3,                  // gpr_rs2_addr
            `REG_ADDR_W'd30,                 // mem_rd_addr
            `WORD_DATA_W'd1039               // mem_out
        );
        end

    # STEP begin
        $display("\n========= Clock 18 ========");
        cpu_top_tb(
            `WORD_DATA_W'h0,                 // gpr_rs1_data
            `WORD_DATA_W'd0,                 // gpr_rs2_data
            `REG_ADDR_W'd0,                  // gpr_rs1_addr
            `REG_ADDR_W'd0,                  // gpr_rs2_addr
            `REG_ADDR_W'd27,                 // mem_rd_addr
            `WORD_DATA_W'd1027               // mem_out
        );
        end

    # STEP begin
        $display("\n========= Clock 19 ========");
        cpu_top_tb(
            `WORD_DATA_W'd1027,              // gpr_rs1_data
            `WORD_DATA_W'd1026,              // gpr_rs2_data
            `REG_ADDR_W'd27,                 // gpr_rs1_addr
            `REG_ADDR_W'd29,                 // gpr_rs2_addr
            `REG_ADDR_W'd12,                 // mem_rd_addr
            `WORD_DATA_W'd76                 // mem_out
        );
        end

    # STEP begin
        $display("\n========= Clock 20 ========");
        cpu_top_tb(
            `WORD_DATA_W'd1026,              // gpr_rs1_data
            `WORD_DATA_W'd14,                // gpr_rs2_data
            `REG_ADDR_W'd29,                 // gpr_rs1_addr
            `REG_ADDR_W'd28,                 // gpr_rs2_addr
            `REG_ADDR_W'd0,                  // mem_rd_addr
            `WORD_DATA_W'd0                  // mem_out
        );
        end

    # STEP begin
        $display("\n========= Clock 21 ========");
        cpu_top_tb(
            `WORD_DATA_W'd1027,              // gpr_rs1_data
            `WORD_DATA_W'd1026,              // gpr_rs2_data
            `REG_ADDR_W'd27,                 // gpr_rs1_addr
            `REG_ADDR_W'd29,                 // gpr_rs2_addr
            `REG_ADDR_W'd0,                  // mem_rd_addr
            `WORD_DATA_W'd0                  // mem_out
        );
        end

    # STEP begin
        $display("\n========= Clock 22 ========");
        cpu_top_tb(
            `WORD_DATA_W'd0,                 // gpr_rs1_data
            `WORD_DATA_W'd0,                 // gpr_rs2_data
            `REG_ADDR_W'd0,                  // gpr_rs1_addr
            `REG_ADDR_W'd0,                  // gpr_rs2_addr
            `REG_ADDR_W'd27,                 // mem_rd_addr
            `WORD_DATA_W'd2053               // mem_out
        );
        end

    # STEP begin
        $display("\n========= Clock 23 ========");
        cpu_top_tb(
            `WORD_DATA_W'd1026,              // gpr_rs1_data
            `WORD_DATA_W'd14,                // gpr_rs2_data
            `REG_ADDR_W'd29,                 // gpr_rs1_addr
            `REG_ADDR_W'd28,                 // gpr_rs2_addr
            `REG_ADDR_W'd12,                 // mem_rd_addr
            `WORD_DATA_W'd92                 // mem_out
        );
        end

    # STEP begin
        $display("\n========= Clock 24 ========");
        cpu_top_tb(
            `WORD_DATA_W'd1026,              // gpr_rs1_data
            `WORD_DATA_W'd14,                // gpr_rs2_data
            `REG_ADDR_W'd29,                 // gpr_rs1_addr
            `REG_ADDR_W'd28,                 // gpr_rs2_addr
            `REG_ADDR_W'd0,                  // mem_rd_addr
            `WORD_DATA_W'd0                  // mem_out
        );
        end

    # STEP begin
        $display("\n========= Clock 25 ========");
        cpu_top_tb(
            `WORD_DATA_W'd1025,              // gpr_rs1_data
            `WORD_DATA_W'd14,                // gpr_rs2_data
            `REG_ADDR_W'd26,                 // gpr_rs1_addr
            `REG_ADDR_W'd28,                 // gpr_rs2_addr
            `REG_ADDR_W'd0,                  // mem_rd_addr
            `WORD_DATA_W'd0                  // mem_out
        );
        end

    # STEP begin
        $display("\n========= Clock 26 ========");
        cpu_top_tb(
            `WORD_DATA_W'h0,                 // gpr_rs1_data
            `WORD_DATA_W'h0,                 // gpr_rs2_data
            `REG_ADDR_W'h0,                  // gpr_rs1_addr
            `REG_ADDR_W'h0,                  // gpr_rs2_addr
            `REG_ADDR_W'd12,                 // mem_rd_addr
            `WORD_DATA_W'd104                // mem_out
        );
        end

    # STEP begin
        $display("\n========= Clock 27 ========");
        cpu_top_tb(
            `WORD_DATA_W'd2053,              // gpr_rs1_data
            `WORD_DATA_W'd1026,              // gpr_rs2_data
            `REG_ADDR_W'd27,                 // gpr_rs1_addr
            `REG_ADDR_W'd29,                 // gpr_rs2_addr
            `REG_ADDR_W'd12,                 // mem_rd_addr
            `WORD_DATA_W'd108                // mem_out
        );
        end

end