`timescale 1ns/1ps

module instruction_memory_tb;

    logic [31:0] address;
    logic [31:0] instruction;

    integer test_count;
    integer error_count;

    instruction_memory dut (
        .address     (address),
        .instruction (instruction)
    );

    task automatic check_instruction(
        input logic [31:0] test_address,
        input logic [31:0] expected_instruction
    );
        begin
            address = test_address;
            #1;
            test_count = test_count + 1;

            if (instruction !== expected_instruction) begin
                $display("ERROR: address=%08h expected=%08h got=%08h",
                         address, expected_instruction, instruction);
                error_count = error_count + 1;
            end
        end
    endtask

    initial begin
        $dumpfile("waveforms/instruction_memory.vcd");
        $dumpvars(0, instruction_memory_tb);

        address     = 32'b0;
        test_count  = 0;
        error_count = 0;

        // 测试环境模拟程序装载，每个数组元素保存一条 32-bit 指令。
        dut.memory[0]   = 32'h00a0_0093; // addi x1, x0, 10
        dut.memory[1]   = 32'h0140_0113; // addi x2, x0, 20
        dut.memory[2]   = 32'h0020_81b3; // add  x3, x1, x2
        dut.memory[255] = 32'hdead_beef;

        check_instruction(32'h0000_0000, 32'h00a0_0093);
        check_instruction(32'h0000_0004, 32'h0140_0113);
        check_instruction(32'h0000_0008, 32'h0020_81b3);
        check_instruction(32'h0000_03fc, 32'hdead_beef);

        // 未对齐和超出 1 KiB 范围的地址返回零。
        check_instruction(32'h0000_0002, 32'b0);
        check_instruction(32'h0000_0400, 32'b0);

        if (error_count == 0)
            $display("PASS: all %0d instruction memory tests passed", test_count);
        else
            $fatal(1, "FAIL: %0d of %0d instruction memory tests failed",
                   error_count, test_count);

        $finish;
    end

endmodule
