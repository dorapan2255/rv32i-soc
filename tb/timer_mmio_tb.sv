`timescale 1ns/1ps

module timer_mmio_tb;

    logic        clk;
    logic        reset;
    logic        uart_tx_line;
    logic        debug_uart_busy;
    logic [31:0] debug_pc;
    logic [31:0] debug_instruction;
    logic        debug_instruction_valid;

    integer error_count;
    integer cycle_count;

    rv32i_soc #(
        .UART_CLOCK_FREQ (40),
        .UART_BAUD_RATE  (10)
    ) dut (
        .clk                     (clk),
        .reset                   (reset),
        .uart_tx                 (uart_tx_line),
        .debug_uart_busy         (debug_uart_busy),
        .debug_pc                (debug_pc),
        .debug_instruction       (debug_instruction),
        .debug_instruction_valid (debug_instruction_valid)
    );

    always #5 clk = ~clk;

    initial begin
        $dumpfile("waveforms/timer_mmio.vcd");
        $dumpvars(0, timer_mmio_tb);

        clk         = 1'b0;
        reset       = 1'b1;
        error_count = 0;
        cycle_count = 0;

        $readmemh("software/timer_test.hex",
                  dut.u_instruction_memory.memory);
        $readmemh("software/timer_test.data.hex",
                  dut.u_data_memory.memory);

        repeat (2) @(posedge clk);
        @(negedge clk);
        reset = 1'b0;

        while ((debug_pc !== 32'd52) && (cycle_count < 40)) begin
            @(posedge clk);
            cycle_count = cycle_count + 1;
        end
        #1;

        if (cycle_count >= 40) begin
            $display("ERROR: timer program did not reach loop");
            error_count = error_count + 1;
        end

        if (dut.u_core.u_reg_file.registers[3] == 32'd0) begin
            $display("ERROR: running timer count read back as zero");
            error_count = error_count + 1;
        end

        if (dut.u_core.u_reg_file.registers[4] !==
            dut.u_core.u_reg_file.registers[5]) begin
            $display("ERROR: stopped timer changed: x4=%08h x5=%08h",
                     dut.u_core.u_reg_file.registers[4],
                     dut.u_core.u_reg_file.registers[5]);
            error_count = error_count + 1;
        end

        if (dut.u_timer.enabled !== 1'b0) begin
            $display("ERROR: timer should be disabled at program end");
            error_count = error_count + 1;
        end

        if (error_count == 0)
            $display("PASS: CPU controlled and read the MMIO timer");
        else
            $fatal(1, "FAIL: %0d MMIO timer error(s)", error_count);

        $finish;
    end

endmodule
