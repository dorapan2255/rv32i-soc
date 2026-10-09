`timescale 1ns/1ps

module rv32i_soc #(
    parameter integer UART_CLOCK_FREQ = 50_000_000,
    parameter integer UART_BAUD_RATE  = 115_200
) (
    input  logic        clk,
    input  logic        reset,
    output logic        uart_tx,
    output logic        debug_uart_busy,
    output logic [31:0] debug_pc,
    output logic [31:0] debug_instruction,
    output logic        debug_instruction_valid
);

    logic        cpu_mem_read;
    logic        cpu_mem_write;
    logic [31:0] data_address;
    logic [31:0] data_write_data;
    logic [31:0] data_read_data;
    logic        ram_read;
    logic        ram_write;
    logic [31:0] ram_read_data;
    logic        uart_write;
    logic [7:0]  uart_write_data;
    logic        timer_count_write;
    logic        timer_control_write;
    logic [31:0] timer_write_data;
    logic [31:0] timer_count;
    logic        timer_enabled;

    rv32i_core u_core (
        .clk                (clk),
        .reset              (reset),
        .instruction_address(debug_pc),
        .instruction        (debug_instruction),
        .data_mem_read      (cpu_mem_read),
        .data_mem_write     (cpu_mem_write),
        .data_address       (data_address),
        .data_write_data    (data_write_data),
        .data_read_data     (data_read_data),
        .instruction_valid  (debug_instruction_valid)
    );

    instruction_memory u_instruction_memory (
        .address     (debug_pc),
        .instruction (debug_instruction)
    );

    data_memory u_data_memory (
        .clk        (clk),
        .mem_read   (ram_read),
        .mem_write  (ram_write),
        .address    (data_address),
        .write_data (data_write_data),
        .read_data  (ram_read_data)
    );

    mmio_interconnect u_mmio_interconnect (
        .cpu_mem_read   (cpu_mem_read),
        .cpu_mem_write  (cpu_mem_write),
        .cpu_address    (data_address),
        .cpu_write_data (data_write_data),
        .cpu_read_data  (data_read_data),
        .ram_read       (ram_read),
        .ram_write      (ram_write),
        .ram_read_data  (ram_read_data),
        .uart_write     (uart_write),
        .uart_write_data(uart_write_data),
        .uart_busy      (debug_uart_busy),
        .timer_count_write  (timer_count_write),
        .timer_control_write(timer_control_write),
        .timer_write_data   (timer_write_data),
        .timer_count        (timer_count),
        .timer_enabled      (timer_enabled)
    );

    uart_tx #(
        .CLOCK_FREQ (UART_CLOCK_FREQ),
        .BAUD_RATE  (UART_BAUD_RATE)
    ) u_uart_tx (
        .clk          (clk),
        .reset        (reset),
        .write_enable (uart_write),
        .write_data   (uart_write_data),
        .tx           (uart_tx),
        .busy         (debug_uart_busy)
    );

    timer u_timer (
        .clk               (clk),
        .reset             (reset),
        .count_write       (timer_count_write),
        .count_write_data  (timer_write_data),
        .control_write     (timer_control_write),
        .control_enable    (timer_write_data[0]),
        .count             (timer_count),
        .enabled           (timer_enabled)
    );

endmodule
