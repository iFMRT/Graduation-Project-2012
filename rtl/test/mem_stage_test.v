`timescale 1ns/1ps

`include "stddef.h"
`include "cpu.h"
`include "mem.h"

module mem_stage_test;
    /******** Clock & Reset ********/
    reg                   clk;            // Clock
    reg                   reset;          // Asynchronous reset
    /********** Pipeline Control Signal **********/
    reg                   stall;          // Stall
    reg                   flush;          // Flush
    /******** SPM Interface ********/
    reg [`WORD_DATA_BUS]  spm_rd_data;    // SPM: Read data
    wire [`WORD_ADDR_BUS] spm_addr;       // SPM: Address
    wire                  spm_as_;        // SPM: Address Strobe
    wire                  spm_rw;         // SPM: Read/Write
    wire [`WORD_DATA_BUS] spm_wr_data;    // SPM: Write data
    /********** EX/MEM Pipeline Register **********/
    reg                   ex_en;          // If Pipeline data enable
    reg [`MEM_OP_BUS]     ex_mem_op;      // Memory operation
    reg [`WORD_DATA_BUS]  ex_mem_wr_data; // Memory write data
    reg [`REG_ADDR_BUS]   ex_dst_addr;    // General purpose register write address
    reg                   ex_gpr_we_;     // General purpose register enable
    reg [`WORD_DATA_BUS]  ex_out;         // EX stage operating result
    /********** MEM/WB Pipeline Register **********/
    wire                  mem_en;         // If Pipeline data enables
    wire [`REG_ADDR_BUS]  mem_dst_addr;
    wire                  mem_gpr_we_;
    wire [`WORD_DATA_BUS] mem_out;        // MEM stage operating result

    /******** Define Simulation Loop********/
    parameter             STEP = 10;

    /******** Generate Clock ********/
    always #(STEP / 2) begin
        clk <= ~clk;
    end

    /******** Instantiate Test Module ********/
    mem_stage mem_stage(
        // Clock & Reset
        .clk(clk),                      // Clock
        .reset(reset),                  // Reset
        /********** Pipeline Control Signal **********/
        .stall(stall),                  // Stall
        .flush(flush),                  // Flush
        /********** SPM Interface **********/
        .spm_rd_data(spm_rd_data),
        .spm_addr(spm_addr),
        .spm_as_(spm_as_),
        .spm_rw(spm_rw),
        .spm_wr_data(spm_wr_data),
        /********* EX/MEM Pipeline Register *********/
        .ex_en(ex_en),          // If Pipeline data enable
        .ex_mem_op(ex_mem_op),
        .ex_mem_wr_data(ex_mem_wr_data),
        .ex_dst_addr(ex_dst_addr),
        .ex_gpr_we_(ex_gpr_we_),
        .ex_out(ex_out),
        /********** MEM/WB Pipeline Register **********/
        .mem_en(mem_en),         // If Pipeline data enables
        .mem_dst_addr(mem_dst_addr),
        .mem_gpr_we_(mem_gpr_we_),
        .mem_out(mem_out)
    );

    /******** Test Case ********/
    initial begin
        # 0 begin
            // Case: read the value 41a4d9 from address 0x154
            /******** Initialize Test Input********/
            clk            <= 1'h1;
            reset          <= `ENABLE;
            stall          <= `DISABLE;
            flush          <= `DISABLE;
            spm_rd_data    <= `WORD_DATA_W'h41a4d9;
            ex_en          <= `ENABLE;
            ex_mem_op      <= `MEM_OP_LW;       // when `MEM_OP_LW, vvp will be infinite loop!
            ex_mem_wr_data <= `WORD_DATA_W'h999; // don't care, e.g: 0x999
            ex_dst_addr    <= `REG_ADDR_W'h7;    // don't care, e.g: 0x7
            ex_gpr_we_     <= `DISABLE_;
            ex_out         <= `WORD_DATA_W'h154;
        end
        # (STEP * 3/4)
        # STEP begin
            /******** Initialize Test Output ********/
            if ( (spm_addr     == `WORD_ADDR_W'h55)     &&
                 (spm_as_      == `ENABLE_)             &&
                 (spm_rw       == `READ)                &&
                 (spm_wr_data  == `WORD_DATA_W'h999)    &&
                 (mem_en       == `DISABLE)             &&
                 (mem_dst_addr == `REG_ADDR_W'h0)       &&
                 (mem_gpr_we_  == `DISABLE_)            &&
                 (mem_out      == `WORD_DATA_W'h0)
               ) begin
                $display("MEM Stage Initialize Test Succeeded !");
            end else begin
                $display("MEM Stage Initialize Test Failed !");
            end
            // Case: read the word 0x41a4d9 from address 0x154
            /******** Read a Word(align) Test Input ********/
            reset          <= `DISABLE;
        end
        # STEP begin
            /******** Read a Word(align) Test Output ********/
            if ( (spm_addr     == `WORD_ADDR_W'h55)     &&
                 (spm_as_      == `ENABLE_)             &&
                 (spm_rw       == `READ)                &&
                 (spm_wr_data  == `WORD_DATA_W'h999)    &&
                 (mem_en       == ex_en)                &&
                 (mem_dst_addr == `REG_ADDR_W'h7)       &&
                 (mem_gpr_we_  == `DISABLE_)            &&
                 (mem_out      == `WORD_DATA_W'h41a4d9)
               ) begin
                $display("MEM Stage Read a Word(align) Test Succeeded !");
            end else begin
                $display("MEM Stage Read a Word(align) Test Failed !");
            end
            // Case: read a half word 0xa4d9 from address 0x154
            /******** Read a Signed Half Word(align) Test Input ********/
            ex_mem_op      <= `MEM_OP_LH;
        end 
        # STEP begin
            /******** Read a Signed Half Word(align) Test Output ********/
            if ( (spm_addr     == `WORD_ADDR_W'h55)     &&
                 (spm_as_      == `ENABLE_)             &&
                 (spm_rw       == `READ)                &&
                 (spm_wr_data  == `WORD_DATA_W'h999)    &&
                 (mem_en       == ex_en)                &&
                 (mem_dst_addr == `REG_ADDR_W'h7)       &&
                 (mem_gpr_we_  == `DISABLE_)            &&
                 (mem_out      == `WORD_DATA_W'hffffa4d9)
               ) begin
                $display("MEM Stage Read a Signed Half Word(align) Test Succeeded !");
            end else begin
                $display("MEM Stage Read a Signed Half Word(align) Test Failed !");
            end
            // Case: read a half word 0xa4d9 from address 0x154
            /******** Read a Half Word(align) Test Input ********/
            ex_mem_op      <= `MEM_OP_LHU;
        end 
        # STEP begin
            /******** Read a Unsigned Half Word(align) Test Output ********/
            if ( (spm_addr     == `WORD_ADDR_W'h55)     &&
                 (spm_as_      == `ENABLE_)             &&
                 (spm_rw       == `READ)                &&
                 (spm_wr_data  == `WORD_DATA_W'h999)    &&
                 (mem_en       == ex_en)                &&
                 (mem_dst_addr == `REG_ADDR_W'h7)       &&
                 (mem_gpr_we_  == `DISABLE_)            &&
                 (mem_out      == `WORD_DATA_W'ha4d9)
               ) begin
                $display("MEM Stage Read a Unsigned Half Word(align) Test Succeeded !");
            end else begin
                $display("MEM Stage Read a Unsigned Half Word(align) Test Failed !");
            end
            // Case: read a byte 0xd9 from address 0x154
            /******** Read a Signed Byte Test Input ********/
            ex_mem_op      <= `MEM_OP_LB;
        end
        # STEP begin
            /******** Read a Signed Byte Test Output ********/
            if ( (spm_addr     == `WORD_ADDR_W'h55)     &&
                 (spm_as_      == `ENABLE_)             &&
                 (spm_rw       == `READ)                &&
                 (spm_wr_data  == `WORD_DATA_W'h999)    &&
                 (mem_en       == ex_en)                &&
                 (mem_dst_addr == `REG_ADDR_W'h7)       &&
                 (mem_gpr_we_  == `DISABLE_)            &&
                 (mem_out      == `WORD_DATA_W'hffffffd9)
               ) begin
                $display("MEM Stage Read a Signed Byte Test Succeeded !");
            end else begin
                $display("MEM Stage Read a Signed Byte Test Failed !");
            end
            // Case: read a byte 0xd9 from address 0x154
            /******** Read a Unsigned Byte Test Input ********/
            ex_mem_op      <= `MEM_OP_LBU;
        end
        # STEP begin
            /******** Read a Unsigned Byte Test Output ********/
            if ( (spm_addr     == `WORD_ADDR_W'h55)     &&
                 (spm_as_      == `ENABLE_)             &&
                 (spm_rw       == `READ)                &&
                 (spm_wr_data  == `WORD_DATA_W'h999)    &&
                 (mem_en       == ex_en)                &&
                 (mem_dst_addr == `REG_ADDR_W'h7)       &&
                 (mem_gpr_we_  == `DISABLE_)            &&
                 (mem_out      == `WORD_DATA_W'hd9)
               ) begin
                $display("MEM Stage Read a Unsigned Byte Test Succeeded !");
            end else begin
                $display("MEM Stage Read a Unsigned Byte Test Failed !");
            end
            // Case: read the value 0x41a4d9 from address 0x59
            /******** Read a Word(miss align) Test Input ********/
            ex_mem_op      <= `MEM_OP_LW;
            ex_out         <= `WORD_DATA_W'h59;
        end
        # STEP begin
            /******** Read a Word(miss align) Test Output ********/
            if ( (spm_addr     == `WORD_ADDR_W'h16)     &&
                 (spm_as_      == `DISABLE_)            &&
                 (spm_rw       == `READ)                &&
                 (spm_wr_data  == `WORD_DATA_W'h999)    &&
                 (mem_en       == ex_en)                &&
                 (mem_dst_addr == `REG_ADDR_W'h0)       &&
                 (mem_gpr_we_  == `DISABLE_)            &&
                 (mem_out      == `WORD_DATA_W'h0)
               ) begin
                $display("MEM Stage Read a Word(miss align) Test Succeeded !");
            end else begin
                $display("MEM Stage Read a Word(miss align) Test Failed !");
            end   ex_out       <= `WORD_DATA_W'h59;
            // Case: read the value 0xa4d9 from address 0x59
            /******** Read a Half Data(miss align) Test Input ********/
            ex_mem_op      <= `MEM_OP_LH;
        end
         # STEP begin
            /******** Read a Half Data(miss align) Test Output ********/
            if ( (spm_addr     == `WORD_ADDR_W'h16)     &&
                 (spm_as_      == `DISABLE_)            &&
                 (spm_rw       == `READ)                &&
                 (spm_wr_data  == `WORD_DATA_W'h999)    &&
                 (mem_en       == ex_en)                &&
                 (mem_dst_addr == `REG_ADDR_W'h0)       &&
                 (mem_gpr_we_  == `DISABLE_)            &&
                 (mem_out      == `WORD_DATA_W'h0)
               ) begin
                $display("MEM Stage Read a Half Data(miss align) Test Succeeded !");
            end else begin
                $display("MEM Stage Read a Half Data(miss align) Test Failed !");
            end   ex_out       <= `WORD_DATA_W'h59;
            // Case: write the value 0x13 to address 0x154 which hold value 0x41a4d9
            /******** Write Data(align) Test Input ********/
            ex_mem_op      <= `MEM_OP_SW;       
            ex_out         <= `WORD_DATA_W'h154;
            ex_mem_wr_data <= `WORD_DATA_W'h13;
        end
        # STEP begin
            /******** Write Data(align) Test Output ********/
            if ( (spm_addr     == `WORD_ADDR_W'h55)     &&
                 (spm_as_      == `ENABLE_)             &&
                 (spm_rw       == `WRITE)               &&
                 (spm_wr_data  == `WORD_DATA_W'h13)     &&
                 (mem_en       == ex_en)                &&
                 (mem_dst_addr == `REG_ADDR_W'h7)       &&
                 (mem_gpr_we_  == `DISABLE_)            &&
                 (mem_out      == `WORD_DATA_W'h0)
               ) begin
                $display("MEM Stage Write Data(align) Test Succeeded !");
            end else begin
                $display("MEM Stage Write Data(align) Test Failed !");
            end
            // Case: write a half word 0x13 to address 0x154 which hold value 0x41a4d9
            /******** Write a Half Word(align) Test Input ********/
            ex_mem_op      <= `MEM_OP_SH;
        end
        # STEP begin
            /******** Write a Half Word(align) Test Output ********/
            if ( (spm_addr     == `WORD_ADDR_W'h55)     &&
                 (spm_as_      == `ENABLE_)             &&
                 (spm_rw       == `WRITE)               &&
                 (spm_wr_data  == `WORD_DATA_W'h410013) &&
                 (mem_en       == ex_en)                &&
                 (mem_dst_addr == `REG_ADDR_W'h7)       &&
                 (mem_gpr_we_  == `DISABLE_)            &&
                 (mem_out      == `WORD_DATA_W'h0)
               ) begin
                $display("MEM Stage Write a Half Word(align) Test Succeeded !");
            end else begin
                $display("MEM Stage Write a Half Word(align) Test Failed !");
            end
            // Case: write half word 0x13 to address 0x154 which hold value 41a4d9
            /******** Write a Byte(align) Test Input ********/
            ex_mem_op      <= `MEM_OP_SB;
        end
        # STEP begin
            /******** Write a Byte(align) Test Output ********/
            if ( (spm_addr     == `WORD_ADDR_W'h55)     &&
                 (spm_as_      == `ENABLE_)             &&
                 (spm_rw       == `WRITE)               &&
                 (spm_wr_data  == `WORD_DATA_W'h41a413) &&
                 (mem_en       == ex_en)                &&
                 (mem_dst_addr == `REG_ADDR_W'h7)       &&
                 (mem_gpr_we_  == `DISABLE_)            &&
                 (mem_out      == `WORD_DATA_W'h0)
               ) begin
                $display("MEM Stage Write a Byte Test Succeeded !");
            end else begin
                $display("MEM Stage Write a Byte Test Failed !");
            end
            // Case: write the value 0x13 to address 0x59 which hold value 41a4d9
            /******** Write Data(miss align) Test Input ********/
            ex_out         <= `WORD_DATA_W'h59;
            ex_mem_op      <= `MEM_OP_SW;
        end
        # STEP begin
            /******** Write Data(miss align) Test Output ********/
            if ( (spm_addr     == `WORD_ADDR_W'h16)     &&
                 (spm_as_      == `DISABLE_)            &&
                 (spm_rw       == `READ)                &&
                 (spm_wr_data  == `WORD_DATA_W'h13)     &&
                 (mem_en       == ex_en)                &&
                 (mem_dst_addr == `REG_ADDR_W'h0)       &&
                 (mem_gpr_we_  == `DISABLE_)            &&
                 (mem_out      == `WORD_DATA_W'h0)
               ) begin
                $display("MEM Stage Write Data(miss align) Test Succeeded !");
            end else begin
                $display("MEM Stage Write Data(miss align) Test Failed !");
            end
            // Case: write a half word 0x13 to address 0x59 which hold value 41a4d9
            /******** Write a Half Word(miss align) Test Input ********/
            ex_mem_op      <= `MEM_OP_SH;
        end
        # STEP begin
            /******** Write a Half Word(miss align) Test Output ********/
            if ( (spm_addr     == `WORD_ADDR_W'h16)     &&
                 (spm_as_      == `DISABLE_)            &&
                 (spm_rw       == `READ)                &&
                 (spm_wr_data  == `WORD_DATA_W'h13)     &&
                 (mem_en       == ex_en)                &&
                 (mem_dst_addr == `REG_ADDR_W'h0)       &&
                 (mem_gpr_we_  == `DISABLE_)            &&
                 (mem_out      == `WORD_DATA_W'h0)
               ) begin
                $display("MEM Stage Write a Half Word(miss align) Test Succeeded !");
            end else begin
                $display("MEM Stage Write a Half Word(miss align) Test Failed !");
            end
            // Case: EX Stage out is 0x59, and the address 0x59 hold value 41a4d9
            /******** No Access Test Input ********/
            ex_mem_op      <= `MEM_OP_NOP;       // when `MEM_OP_LW, vvp can't finish! 
            ex_mem_wr_data <= `WORD_DATA_W'h999; // don't care, e.g: 0x999
            ex_gpr_we_     <= `ENABLE_;
        end
        # STEP begin
            /******** No Access Test Output ********/
            if ((spm_addr     == `WORD_ADDR_W'h16)      &&
                (spm_as_      == `DISABLE_)             &&
                (spm_rw       == `READ)                 &&
                (spm_wr_data  == `WORD_DATA_W'h999)     &&
                (mem_en       == ex_en)                 &&
                (mem_dst_addr == `REG_ADDR_W'h7)        &&
                (mem_gpr_we_  == `ENABLE_)              &&
                (mem_out  == `WORD_DATA_W'h59)
                ) begin
                $display("MEM Stage No Access Test Succeeded !");
            end else begin
                $display("MEM Stage No Access Test Failed !");
            end

            /******** Pipeline Line Disable Test Input ********/
            ex_en          <= `DISABLE;
        end
        # STEP begin
            /******** Pipeline Line Disable Test Output ********/
            if ((spm_addr     == `WORD_ADDR_W'h16)      &&
                (spm_as_      == `DISABLE_)             &&
                (spm_rw       == `READ)                 &&
                (spm_wr_data  == `WORD_DATA_W'h999)     &&
                (mem_en       == ex_en)                 &&
                (mem_dst_addr == `REG_ADDR_W'h7)        &&
                (mem_gpr_we_  == `ENABLE_)              &&   
                (mem_out  == `WORD_DATA_W'h0)
               ) begin
                $display("MEM Stage Pipeline Line Disable Test Succeeded !");
            end else begin
                $display("MEM Stage Pipeline Line Disable Test Failed !");
            end
            /******** Pipeline Flush Test Input ********/
            ex_en          <= `ENABLE;
            flush          <= `ENABLE;
        end
        # STEP begin
            /******** Pipeline Flush Test Output ********/
            if ((spm_addr     == `WORD_ADDR_W'h16)      &&
                (spm_as_      == `DISABLE_)             &&
                (spm_rw       == `READ)                 &&
                (spm_wr_data  == `WORD_DATA_W'h999)     &&
                (mem_en       == `DISABLE)                 &&
                (mem_dst_addr == `REG_ADDR_W'h0)        &&
                (mem_gpr_we_  == `DISABLE_)              &&
                (mem_out  == `WORD_DATA_W'h0)
                ) begin
                $display("MEM Stage Pipeline Flush Test Succeeded !");
            end else begin
                $display("MEM Stage Pipeline Flush Test Failed !");
            end
            
            /******** Pipeline Stall Test Input ********/
            flush          <= `DISABLE;
            stall          <= `ENABLE;
        end
        # STEP begin
            /******** Pipeline Stall Test Output ********/
            if ((spm_addr     == `WORD_ADDR_W'h16)      &&
                (spm_as_      == `DISABLE_)             &&
                (spm_rw       == `READ)                 &&
                (spm_wr_data  == `WORD_DATA_W'h999)     &&
                (mem_en       == `DISABLE)                 &&
                (mem_dst_addr == `REG_ADDR_W'h0)        &&
                (mem_gpr_we_  == `DISABLE_)              &&
                (mem_out  == `WORD_DATA_W'h0)
                ) begin
                $display("MEM Stage Pipeline Stall Test Succeeded !");
            end else begin
                $display("MEM Stage Pipeline Stall Test Failed !");
            end
            $finish;
        end
    end // initial begin

    /******** Output Waveform ********/
    initial begin
       $dumpfile("mem_stage.vcd");
       $dumpvars(0,mem_stage);
    end
endmodule // mem_stage_test
