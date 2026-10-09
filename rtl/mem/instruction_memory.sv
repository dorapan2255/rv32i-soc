`timescale 1ns/1ps

module instruction_memory (
    input  logic [31:0] address,
    output logic [31:0] instruction
);

    // 程序镜像由仿真 testbench 通过 $readmemh 装载。
    /* verilator lint_off UNDRIVEN */
    logic [31:0] memory [0:255];
    /* verilator lint_on UNDRIVEN */

    always_comb begin
        instruction = 32'b0;

        if ((address[31:10] == 22'b0) && (address[1:0] == 2'b00))
            instruction = memory[address[9:2]];
    end

endmodule
