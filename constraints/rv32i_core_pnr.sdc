# P&R 阶段沿用 100 MHz 目标，并为时钟实现和芯片边界保留预算。
create_clock -name core_clk -period 10.000 [get_ports clk]
# setup 覆盖周期级抖动预算；hold 使用同边沿的较小局部不确定度。
set_clock_uncertainty -setup 0.200 [get_clocks core_clk]
set_clock_uncertainty -hold 0.050 [get_clocks core_clk]

set non_clock_inputs [all_inputs -no_clocks]
set_input_delay 1.000 -clock core_clk $non_clock_inputs
set_output_delay 1.000 -clock core_clk [all_outputs]
set_driving_cell -lib_cell BUF_X1 $non_clock_inputs
set_load 10.000 [all_outputs]
