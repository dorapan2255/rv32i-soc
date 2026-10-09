`timescale 1ns/1ps

module rv32i_core (
    input  logic        clk,
    input  logic        reset,

    output logic [31:0] instruction_address,
    input  logic [31:0] instruction,

    output logic        data_mem_read,
    output logic        data_mem_write,
    output logic [31:0] data_address,
    output logic [31:0] data_write_data,
    input  logic [31:0] data_read_data,

    output logic        instruction_valid
);

    logic [31:0] current_pc;
    logic [31:0] next_pc;

    logic [6:0]  opcode;
    logic [4:0]  rd_addr;
    logic [2:0]  funct3;
    logic [4:0]  rs1_addr;
    logic [4:0]  rs2_addr;
    logic [6:0]  funct7;

    logic [3:0]  alu_op;
    logic [2:0]  imm_type;
    logic [1:0]  alu_a_sel;
    logic        alu_src_imm;
    logic        reg_write;
    logic        control_mem_read;
    logic        control_mem_write;
    logic [1:0]  wb_sel;
    logic [1:0]  branch_type;
    logic        jump;
    logic        jump_reg;

    logic [31:0] rs1_data;
    logic [31:0] rs2_data;
    logic [31:0] immediate;
    logic [31:0] alu_a;
    logic [31:0] alu_b;
    logic [31:0] alu_result;
    logic [31:0] writeback_data;
    // 仅用于观察分支判定；PC 选择已经由 next_pc 表达。
    /* verilator lint_off UNUSEDSIGNAL */
    logic        branch_taken;
    /* verilator lint_on UNUSEDSIGNAL */

    localparam logic [1:0] ALU_A_RS1  = 2'b00;
    localparam logic [1:0] ALU_A_PC   = 2'b01;
    localparam logic [1:0] ALU_A_ZERO = 2'b10;

    localparam logic [1:0] WB_ALU = 2'b00;
    localparam logic [1:0] WB_MEM = 2'b01;
    localparam logic [1:0] WB_PC4 = 2'b10;

    assign instruction_address = current_pc;
    assign data_address        = alu_result;
    assign data_write_data     = rs2_data;
    assign data_mem_read       = control_mem_read && !reset;
    assign data_mem_write      = control_mem_write && !reset;

    pc u_pc (
        .clk        (clk),
        .reset      (reset),
        .next_pc    (next_pc),
        .current_pc (current_pc)
    );

    decoder u_decoder (
        .instruction (instruction),
        .opcode      (opcode),
        .rd_addr     (rd_addr),
        .funct3      (funct3),
        .rs1_addr    (rs1_addr),
        .rs2_addr    (rs2_addr),
        .funct7      (funct7)
    );

    control_unit u_control_unit (
        .opcode            (opcode),
        .funct3            (funct3),
        .funct7            (funct7),
        .alu_op            (alu_op),
        .imm_type          (imm_type),
        .alu_a_sel         (alu_a_sel),
        .alu_src_imm       (alu_src_imm),
        .reg_write         (reg_write),
        .mem_read          (control_mem_read),
        .mem_write         (control_mem_write),
        .wb_sel            (wb_sel),
        .branch_type       (branch_type),
        .jump              (jump),
        .jump_reg          (jump_reg),
        .instruction_valid (instruction_valid)
    );

    reg_file u_reg_file (
        .clk          (clk),
        .write_enable (reg_write && !reset),
        .rs1_addr     (rs1_addr),
        .rs2_addr     (rs2_addr),
        .rd_addr      (rd_addr),
        .rd_data      (writeback_data),
        .rs1_data     (rs1_data),
        .rs2_data     (rs2_data)
    );

    imm_gen u_imm_gen (
        .instruction (instruction),
        .imm_type    (imm_type),
        .immediate   (immediate)
    );

    always_comb begin
        case (alu_a_sel)
            ALU_A_RS1:  alu_a = rs1_data;
            ALU_A_PC:   alu_a = current_pc;
            ALU_A_ZERO: alu_a = 32'b0;
            default:    alu_a = 32'b0;
        endcase

        if (alu_src_imm)
            alu_b = immediate;
        else
            alu_b = rs2_data;
    end

    alu u_alu (
        .a      (alu_a),
        .b      (alu_b),
        .alu_op (alu_op),
        .result (alu_result)
    );

    always_comb begin
        case (wb_sel)
            WB_ALU: writeback_data = alu_result;
            WB_MEM: writeback_data = data_read_data;
            WB_PC4: writeback_data = current_pc + 32'd4;
            default: writeback_data = 32'b0;
        endcase
    end

    branch_jump_unit u_branch_jump_unit (
        .current_pc   (current_pc),
        .immediate    (immediate),
        .alu_result   (alu_result),
        .branch_type  (branch_type),
        .jump         (jump),
        .jump_reg     (jump_reg),
        .branch_taken (branch_taken),
        .next_pc      (next_pc)
    );

endmodule
