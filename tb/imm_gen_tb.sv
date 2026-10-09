`timescale 1ns/1ps

module imm_gen_tb;

    localparam logic [2:0] IMM_I = 3'b000;
    localparam logic [2:0] IMM_S = 3'b001;
    localparam logic [2:0] IMM_B = 3'b010;
    localparam logic [2:0] IMM_U = 3'b011;
    localparam logic [2:0] IMM_J = 3'b100;

    logic [31:0] instruction;
    logic [2:0]  imm_type;
    logic [31:0] immediate;

    integer test_count;
    integer error_count;

    imm_gen dut (
        .instruction (instruction),
        .imm_type    (imm_type),
        .immediate   (immediate)
    );

    task automatic check_immediate(
        input logic [31:0] test_instruction,
        input logic [2:0]  test_imm_type,
        input logic [31:0] expected_immediate
    );
        begin
            instruction = test_instruction;
            imm_type    = test_imm_type;
            #1;

            test_count = test_count + 1;
            if (immediate !== expected_immediate) begin
                $display("ERROR: type=%03b instruction=%08h expected=%08h got=%08h",
                         imm_type, instruction, expected_immediate, immediate);
                error_count = error_count + 1;
            end
        end
    endtask

    initial begin
        $dumpfile("waveforms/imm_gen.vcd");
        $dumpvars(0, imm_gen_tb);

        instruction = 32'b0;
        imm_type    = 3'b0;
        test_count  = 0;
        error_count = 0;

        check_immediate(32'h7ff0_0000, IMM_I, 32'h0000_07ff);
        check_immediate(32'hfff0_0000, IMM_I, 32'hffff_ffff);

        check_immediate(32'h0a00_0a80, IMM_S, 32'h0000_00b5);
        check_immediate(32'hfe00_0800, IMM_S, 32'hffff_fff0);

        check_immediate(32'h0000_0800, IMM_B, 32'h0000_0010);
        check_immediate(32'hfe00_0e80, IMM_B, 32'hffff_fffc);

        check_immediate(32'h1234_5000, IMM_U, 32'h1234_5000);
        check_immediate(32'hffff_f000, IMM_U, 32'hffff_f000);

        check_immediate(32'h0010_0000, IMM_J, 32'h0000_0800);
        check_immediate(32'hffdff000, IMM_J, 32'hffff_fffc);

        check_immediate(32'hffff_ffff, 3'b111, 32'b0);

        if (error_count == 0)
            $display("PASS: all %0d immediate generator tests passed", test_count);
        else
            $fatal(1, "FAIL: %0d of %0d immediate generator tests failed",
                   error_count, test_count);

        $finish;
    end

endmodule
