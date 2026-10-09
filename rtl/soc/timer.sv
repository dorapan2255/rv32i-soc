`timescale 1ns/1ps

module timer (
    input  logic        clk,
    input  logic        reset,
    input  logic        count_write,
    input  logic [31:0] count_write_data,
    input  logic        control_write,
    input  logic        control_enable,
    output logic [31:0] count,
    output logic        enabled
);

    always_ff @(posedge clk) begin
        if (reset) begin
            count   <= 32'b0;
            enabled <= 1'b0;
        end else begin
            if (control_write)
                enabled <= control_enable;

            // 软件装载优先于自由运行计数，避免同一周期出现含糊结果。
            if (count_write)
                count <= count_write_data;
            else if (enabled && !(control_write && !control_enable))
                count <= count + 32'd1;
        end
    end

endmodule
