`timescale 1ns/1ps

module system_demo_tb;

    localparam integer CLOCK_FREQ   = 40;
    localparam integer BAUD_RATE    = 10;
    localparam integer CLKS_PER_BIT = CLOCK_FREQ / BAUD_RATE;
    localparam integer FRAME_BYTES  = 11;

    logic        clk;
    logic        reset;
    logic        uart_tx_line;
    logic        debug_uart_busy;
    logic [31:0] debug_pc;
    logic [31:0] debug_instruction;
    logic        debug_instruction_valid;
    logic [7:0]  received [0:FRAME_BYTES-1];

    integer error_count;
    integer byte_number;
    logic [31:0] uart_sum;
    logic [31:0] uart_timer;

    rv32i_soc #(
        .UART_CLOCK_FREQ (CLOCK_FREQ),
        .UART_BAUD_RATE  (BAUD_RATE)
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

    // 程序跑飞或UART没有发送时，明确失败而不是让回归永久等待。
    initial begin
        repeat (2000) @(posedge clk);
        $fatal(1, "FAIL: system demo timeout");
    end

    task automatic receive_uart_byte(input integer index);
        integer bit_number;
        begin
            @(negedge uart_tx_line);
            repeat (CLKS_PER_BIT / 2) @(posedge clk);
            #1;

            if (uart_tx_line !== 1'b0) begin
                $display("ERROR: byte %0d start bit is not low", index);
                error_count = error_count + 1;
            end

            for (bit_number = 0; bit_number < 8; bit_number = bit_number + 1) begin
                repeat (CLKS_PER_BIT) @(posedge clk);
                #1;
                received[index][bit_number] = uart_tx_line;
            end

            repeat (CLKS_PER_BIT) @(posedge clk);
            #1;
            if (uart_tx_line !== 1'b1) begin
                $display("ERROR: byte %0d stop bit is not high", index);
                error_count = error_count + 1;
            end
        end
    endtask

    initial begin
        $dumpfile("waveforms/system_demo.vcd");
        $dumpvars(0, system_demo_tb);

        clk         = 1'b0;
        reset       = 1'b1;
        error_count = 0;
        uart_sum    = 32'b0;
        uart_timer  = 32'b0;

        for (byte_number = 0; byte_number < FRAME_BYTES;
             byte_number = byte_number + 1)
            received[byte_number] = 8'b0;

        $readmemh("software/system_demo.hex",
                  dut.u_instruction_memory.memory);
        $readmemh("software/system_demo.data.hex",
                  dut.u_data_memory.memory);

        repeat (2) @(posedge clk);
        @(negedge clk);
        reset = 1'b0;

        for (byte_number = 0; byte_number < FRAME_BYTES;
             byte_number = byte_number + 1)
            receive_uart_byte(byte_number);

        wait (debug_uart_busy == 1'b0);
        #1;

        uart_sum = {received[4], received[3], received[2], received[1]};
        uart_timer = {received[9], received[8], received[7], received[6]};

        if ((received[0] !== 8'h53) || (received[5] !== 8'h54) ||
            (received[10] !== 8'h0a)) begin
            $display("ERROR: UART frame markers are incorrect");
            error_count = error_count + 1;
        end

        if (uart_sum !== 32'd55) begin
            $display("ERROR: UART sum expected=55 got=%0d", uart_sum);
            error_count = error_count + 1;
        end

        if (dut.u_data_memory.memory[0] !== 32'd55) begin
            $display("ERROR: RAM sum expected=55 got=%0d",
                     dut.u_data_memory.memory[0]);
            error_count = error_count + 1;
        end

        if ((uart_timer == 32'd0) ||
            (uart_timer !== dut.u_data_memory.memory[1])) begin
            $display("ERROR: timer UART=%08h RAM=%08h",
                     uart_timer, dut.u_data_memory.memory[1]);
            error_count = error_count + 1;
        end

        if (dut.u_timer.enabled !== 1'b0) begin
            $display("ERROR: timer should be stopped after snapshot");
            error_count = error_count + 1;
        end

        if (error_count == 0)
            $display("PASS: sum=55, timer=%0d, RAM readback and UART frame verified",
                     uart_timer);
        else
            $fatal(1, "FAIL: %0d system demo error(s)", error_count);

        $finish;
    end

endmodule
