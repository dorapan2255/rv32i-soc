# JALR、栈与Data Memory初始化

## 1. 功能组成

普通C函数调用同时需要：

- `JAL`写入返回地址并跳到函数；
- `JALR`从`ra`中的地址返回，或进行间接函数调用；
- `sp`指向一块可读写RAM，用于保存返回地址、局部变量和临时寄存器；
- `.data`包含已初始化全局变量；
- `.bss`在进入`main`前清零。

只有编译C源码而没有启动代码和内存布局，生成的机器码并不能构成可正确运行的裸机
程序。

## 2. JALR硬件数据通路

JALR编码为I-type，目标地址为：

```text
target = (rs1 + sign_extend(imm[11:0])) & 0xffff_fffe
rd     = PC + 4
```

Control Unit让ALU执行`rs1 + immediate`，writeback仍选择`PC+4`。Branch/Jump Unit收到
独立的`jump_reg`信号后选择ALU结果，并强制清零bit 0。JAL和JALR不能共用完全相同的
next-PC表达式，因为JAL基于当前PC，而JALR基于寄存器。

模块测试还检查了奇数目标地址`0x123`最终变成`0x122`。

## 3. Harvard内存布局

本SoC使用独立的1 KiB Instruction Memory和1 KiB Data Memory。两者CPU地址都从0
开始，但属于不同物理存储阵列：取指访问IMEM，`LW/SW`访问DMEM。

```text
Instruction Memory                 Data Memory
0x000 ┌──────────────┐             0x000 ┌──────────────┐
      │ .text/.rodata│                   │ .data        │
      │              │                   │ .bss         │
0x3ff └──────────────┘             0x2ff ├──────────────┤
                                    0x300 │ reserved stack│
                                          │      ↓       │
                                    0x400 └── stack top ─┘
```

Linker script限制静态数据必须在`0x300`以下，为栈保留顶部256 bytes。栈顶`0x400`
符合RISC-V ABI的16-byte对齐要求，第一次建立栈帧时`sp`向低地址移动。

## 4. 两份memory image

每个程序生成：

```text
program.hex       → Instruction Memory
program.data.hex  → Data Memory
```

`objcopy --only-section=.text`生成IMEM binary，`--only-section=.data`生成DMEM binary，
随后转换为各256行的32-bit hex。`.bss`在ELF中是`NOBITS`，不占用镜像空间。

传统单片机常把`.data`初值放在Flash，再由启动代码复制到RAM。Instruction Memory
不能被`LW`访问，因此启动代码无法从IMEM读取这些初值。仿真环境直接把
`program.data.hex`预装到Data Memory；FPGA可用相同文件初始化block RAM。带有可寻址
boot ROM或SRAM macro的系统也可以使用ROM到RAM复制流程。

## 5. crt0启动过程

进入`main`前执行：

```text
1. sp = 0x400
2. x5 = __bss_start
3. x6 = __bss_end
4. 循环SW x0清零.bss
5. JAL ra, main
6. main若返回则进入halt循环
```

清零循环只使用CPU支持的LUI、ADDI、BEQ、SW和JAL。`main`以及普通C函数可以用
新增的JALR返回。

## 6. C端到端验证

`uart_test.c`包含：

- `.data`中的`initialized_word = 0x11223344`；
- `.bss`中的`zero_initialized_word`；
- `noinline`普通函数；
- 强制建立栈帧的volatile局部数组；
- 函数返回产生的`jalr x0, 0(ra)`；
- GCC产生的AUIPC+JALR函数调用；
- UART状态轮询和MMIO写入。

程序只有在`.data`正确、`.bss`已清零、函数调用正确时才发送ASCII `A`。testbench还
检查：

- DMEM地址0保持`0x11223344`；
- BSS变量被函数更新为`0x11223344`；
- `sp`位于`0x300–0x400`且16-byte对齐；
- `main`的返回地址被保存到栈；
- UART写入没有破坏RAM哨兵值。

## 7. 功能边界

该系统可以运行带普通函数、局部变量和简单全局变量的freestanding C程序，但仍没有：

- libc和系统调用；
- heap与动态内存；
- byte/halfword load/store，因此不适合直接操作普通char数组；
- 中断上下文保存；
- 启动代码中的`.data` ROM复制。

这些限制应在项目报告中明确描述，避免把“可以运行受约束的裸机C程序”表述成完整
C运行时环境。
