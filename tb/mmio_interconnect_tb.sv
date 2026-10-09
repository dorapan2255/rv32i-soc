`timescale 1ns/1ps

module mmio_interconnect_tb;

    logic        cpu_mem_read;
    logic        cpu_mem_write;
    logic [31:0] cpu_address;
    logic [31:0] cpu_write_data;
    logic [31:0] cpu_read_data;
    logic        ram_read;
    logic        ram_write;
    logic [31:0] ram_read_data;
    logic        uart_write;
    logic [7:0]  uart_write_data;
    logic        uart_busy;
    logic        timer_count_write;
    logic        timer_control_write;
    logic [31:0] timer_write_data;
    logic [31:0] timer_count;
    logic        timer_enabled;

    integer test_count;
    integer error_count;

    mmio_interconnect dut (
        .cpu_mem_read   (cpu_mem_read),
        .cpu_mem_write  (cpu_mem_write),
        .cpu_address    (cpu_address),
        .cpu_write_data (cpu_write_data),
        .cpu_read_data  (cpu_read_data),
        .ram_read       (ram_read),
        .ram_write      (ram_write),
        .ram_read_data  (ram_read_data),
        .uart_write     (uart_write),
        .uart_write_data(uart_write_data),
        .uart_busy      (uart_busy),
        .timer_count_write  (timer_count_write),
        .timer_control_write(timer_control_write),
        .timer_write_data   (timer_write_data),
        .timer_count        (timer_count),
        .timer_enabled      (timer_enabled)
    );

    task automatic check_outputs(
        input logic [31:0] expected_read_data,
        input logic expected_ram_read,
        input logic expected_ram_write,
        input logic expected_uart_write,
        input logic expected_timer_count_write,
        input logic expected_timer_control_write
    );
        begin
            #1;
            test_count = test_count + 1;
            if ((cpu_read_data !== expected_read_data) ||
                (ram_read !== expected_ram_read) ||
                (ram_write !== expected_ram_write) ||
                (uart_write !== expected_uart_write) ||
                (timer_count_write !== expected_timer_count_write) ||
                (timer_control_write !== expected_timer_control_write)) begin
                $display("ERROR: addr=%08h read=%0b write=%0b busy=%0b",
                         cpu_address, cpu_mem_read, cpu_mem_write, uart_busy);
                $display(" expected data=%08h rr=%0b rw=%0b uw=%0b tcw=%0b trw=%0b",
                         expected_read_data, expected_ram_read,
                         expected_ram_write, expected_uart_write,
                         expected_timer_count_write,
                         expected_timer_control_write);
                $display("      got data=%08h rr=%0b rw=%0b uw=%0b tcw=%0b trw=%0b",
                         cpu_read_data, ram_read, ram_write, uart_write,
                         timer_count_write, timer_control_write);
                error_count = error_count + 1;
            end
        end
    endtask

    initial begin
        $dumpfile("waveforms/mmio_interconnect.vcd");
        $dumpvars(0, mmio_interconnect_tb);

        cpu_mem_read   = 1'b0;
        cpu_mem_write  = 1'b0;
        cpu_address    = 32'b0;
        cpu_write_data = 32'h1234_5641;
        ram_read_data  = 32'hdead_beef;
        uart_busy      = 1'b0;
        timer_count    = 32'h1234_5678;
        timer_enabled  = 1'b1;
        test_count     = 0;
        error_count    = 0;

        cpu_mem_read = 1'b1;
        check_outputs(32'hdead_beef, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0);

        cpu_mem_read  = 1'b0;
        cpu_mem_write = 1'b1;
        check_outputs(32'b0, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0);

        cpu_address = 32'h1000_0000;
        check_outputs(32'b0, 1'b0, 1'b0, 1'b1, 1'b0, 1'b0);
        if (uart_write_data !== 8'h41) begin
            $display("ERROR: UART write data expected=41 got=%02h", uart_write_data);
            error_count = error_count + 1;
        end

        uart_busy = 1'b1;
        check_outputs(32'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0);

        cpu_mem_write = 1'b0;
        cpu_mem_read  = 1'b1;
        cpu_address   = 32'h1000_0004;
        check_outputs(32'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0);

        uart_busy = 1'b0;
        check_outputs(32'd1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0);

        cpu_address = 32'h1000_0010;
        check_outputs(32'h1234_5678, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0);

        cpu_address = 32'h1000_0014;
        check_outputs(32'd1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0);

        cpu_mem_read  = 1'b0;
        cpu_mem_write = 1'b1;
        cpu_address   = 32'h1000_0010;
        check_outputs(32'b0, 1'b0, 1'b0, 1'b0, 1'b1, 1'b0);
        if (timer_write_data !== cpu_write_data) begin
            $display("ERROR: timer write data expected=%08h got=%08h",
                     cpu_write_data, timer_write_data);
            error_count = error_count + 1;
        end

        cpu_address = 32'h1000_0014;
        check_outputs(32'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1);

        cpu_mem_write = 1'b0;
        cpu_mem_read  = 1'b1;
        cpu_address = 32'h2000_0000;
        check_outputs(32'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0);

        if (error_count == 0)
            $display("PASS: all %0d MMIO interconnect tests passed", test_count);
        else
            $fatal(1, "FAIL: %0d MMIO interconnect error(s)", error_count);

        $finish;
    end

endmodule
