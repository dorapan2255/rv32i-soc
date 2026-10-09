# Instruction Memory 与 Data Memory

## 为什么分成两个存储器

单周期CPU使用分离的指令存储器和数据存储器：

```text
PC ──> Instruction Memory ──> instruction

ALU address ──> Data Memory <──> load/store data
```

这样一个周期内可以同时取指和访问数据，不需要为单端口存储器增加仲裁。这个结构
属于Harvard Architecture形式。

## 容量和地址

两个存储器都包含256个32-bit word：

```text
256 × 4 byte = 1024 byte = 1 KiB
```

CPU 使用 byte address。地址转换关系为：

```text
memory index = address[9:2]
```

例如：

| Byte address | 数组下标 |
|---:|---:|
| `0x000` | 0 |
| `0x004` | 1 |
| `0x008` | 2 |
| `0x3fc` | 255 |

地址最低两位 `address[1:0]` 表示一个 32-bit word 内的 byte 位置。当前只支持
对齐的 word 访问，所以合法地址必须满足：

```text
address[1:0] == 2'b00
```

## Instruction Memory

取指是组合读取。PC 地址变化后，`instruction` 随组合路径更新：

```systemverilog
instruction = memory[address[9:2]];
```

该模块没有写端口。模块级testbench使用层次化路径：

```systemverilog
dut.memory[0] = 32'h00a00093;
```

模拟程序预先装入。程序级测试时会改用：

```systemverilog
$readmemh("software/program.hex", dut.memory);
```

将汇编或 C 程序生成的机器码载入指令存储器。

## Data Memory

数据存储器使用组合读、同步写：

```text
LW：地址有效且 mem_read=1 时组合输出 read_data
SW：时钟上升沿且 mem_write=1 时写入 write_data
```

这与 Register File 的“组合读、同步写”结构类似。SW 的数据来自寄存器堆
`rs2_data`，地址来自 ALU 的 `rs1_data + S型立即数`。LW 的地址同样由 ALU
计算，读取结果通过写回选择器写入 `rd`。

## 为什么存储器没有 reset

复位整个存储阵列会引入大量复位逻辑，并可能妨碍综合工具识别存储结构。正常程序
不应依赖未初始化的数据存储器内容。testbench 会在读取前先写入已知数据，或者在
仿真开始时加载初始化文件。

## 非法地址处理

非法地址采用以下确定行为：

- 未对齐读取返回零；
- 超出 1 KiB 范围的读取返回零；
- 未对齐写入被忽略；
- 越界写入被忽略。

完整RISC-V系统通常产生访问异常或通过总线返回错误。该CPU未实现异常和CSR，
因此非法访问采用无副作用行为。

## 功能边界

Data Memory 只支持 32-bit `LW/SW`，没有实现 byte enable，因此暂不支持 LB、
LBU、LH、LHU、SB和SH。
