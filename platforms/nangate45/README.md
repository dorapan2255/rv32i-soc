# Nangate45 标准单元库

本目录使用 OpenROAD Flow Scripts 提供的 Nangate Open Cell Library typical
corner Liberty 文件。它包含标准单元的逻辑功能、面积、延迟、转换时间和功耗模型，
供 Yosys 标准单元映射与 OpenSTA 静态时序分析共同使用。

- 上游仓库：`The-OpenROAD-Project/OpenROAD-flow-scripts`
- 上游路径：`flow/platforms/nangate45/lib/NangateOpenCellLibrary_typical.lib`
- 时间单位：1 ns
- 电容单位：1 fF

Nangate45 是教学和开源流程常用的虚拟 45 nm 工艺库。这里得到的面积和时序适合做
设计比较及流程学习，不应视为某个可流片商业工艺的签核结果。
