# 单周期 RV32I 顶层数据通路

## 两个层次

顶层分为：

```text
rv32i_core：CPU 核心，只通过接口访问指令和数据
rv32i_soc：CPU 核心 + Instruction Memory + Data Memory
```

这种边界使`rv32i_soc`中的地址译码、UART和Timer与CPU内部执行逻辑相互独立。

## 单周期数据流

```text
PC ──> Instruction Memory ──> instruction
 │                                  │
 │                                  ├──> Decoder ──> register addresses
 │                                  ├──> Control Unit ──> control signals
 │                                  └──> Immediate Generator
 │
 │        Register File ──> ALU ──> Data Memory
 │              ▲             │            │
 │              └──── writeback mux <──────┘
 │
 └──> Branch/Jump Unit ──> next_pc ──> PC
```

一条指令的组合逻辑在一个时钟周期内完成取指、译码、读寄存器、计算和结果选择。
到时钟上升沿时，结果写入寄存器堆或数据存储器，同时 PC 更新。

## ALU 输入选择

ALU 输入 A 有三个来源：

```text
rs1_data：普通算术、Load、Store、Branch
current_pc：AUIPC 和 JAL 的目标地址计算
0：LUI，通过 0 + U型立即数得到结果
```

ALU 输入 B 有两个来源：

```text
rs2_data：R 型算术和分支比较
immediate：立即数运算、地址计算、LUI、AUIPC、JAL
```

## 写回选择

写回寄存器堆的 `rd_data` 有三个来源：

```text
ALU result：算术、逻辑、LUI、AUIPC
Data Memory read_data：LW
current_pc + 4：JAL 的返回地址
```

## 复位期间的副作用屏蔽

PC 在 reset 时回到零。寄存器堆和数据存储器本身没有整体 reset，因此顶层额外
使用 `!reset` 屏蔽写使能：

```systemverilog
reg_write_enable = reg_write && !reset;
data_mem_write   = control_mem_write && !reset;
```

这样 reset 时即使组合译码暂时看到一条有效指令，也不会修改架构状态。

## 集成测试程序

testbench 装入一个小型机器码程序，依次验证：

1. ADDI 产生两个操作数；
2. ADD 得到 30；
3. SW 将 30 写入 Data Memory；
4. LW 将数据读回另一个寄存器；
5. BEQ 成立并跳过一条指令；
6. JAL 跳转并把 `PC+4` 写入链接寄存器；
7. LUI 产生高 20-bit 常量；
8. AUIPC 写入当前 PC；
9. BNE 成立并跳过一条指令；
10. XOR 验证后续顺序执行；
11. 非法全零指令不产生写寄存器或写内存副作用。

testbench 最后直接检查寄存器堆和数据存储器中的架构结果。层次化访问只用于验证，
不会成为综合后硬件的一部分。

## 单周期结构的时序特性

单周期结构简单，但一个周期内的最长路径可能经过：

```text
PC → Instruction Memory → Decoder/Control → Register File
   → ALU → Data Memory → Writeback → Register File
```

因此最高时钟频率受到该长组合路径限制。综合和STA结果用于量化路径延迟。
