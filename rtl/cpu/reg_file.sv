`timescale 1ns/1ps

module reg_file (
    input  logic        clk,
    input  logic        write_enable,
    input  logic [4:0]  rs1_addr,
    input  logic [4:0]  rs2_addr,
    input  logic [4:0]  rd_addr,
    input  logic [31:0] rd_data,
    output logic [31:0] rs1_data,
    output logic [31:0] rs2_data
);

    // 只实现 x1～x31；x0 由读端口的默认值直接提供。
    logic [31:0] registers [1:31];

    integer read_index;
    always_comb begin
        rs1_data = 32'b0;
        rs2_data = 32'b0;

        for (read_index = 1; read_index < 32; read_index = read_index + 1) begin
            if (rs1_addr == 5'(read_index))
                rs1_data = registers[read_index];
            if (rs2_addr == 5'(read_index))
                rs2_data = registers[read_index];
        end
    end

    always_ff @(posedge clk) begin
        if (write_enable && (rd_addr != 5'd0))
            registers[rd_addr] <= rd_data;
    end

endmodule
