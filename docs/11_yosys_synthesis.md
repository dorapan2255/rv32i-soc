# 使用 Yosys 综合 rv32i_core

## 综合范围

综合顶层是`rv32i_core`，不包含Instruction Memory、Data Memory和
testbench。CPU 核通过端口访问指令和数据：

```text
instruction_address ──> 外部指令存储器
instruction         <── 外部指令存储器

data_address        ──> 外部数据存储系统
data_write_data     ──> 外部数据存储系统
data_read_data      <── 外部数据存储系统
```

该范围用于独立分析CPU逻辑，避免memory array映射方式影响结果。

## 运行方法

```bash
make synth-core
```

综合脚本依次执行：

1. `read_verilog -sv`：读取 SystemVerilog RTL；
2. `hierarchy -check`：检查模块实例和顶层层次；
3. `check -assert`：将结构问题作为失败处理；
4. `proc`：将过程块转换为 mux、触发器和组合逻辑；
5. `opt`：常量传播和冗余逻辑优化；
6. `fsm`：识别并优化有限状态机；
7. `memory`：处理内部 memory representation；
8. `techmap`：展开算术等 RTL 级单元；
9. `abc`：映射到 generic logic gates；
10. `stat`：统计 wire、cell 和各种 cell 类型；
11. `write_verilog`、`write_json`：保存综合网表。

## 生成文件

```text
reports/rv32i_core_synthesis.log  完整 Yosys 日志
reports/rv32i_core_stats.txt      最终统计摘要
reports/rv32i_core_synth.v        generic gate-level Verilog
reports/rv32i_core_synth.json     结构化综合网表
```

## 如何理解统计结果

寄存器堆包含 31 个可写的 32-bit 普通寄存器，`x0` 由旁路逻辑固定为零。因此仅
寄存器堆就可能产生接近 992 个状态 bit；PC 另外包含 32 个状态 bit。最终触发器
数量还取决于 Yosys 对未使用状态和写使能逻辑的优化。

组合逻辑数量主要来自：

- ALU 的加减、比较和移位；
- 两个寄存器读端口的大型选择网络；
- Decoder 和 Control Unit；
- 写回、ALU 输入和 next-PC 多路选择器。

## 统计结果不能说明什么

ABC使用的是 Yosys generic gates，没有指定真实 foundry standard-cell library。
因此报告中的 cell count 可以用于版本间相对比较，但不能直接作为芯片面积。

Generic综合不包含时钟约束、布线寄生参数和标准单元延时，因此不能从该结果得出最高
频率或 slack。STA 至少还需要：

```text
Liberty standard-cell library
clock constraint
input/output delay assumptions
综合网表
```

具有工艺意义的area和timing由Nangate45映射、OpenSTA和OpenROAD报告提供。

## 综合检查结论

Yosys 版本：

```text
Yosys 0.33
```

`make synth-core`完成RTL读取、层次检查、过程转换、generic gate映射和网表输出。
脚本随后清空Yosys内部设计，重新读取最终`rv32i_core_synth.v`，再次执行
`hierarchy -check`和`check -assert`。最终报告为0个结构问题，说明RTL可以完成综合，
生成的Verilog网表也能独立重新解析且没有未驱动网络等结构错误。

generic gate数量会随RTL写法和Yosys优化发生变化，因此本文不固定记录总cell或各模块
细分数字。需要排查某次综合结果时，可查看本次运行生成的`rv32i_core_stats.txt`和完整
日志。具有工艺意义的标准单元数量、面积和时序统一以Nangate45映射、OpenSTA及OpenROAD
报告为准。
