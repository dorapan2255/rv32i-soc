`timescale 1ns/1ps

module rv32i_soc_tb;

    logic        clk;
    logic        reset;
    logic [31:0] debug_pc;
    logic [31:0] debug_instruction;
    logic        debug_instruction_valid;

    integer check_count;
    integer error_count;

    rv32i_soc dut (
        .clk                     (clk),
        .reset                   (reset),
        .debug_pc                (debug_pc),
        .debug_instruction       (debug_instruction),
        .debug_instruction_valid (debug_instruction_valid)
    );

    always #5 clk = ~clk;

    task automatic check_value(
        input logic [31:0] actual,
        input logic [31:0] expected,
        input logic [31:0] check_id
    );
        begin
            check_count = check_count + 1;
            if (actual !== expected) begin
                $display("ERROR check %0d: expected=%08h got=%08h",
                         check_id, expected, actual);
                error_count = error_count + 1;
            end
        end
    endtask

    initial begin
        $dumpfile("waveforms/rv32i_soc.vcd");
        $dumpvars(0, rv32i_soc_tb);

        clk         = 1'b0;
        reset       = 1'b1;
        check_count = 0;
        error_count = 0;

        // Hex由RISC-V ELF自动生成，并填充到完整的1 KiB memory image。
        $readmemh("software/integration_test.hex",
                  dut.u_instruction_memory.memory);
        $readmemh("software/integration_test.data.hex",
                  dut.u_data_memory.memory);

        // 给应被跳过的 x9 一个哨兵值，确认分支没有执行该指令。
        dut.u_core.u_reg_file.registers[9] = 32'hfeed_face;

        repeat (2) @(posedge clk);
        @(negedge clk);
        reset = 1'b0;

        // 实际执行 13 条指令；BEQ、JAL、BNE 各跳过一条。
        repeat (13) @(posedge clk);
        #1;

        check_value(dut.u_core.u_reg_file.registers[1],  32'd10,        32'd1);
        check_value(dut.u_core.u_reg_file.registers[2],  32'd20,        32'd2);
        check_value(dut.u_core.u_reg_file.registers[3],  32'd30,        32'd3);
        check_value(dut.u_core.u_reg_file.registers[4],  32'd30,        32'd4);
        check_value(dut.u_core.u_reg_file.registers[5],  32'd2,         32'd5);
        check_value(dut.u_core.u_reg_file.registers[6],  32'd36,        32'd6);
        check_value(dut.u_core.u_reg_file.registers[7],  32'h1234_5000, 32'd7);
        check_value(dut.u_core.u_reg_file.registers[8],  32'd44,        32'd8);
        check_value(dut.u_core.u_reg_file.registers[9],  32'hfeed_face, 32'd9);
        check_value(dut.u_core.u_reg_file.registers[10], 32'd30,        32'd10);
        check_value(dut.u_data_memory.memory[0],         32'd30,        32'd11);
        check_value(debug_pc,                            32'd64,        32'd12);
        check_value({31'b0, debug_instruction_valid},    32'b0,         32'd13);

        if (error_count == 0)
            $display("PASS: all %0d RV32I SoC integration checks passed",
                     check_count);
        else
            $fatal(1, "FAIL: %0d of %0d RV32I SoC integration checks failed",
                   error_count, check_count);

        $finish;
    end

endmodule
