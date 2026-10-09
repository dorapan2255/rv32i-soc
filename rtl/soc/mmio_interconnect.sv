`timescale 1ns/1ps

module mmio_interconnect (
    input  logic        cpu_mem_read,
    input  logic        cpu_mem_write,
    input  logic [31:0] cpu_address,
    input  logic [31:0] cpu_write_data,
    output logic [31:0] cpu_read_data,

    output logic        ram_read,
    output logic        ram_write,
    input  logic [31:0] ram_read_data,

    output logic        uart_write,
    output logic [7:0]  uart_write_data,
    input  logic        uart_busy,

    output logic        timer_count_write,
    output logic        timer_control_write,
    output logic [31:0] timer_write_data,
    input  logic [31:0] timer_count,
    input  logic        timer_enabled
);

    localparam logic [31:0] UART_TXDATA_ADDR = 32'h1000_0000;
    localparam logic [31:0] UART_STATUS_ADDR = 32'h1000_0004;
    localparam logic [31:0] TIMER_COUNT_ADDR  = 32'h1000_0010;
    localparam logic [31:0] TIMER_CTRL_ADDR   = 32'h1000_0014;

    wire ram_selected = (cpu_address[31:10] == 22'b0);

    assign ram_read  = cpu_mem_read && ram_selected;
    assign ram_write = cpu_mem_write && ram_selected;

    assign uart_write = cpu_mem_write &&
                        (cpu_address == UART_TXDATA_ADDR) &&
                        !uart_busy;
    assign uart_write_data = cpu_write_data[7:0];

    assign timer_count_write = cpu_mem_write &&
                               (cpu_address == TIMER_COUNT_ADDR);
    assign timer_control_write = cpu_mem_write &&
                                 (cpu_address == TIMER_CTRL_ADDR);
    assign timer_write_data = cpu_write_data;

    assign cpu_read_data =
        !cpu_mem_read ? 32'b0 :
        ram_selected ? ram_read_data :
        (cpu_address == UART_STATUS_ADDR) ? {31'b0, !uart_busy} :
        (cpu_address == TIMER_COUNT_ADDR) ? timer_count :
        (cpu_address == TIMER_CTRL_ADDR) ? {31'b0, timer_enabled} :
        32'b0;

endmodule
