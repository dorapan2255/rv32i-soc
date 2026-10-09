# 软件仿真与自动回归

## 文件之间的关系

程序级验证包含三层表示：

```text
software/integration_test.S
        │ RISC-V GCC/assembler + linker
        ▼
software/build/integration_test.elf
        │ objcopy + bin_to_hex.py
        ▼
software/integration_test.hex
        │ 每行一个 32-bit 机器码 word
        ▼
Instruction Memory
        │ CPU 按 PC 逐条取指
        ▼
rv32i_soc_tb 自动检查最终状态
```

`.hex`现在是自动生成的构建产物，不再手工维护。ELF、link map和反汇编保存在
`software/build/`，详细流程见`docs/16_riscv_software_flow.md`。

## `$readmemh` 的作用

testbench 使用：

```systemverilog
$readmemh("software/integration_test.hex",
          dut.u_instruction_memory.memory);
```

`$readmemh` 将文本中的十六进制数依次写入数组。第一行进入 `memory[0]`，对应
byte address 0；第二行进入 `memory[1]`，对应 byte address 4。

它是仿真系统任务，不是 CPU 在运行时执行的写存储器操作。

## Makefile 的作用

过去需要手动输入较长的 `iverilog` 文件列表。Makefile 将编译顺序和顶层模块
固定下来，降低漏文件或选错顶层的风险。

运行完整回归：

```bash
make test
```

只运行程序级 SoC 测试：

```bash
make test-soc
```

运行测试后打开顶层波形：

```bash
make wave-soc
```

删除仿真和软件构建产物：

```bash
make clean
```

VCD波形不会被`make clean`删除，可用于信号检查；Git仓库
是否提交波形应在整理 README 和发布版本时统一决定。

## 测试层次

```text
module-level：ALU、寄存器堆、立即数、译码、控制、PC、内存
integration-level：rv32i_soc 执行多种指令组成的小程序
```

模块级测试便于定位局部错误，集成测试证明模块连接和跨周期状态更新正确。两者都
需要保留：只跑集成测试时，失败原因可能跨越多个模块；只跑模块测试则无法发现
接口编码不一致或数据通路连接错误。
