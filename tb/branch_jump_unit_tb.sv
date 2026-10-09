`timescale 1ns/1ps

module branch_jump_unit_tb;

    localparam logic [1:0] BR_NONE = 2'b00;
    localparam logic [1:0] BR_EQ   = 2'b01;
    localparam logic [1:0] BR_NE   = 2'b10;

    logic [31:0] current_pc;
    logic [31:0] immediate;
    logic [31:0] alu_result;
    logic [1:0]  branch_type;
    logic        jump;
    logic        jump_reg;
    logic        branch_taken;
    logic [31:0] next_pc;

    integer test_count;
    integer error_count;

    branch_jump_unit dut (
        .current_pc   (current_pc),
        .immediate    (immediate),
        .alu_result   (alu_result),
        .branch_type  (branch_type),
        .jump         (jump),
        .jump_reg     (jump_reg),
        .branch_taken (branch_taken),
        .next_pc      (next_pc)
    );

    task automatic check_next_pc(
        input logic [31:0] test_pc,
        input logic [31:0] test_immediate,
        input logic [31:0] test_alu_result,
        input logic [1:0]  test_branch_type,
        input logic        test_jump,
        input logic        test_jump_reg,
        input logic        expected_branch_taken,
        input logic [31:0] expected_next_pc
    );
        begin
            current_pc  = test_pc;
            immediate   = test_immediate;
            alu_result  = test_alu_result;
            branch_type = test_branch_type;
            jump        = test_jump;
            jump_reg    = test_jump_reg;
            #1;

            test_count = test_count + 1;
            if ((branch_taken !== expected_branch_taken) ||
                (next_pc !== expected_next_pc)) begin
                $display("ERROR: pc=%08h imm=%08h alu=%08h branch=%02b jump=%0b jalr=%0b",
                         current_pc, immediate, alu_result, branch_type,
                         jump, jump_reg);
                $display("  expected taken=%0b next_pc=%08h, got taken=%0b next_pc=%08h",
                         expected_branch_taken, expected_next_pc,
                         branch_taken, next_pc);
                error_count = error_count + 1;
            end
        end
    endtask

    initial begin
        $dumpfile("waveforms/branch_jump_unit.vcd");
        $dumpvars(0, branch_jump_unit_tb);

        current_pc  = 32'b0;
        immediate   = 32'b0;
        alu_result  = 32'b0;
        branch_type = BR_NONE;
        jump        = 1'b0;
        jump_reg    = 1'b0;
        test_count  = 0;
        error_count = 0;

        // 普通顺序执行
        check_next_pc(32'd100, 32'd16, 32'b0, BR_NONE, 1'b0, 1'b0,
                      1'b0, 32'd104);

        // BEQ：相等时跳转，不相等时继续 PC+4
        check_next_pc(32'd100, 32'd16, 32'b0, BR_EQ, 1'b0, 1'b0,
                      1'b1, 32'd116);
        check_next_pc(32'd100, 32'd16, 32'd5, BR_EQ, 1'b0, 1'b0,
                      1'b0, 32'd104);

        // BNE：不相等时使用负偏移跳转
        check_next_pc(32'd100, 32'hffff_fff8, 32'd1, BR_NE, 1'b0, 1'b0,
                      1'b1, 32'd92);
        check_next_pc(32'd100, 32'hffff_fff8, 32'b0, BR_NE, 1'b0, 1'b0,
                      1'b0, 32'd104);

        // JAL 无条件跳转；jump 对 next_pc 的选择优先于分支结果
        check_next_pc(32'd100, 32'd32, 32'd1, BR_NONE, 1'b1, 1'b0,
                      1'b0, 32'd132);
        check_next_pc(32'd100, 32'd32, 32'b0, BR_EQ, 1'b1, 1'b0,
                      1'b1, 32'd132);

        // JALR使用ALU结果作为目标，并强制清零bit 0。
        check_next_pc(32'd100, 32'd32, 32'h0000_0123, BR_NONE, 1'b0, 1'b1,
                      1'b0, 32'h0000_0122);

        // 未定义 branch_type 按不分支处理
        check_next_pc(32'd100, 32'd64, 32'b0, 2'b11, 1'b0, 1'b0,
                      1'b0, 32'd104);

        if (error_count == 0)
            $display("PASS: all %0d branch/jump tests passed", test_count);
        else
            $fatal(1, "FAIL: %0d of %0d branch/jump tests failed",
                   error_count, test_count);

        $finish;
    end

endmodule
