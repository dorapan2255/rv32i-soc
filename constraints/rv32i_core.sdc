# 当前阶段的目标时钟：10 ns，即 100 MHz。
create_clock -name core_clk -period 10.000 [get_ports clk]
set_clock_uncertainty 0.200 [get_clocks core_clk]

# 用 1 ns 表示芯片外部逻辑/存储器已经消耗的时间预算。
set non_clock_inputs [all_inputs -no_clocks]
set_input_delay 1.000 -clock core_clk $non_clock_inputs
set_output_delay 1.000 -clock core_clk [all_outputs]

# 为输入端加入典型缓冲器驱动，为输出端加入 10 fF 负载。
set_driving_cell -lib_cell BUF_X1 $non_clock_inputs
set_load 10.000 [all_outputs]
