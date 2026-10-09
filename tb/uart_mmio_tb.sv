`timescale 1ns/1ps

module uart_mmio_tb;

    localparam integer CLOCK_FREQ   = 40;
    localparam integer BAUD_RATE    = 10;
    localparam integer CLKS_PER_BIT = CLOCK_FREQ / BAUD_RATE;

    logic        clk;
    logic        reset;
    logic        uart_tx_line;
    logic        debug_uart_busy;
    logic [31:0] debug_pc;
    logic [31:0] debug_instruction;
    logic        debug_instruction_valid;
    logic [7:0]  received_byte;

    integer error_count;

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

    task automatic receive_uart_byte;
        integer bit_number;
        begin
            @(negedge uart_tx_line);
            repeat (CLKS_PER_BIT / 2) @(posedge clk);
            #1;

            if (uart_tx_line !== 1'b0) begin
                $display("ERROR: MMIO UART start bit is not low");
                error_count = error_count + 1;
            end

            for (bit_number = 0; bit_number < 8; bit_number = bit_number + 1) begin
                repeat (CLKS_PER_BIT) @(posedge clk);
                #1;
                received_byte[bit_number] = uart_tx_line;
            end

            repeat (CLKS_PER_BIT) @(posedge clk);
            #1;
            if (uart_tx_line !== 1'b1) begin
                $display("ERROR: MMIO UART stop bit is not high");
                error_count = error_count + 1;
            end
        end
    endtask

    initial begin
        $dumpfile("waveforms/uart_mmio.vcd");
        $dumpvars(0, uart_mmio_tb);

        clk           = 1'b0;
        reset         = 1'b1;
        received_byte = 8'b0;
        error_count   = 0;

        $readmemh("software/uart_test.hex",
                  dut.u_instruction_memory.memory);
        $readmemh("software/uart_test.data.hex",
                  dut.u_data_memory.memory);

        // 使用静态数据范围之外的哨兵，证明UART写入没有泄漏到RAM。
        dut.u_data_memory.memory[200] = 32'hdead_beef;

        repeat (2) @(posedge clk);
        @(negedge clk);
        reset = 1'b0;

        receive_uart_byte();
        wait (debug_uart_busy == 1'b0);
        #1;

        if (received_byte !== 8'h41) begin
            $display("ERROR: MMIO UART expected=41 got=%02h", received_byte);
            error_count = error_count + 1;
        end

        if (dut.u_data_memory.memory[0] !== 32'h1122_3344) begin
            $display("ERROR: .data initialization failed: %08h",
                     dut.u_data_memory.memory[0]);
            error_count = error_count + 1;
        end

        if (dut.u_data_memory.memory[1] !== 32'h1122_3344) begin
            $display("ERROR: C function/global write failed: %08h",
                     dut.u_data_memory.memory[1]);
            error_count = error_count + 1;
        end

        if ((dut.u_core.u_reg_file.registers[2] < 32'h0000_0300) ||
            (dut.u_core.u_reg_file.registers[2] > 32'h0000_0400) ||
            (dut.u_core.u_reg_file.registers[2][3:0] != 4'b0)) begin
            $display("ERROR: stack pointer is outside aligned stack region: %08h",
                     dut.u_core.u_reg_file.registers[2]);
            error_count = error_count + 1;
        end

        if (dut.u_data_memory.memory[255] !== 32'h0000_002c) begin
            $display("ERROR: main return address was not saved on stack: %08h",
                     dut.u_data_memory.memory[255]);
            error_count = error_count + 1;
        end

        if (dut.u_data_memory.memory[200] !== 32'hdead_beef) begin
            $display("ERROR: UART write leaked into Data Memory: %08h",
                     dut.u_data_memory.memory[200]);
            error_count = error_count + 1;
        end

        if (error_count == 0)
            $display("PASS: CPU sent ASCII 'A' through MMIO UART TX");
        else
            $fatal(1, "FAIL: %0d MMIO UART error(s)", error_count);

        $finish;
    end

endmodule
