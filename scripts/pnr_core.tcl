set platform_dir "platforms/nangate45"
set result_dir "results/pnr"
set report_dir "reports/pnr"
file mkdir $result_dir
file mkdir $report_dir

set_thread_count 4

puts "\n========== 1. 读取物理库和门级网表 =========="
read_lef $platform_dir/lef/NangateOpenCellLibrary.tech.lef
read_lef $platform_dir/lef/NangateOpenCellLibrary.macro.mod.lef
read_liberty $platform_dir/lib/NangateOpenCellLibrary_typical.lib
read_verilog reports/rv32i_core_nangate45.v
link_design rv32i_core
read_sdc constraints/rv32i_core_pnr.sdc

puts "\n========== 2. Floorplan 和 I/O pin placement =========="
initialize_floorplan \
    -utilization 35 \
    -aspect_ratio 1.0 \
    -core_space 10 \
    -site FreePDK45_38x28_10R_NP_162NW_34O
source $platform_dir/make_tracks.tcl
place_pins -hor_layers metal5 -ver_layers metal6 -corner_avoidance 5

# 插入 well tap/endcap，避免标准单元阱区距离过大。
tapcell -distance 120 -tapcell_master TAPCELL_X1 -endcap_master TAPCELL_X1
write_db $result_dir/01_floorplan.odb
write_def $result_dir/01_floorplan.def

puts "\n========== 3. Global placement 和 detailed placement =========="
source $platform_dir/setRC.tcl
global_placement -density 0.55 -timing_driven -routability_driven
detailed_placement
check_placement -verbose -report_file_name $report_dir/placement_check.rpt
estimate_parasitics -placement
write_db $result_dir/02_placement.odb
write_def $result_dir/02_placement.def

puts "\n========== 4. CTS 和时序修复 =========="
clock_tree_synthesis \
    -root_buf CLKBUF_X3 \
    -buf_list {CLKBUF_X3 CLKBUF_X2 CLKBUF_X1} \
    -wire_unit 20
set_propagated_clock [all_clocks]
repair_clock_nets
detailed_placement
estimate_parasitics -placement
# 先修复 setup。hold 在获得实际布线寄生后评估，避免对零线长模型过度插入缓冲器。
repair_timing -setup -max_utilization 70
detailed_placement
write_db $result_dir/03_cts.odb
write_def $result_dir/03_cts.def

puts "\n========== 5. Global routing =========="
set ::env(MIN_ROUTING_LAYER) metal2
set ::env(MIN_CLK_ROUTING_LAYER) metal4
set ::env(MAX_ROUTING_LAYER) metal10
source $platform_dir/fastroute.tcl
global_route \
    -guide_file $result_dir/rv32i_core.route_guide \
    -congestion_report_file $report_dir/congestion.rpt
estimate_parasitics -global_routing
write_db $result_dir/04_global_route.odb
write_def $result_dir/04_global_route.def

puts "\n========== 6. Detailed routing =========="
detailed_route \
    -bottom_routing_layer metal2 \
    -top_routing_layer metal10 \
    -output_drc $report_dir/detailed_route_drc.rpt \
    -output_guide_coverage $report_dir/guide_coverage.rpt \
    -verbose 1

# 使用 OpenRCX 的 Nangate45 规则从最终布线提取 RC 寄生参数。
extract_parasitics -ext_model_file $platform_dir/rcx_patterns.rules

puts "\n========== 7. Filler、最终数据库和报告 =========="
filler_placement {FILLCELL_X32 FILLCELL_X16 FILLCELL_X8 FILLCELL_X4 FILLCELL_X2 FILLCELL_X1}
write_db $result_dir/rv32i_core_final.odb
write_def $result_dir/rv32i_core_final.def
write_verilog $result_dir/rv32i_core_final.v
write_spef $result_dir/rv32i_core_final.spef

puts "\n========== Final area =========="
report_design_area
puts "\n========== Final setup =========="
report_wns
report_tns
report_worst_slack -max
report_checks -path_delay max -group_count 3 -endpoint_count 1 -format full_clock_expanded
puts "\n========== Final hold =========="
report_worst_slack -min
report_checks -path_delay min -group_count 3 -endpoint_count 1 -format full_clock_expanded
puts "\n========== Clock skew =========="
report_clock_skew -setup -clock core_clk
report_clock_skew -hold -clock core_clk

puts "\nP&R completed: $result_dir/rv32i_core_final.odb"
