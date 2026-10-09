`timescale 1ns/1ps

module reg_file_tb;

    logic        clk;
    logic        write_enable;
    logic [4:0]  rs1_addr;
    logic [4:0]  rs2_addr;
    logic [4:0]  rd_addr;
    logic [31:0] rd_data;
    logic [31:0] rs1_data;
    logic [31:0] rs2_data;

    integer test_count;
    integer error_count;

    reg_file dut (
        .clk          (clk),
        .write_enable (write_enable),
        .rs1_addr     (rs1_addr),
        .rs2_addr     (rs2_addr),
        .rd_addr      (rd_addr),
        .rd_data      (rd_data),
        .rs1_data     (rs1_data),
        .rs2_data     (rs2_data)
    );

    always #5 clk = ~clk;

    task automatic write_register(
        input logic [4:0]  address,
        input logic [31:0] data
    );
        begin
            @(negedge clk);
            write_enable = 1'b1;
            rd_addr      = address;
            rd_data      = data;
            @(posedge clk);
            #1;
            write_enable = 1'b0;
        end
    endtask

    task automatic check_read(
        input logic [4:0]  test_rs1_addr,
        input logic [4:0]  test_rs2_addr,
        input logic [31:0] expected_rs1_data,
        input logic [31:0] expected_rs2_data
    );
        begin
            rs1_addr = test_rs1_addr;
            rs2_addr = test_rs2_addr;
            #1;

            test_count = test_count + 1;

            if (rs1_data !== expected_rs1_data) begin
                $display("ERROR: x%0d expected %08h, got %08h on rs1",
                         rs1_addr, expected_rs1_data, rs1_data);
                error_count = error_count + 1;
            end

            if (rs2_data !== expected_rs2_data) begin
                $display("ERROR: x%0d expected %08h, got %08h on rs2",
                         rs2_addr, expected_rs2_data, rs2_data);
                error_count = error_count + 1;
            end
        end
    endtask

    initial begin
        $dumpfile("waveforms/reg_file.vcd");
        $dumpvars(0, reg_file_tb);

        clk          = 1'b0;
        write_enable = 1'b0;
        rs1_addr     = 5'd0;
        rs2_addr     = 5'd0;
        rd_addr      = 5'd0;
        rd_data      = 32'b0;
        test_count   = 0;
        error_count  = 0;

        check_read(5'd0, 5'd0, 32'b0, 32'b0);

        write_register(5'd1, 32'h1234_5678);
        write_register(5'd2, 32'hdead_beef);
        check_read(5'd1, 5'd2, 32'h1234_5678, 32'hdead_beef);
        check_read(5'd2, 5'd1, 32'hdead_beef, 32'h1234_5678);

        write_register(5'd1, 32'hcafe_babe);
        check_read(5'd1, 5'd2, 32'hcafe_babe, 32'hdead_beef);

        @(negedge clk);
        write_enable = 1'b0;
        rd_addr      = 5'd2;
        rd_data      = 32'hffff_ffff;
        @(posedge clk);
        #1;
        check_read(5'd2, 5'd1, 32'hdead_beef, 32'hcafe_babe);

        write_register(5'd0, 32'hffff_ffff);
        check_read(5'd0, 5'd1, 32'b0, 32'hcafe_babe);

        if (error_count == 0)
            $display("PASS: all %0d register file checks passed", test_count);
        else
            $fatal(1, "FAIL: %0d register file check(s) failed", error_count);

        $finish;
    end

endmodule
