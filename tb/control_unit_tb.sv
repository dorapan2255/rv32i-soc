`timescale 1ns/1ps

module control_unit_tb;

    localparam logic [3:0] ALU_ADD = 4'b0000;
    localparam logic [3:0] ALU_SUB = 4'b0001;
    localparam logic [3:0] ALU_AND = 4'b0010;
    localparam logic [3:0] ALU_OR  = 4'b0011;
    localparam logic [3:0] ALU_XOR = 4'b0100;
    localparam logic [3:0] ALU_SLT = 4'b0101;
    localparam logic [3:0] ALU_SLL = 4'b0110;
    localparam logic [3:0] ALU_SRL = 4'b0111;
    localparam logic [3:0] ALU_SRA = 4'b1000;

    localparam logic [2:0] IMM_I = 3'b000;
    localparam logic [2:0] IMM_S = 3'b001;
    localparam logic [2:0] IMM_B = 3'b010;
    localparam logic [2:0] IMM_U = 3'b011;
    localparam logic [2:0] IMM_J = 3'b100;

    localparam logic [1:0] A_RS1  = 2'b00;
    localparam logic [1:0] A_PC   = 2'b01;
    localparam logic [1:0] A_ZERO = 2'b10;
    localparam logic [1:0] WB_ALU = 2'b00;
    localparam logic [1:0] WB_MEM = 2'b01;
    localparam logic [1:0] WB_PC4 = 2'b10;
    localparam logic [1:0] BR_NONE = 2'b00;
    localparam logic [1:0] BR_EQ   = 2'b01;
    localparam logic [1:0] BR_NE   = 2'b10;

    logic [6:0] opcode;
    logic [2:0] funct3;
    logic [6:0] funct7;
    logic [3:0] alu_op;
    logic [2:0] imm_type;
    logic [1:0] alu_a_sel;
    logic       alu_src_imm;
    logic       reg_write;
    logic       mem_read;
    logic       mem_write;
    logic [1:0] wb_sel;
    logic [1:0] branch_type;
    logic       jump;
    logic       jump_reg;
    logic       instruction_valid;

    integer test_count;
    integer error_count;

    control_unit dut (
        .opcode           (opcode),
        .funct3           (funct3),
        .funct7           (funct7),
        .alu_op           (alu_op),
        .imm_type         (imm_type),
        .alu_a_sel        (alu_a_sel),
        .alu_src_imm      (alu_src_imm),
        .reg_write        (reg_write),
        .mem_read         (mem_read),
        .mem_write        (mem_write),
        .wb_sel           (wb_sel),
        .branch_type      (branch_type),
        .jump             (jump),
        .jump_reg         (jump_reg),
        .instruction_valid(instruction_valid)
    );

    task automatic check_control(
        input logic [6:0] test_opcode,
        input logic [2:0] test_funct3,
        input logic [6:0] test_funct7,
        input logic [3:0] expected_alu_op,
        input logic [2:0] expected_imm_type,
        input logic [1:0] expected_alu_a_sel,
        input logic       expected_alu_src_imm,
        input logic       expected_reg_write,
        input logic       expected_mem_read,
        input logic       expected_mem_write,
        input logic [1:0] expected_wb_sel,
        input logic [1:0] expected_branch_type,
        input logic       expected_jump,
        input logic       expected_valid
    );
        logic expected_jump_reg;
        begin
            opcode = test_opcode;
            funct3 = test_funct3;
            funct7 = test_funct7;
            #1;
            test_count = test_count + 1;
            expected_jump_reg = (test_opcode == 7'b1100111) &&
                                (test_funct3 == 3'b000) && expected_valid;

            if ({alu_op, imm_type, alu_a_sel, alu_src_imm, reg_write,
                 mem_read, mem_write, wb_sel, branch_type, jump, jump_reg,
                 instruction_valid} !==
                {expected_alu_op, expected_imm_type, expected_alu_a_sel,
                 expected_alu_src_imm, expected_reg_write, expected_mem_read,
                 expected_mem_write, expected_wb_sel, expected_branch_type,
                 expected_jump, expected_jump_reg, expected_valid}) begin
                $display("ERROR: opcode=%07b funct3=%03b funct7=%07b",
                         opcode, funct3, funct7);
                $display("  actual:   alu=%04b imm=%03b a_sel=%02b src_imm=%0b reg_w=%0b mem_r=%0b mem_w=%0b wb=%02b br=%02b jump=%0b jalr=%0b valid=%0b",
                         alu_op, imm_type, alu_a_sel, alu_src_imm, reg_write,
                         mem_read, mem_write, wb_sel, branch_type, jump, jump_reg,
                         instruction_valid);
                $display("  expected: alu=%04b imm=%03b a_sel=%02b src_imm=%0b reg_w=%0b mem_r=%0b mem_w=%0b wb=%02b br=%02b jump=%0b valid=%0b",
                         expected_alu_op, expected_imm_type, expected_alu_a_sel,
                         expected_alu_src_imm, expected_reg_write,
                         expected_mem_read, expected_mem_write, expected_wb_sel,
                         expected_branch_type, expected_jump, expected_valid);
                error_count = error_count + 1;
            end
        end
    endtask

    initial begin
        $dumpfile("waveforms/control_unit.vcd");
        $dumpvars(0, control_unit_tb);
        test_count = 0;
        error_count = 0;

        // R 型：ADD、SUB、AND、OR、XOR、SLT、SLL、SRL、SRA
        check_control(7'b0110011, 3'b000, 7'b0000000, ALU_ADD, IMM_I, A_RS1, 0, 1, 0, 0, WB_ALU, BR_NONE, 0, 1);
        check_control(7'b0110011, 3'b000, 7'b0100000, ALU_SUB, IMM_I, A_RS1, 0, 1, 0, 0, WB_ALU, BR_NONE, 0, 1);
        check_control(7'b0110011, 3'b111, 7'b0000000, ALU_AND, IMM_I, A_RS1, 0, 1, 0, 0, WB_ALU, BR_NONE, 0, 1);
        check_control(7'b0110011, 3'b110, 7'b0000000, ALU_OR,  IMM_I, A_RS1, 0, 1, 0, 0, WB_ALU, BR_NONE, 0, 1);
        check_control(7'b0110011, 3'b100, 7'b0000000, ALU_XOR, IMM_I, A_RS1, 0, 1, 0, 0, WB_ALU, BR_NONE, 0, 1);
        check_control(7'b0110011, 3'b010, 7'b0000000, ALU_SLT, IMM_I, A_RS1, 0, 1, 0, 0, WB_ALU, BR_NONE, 0, 1);
        check_control(7'b0110011, 3'b001, 7'b0000000, ALU_SLL, IMM_I, A_RS1, 0, 1, 0, 0, WB_ALU, BR_NONE, 0, 1);
        check_control(7'b0110011, 3'b101, 7'b0000000, ALU_SRL, IMM_I, A_RS1, 0, 1, 0, 0, WB_ALU, BR_NONE, 0, 1);
        check_control(7'b0110011, 3'b101, 7'b0100000, ALU_SRA, IMM_I, A_RS1, 0, 1, 0, 0, WB_ALU, BR_NONE, 0, 1);

        // I 型 ALU：ADDI、ANDI、ORI、XORI
        check_control(7'b0010011, 3'b000, 7'b1111111, ALU_ADD, IMM_I, A_RS1, 1, 1, 0, 0, WB_ALU, BR_NONE, 0, 1);
        check_control(7'b0010011, 3'b111, 7'b1010101, ALU_AND, IMM_I, A_RS1, 1, 1, 0, 0, WB_ALU, BR_NONE, 0, 1);
        check_control(7'b0010011, 3'b110, 7'b1010101, ALU_OR,  IMM_I, A_RS1, 1, 1, 0, 0, WB_ALU, BR_NONE, 0, 1);
        check_control(7'b0010011, 3'b100, 7'b1010101, ALU_XOR, IMM_I, A_RS1, 1, 1, 0, 0, WB_ALU, BR_NONE, 0, 1);

        // LW、SW、BEQ、BNE、JAL、JALR、LUI、AUIPC
        check_control(7'b0000011, 3'b010, 7'b0000000, ALU_ADD, IMM_I, A_RS1, 1, 1, 1, 0, WB_MEM, BR_NONE, 0, 1);
        check_control(7'b0100011, 3'b010, 7'b0000000, ALU_ADD, IMM_S, A_RS1, 1, 0, 0, 1, WB_ALU, BR_NONE, 0, 1);
        check_control(7'b1100011, 3'b000, 7'b0000000, ALU_SUB, IMM_B, A_RS1, 0, 0, 0, 0, WB_ALU, BR_EQ,   0, 1);
        check_control(7'b1100011, 3'b001, 7'b0000000, ALU_SUB, IMM_B, A_RS1, 0, 0, 0, 0, WB_ALU, BR_NE,   0, 1);
        check_control(7'b1101111, 3'b000, 7'b0000000, ALU_ADD, IMM_J, A_PC,  1, 1, 0, 0, WB_PC4, BR_NONE, 1, 1);
        check_control(7'b1100111, 3'b000, 7'b0000000, ALU_ADD, IMM_I, A_RS1, 1, 1, 0, 0, WB_PC4, BR_NONE, 0, 1);
        check_control(7'b1100111, 3'b001, 7'b0000000, ALU_ADD, IMM_I, A_RS1, 0, 0, 0, 0, WB_ALU, BR_NONE, 0, 0);
        check_control(7'b0110111, 3'b000, 7'b0000000, ALU_ADD, IMM_U, A_ZERO,1, 1, 0, 0, WB_ALU, BR_NONE, 0, 1);
        check_control(7'b0010111, 3'b000, 7'b0000000, ALU_ADD, IMM_U, A_PC,  1, 1, 0, 0, WB_ALU, BR_NONE, 0, 1);

        // 非法 funct7 和未知 opcode 必须关闭所有写使能
        check_control(7'b0110011, 3'b000, 7'b1111111, ALU_ADD, IMM_I, A_RS1, 0, 0, 0, 0, WB_ALU, BR_NONE, 0, 0);
        check_control(7'b1111111, 3'b111, 7'b1111111, ALU_ADD, IMM_I, A_RS1, 0, 0, 0, 0, WB_ALU, BR_NONE, 0, 0);

        if (error_count == 0)
            $display("PASS: all %0d control unit tests passed", test_count);
        else
            $fatal(1, "FAIL: %0d of %0d control unit tests failed",
                   error_count, test_count);

        $finish;
    end

endmodule
