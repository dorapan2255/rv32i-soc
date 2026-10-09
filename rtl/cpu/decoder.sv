`timescale 1ns/1ps

module decoder (
    input  logic [31:0] instruction,
    output logic [6:0]  opcode,
    output logic [4:0]  rd_addr,
    output logic [2:0]  funct3,
    output logic [4:0]  rs1_addr,
    output logic [4:0]  rs2_addr,
    output logic [6:0]  funct7
);

    assign opcode   = instruction[6:0];
    assign rd_addr  = instruction[11:7];
    assign funct3   = instruction[14:12];
    assign rs1_addr = instruction[19:15];
    assign rs2_addr = instruction[24:20];
    assign funct7   = instruction[31:25];

endmodule
