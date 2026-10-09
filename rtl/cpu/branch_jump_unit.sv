`timescale 1ns/1ps

module branch_jump_unit (
    input  logic [31:0] current_pc,
    input  logic [31:0] immediate,
    input  logic [31:0] alu_result,
    input  logic [1:0]  branch_type,
    input  logic        jump,
    input  logic        jump_reg,
    output logic        branch_taken,
    output logic [31:0] next_pc
);

    localparam logic [1:0] BR_NONE = 2'b00;
    localparam logic [1:0] BR_EQ   = 2'b01;
    localparam logic [1:0] BR_NE   = 2'b10;

    always_comb begin
        branch_taken = 1'b0;
        next_pc      = current_pc + 32'd4;

        case (branch_type)
            BR_EQ: branch_taken = (alu_result == 32'b0);
            BR_NE: branch_taken = (alu_result != 32'b0);
            BR_NONE: branch_taken = 1'b0;
            default: branch_taken = 1'b0;
        endcase

        if (jump_reg)
            // RV32I规定JALR目标地址的最低位必须清零。
            next_pc = {alu_result[31:1], 1'b0};
        else if (jump)
            next_pc = current_pc + immediate;
        else if (branch_taken)
            next_pc = current_pc + immediate;
    end

endmodule
