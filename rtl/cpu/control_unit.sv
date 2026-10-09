`timescale 1ns/1ps

module control_unit (
    input  logic [6:0] opcode,
    input  logic [2:0] funct3,
    input  logic [6:0] funct7,

    output logic [3:0] alu_op,
    output logic [2:0] imm_type,
    output logic [1:0] alu_a_sel,
    output logic       alu_src_imm,
    output logic       reg_write,
    output logic       mem_read,
    output logic       mem_write,
    output logic [1:0] wb_sel,
    output logic [1:0] branch_type,
    output logic       jump,
    output logic       jump_reg,
    output logic       instruction_valid
);

    localparam logic [6:0] OPCODE_OP     = 7'b0110011;
    localparam logic [6:0] OPCODE_OP_IMM = 7'b0010011;
    localparam logic [6:0] OPCODE_LOAD   = 7'b0000011;
    localparam logic [6:0] OPCODE_STORE  = 7'b0100011;
    localparam logic [6:0] OPCODE_BRANCH = 7'b1100011;
    localparam logic [6:0] OPCODE_JAL    = 7'b1101111;
    localparam logic [6:0] OPCODE_JALR   = 7'b1100111;
    localparam logic [6:0] OPCODE_LUI    = 7'b0110111;
    localparam logic [6:0] OPCODE_AUIPC  = 7'b0010111;

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

    localparam logic [1:0] ALU_A_RS1  = 2'b00;
    localparam logic [1:0] ALU_A_PC   = 2'b01;
    localparam logic [1:0] ALU_A_ZERO = 2'b10;

    localparam logic [1:0] WB_ALU = 2'b00;
    localparam logic [1:0] WB_MEM = 2'b01;
    localparam logic [1:0] WB_PC4 = 2'b10;

    localparam logic [1:0] BR_NONE = 2'b00;
    localparam logic [1:0] BR_EQ   = 2'b01;
    localparam logic [1:0] BR_NE   = 2'b10;

    always_comb begin
        alu_op            = ALU_ADD;
        imm_type          = IMM_I;
        alu_a_sel         = ALU_A_RS1;
        alu_src_imm       = 1'b0;
        reg_write         = 1'b0;
        mem_read          = 1'b0;
        mem_write         = 1'b0;
        wb_sel            = WB_ALU;
        branch_type       = BR_NONE;
        jump              = 1'b0;
        jump_reg          = 1'b0;
        instruction_valid = 1'b0;

        case (opcode)
            OPCODE_OP: begin
                case (funct3)
                    3'b000: begin
                        if (funct7 == 7'b0000000) begin
                            alu_op = ALU_ADD;
                            reg_write = 1'b1;
                            instruction_valid = 1'b1;
                        end else if (funct7 == 7'b0100000) begin
                            alu_op = ALU_SUB;
                            reg_write = 1'b1;
                            instruction_valid = 1'b1;
                        end
                    end
                    3'b111: begin
                        if (funct7 == 7'b0000000) begin
                            alu_op = ALU_AND;
                            reg_write = 1'b1;
                            instruction_valid = 1'b1;
                        end
                    end
                    3'b110: begin
                        if (funct7 == 7'b0000000) begin
                            alu_op = ALU_OR;
                            reg_write = 1'b1;
                            instruction_valid = 1'b1;
                        end
                    end
                    3'b100: begin
                        if (funct7 == 7'b0000000) begin
                            alu_op = ALU_XOR;
                            reg_write = 1'b1;
                            instruction_valid = 1'b1;
                        end
                    end
                    3'b010: begin
                        if (funct7 == 7'b0000000) begin
                            alu_op = ALU_SLT;
                            reg_write = 1'b1;
                            instruction_valid = 1'b1;
                        end
                    end
                    3'b001: begin
                        if (funct7 == 7'b0000000) begin
                            alu_op = ALU_SLL;
                            reg_write = 1'b1;
                            instruction_valid = 1'b1;
                        end
                    end
                    3'b101: begin
                        if (funct7 == 7'b0000000) begin
                            alu_op = ALU_SRL;
                            reg_write = 1'b1;
                            instruction_valid = 1'b1;
                        end else if (funct7 == 7'b0100000) begin
                            alu_op = ALU_SRA;
                            reg_write = 1'b1;
                            instruction_valid = 1'b1;
                        end
                    end
                    default: begin
                    end
                endcase
            end

            OPCODE_OP_IMM: begin
                imm_type    = IMM_I;
                alu_src_imm = 1'b1;

                case (funct3)
                    3'b000: begin
                        alu_op = ALU_ADD;
                        reg_write = 1'b1;
                        instruction_valid = 1'b1;
                    end
                    3'b111: begin
                        alu_op = ALU_AND;
                        reg_write = 1'b1;
                        instruction_valid = 1'b1;
                    end
                    3'b110: begin
                        alu_op = ALU_OR;
                        reg_write = 1'b1;
                        instruction_valid = 1'b1;
                    end
                    3'b100: begin
                        alu_op = ALU_XOR;
                        reg_write = 1'b1;
                        instruction_valid = 1'b1;
                    end
                    default: begin
                    end
                endcase
            end

            OPCODE_LOAD: begin
                if (funct3 == 3'b010) begin
                    alu_op            = ALU_ADD;
                    imm_type          = IMM_I;
                    alu_src_imm       = 1'b1;
                    reg_write         = 1'b1;
                    mem_read          = 1'b1;
                    wb_sel            = WB_MEM;
                    instruction_valid = 1'b1;
                end
            end

            OPCODE_STORE: begin
                if (funct3 == 3'b010) begin
                    alu_op            = ALU_ADD;
                    imm_type          = IMM_S;
                    alu_src_imm       = 1'b1;
                    mem_write         = 1'b1;
                    instruction_valid = 1'b1;
                end
            end

            OPCODE_BRANCH: begin
                alu_op      = ALU_SUB;
                imm_type    = IMM_B;

                case (funct3)
                    3'b000: begin
                        branch_type       = BR_EQ;
                        instruction_valid = 1'b1;
                    end
                    3'b001: begin
                        branch_type       = BR_NE;
                        instruction_valid = 1'b1;
                    end
                    default: begin
                    end
                endcase
            end

            OPCODE_JAL: begin
                alu_op            = ALU_ADD;
                imm_type          = IMM_J;
                alu_a_sel         = ALU_A_PC;
                alu_src_imm       = 1'b1;
                reg_write         = 1'b1;
                wb_sel            = WB_PC4;
                jump              = 1'b1;
                instruction_valid = 1'b1;
            end

            OPCODE_JALR: begin
                if (funct3 == 3'b000) begin
                    alu_op            = ALU_ADD;
                    imm_type          = IMM_I;
                    alu_a_sel         = ALU_A_RS1;
                    alu_src_imm       = 1'b1;
                    reg_write         = 1'b1;
                    wb_sel            = WB_PC4;
                    jump_reg          = 1'b1;
                    instruction_valid = 1'b1;
                end
            end

            OPCODE_LUI: begin
                alu_op            = ALU_ADD;
                imm_type          = IMM_U;
                alu_a_sel         = ALU_A_ZERO;
                alu_src_imm       = 1'b1;
                reg_write         = 1'b1;
                instruction_valid = 1'b1;
            end

            OPCODE_AUIPC: begin
                alu_op            = ALU_ADD;
                imm_type          = IMM_U;
                alu_a_sel         = ALU_A_PC;
                alu_src_imm       = 1'b1;
                reg_write         = 1'b1;
                instruction_valid = 1'b1;
            end

            default: begin
            end
        endcase
    end

endmodule
