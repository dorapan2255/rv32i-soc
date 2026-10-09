# OpenROAD Basic P&R

## 1. 功能

该流程把标准单元门级网表转换为具有实际二维位置和金属连线的物理设计。完整路径为：

```text
门级网表
  → floorplan
  → I/O pin placement
  → tapcell/endcap insertion
  → global placement
  → detailed placement
  → clock tree synthesis
  → global routing
  → detailed routing
  → RC extraction
  → post-route STA
```

运行命令：

```bash
make pnr-core
```

该命令先执行`make timing`，生成门级网表和Liberty映射结果。

## 2. 物理设计输入

OpenROAD 除了门级网表和 Liberty，还需要以下物理信息：

| 文件 | 作用 |
|---|---|
| `NangateOpenCellLibrary.tech.lef` | 金属层、via、线宽和间距规则 |
| `NangateOpenCellLibrary.macro.mod.lef` | 每种标准单元的尺寸、障碍物和 pin 几何 |
| `make_tracks.tcl` | 各金属层 routing track 的间距和偏移 |
| `setRC.tcl` | 各层单位长度电阻、电容模型 |
| `rcx_patterns.rules` | OpenRCX 布线后寄生参数提取规则 |
| `rv32i_core_pnr.sdc` | setup/hold、输入延迟和输出负载约束 |

Liberty 描述“这个门有多快”，LEF 描述“这个门有多大、pin 在哪里”，二者缺一不可。

## 3. Floorplan

Floorplan参数为：

```text
initial utilization = 35%
aspect ratio        = 1.0
core margin         = 10 µm
placement site      = FreePDK45_38x28_10R_NP_162NW_34O
```

最终die尺寸为`199.32 µm × 199.32 µm`，core可放置区域为
`179.17 µm × 177.80 µm`。边缘空间用于I/O pin和布线。

设计有165个顶层 pin。水平边使用 metal5，垂直边使用 metal6，避免所有 pin 堆积在
低层金属上。

## 4. Placement 与 CTS

全局放置先求解近似位置，详细放置再把每个标准单元对齐到合法 row/site，并消除重叠。
本设计的 placement density 目标为0.55，同时开启 timing-driven 和
routability-driven 优化。

CTS 使用 `CLKBUF_X1/X2/X3` 构建时钟树：

| CTS 指标 | 结果 |
|---|---:|
| 时钟 sink | 1024 |
| 插入的时钟缓冲器 | 137 |
| 缓冲器路径深度 | 3级 |
| setup skew（含不确定度） | 0.22 ns |
| hold skew（含不确定度） | −0.07 ns |

1024个 sink 正好对应31个32-bit通用寄存器和32-bit PC。

## 5. Routing 与寄生参数

信号使用 metal2–metal10，时钟优先使用 metal4–metal10。详细布线器经历多轮修复：

```text
1584 → 208 → 147 → 0 violations
```

最终结果：

| 指标 | 结果 |
|---|---:|
| Detailed-route DRC violations | 0 |
| 总布线长度 | 126387 µm |
| via 数量 | 53999 |
| 标准单元设计面积 | 13624 µm² |
| Core utilization | 43% |

布线完成后使用 OpenRCX 提取寄生电阻和电容，并写出约8.5 MB的 SPEF 文件。

## 6. Post-route STA

P&R 使用：

```text
时钟周期          10.00 ns
setup uncertainty  0.20 ns
hold uncertainty   0.05 ns
输入延迟            1.00 ns
输出延迟            1.00 ns
```

最终时序结果：

| 检查 | 最差 slack | 结果 |
|---|---:|---|
| Setup | +5.03 ns | MET |
| Hold | +0.06 ns | MET |
| Setup TNS | 0 ns | 无违例 |

Setup 最慢路径仍是 instruction 输入到 data_address 输出的组合路径，说明单周期核心的
译码、MUX 和地址计算是最长路径。Hold 最慢路径来自寄存器堆中很短的寄存器反馈
路径。

## 7. 输出文件

`results/pnr/` 中保存：

- `01_floorplan.odb/.def`：floorplan checkpoint；
- `02_placement.odb/.def`：placement checkpoint；
- `03_cts.odb/.def`：CTS checkpoint；
- `04_global_route.odb/.def`：global routing checkpoint；
- `rv32i_core_final.odb`：最终OpenROAD数据库；
- `rv32i_core_final.def`：最终物理实现DEF；
- `rv32i_core_final.v`：CTS和物理优化后的门级网表；
- `rv32i_core_final.spef`：提取的RC寄生参数。

完整日志位于 `reports/pnr/rv32i_core_pnr.log`。

在支持WSLg图形界面的终端中打开最终布局：

```bash
bash scripts/view_layout.sh
```

进入GUI后可切换metal layer、查看placement、时钟树和拥塞，并使用GUI的截图功能导出
报告图片。

## 8. 结果边界

这是教学用途的basic P&R：尚未加入power grid、power/ground连接、IR drop分析、版图
密度填充、KLayout signoff DRC/LVS和GDS stream-out。因此“0 violations”指
OpenROAD detailed router 的布线DRC，不等同于foundry signoff。
