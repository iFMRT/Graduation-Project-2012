/**
 * filename  : hmu_test.v
 * testmodule: hmu
 * author    : besky
 * time      : 2016-05-17 23:15:28
 */
`timescale 1ns/1ps

`include "stddef.h"
`include "isa.h"
`include "vunit.v"
`include "hart_ctrl.h"

module hart_ctrl_test;
    /* Parameter Define ==============================================*/
    parameter DUT_IN_W     = 9 + `HART_ID_W + `HART_STATE_W * 5;
    parameter DUT_OUT_W    = `HART_STATE_W * 3;

    parameter VUNIT_OP_EQ  = `VUNIT_OP_EQ;   // just allow add new line
    parameter VUNIT_OP_NEQ = `VUNIT_OP_NEQ;  // never modify exists!!!

    /* Random Signals ============================*/
    reg                  set_hart_r;
    reg [`HART_ID_B]     set_hart_id_r;
    reg                  set_hart_val_r;

    reg                  is_branch_r;
    reg                  is_load_r;
    reg [`HART_STATE_B]  de_hstate_r;

    reg                  i_cache_miss_r;
    reg [`HART_STATE_B]  if_hstate_r;
    reg                  use_cache_miss_r;
    reg [`HART_STATE_B]  use_hstate_r;

    reg                  i_cache_fin_r;
    reg [`HART_STATE_B]  i_cache_fin_hstate_r;
    reg                  d_cache_fin_r;
    reg [`HART_STATE_B]  d_cache_fin_hstate_r;

    always @(posedge clk) begin
        set_hart_r       = $random;
        set_hart_id_r    = $random;
        set_hart_val_r   = $random;

        is_branch_r      = $random;
        is_load_r        = $random;
        de_hstate_r      = gen_hstate($random);

        i_cache_miss_r   = $random;
        if_hstate_r      = gen_hstate($random);
        use_cache_miss_r = $random;
        use_hstate_r     = gen_hstate($random);

        i_cache_fin_r    = $random;
        i_cache_fin_hstate_r = gen_hstate($random);
        d_cache_fin_r    = $random;
        d_cache_fin_hstate_r = gen_hstate($random);
    end

    function [`HART_STATE_B] gen_hstate;
        input [`HART_ID_B] fmt;
        gen_hstate = `HART_STATE_W'b0001 << fmt;
    endfunction

    /* hmu Instance ==============================*/
    reg  [DUT_IN_W-1:0]   dut_in;
    wire                  rst;

    wire                  set_hart;
    wire [`HART_ID_B]     set_hart_id;
    wire                  set_hart_val;

    wire                  is_branch;
    wire                  is_load;
    wire [`HART_STATE_B]  de_hstate;

    wire                  i_cache_miss;
    wire [`HART_STATE_B]  if_hstate;
    wire                  use_cache_miss;
    wire [`HART_STATE_B]  use_hstate;

    wire                  i_cache_fin;
    wire [`HART_STATE_B]  i_cache_fin_hstate;
    wire                  d_cache_fin;
    wire [`HART_STATE_B]  d_cache_fin_hstate;

    wire [DUT_OUT_W-1:0]  dut_out;
    wire [`HART_STATE_B]  hart_issue_hstate;
    wire [`HART_STATE_B]  hart_acti_hstate;
    wire [`HART_STATE_B]  hart_idle_hstate;

    hart_ctrl hart_ctrl_t (
        .clk                (clk),
        .rst                (rst),

        .set_hart           (set_hart),
        .set_hart_id        (set_hart_id),
        .set_hart_val       (set_hart_val),

        .is_branch          (is_branch),
        .is_load            (is_load),
        .de_hstate          (de_hstate),
        .i_cache_miss       (i_cache_miss),
        .if_hstate          (if_hstate),
        .use_cache_miss     (use_cache_miss),
        .use_hstate         (use_hstate),

        .i_cache_fin        (i_cache_fin),
        .i_cache_fin_hstate (i_cache_fin_hstate),
        .d_cache_fin        (d_cache_fin),
        .d_cache_fin_hstate (d_cache_fin_hstate),

        .hmu_issue_hstate   (hmu_issue_hstate),
        .hmu_acti_hstate    (hmu_acti_hstate),
        .hmu_idle_hstate    (hmu_idle_hstate)
    );

    assign {
        rst, set_hart, set_hart_id, set_hart_val,
        is_branch, is_load, de_hstate,
        i_cache_miss, if_hstate, use_cache_miss, use_hstate,
        i_cache_fin, i_cache_fin_hstate,
        d_cache_fin, d_cache_fin_hstate
    } = dut_in;
    assign dut_out = {hmu_issue_hstate, hmu_acti_hstate, hmu_idle_hstate};

    /* VUNIT Instance ================================================*/
    reg                    check;            // DON'T MODIFY THIS SECTION!!!
    reg  [DUT_OUT_W-1:0]   exp_val;
    reg  [`VUNIT_OP_B]     vunit_op;
    wire                   is_right;

    vunit #(DUT_OUT_W) vunit_t (
        .check    (check),
        .real_val (dut_out),            // tested output => vunit input
        .exp_val  (exp_val),
        .op       (vunit_op),
        .is_right (is_right)
    );

    /* Interface Connection ==========================================*/
    integer times = 1;
    task vector;
        input [DUT_IN_W-1:0]   dut_in_t;
        input [`VUNIT_OP_B]    vunit_op_t;
        input [DUT_OUT_W-1:0]  exp_val_t;

        begin
            dut_in = dut_in_t;
            # STEP begin
                /** Add Test Input Signals at Bellow */
                $write("%m.%2d: (%b. %b, %d, %b. %b, %b, %b. %b, %b. %b, %b. %b, %b, %b, %b. %b) => ", times, 
                    rst, 
                    set_hart, set_hart_id, set_hart_val,
                    is_branch, is_load, de_hstate,
                    i_cache_miss,   if_hstate,
                    use_cache_miss, use_hstate,
                    i_cache_fin, i_cache_fin_hstate,
                    d_cache_fin, d_cache_fin_hstate,
                    exp_val_t);
                /** Test Control Section, DON'T MODIFY!!! **/
                times    = times + 1;
                exp_val  = exp_val_t;
                vunit_op = vunit_op_t;
                check    = ~check;
                /** Test Control Section END **/
            end
        end
    endtask

    task rst_vector;
        begin
            vector(
                {`ENABLE, `DISABLE, set_hart_id_r, set_hart_val_r,
                is_branch_r, is_load_r, de_hstate_r,
                `DISABLE, if_hstate_r,
                `DISABLE, use_hstate_r,
                i_cache_fin_r, i_cache_fin_hstate_r, 
                d_cache_fin_r, d_cache_fin_hstate_r}, 
                VUNIT_OP_EQ,
                {4'b0001, 4'b0001, 4'b1110}
            );
        end
    endtask

    task i_cache_fin_vector;
        input [`HART_STATE_B] i_cache_fin_hstate_t;
        input [DUT_OUT_W-1:0] exp_val_t;
        vector(
            {`DISABLE, `DISABLE, set_hart_id_r, set_hart_val_r,
            `DISABLE, `DISABLE, de_hstate_r,
            `DISABLE, if_hstate_r,
            `DISABLE, use_hstate_r,
            `ENABLE, i_cache_fin_hstate_t,
            `DISABLE, d_cache_fin_hstate_r},
            VUNIT_OP_EQ, 
            exp_val_t
        );
    endtask

    task d_cache_fin_vector;
        input [`HART_STATE_B] d_cache_fin_hstate_t;
        input [DUT_OUT_W-1:0] exp_val_t;
        vector(
            {`DISABLE, `DISABLE, set_hart_id_r, set_hart_val_r,
            `DISABLE, `DISABLE, de_hstate_r,
            `DISABLE, if_hstate_r,
            `DISABLE, use_hstate_r,
            `DISABLE, i_cache_fin_hstate_r,
            `ENABLE, d_cache_fin_hstate_t},
            VUNIT_OP_EQ, 
            exp_val_t
        );
    endtask

    task set_hart_vector;
        input [`HART_ID_B]    set_hart_id_t;
        input                 set_hart_val_t;
        input [DUT_OUT_W-1:0] exp_val_t;
        vector(
            {`DISABLE, `ENABLE, set_hart_id_t, set_hart_val_t,
            `DISABLE, `DISABLE, de_hstate_r,
            `DISABLE, if_hstate_r,
            `DISABLE, use_hstate_r,
            `DISABLE, i_cache_fin_hstate_r, 
            `DISABLE, d_cache_fin_hstate_r},
            VUNIT_OP_EQ, 
            exp_val_t
        );
    endtask

    task is_branch_vector;
        input [`HART_STATE_B] de_hstate_t;
        input [DUT_OUT_W-1:0] exp_val_t;
        vector(
            {`DISABLE, `DISABLE, set_hart_id_r, set_hart_val_r,
            `ENABLE, `DISABLE, de_hstate_t,
            `DISABLE, if_hstate_r,
            `DISABLE, use_hstate_r,
            `DISABLE, i_cache_fin_hstate_r, 
            `DISABLE, d_cache_fin_hstate_r},
            VUNIT_OP_EQ, 
            exp_val_t
        );
    endtask

    task is_load_vector;
        input [`HART_STATE_B] de_hstate_t;
        input [DUT_OUT_W-1:0] exp_val_t;
        vector(
            {`DISABLE, `DISABLE, set_hart_id_r, set_hart_val_r,
            `DISABLE, `ENABLE, de_hstate_t,
            `DISABLE, if_hstate_r,
            `DISABLE, use_hstate_r,
            `DISABLE, i_cache_fin_hstate_r, 
            `DISABLE, d_cache_fin_hstate_r},
            VUNIT_OP_EQ, 
            exp_val_t
        );
    endtask

    task i_cache_miss_vector;
        input [`HART_STATE_B] if_hstate_t;
        input [DUT_OUT_W-1:0] exp_val_t;
        vector(
            {`DISABLE, `DISABLE, set_hart_id_r, set_hart_val_r,
            `DISABLE, `DISABLE, de_hstate_r,
            `ENABLE, if_hstate_t,
            `DISABLE, use_hstate_r,
            `DISABLE, i_cache_fin_hstate_r, 
            `DISABLE, d_cache_fin_hstate_r},
            VUNIT_OP_EQ, 
            exp_val_t
        );
    endtask

    task use_cache_miss_vector;
        input [`HART_STATE_B] use_hstate_t;
        input [DUT_OUT_W-1:0] exp_val_t;
        vector(
            {`DISABLE, `DISABLE, set_hart_id_r, set_hart_val_r,
            `DISABLE, `DISABLE, de_hstate_r,
            `DISABLE, if_hstate_r,
            `ENABLE , use_hstate_t,
            `DISABLE, i_cache_fin_hstate_r, 
            `DISABLE, d_cache_fin_hstate_r},
            VUNIT_OP_EQ, 
            exp_val_t
        );
    endtask

    task normal_vector;
        input [DUT_OUT_W-1:0] exp_val_t;
        vector(
            {`DISABLE, `DISABLE, set_hart_id_r, set_hart_val_r,
            `DISABLE, `DISABLE, de_hstate_r,
            `DISABLE, if_hstate_r,
            `DISABLE, use_hstate_r,
            `DISABLE, i_cache_fin_hstate_r, 
            `DISABLE, d_cache_fin_hstate_r},
            VUNIT_OP_EQ, 
            exp_val_t
        );
    endtask

    task cache_miss_vector;
        input [`HART_STATE_B] if_hstate_t;
        input [`HART_STATE_B] use_hstate_t;
        input [DUT_OUT_W-1:0] exp_val_t;
        vector(
            {`DISABLE, `DISABLE, set_hart_id_r, set_hart_val_r,
            `DISABLE, `DISABLE, de_hstate_r,
            `ENABLE , if_hstate_t,
            `ENABLE , use_hstate_t,
            `DISABLE, i_cache_fin_hstate_r, 
            `DISABLE, d_cache_fin_hstate_r},
            VUNIT_OP_EQ, 
            exp_val_t
        );
    endtask

    task bl_uc_miss_vector;    // (branch or load) and use cache miss test
        input                 is_branch_t;
        input                 is_load_t;
        input [`HART_STATE_B] de_hstate_t;
        input [`HART_STATE_B] use_hstate_t;
        input [DUT_OUT_W-1:0] exp_val_t;
        vector(
            {`DISABLE, `DISABLE, set_hart_id_r, set_hart_val_r,
            is_branch_t, is_load_t, de_hstate_t,
            `DISABLE, if_hstate_r,
            `ENABLE , use_hstate_t,
            `DISABLE, i_cache_fin_hstate_r, 
            `DISABLE, d_cache_fin_hstate_r},
            VUNIT_OP_EQ, 
            exp_val_t
        );
    endtask

    /* Test Vector ===================================================*/
    initial begin
        # 0 begin         // DON'T CHANGE HERE
            clk   <= 1;   // just add initial signals if needed
            check <= 1;
        end

        # (STEP * 3 / 4)

        // test1-10 reset 状态下，重置 0 号硬件线索为主线索，活跃状态
        # (STEP) $display("\ntest rst");
        repeat (10) rst_vector();

        // test11-13 如果有指令 cache 访问完成信号，相应线索设为活跃态
        # (STEP) $display("\ntest i_cache_fin");
        i_cache_fin_vector(4'b0001, {4'b0001, 4'b0001, 4'b1110});
        i_cache_fin_vector(4'b0010, {4'b0001, 4'b0011, 4'b1110});
        i_cache_fin_vector(4'b0100, {4'b0001, 4'b0111, 4'b1110});

        // test14-23 数据 cache 访问完成，相应线索设为活跃状态
        # (STEP) $display("\ntest d_cache_fin");
        d_cache_fin_vector(4'b0001, {4'b0001, 4'b0111, 4'b1110});
        d_cache_fin_vector(4'b0010, {4'b0001, 4'b0111, 4'b1110});
        d_cache_fin_vector(4'b0100, {4'b0001, 4'b0111, 4'b1110});
        d_cache_fin_vector(4'b1000, {4'b1000, 4'b1111, 4'b1110});
        d_cache_fin_vector(4'b0100, {4'b0100, 4'b1111, 4'b1110});
        d_cache_fin_vector(4'b0001, {4'b0010, 4'b1111, 4'b1110});
        d_cache_fin_vector(4'b0010, {4'b0001, 4'b1111, 4'b1110});
        d_cache_fin_vector(4'b0001, {4'b1000, 4'b1111, 4'b1110});
        d_cache_fin_vector(4'b0001, {4'b0100, 4'b1111, 4'b1110});
        d_cache_fin_vector(4'b0001, {4'b0010, 4'b1111, 4'b1110});

        // test24-35 设置线索状态信号，相应线索状态改变
        # (STEP) $display("\ntest set_hart");
        # (STEP/2)
        set_hart_vector(2'b01, 1'b0, {4'b0001, 4'b1101, 4'b1110});
        set_hart_vector(2'b10, 1'b0, {4'b0001, 4'b1001, 4'b1110});
        set_hart_vector(2'b00, 1'b0, {4'b1000, 4'b1000, 4'b1111});
        set_hart_vector(2'b11, 1'b0, {4'b0000, 4'b0000, 4'b1111});
        rst_vector();
        set_hart_vector(2'b10, 1'b1, {4'b0001, 4'b0101, 4'b1010});
        set_hart_vector(2'b00, 1'b0, {4'b0100, 4'b0100, 4'b1011});
        set_hart_vector(2'b11, 1'b1, {4'b0100, 4'b1100, 4'b0011});
        set_hart_vector(2'b00, 1'b1, {4'b0100, 4'b1101, 4'b0010});
        set_hart_vector(2'b01, 1'b1, {4'b0010, 4'b1111, 4'b0000});
        set_hart_vector(2'b01, 1'b0, {4'b0100, 4'b1101, 4'b0010});
        set_hart_vector(2'b11, 1'b0, {4'b0100, 4'b0101, 4'b1010});

        // test36-45 分支指令测试
        # (STEP) $display("\ntest is_branch");
        is_branch_vector(4'b0001,     {4'b0100, 4'b0101, 4'b1010});
        is_branch_vector(4'b0010,     {4'b0100, 4'b0101, 4'b1010});
        is_branch_vector(4'b1000,     {4'b0100, 4'b0101, 4'b1010});
        is_branch_vector(4'b0100,     {4'b0001, 4'b0101, 4'b1010});
        is_branch_vector(4'b0010,     {4'b0100, 4'b0101, 4'b1010});
         set_hart_vector(2'b01, 1'b1, {4'b0100, 4'b0111, 4'b1000});
        is_branch_vector(4'b0100,     {4'b0010, 4'b0111, 4'b1000});
        is_branch_vector(4'b0000,     {4'b0100, 4'b0111, 4'b1000});
         set_hart_vector(2'b11, 1'b1, {4'b0010, 4'b1111, 4'b0000});
        is_branch_vector(4'b1111,     {4'b0001, 4'b1111, 4'b0000});    // 输入 4'b1111 只是为了方便测试，实际中不会出现

        // test46-54 load 指令测试
        # (STEP) $display("\ntest is_load");
         is_load_vector(4'b0100,     {4'b0100, 4'b1111, 4'b0000});    // 交叉发射时忽略 load
         is_load_vector(4'b0100,     {4'b0010, 4'b1111, 4'b0000});
        set_hart_vector(2'b01, 1'b0, {4'b0100, 4'b1101, 4'b0010});    // 测试三个活跃线索时 load 指令的处理
         is_load_vector(4'b0100,     {4'b1000, 4'b1101, 4'b0010});
         is_load_vector(4'b0000,     {4'b0100, 4'b1101, 4'b0010});    // 在 check 点已经过了一个周期，没有检测到 0001 线索的发射
        set_hart_vector(2'b10, 1'b0, {4'b1000, 4'b1001, 4'b0110});    // 测试两个活跃线索时 load 指令的处理
         is_load_vector(4'b1000,     {4'b0001, 4'b1001, 4'b0110});    // load 指令，从次级线索发射
         is_load_vector(4'b0001,     {4'b1000, 4'b1001, 4'b0110});    // 再次从次级线索发射，这里也是因为错过检查点，具体分析波形图
         is_load_vector(4'b0001,     {4'b1000, 4'b1001, 4'b0110});    // 忽略次级线索的 load 指令，继续从主线索发射

        // test55-65 i_cache_miss 测试
        # (STEP) $display("\ntest i_cache_miss");
        # (STEP/2)
        i_cache_miss_vector(4'b0001, {4'b1000, 4'b1000, 4'b0110});    // 次级线索 i_cache_miss 两个周期后该线索状态转换为 pend
              normal_vector(         {4'b1000, 4'b1000, 4'b0110});    // 次级线索 pend，注意 IDLE 不会改变，因为该线索还存在处理器上
        i_cache_miss_vector(4'b1000, {4'b0000, 4'b0000, 4'b0110});    // 主线索 i_cache_miss 切换线索，两个周期后该线索状态转换为 pend
              normal_vector(         {4'b0000, 4'b0000, 4'b0110});    // 主线索 pend，注意 IDLE 不会改变，因为该线索还存在处理器上
         i_cache_fin_vector(4'b0001, {4'b0001, 4'b0001, 4'b0110});    // 无活跃线索时，有次级线索访存完成，则设置为主线索
              normal_vector(         {4'b0001, 4'b0001, 4'b0110});
         i_cache_fin_vector(4'b1000, {4'b0001, 4'b1001, 4'b0110});
         i_cache_fin_vector(4'b0100, {4'b0001, 4'b1101, 4'b0110});
        i_cache_miss_vector(4'b0001, {4'b1000, 4'b1100, 4'b0110});    // 主线索 i_cache_miss
        i_cache_miss_vector(4'b1000, {4'b0100, 4'b0100, 4'b0110});    // 次线索 i_cache_miss
        i_cache_miss_vector(4'b0100, {4'b0000, 4'b0000, 4'b0110});    // 次线索 i_cache_miss


        // test66-71 use_cache_miss 测试
        # (STEP) $display("\ntest use_cache_miss");
           i_cache_fin_vector(4'b1000, {4'b1000, 4'b1000, 4'b0110});    // 首先设置两个活跃线索
           i_cache_fin_vector(4'b0100, {4'b1000, 4'b1100, 4'b0110});
        use_cache_miss_vector(4'b0100, {4'b1000, 4'b1000, 4'b0110});    // 次线索 use_cache_miss
           i_cache_fin_vector(4'b0100, {4'b1000, 4'b1100, 4'b0110});    // 原次线索访存完成
        use_cache_miss_vector(4'b1000, {4'b0100, 4'b0100, 4'b0110});    // 主线索 use_cache_miss
           i_cache_fin_vector(4'b1000, {4'b0100, 4'b1100, 4'b0110});    // 原主线索访存完成

        // test72-80 i_cache & d_cache miss
        # (STEP) $display("\ntest cache_miss");
         cache_miss_vector(4'b1000, 4'b0100, {4'b0000, 4'b0000, 4'b0110});    // 主线索 i_cache_miss 次线索 use_cache_miss
        i_cache_fin_vector(4'b0100,          {4'b0100, 4'b0100, 4'b0110});    // 原次线索访存完成
        i_cache_fin_vector(4'b1100,          {4'b0100, 4'b1100, 4'b0110});    // 原主线索访存完成
           set_hart_vector(2'b00  , 1'b1   , {4'b0100, 4'b1101, 4'b0110});    // 设置新的线索
         cache_miss_vector(4'b1000, 4'b0100, {4'b0001, 4'b0001, 4'b0110});    // 次线索 i_cache_miss 主线索 use_cache_miss
           set_hart_vector(2'b11  , 1'b1   , {4'b0001, 4'b1001, 4'b0110});    // 设置新的线索
           set_hart_vector(2'b10  , 1'b1   , {4'b0001, 4'b1101, 4'b0010});    // 设置新的线索
           set_hart_vector(2'b01  , 1'b1   , {4'b1000, 4'b1111, 4'b0000});    // 交叉发射
         cache_miss_vector(4'b1000, 4'b0001, {4'b0100, 4'b0110, 4'b0000});    // 次线索 i_cache_miss 主线索 use_cache_miss

        // test81-87 branch_load and use_cache_miss
        # (STEP) $display("\ntest cache_miss");
         bl_uc_miss_vector(1'b1, 1'b0, 4'b0010, 4'b0100, {4'b0010, 4'b0010, 4'b0000});    // 次线索 branch 主线索 use_cache_miss
        d_cache_fin_vector(                     4'b0100, {4'b0010, 4'b0110, 4'b0000});
         bl_uc_miss_vector(1'b0, 1'b1, 4'b0100, 4'b0010, {4'b0100, 4'b0100, 4'b0000});    // 次线索 load   主线索 use_cache_miss
        d_cache_fin_vector(                     4'b0010, {4'b0100, 4'b0110, 4'b0000});
         bl_uc_miss_vector(1'b1, 1'b0, 4'b0100, 4'b0100, {4'b0010, 4'b0010, 4'b0000});    // 主线索 branch 主线索 use_cache_miss
        d_cache_fin_vector(                     4'b0100, {4'b0010, 4'b0110, 4'b0000});    // 恢复原主线索
         bl_uc_miss_vector(1'b1, 1'b0, 4'b0010, 4'b0100, {4'b0010, 4'b0010, 4'b0000});    // 主线索 branch 次线索 use_cache_miss

        # STEP $finish;
    end

    /* Clock Generation ==============================================*/
    parameter STEP  = `VUNIT_STEP;        // 10M
    reg                clk;
    always #(STEP / 2) clk <= ~clk;

    /* Wave Generation ===============================================*/
    initial begin
        $dumpfile("hmu_test.vcd");
        $dumpvars(0, hmu_t);
        $dumpvars(0, vunit_t);
    end
endmodule
