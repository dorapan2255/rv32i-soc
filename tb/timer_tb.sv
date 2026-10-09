`timescale 1ns/1ps

module timer_tb;

    logic        clk;
    logic        reset;
    logic        count_write;
    logic [31:0] count_write_data;
    logic        control_write;
    logic        control_enable;
    logic [31:0] count;
    logic        enabled;

    integer test_count;
    integer error_count;

    timer dut (
        .clk              (clk),
        .reset            (reset),
        .count_write      (count_write),
        .count_write_data (count_write_data),
        .control_write    (control_write),
        .control_enable   (control_enable),
        .count            (count),
        .enabled          (enabled)
    );

    always #5 clk = ~clk;

    task automatic check_state(
        input logic [31:0] expected_count,
        input logic expected_enabled
    );
        begin
            test_count = test_count + 1;
            if ((count !== expected_count) ||
                (enabled !== expected_enabled)) begin
                $display("ERROR: expected count=%08h enabled=%0b, got count=%08h enabled=%0b",
                         expected_count, expected_enabled, count, enabled);
                error_count = error_count + 1;
            end
        end
    endtask

    initial begin
        $dumpfile("waveforms/timer.vcd");
        $dumpvars(0, timer_tb);

        clk              = 1'b0;
        reset            = 1'b1;
        count_write      = 1'b0;
        count_write_data = 32'b0;
        control_write    = 1'b0;
        control_enable   = 1'b0;
        test_count       = 0;
        error_count      = 0;

        @(posedge clk); #1;
        check_state(32'd0, 1'b0);

        reset = 1'b0;
        repeat (2) @(posedge clk);
        #1;
        check_state(32'd0, 1'b0);

        control_write  = 1'b1;
        control_enable = 1'b1;
        @(posedge clk); #1;
        control_write = 1'b0;
        check_state(32'd0, 1'b1);

        repeat (3) @(posedge clk);
        #1;
        check_state(32'd3, 1'b1);

        count_write      = 1'b1;
        count_write_data = 32'hffff_fffe;
        @(posedge clk); #1;
        count_write = 1'b0;
        check_state(32'hffff_fffe, 1'b1);

        repeat (2) @(posedge clk);
        #1;
        check_state(32'd0, 1'b1);

        control_write  = 1'b1;
        control_enable = 1'b0;
        @(posedge clk); #1;
        control_write = 1'b0;
        check_state(32'd0, 1'b0);

        repeat (2) @(posedge clk);
        #1;
        check_state(32'd0, 1'b0);

        if (error_count == 0)
            $display("PASS: all %0d timer checks passed", test_count);
        else
            $fatal(1, "FAIL: %0d timer error(s)", error_count);

        $finish;
    end

endmodule
