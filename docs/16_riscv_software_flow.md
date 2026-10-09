# RISC-V 软件构建流

## 1. 构建输入与输出

分支偏移、JAL立即数和指令地址由工具链根据`.S`或`.c`源码生成，
所有机器码文件都由GNU RISC-V工具链生成。

```text
.S / .c
   ↓ riscv64-unknown-elf-gcc
ELF
   ├── objdump → disasm
   ├── linker  → map
   └── objcopy → raw binary
                    ↓ bin_to_hex.py
              32-bit memory hex
                    ↓ $readmemh
              Instruction Memory
```

## 2. 构建命令

只构建软件：

```bash
make software
```

完整测试会自动先构建软件：

```bash
make test
```

清理软件构建产物：

```bash
make software-clean
```

软件Makefile中的默认工具前缀为：

```text
RISCV_PREFIX ?= riscv64-unknown-elf-
```

因此`riscv64-unknown-elf-gcc`、`objcopy`和`objdump`默认必须位于`PATH`中；缺少任一
工具时，构建会输出错误并停止，不会自动回退到某个本地安装目录。如需使用自定义路径，
应显式覆盖前缀，例如：

```bash
make RISCV_PREFIX=/opt/riscv/bin/riscv64-unknown-elf- software
```

## 3. 架构限制

编译参数为：

```text
-march=rv32i
-mabi=ilp32
-mno-relax
-nostdlib
-nostartfiles
-ffreestanding
```

- `rv32i`禁止M扩展、压缩指令和浮点指令；
- `ilp32`规定32-bit整数、指针和long的ABI；
- `mno-relax`使链接器不把指令序列替换成CPU尚未验证的形式；
- `nostdlib/nostartfiles`避免引入该SoC无法支持的操作系统启动代码和C库；
- `ffreestanding`表示程序运行在裸机环境。

`check_instruction_subset.py`进一步读取反汇编，确认最终ELF只包含该CPU实现的21条
指令。检查的是链接后的实际机器代码，比只检查编译参数更可靠。

## 4. Linker script

`linker.ld`规定：

- `_start`位于地址0；
- `.text`和只读数据放进Instruction Memory；
- 可执行镜像最大为1 KiB；
- 超出容量时链接直接失败。

该CPU使用分离的Instruction/Data Memory。软件流会分别生成IMEM与DMEM镜像，
linker为静态数据和栈分配地址；仍应避免动态内存和标准库。

## 5. C启动代码

`crt0.S`在进入C程序前完成以下操作：

```text
sp = 0x400
清零 __bss_start 到 __bss_end
JAL调用main
main返回后进入halt循环
```

普通函数使用JAL/JALR完成调用和返回。`.data`由独立的Data Memory镜像预装。

## 6. 从binary生成hex

GNU objcopy首先输出little-endian裸二进制。`bin_to_hex.py`每4字节读取一次，并按
little-endian组合成一个32-bit整数。例如内存中的4个byte：

```text
ef 00 80 00
```

转换为：

```text
008000ef
```

hex被填充到完整的256行，即1 KiB Instruction Memory。因此testbench不需要写死程序
最后一行，也不会残留上一次仿真的旧指令。

## 7. 输出文件

以`uart_test`为例：

| 文件 | 用途 |
|---|---|
| `uart_test.c` | 人维护的C源码 |
| `build/uart_test.elf` | 带符号和段信息的可执行文件 |
| `build/uart_test.map` | 链接地址和符号分布 |
| `build/uart_test.disasm` | 最终机器码反汇编 |
| `uart_test.hex` | Instruction Memory使用的32-bit镜像 |
| `uart_test.data.hex` | Data Memory使用的32-bit镜像 |

`.disasm`列出PC地址和实际指令，可与GTKWave中的`debug_pc`和`debug_instruction`
对照。C源码中的一行可能对应多条机器指令，不能假定源码行号与CPU周期一一对应。

## 8. 程序集合

- `integration_test.S`：汇编器和链接器生成的CPU指令集集成测试；
- `timer_test.S`：汇编器和链接器生成的Timer测试；
- `uart_test.c`：由GCC编译的裸机C程序，轮询STATUS并发送ASCII `A`。
- `system_demo.c`：计算1到10之和，读写RAM、读取Timer并通过UART发送结果。

汇编和C程序均由同一构建流生成可供CPU执行的memory image。
