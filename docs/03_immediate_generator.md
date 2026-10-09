# 立即数生成器：指令字段拼接与符号扩展

## 立即数是什么

立即数是直接编码在指令中的常量。例如：

```assembly
addi x5, x4, 12
```

其中 `12` 就是立即数。RISC-V 指令固定为 32-bit，但不同指令格式把立即数放在
不同位置，因此 CPU 需要立即数生成器将这些位取出、重新排列并扩展为 32-bit。

本模块输入完整指令 `instruction` 和控制信号 `imm_type`，输出 `immediate`。
`imm_type`由Control Unit根据指令的opcode产生。

## 五种立即数格式

### I 型

用于 ADDI、ANDI、ORI、XORI、LW 等指令：

```text
imm[11:0] = instruction[31:20]
```

这是 12-bit 有符号数，需要将 `instruction[31]` 复制到高 20-bit。

### S 型

用于 SW。立即数被分成两段：

```text
imm[11:5] = instruction[31:25]
imm[4:0]  = instruction[11:7]
```

两段拼接后再进行符号扩展。

### B 型

用于 BEQ、BNE 等分支指令：

```text
imm[12]   = instruction[31]
imm[11]   = instruction[7]
imm[10:5] = instruction[30:25]
imm[4:1]  = instruction[11:8]
imm[0]    = 0
```

分支目标按 2-byte 对齐，因此最低位不存入指令，生成时直接补 `0`。

### U 型

用于 LUI 和 AUIPC：

```text
imm[31:12] = instruction[31:12]
imm[11:0]  = 0
```

它直接提供一个已经位于高 20-bit 的立即数，不执行普通的符号扩展。

### J 型

用于 JAL：

```text
imm[20]    = instruction[31]
imm[19:12] = instruction[19:12]
imm[11]    = instruction[20]
imm[10:1]  = instruction[30:21]
imm[0]     = 0
```

J 型立即数同样按 2-byte 对齐，所以最低位补零，并根据 `imm[20]` 进行符号扩展。

## 拼接和复制运算符

花括号用于拼接：

```systemverilog
{instruction[31:25], instruction[11:7]}
```

双层花括号表示重复：

```systemverilog
{20{instruction[31]}}
```

它将符号位复制 20 次。例如符号位为 `1`，高 20-bit 就全部填充为 `1`，从而
保持负数的二进制补码数值。

## 为什么 B 型和 J 型字段看起来被打乱

RISC-V 将立即数字段这样排列，是为了让不同指令格式尽量共享寄存器编号、opcode
和符号位的位置，并简化硬件布线。立即数生成器只负责按照规范恢复正确顺序，
不能把指令中的几段简单按位置直接连接。

## 验证信号

在 GTKWave 中加入 `instruction`、`imm_type` 和 `immediate`，均可使用十六进制
显示。重点观察：

- `instruction[31]=0` 时，I/S/B/J 型正立即数高位补零；
- `instruction[31]=1` 时，负立即数高位补一；
- B/J 型输出最低位始终为零；
- U 型输出低 12-bit 始终为零；
- 未定义的 `imm_type` 输出零。
