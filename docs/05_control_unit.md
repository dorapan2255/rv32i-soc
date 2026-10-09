# Control Unit：从指令字段产生控制信号

## 模块作用

Decoder 只提取 `opcode`、`funct3` 和 `funct7` 等原始字段。Control Unit 根据
这些字段判断当前指令的含义，并控制数据通路中的多路选择器、寄存器堆和内存。

```text
opcode + funct3 + funct7
            │
            ▼
      Control Unit
            │
            ├── ALU 执行什么操作
            ├── ALU 输入来自哪里
            ├── 使用哪种立即数
            ├── 是否写寄存器
            ├── 是否访问数据存储器
            ├── 写回数据来自哪里
            └── 是否分支或跳转
```

Control Unit 是组合逻辑，不保存状态，也不需要时钟。

## 主要控制信号

| 信号 | 作用 |
|---|---|
| `alu_op` | 选择 ADD、SUB、AND、OR、XOR、SLT 或移位操作 |
| `imm_type` | 选择 I、S、B、U、J 型立即数 |
| `alu_a_sel` | ALU 输入 A 选择 `rs1_data`、PC 或零 |
| `alu_src_imm` | ALU 输入 B 选择 `rs2_data` 或立即数 |
| `reg_write` | 允许在时钟沿写入 `rd` |
| `mem_read` | 当前指令需要读取数据存储器 |
| `mem_write` | 当前指令需要写数据存储器 |
| `wb_sel` | 写回寄存器的数据选择 ALU、Memory 或 `PC+4` |
| `branch_type` | 无分支、BEQ 或 BNE |
| `jump` | 当前指令是无条件跳转 JAL |
| `instruction_valid` | 当前字段组合属于已支持指令 |

## 典型指令的数据流

### ADD

```text
ALU A = rs1_data
ALU B = rs2_data
ALU operation = ADD
writeback = ALU result
reg_write = 1
```

### ADDI

```text
ALU A = rs1_data
ALU B = I 型立即数
ALU operation = ADD
writeback = ALU result
reg_write = 1
```

ADD 和 ADDI 都执行加法，区别在于 ALU 的第二个输入来源。

### LW

```text
address = rs1_data + I 型立即数
mem_read = 1
writeback = memory data
reg_write = 1
```

ALU 在 LW 中用于计算内存地址，而写回数据来自内存。

### SW

```text
address = rs1_data + S 型立即数
memory write data = rs2_data
mem_write = 1
reg_write = 0
```

SW 不产生目的寄存器结果，所以必须关闭 `reg_write`。

### BEQ 和 BNE

该设计让ALU执行`rs1_data - rs2_data`，Branch Logic根据结果是否为
零判断两个操作数是否相等。分支目标地址由 `PC + B 型立即数` 产生。

### LUI

LUI 希望将 U 型立即数直接写入 `rd`。现有 ALU 没有单独的 PASS_B 操作，因此
选择：

```text
ALU A = 0
ALU B = U 型立即数
ALU operation = ADD
```

结果就是该立即数。

### AUIPC

```text
ALU A = PC
ALU B = U 型立即数
ALU operation = ADD
```

### JAL

JAL 需要同时完成两件事：

1. 下一条 PC 选择 `PC + J 型立即数`；
2. 将返回地址 `PC + 4` 写入 `rd`。

所以 `jump=1`、`reg_write=1`、`wb_sel=WB_PC4`。

### JALR

JALR同样把`PC+4`写入`rd`，但跳转目标来自`rs1 + I型立即数`。Control Unit让ALU
执行加法，并置`jump_reg=1`；Branch/Jump Unit再清零目标地址bit 0。

## 安全默认值

`always_comb` 开头先关闭所有具有副作用的信号：

```text
reg_write = 0
mem_read  = 0
mem_write = 0
jump      = 0
jump_reg  = 0
instruction_valid = 0
```

只有完整匹配受支持指令后才打开它们。这样遇到非法 opcode 或非法 funct 组合时，
不会意外修改寄存器或内存。这种“默认关闭、匹配后开启”的方式也避免组合逻辑
赋值不完整和 latch 推断。

## 支持范围

Control Unit识别21条指令：

```text
ADD SUB AND OR XOR SLT SLL SRL SRA
ADDI ANDI ORI XORI
LW SW
BEQ BNE
JAL JALR LUI AUIPC
```

不支持无符号比较、其他分支和CSR。非法指令通过`instruction_valid=0`标记，
同时关闭寄存器和存储器写使能。
