`timescale 1ns/1ps

module alu_tb;

    localparam logic [3:0] ALU_ADD = 4'b0000;
    localparam logic [3:0] ALU_SUB = 4'b0001;
    localparam logic [3:0] ALU_AND = 4'b0010;
    localparam logic [3:0] ALU_OR  = 4'b0011;
    localparam logic [3:0] ALU_XOR = 4'b0100;
    localparam logic [3:0] ALU_SLT = 4'b0101;
    localparam logic [3:0] ALU_SLL = 4'b0110;
    localparam logic [3:0] ALU_SRL = 4'b0111;
    localparam logic [3:0] ALU_SRA = 4'b1000;

    logic [31:0] a;
    logic [31:0] b;
    logic [3:0]  alu_op;
    logic [31:0] result;

    integer test_count;
    integer error_count;

    alu dut (
        .a      (a),
        .b      (b),
        .alu_op (alu_op),
        .result (result)
    );

    task automatic check_alu(
        input logic [31:0] test_a,
        input logic [31:0] test_b,
        input logic [3:0]  test_op,
        input logic [31:0] expected_result
    );
        begin
            a      = test_a;
            b      = test_b;
            alu_op = test_op;
            #1;

            test_count = test_count + 1;
            if (result !== expected_result) begin
                $display("ERROR: op=%04b a=%08h b=%08h expected=%08h got=%08h",
                         alu_op, a, b, expected_result, result);
                error_count = error_count + 1;
            end
        end
    endtask

    initial begin
        $dumpfile("waveforms/alu.vcd");
        $dumpvars(0, alu_tb);

        test_count  = 0;
        error_count = 0;

        check_alu(32'd10,        32'd20,        ALU_ADD, 32'd30);
        check_alu(32'hffff_ffff, 32'd1,         ALU_ADD, 32'h0000_0000);
        check_alu(32'd20,        32'd7,         ALU_SUB, 32'd13);
        check_alu(32'd0,         32'd1,         ALU_SUB, 32'hffff_ffff);

        check_alu(32'haaaa_5555, 32'h0f0f_0f0f, ALU_AND, 32'h0a0a_0505);
        check_alu(32'haaaa_5555, 32'h0f0f_0f0f, ALU_OR,  32'hafaf_5f5f);
        check_alu(32'haaaa_5555, 32'h0f0f_0f0f, ALU_XOR, 32'ha5a5_5a5a);

        check_alu(32'hffff_ffff, 32'd1,         ALU_SLT, 32'd1);
        check_alu(32'd1,         32'hffff_ffff, ALU_SLT, 32'd0);
        check_alu(32'd5,         32'd5,         ALU_SLT, 32'd0);

        check_alu(32'd1,         32'd0,         ALU_SLL, 32'd1);
        check_alu(32'd1,         32'd31,        ALU_SLL, 32'h8000_0000);
        check_alu(32'h8000_0000, 32'd31,        ALU_SRL, 32'd1);
        check_alu(32'h8000_0000, 32'd1,         ALU_SRA, 32'hc000_0000);
        check_alu(32'd3,         32'hffff_ffe1, ALU_SLL, 32'd6);

        check_alu(32'h1234_5678, 32'h8765_4321, 4'b1111, 32'b0);

        if (error_count == 0)
            $display("PASS: all %0d ALU tests passed", test_count);
        else
            $fatal(1, "FAIL: %0d of %0d ALU tests failed",
                   error_count, test_count);

        $finish;
    end

endmodule
