`timescale 1ns/1ps

module uart_tx_tb;

    localparam integer CLOCK_FREQ   = 40;
    localparam integer BAUD_RATE    = 10;
    localparam integer CLKS_PER_BIT = CLOCK_FREQ / BAUD_RATE;

    logic       clk;
    logic       reset;
    logic       write_enable;
    logic [7:0] write_data;
    logic       tx;
    logic       busy;

    integer test_count;
    integer error_count;

    uart_tx #(
        .CLOCK_FREQ (CLOCK_FREQ),
        .BAUD_RATE  (BAUD_RATE)
    ) dut (
        .clk          (clk),
        .reset        (reset),
        .write_enable (write_enable),
        .write_data   (write_data),
        .tx           (tx),
        .busy         (busy)
    );

    always #5 clk = ~clk;

    task automatic request_send(input logic [7:0] data);
        begin
            @(negedge clk);
            write_data   = data;
            write_enable = 1'b1;
            @(posedge clk);
            #1;
            write_enable = 1'b0;
        end
    endtask

    task automatic receive_and_check(input logic [7:0] expected_data);
        logic [7:0] received_data;
        integer bit_number;
        begin
            @(negedge tx);

            repeat (CLKS_PER_BIT / 2) @(posedge clk);
            #1;
            if (tx !== 1'b0) begin
                $display("ERROR: UART start bit is not low");
                error_count = error_count + 1;
            end

            for (bit_number = 0; bit_number < 8; bit_number = bit_number + 1) begin
                repeat (CLKS_PER_BIT) @(posedge clk);
                #1;
                received_data[bit_number] = tx;
            end

            repeat (CLKS_PER_BIT) @(posedge clk);
            #1;
            if (tx !== 1'b1) begin
                $display("ERROR: UART stop bit is not high");
                error_count = error_count + 1;
            end

            test_count = test_count + 1;
            if (received_data !== expected_data) begin
                $display("ERROR: expected byte=%02h got=%02h",
                         expected_data, received_data);
                error_count = error_count + 1;
            end
        end
    endtask

    initial begin
        $dumpfile("waveforms/uart_tx.vcd");
        $dumpvars(0, uart_tx_tb);

        clk          = 1'b0;
        reset        = 1'b1;
        write_enable = 1'b0;
        write_data   = 8'b0;
        test_count   = 0;
        error_count  = 0;

        repeat (2) @(posedge clk);
        @(negedge clk);
        reset = 1'b0;

        fork
            receive_and_check(8'h41);
            request_send(8'h41);
        join

        wait (busy == 1'b0);

        fork
            receive_and_check(8'h5a);
            begin
                request_send(8'h5a);
                // busy 期间请求发送 0xff，发送器必须忽略。
                repeat (2) @(negedge clk);
                write_data   = 8'hff;
                write_enable = 1'b1;
                @(posedge clk);
                #1;
                write_enable = 1'b0;
            end
        join

        wait (busy == 1'b0);
        repeat (2) @(posedge clk);

        if (error_count == 0)
            $display("PASS: all %0d UART TX bytes passed", test_count);
        else
            $fatal(1, "FAIL: %0d UART TX error(s)", error_count);

        $finish;
    end

endmodule
