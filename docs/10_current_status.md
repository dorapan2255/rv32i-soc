# 系统规格与实现范围

## CPU

`rv32i_core`采用单周期RV32I结构，包含PC、Decoder、Control Unit、Register File、
Immediate Generator、ALU、Branch/Jump Unit和Writeback MUX。支持21条指令：

```text
ADD SUB AND OR XOR SLT SLL SRL SRA
ADDI ANDI ORI XORI
LW SW BEQ BNE JAL JALR LUI AUIPC
```

Register File提供两个组合读端口和一个同步写端口。x0由读端常数零产生，物理状态只实现
x1–x31。数据访存仅支持4-byte对齐的32-bit `LW/SW`。

## SoC

`rv32i_soc`连接1 KiB Instruction Memory、1 KiB Data Memory、MMIO interconnect、UART TX
和32-bit Timer。UART与Timer通过普通数据访存指令访问。

| 地址 | 功能 |
|---|---|
| `0x0000_0000–0x0000_03ff` | Data Memory |
| `0x1000_0000` | UART TXDATA |
| `0x1000_0004` | UART STATUS |
| `0x1000_0010` | TIMER COUNT |
| `0x1000_0014` | TIMER CONTROL |

## 软件环境

软件使用RV32I/ILP32 ABI和freestanding链接方式。`crt0.S`设置`sp=0x400`、清零`.bss`并
调用`main`。构建系统分别生成Instruction Memory与Data Memory的hex镜像，并检查最终
反汇编是否只包含受支持指令。

## 验证范围

验证包括模块级self-checking testbench、指令级集成程序、C函数/栈/全局变量测试、UART
串行重建、Timer控制和系统级“求和→RAM→Timer→UART”程序。`make regression`执行完整
功能回归。

## 实现结果

Nangate45映射结果为6186个标准单元、1024个DFF和11254.46 µm²映射面积。10 ns约束下，
pre-layout setup WNS为+4.208 ns；post-route setup/hold最差slack分别为+5.03 ns和
+0.06 ns。OpenROAD详细布线结果为0个违例。

## 功能边界

设计不包含M扩展、CSR、中断、Cache、AXI、浮点、流水线、异常处理、byte/halfword访存、
libc、系统调用和动态内存。物理实现不包含SRAM macro、I/O pad、完整power grid、foundry
signoff DRC/LVS和GDS stream-out。
