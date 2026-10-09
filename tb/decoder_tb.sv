`timescale 1ns/1ps

module decoder_tb;

    logic [31:0] instruction;
    logic [6:0]  opcode;
    logic [4:0]  rd_addr;
    logic [2:0]  funct3;
    logic [4:0]  rs1_addr;
    logic [4:0]  rs2_addr;
    logic [6:0]  funct7;

    integer test_count;
    integer error_count;

    decoder dut (
        .instruction (instruction),
        .opcode      (opcode),
        .rd_addr     (rd_addr),
        .funct3      (funct3),
        .rs1_addr    (rs1_addr),
        .rs2_addr    (rs2_addr),
        .funct7      (funct7)
    );

    task automatic check_fields(
        input logic [31:0] test_instruction,
        input logic [6:0]  expected_opcode,
        input logic [4:0]  expected_rd_addr,
        input logic [2:0]  expected_funct3,
        input logic [4:0]  expected_rs1_addr,
        input logic [4:0]  expected_rs2_addr,
        input logic [6:0]  expected_funct7
    );
        begin
            instruction = test_instruction;
            #1;
            test_count = test_count + 1;

            if ((opcode   !== expected_opcode)   ||
                (rd_addr  !== expected_rd_addr)  ||
                (funct3   !== expected_funct3)   ||
                (rs1_addr !== expected_rs1_addr) ||
                (rs2_addr !== expected_rs2_addr) ||
                (funct7   !== expected_funct7)) begin
                $display("ERROR: instruction=%08h", instruction);
                $display("  opcode expected=%02h got=%02h", expected_opcode, opcode);
                $display("  rd     expected=%0d got=%0d", expected_rd_addr, rd_addr);
                $display("  funct3 expected=%01h got=%01h", expected_funct3, funct3);
                $display("  rs1    expected=%0d got=%0d", expected_rs1_addr, rs1_addr);
                $display("  rs2    expected=%0d got=%0d", expected_rs2_addr, rs2_addr);
                $display("  funct7 expected=%02h got=%02h", expected_funct7, funct7);
                error_count = error_count + 1;
            end
        end
    endtask

    initial begin
        $dumpfile("waveforms/decoder.vcd");
        $dumpvars(0, decoder_tb);

        instruction = 32'b0;
        test_count  = 0;
        error_count = 0;

        // ADD x3, x1, x2
        check_fields(32'h0020_81b3, 7'b0110011, 5'd3, 3'b000,
                     5'd1, 5'd2, 7'b0000000);

        // SUB x6, x4, x5
        check_fields(32'h4052_0333, 7'b0110011, 5'd6, 3'b000,
                     5'd4, 5'd5, 7'b0100000);

        // ADDI x5, x4, -8
        check_fields(32'hff82_0293, 7'b0010011, 5'd5, 3'b000,
                     5'd4, 5'd24, 7'b1111111);

        // LW x7, 12(x8)
        check_fields(32'h00c4_2383, 7'b0000011, 5'd7, 3'b010,
                     5'd8, 5'd12, 7'b0000000);

        // SW x7, 16(x8); S 型的 instruction[11:7] 不是 rd
        check_fields(32'h0074_2823, 7'b0100011, 5'd16, 3'b010,
                     5'd8, 5'd7, 7'b0000000);

        // BEQ x1, x2, 16; B 型的 instruction[11:7] 不是 rd
        check_fields(32'h0020_8863, 7'b1100011, 5'd16, 3'b000,
                     5'd1, 5'd2, 7'b0000000);

        // JAL x1, 2048
        check_fields(32'h0010_00ef, 7'b1101111, 5'd1, 3'b000,
                     5'd0, 5'd1, 7'b0000000);

        // LUI x10, 0x12345
        check_fields(32'h1234_5537, 7'b0110111, 5'd10, 3'b101,
                     5'd8, 5'd3, 7'b0001001);

        // AUIPC x11, 0x12345
        check_fields(32'h1234_5597, 7'b0010111, 5'd11, 3'b101,
                     5'd8, 5'd3, 7'b0001001);

        if (error_count == 0)
            $display("PASS: all %0d decoder tests passed", test_count);
        else
            $fatal(1, "FAIL: %0d of %0d decoder tests failed",
                   error_count, test_count);

        $finish;
    end

endmodule
