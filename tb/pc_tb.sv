`timescale 1ns/1ps

module pc_tb;

    logic        clk;
    logic        reset;
    logic [31:0] next_pc;
    logic [31:0] current_pc;

    integer test_count;
    integer error_count;

    pc dut (
        .clk        (clk),
        .reset      (reset),
        .next_pc    (next_pc),
        .current_pc (current_pc)
    );

    always #5 clk = ~clk;

    task automatic check_after_rising_edge(
        input logic [31:0] expected_pc
    );
        begin
            @(posedge clk);
            #1;
            test_count = test_count + 1;
            if (current_pc !== expected_pc) begin
                $display("ERROR: expected PC=%08h, got PC=%08h",
                         expected_pc, current_pc);
                error_count = error_count + 1;
            end
        end
    endtask

    initial begin
        $dumpfile("waveforms/pc.vcd");
        $dumpvars(0, pc_tb);

        clk         = 1'b0;
        reset       = 1'b1;
        next_pc     = 32'hffff_ffff;
        test_count  = 0;
        error_count = 0;

        check_after_rising_edge(32'h0000_0000);

        @(negedge clk);
        reset   = 1'b0;
        next_pc = 32'h0000_0004;
        check_after_rising_edge(32'h0000_0004);

        @(negedge clk);
        next_pc = 32'h0000_0008;
        check_after_rising_edge(32'h0000_0008);

        @(negedge clk);
        next_pc = 32'h0000_0100;
        check_after_rising_edge(32'h0000_0100);

        @(negedge clk);
        reset   = 1'b1;
        next_pc = 32'h1234_5678;
        check_after_rising_edge(32'h0000_0000);

        if (error_count == 0)
            $display("PASS: all %0d PC tests passed", test_count);
        else
            $fatal(1, "FAIL: %0d of %0d PC tests failed",
                   error_count, test_count);

        $finish;
    end

endmodule
