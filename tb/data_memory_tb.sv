`timescale 1ns/1ps

module data_memory_tb;

    logic        clk;
    logic        mem_read;
    logic        mem_write;
    logic [31:0] address;
    logic [31:0] write_data;
    logic [31:0] read_data;

    integer test_count;
    integer error_count;

    data_memory dut (
        .clk        (clk),
        .mem_read   (mem_read),
        .mem_write  (mem_write),
        .address    (address),
        .write_data (write_data),
        .read_data  (read_data)
    );

    always #5 clk = ~clk;

    task automatic write_word(
        input logic [31:0] test_address,
        input logic [31:0] test_data
    );
        begin
            @(negedge clk);
            mem_write = 1'b1;
            address   = test_address;
            write_data = test_data;
            @(posedge clk);
            #1;
            mem_write = 1'b0;
        end
    endtask

    task automatic check_read(
        input logic [31:0] test_address,
        input logic        test_mem_read,
        input logic [31:0] expected_data
    );
        begin
            address  = test_address;
            mem_read = test_mem_read;
            #1;
            test_count = test_count + 1;

            if (read_data !== expected_data) begin
                $display("ERROR: address=%08h mem_read=%0b expected=%08h got=%08h",
                         address, mem_read, expected_data, read_data);
                error_count = error_count + 1;
            end
        end
    endtask

    initial begin
        $dumpfile("waveforms/data_memory.vcd");
        $dumpvars(0, data_memory_tb);

        clk         = 1'b0;
        mem_read    = 1'b0;
        mem_write   = 1'b0;
        address     = 32'b0;
        write_data  = 32'b0;
        test_count  = 0;
        error_count = 0;

        write_word(32'h0000_0000, 32'h1234_5678);
        write_word(32'h0000_0004, 32'hdead_beef);
        check_read(32'h0000_0000, 1'b1, 32'h1234_5678);
        check_read(32'h0000_0004, 1'b1, 32'hdead_beef);

        // 同一地址再次写入，应覆盖旧值。
        write_word(32'h0000_0004, 32'hcafe_babe);
        check_read(32'h0000_0004, 1'b1, 32'hcafe_babe);

        // 关闭读使能后，输出为零。
        check_read(32'h0000_0004, 1'b0, 32'b0);

        // 未对齐写和越界写都应被忽略。
        write_word(32'h0000_0002, 32'hffff_ffff);
        write_word(32'h0000_0400, 32'hffff_ffff);
        check_read(32'h0000_0000, 1'b1, 32'h1234_5678);
        check_read(32'h0000_0002, 1'b1, 32'b0);
        check_read(32'h0000_0400, 1'b1, 32'b0);

        if (error_count == 0)
            $display("PASS: all %0d data memory tests passed", test_count);
        else
            $fatal(1, "FAIL: %0d of %0d data memory tests failed",
                   error_count, test_count);

        $finish;
    end

endmodule
