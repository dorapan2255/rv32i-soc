`timescale 1ns/1ps

module data_memory (
    input  logic        clk,
    input  logic        mem_read,
    input  logic        mem_write,
    input  logic [31:0] address,
    input  logic [31:0] write_data,
    output logic [31:0] read_data
);

    logic [31:0] memory [0:255];

    always_comb begin
        read_data = 32'b0;

        if (mem_read &&
            (address[31:10] == 22'b0) &&
            (address[1:0] == 2'b00))
            read_data = memory[address[9:2]];
    end

    always_ff @(posedge clk) begin
        if (mem_write &&
            (address[31:10] == 22'b0) &&
            (address[1:0] == 2'b00))
            memory[address[9:2]] <= write_data;
    end

endmodule
