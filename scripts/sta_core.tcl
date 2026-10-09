set liberty_file "platforms/nangate45/lib/NangateOpenCellLibrary_typical.lib"
set netlist_file "reports/rv32i_core_nangate45.v"
set sdc_file "constraints/rv32i_core.sdc"

read_liberty $liberty_file
read_verilog $netlist_file
link_design rv32i_core
read_sdc $sdc_file

# 先检查网表、时钟和约束是否完整，再输出总体结果与最慢路径。
puts "\n========== 约束完整性检查 =========="
check_setup
puts "\n========== 分析单位 =========="
report_units
puts "\n========== 时钟 =========="
report_clock_properties [all_clocks]
puts "\n========== Setup 汇总 =========="
report_worst_slack -max
report_tns
puts "\n========== 最慢的 3 条路径 =========="
report_checks -path_delay max -group_count 3 -endpoint_count 1 \
    -fields {slew capacitance input_pin net} -format full_clock_expanded \
    -digits 3
