`timescale 1ns/1ps

module uart_tx #(
    parameter integer CLOCK_FREQ = 50_000_000,
    parameter integer BAUD_RATE  = 115_200
) (
    input  logic       clk,
    input  logic       reset,
    input  logic       write_enable,
    input  logic [7:0] write_data,
    output logic       tx,
    output logic       busy
);

    localparam integer CLKS_PER_BIT_RAW = CLOCK_FREQ / BAUD_RATE;
    localparam integer CLKS_PER_BIT =
        (CLKS_PER_BIT_RAW < 1) ? 1 : CLKS_PER_BIT_RAW;
    localparam integer COUNTER_WIDTH =
        (CLKS_PER_BIT <= 1) ? 1 : $clog2(CLKS_PER_BIT);
    localparam logic [COUNTER_WIDTH-1:0] BAUD_COUNTER_MAX =
        COUNTER_WIDTH'(CLKS_PER_BIT - 1);

    localparam logic [1:0] STATE_IDLE  = 2'b00;
    localparam logic [1:0] STATE_START = 2'b01;
    localparam logic [1:0] STATE_DATA  = 2'b10;
    localparam logic [1:0] STATE_STOP  = 2'b11;

    logic [1:0] state;
    logic [COUNTER_WIDTH-1:0] baud_counter;
    logic [2:0] bit_index;
    logic [7:0] tx_buffer;

    always_ff @(posedge clk) begin
        if (reset) begin
            state        <= STATE_IDLE;
            baud_counter <= '0;
            bit_index    <= 3'b0;
            tx_buffer    <= 8'b0;
            tx           <= 1'b1;
            busy         <= 1'b0;
        end else begin
            case (state)
                STATE_IDLE: begin
                    tx           <= 1'b1;
                    busy         <= 1'b0;
                    baud_counter <= '0;
                    bit_index    <= 3'b0;

                    if (write_enable) begin
                        tx_buffer <= write_data;
                        tx        <= 1'b0;
                        busy      <= 1'b1;
                        state     <= STATE_START;
                    end
                end

                STATE_START: begin
                    if (baud_counter == BAUD_COUNTER_MAX) begin
                        baud_counter <= '0;
                        tx           <= tx_buffer[0];
                        state        <= STATE_DATA;
                    end else begin
                        baud_counter <= baud_counter + 1'b1;
                    end
                end

                STATE_DATA: begin
                    if (baud_counter == BAUD_COUNTER_MAX) begin
                        baud_counter <= '0;

                        if (bit_index == 3'd7) begin
                            tx    <= 1'b1;
                            state <= STATE_STOP;
                        end else begin
                            bit_index <= bit_index + 1'b1;
                            tx        <= tx_buffer[bit_index + 1'b1];
                        end
                    end else begin
                        baud_counter <= baud_counter + 1'b1;
                    end
                end

                STATE_STOP: begin
                    if (baud_counter == BAUD_COUNTER_MAX) begin
                        baud_counter <= '0;
                        tx           <= 1'b1;
                        busy         <= 1'b0;
                        state        <= STATE_IDLE;
                    end else begin
                        baud_counter <= baud_counter + 1'b1;
                    end
                end

                default: begin
                    state        <= STATE_IDLE;
                    baud_counter <= '0;
                    bit_index    <= 3'b0;
                    tx           <= 1'b1;
                    busy         <= 1'b0;
                end
            endcase
        end
    end

endmodule
