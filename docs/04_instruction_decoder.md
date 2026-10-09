# 指令字段提取：认识 RV32I 的 32-bit 指令

## 本模块的边界

`decoder`只负责从32-bit指令的固定位置提取字段。它不判断指令是ADD、LW还是BEQ，
也不产生寄存器写使能等控制信号；指令语义由Control Unit解析。

把字段提取和控制逻辑分开，有助于分别验证两类问题：

1. 是否从正确的 bit 位置取得字段；
2. 是否根据字段组合产生正确控制信号。

## 固定字段位置

RV32I 基础指令长度为 32-bit，常用字段位置为：

```text
31          25 24      20 19      15 14   12 11       7 6       0
+--------------+----------+----------+-------+----------+---------+
|    funct7    |   rs2    |   rs1    |funct3 |    rd    | opcode  |
+--------------+----------+----------+-------+----------+---------+
```

对应 RTL：

```systemverilog
assign opcode   = instruction[6:0];
assign rd_addr  = instruction[11:7];
assign funct3   = instruction[14:12];
assign rs1_addr = instruction[19:15];
assign rs2_addr = instruction[24:20];
assign funct7   = instruction[31:25];
```

这些只是固定位置的连线，不需要 `always_comb`、时钟或状态。

## 各字段的作用

| 字段 | 主要作用 |
|---|---|
| `opcode` | 区分大类，如寄存器运算、立即数运算、加载、存储、分支 |
| `rd` | 目的寄存器编号 |
| `funct3` | 在同一 opcode 下进一步区分操作 |
| `rs1` | 第一个源寄存器编号 |
| `rs2` | 第二个源寄存器编号 |
| `funct7` | 对部分指令进一步区分，例如 ADD 与 SUB |

例如 ADD 和 SUB 的 `opcode`、`funct3` 都相同，Control Unit 还需要检查
`funct7[5]`：

```text
ADD: funct7 = 0000000
SUB: funct7 = 0100000
```

## 为什么有些提取结果看起来没有意义

不同指令格式会复用相同 bit 位置。R 型指令确实把 `[11:7]` 用作 `rd`，但 S 型
SW 指令会把这五位作为立即数的一部分。Decoder 仍然可以输出 `rd_addr`，只是
Control Unit 知道 SW 不写寄存器，因此不会使用这个输出。

同理，I 型指令的 `[24:20]` 属于立即数，但固定字段提取模块仍会把它显示为
`rs2_addr`。这些输出本身只是原始 bit 切片，是否有效取决于指令格式。

## 示例：ADD x3, x1, x2

机器码为：

```text
0x002081b3
```

提取结果：

```text
opcode = 0110011
rd     = 3
funct3 = 000
rs1    = 1
rs2    = 2
funct7 = 0000000
```

Control Unit根据`opcode=0110011`、`funct3=000`、`funct7=0000000`判断这是ADD，
并选择ALU加法操作。

## 验证信号

在 GTKWave 中加入 `instruction`、`opcode`、`rd_addr`、`funct3`、`rs1_addr`、
`rs2_addr` 和 `funct7`。将指令设为十六进制，寄存器地址设为十进制，其余控制
字段设为二进制。观察每次指令变化时，各输出是否在同一时刻随之改变。
