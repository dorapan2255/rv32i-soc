`timescale 1ns/1ps

module imm_gen (
    // 指令低 7 位是 opcode，不参与任何 RV32I 立即数的拼接。
    /* verilator lint_off UNUSEDSIGNAL */
    input  logic [31:0] instruction,
    /* verilator lint_on UNUSEDSIGNAL */
    input  logic [2:0]  imm_type,
    output logic [31:0] immediate
);

    localparam logic [2:0] IMM_I = 3'b000;
    localparam logic [2:0] IMM_S = 3'b001;
    localparam logic [2:0] IMM_B = 3'b010;
    localparam logic [2:0] IMM_U = 3'b011;
    localparam logic [2:0] IMM_J = 3'b100;

    always_comb begin
        immediate = 32'b0;

        case (imm_type)
            IMM_I: immediate = {
                {20{instruction[31]}},
                instruction[31:20]
            };

            IMM_S: immediate = {
                {20{instruction[31]}},
                instruction[31:25],
                instruction[11:7]
            };

            IMM_B: immediate = {
                {19{instruction[31]}},
                instruction[31],
                instruction[7],
                instruction[30:25],
                instruction[11:8],
                1'b0
            };

            IMM_U: immediate = {
                instruction[31:12],
                12'b0
            };

            IMM_J: immediate = {
                {11{instruction[31]}},
                instruction[31],
                instruction[19:12],
                instruction[20],
                instruction[30:21],
                1'b0
            };

            default: immediate = 32'b0;
        endcase
    end

endmodule
