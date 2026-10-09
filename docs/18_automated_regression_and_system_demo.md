# 自动化Regression与系统级软件程序

## 1. 系统程序功能

系统程序覆盖CPU、RAM、Timer和UART的数据流：

```text
循环计算1 + 2 + ... + 10
          ↓
将55写入RAM并用LW读回
          ↓
读取并停止memory-mapped Timer
          ↓
将求和结果与Timer快照通过UART发送
          ↓
testbench逐位接收并自动核对
```

程序源码是`software/system_demo.c`，对应testbench是`tb/system_demo_tb.sv`。

## 2. UART二进制帧

CPU只支持32-bit `LW/SW`，尚未支持`LB/SB`，也没有M扩展中的硬件除法。如果在C中
直接格式化十进制字符串，编译器通常需要字节访存或运行时除法函数。因此本程序发送
固定格式的二进制帧：

```text
byte 0      0x53，即ASCII 'S'
byte 1..4   32-bit sum，小端序
byte 5      0x54，即ASCII 'T'
byte 6..9   32-bit timer，小端序
byte 10     0x0a，换行
```

例如求和结果55表示为`53 37 00 00 00 54 ... 0a`。这个协议不依赖libc，且testbench可以
完整恢复32-bit结果。该帧格式不依赖byte load/store、除法或libc。

## 3. 软件执行过程

`main`先使能Timer，再用真实循环计算1到10的和。局部变量`sum`声明为`volatile`，阻止
编译器把整个循环替换成常量55。反汇编中可以看到循环内的`ADD`和`BNE`。

结果结构体位于`.bss`开头：

```c
results.sum   = sum;
sum_readback = results.sum;
results.timer = timer_readback;
```

因此UART发送的是RAM读回值，不是计算寄存器的直接副本。Timer快照写入RAM后，程序关闭
Timer，保证testbench观察时计数值不会继续变化。

UART发送32-bit值时需要右移8位。CPU支持寄存器形式`SRL`，尚未支持立即数形式
`SRLI`，所以软件用一小段内联汇编明确生成`SRL`。生成的ELF仍会经过指令白名单检查。

## 4. Self-checking testbench

testbench按8N1时序采样`uart_tx`引脚，而不是直接观察UART内部写使能：

1. 等待下降沿并检查start bit；
2. 在每个数据位中点采样，按LSB-first恢复字节；
3. 检查stop bit；
4. 拼回sum和Timer两个32-bit字段；
5. 将UART值与Data Memory中的结果交叉比较。

最终检查包括：

- UART帧头、分隔符和换行正确；
- UART中的sum等于55；
- RAM中的sum等于55；
- Timer快照非零；
- UART与RAM中的Timer快照相同；
- 程序结束时Timer已停止。

测试另有2000个时钟周期的watchdog。程序跑飞或UART没有输出时会明确报timeout，而不会
让自动化任务永久等待。

## 5. 运行方法

只运行新系统程序：

```bash
make test-system-demo
```

运行完整自动化回归：

```bash
make regression
```

`regression`会先构建所有RISC-V软件并检查反汇编，再执行全部模块级、CPU级和SoC级
self-checking testbench。任一编译或仿真命令返回非零状态，Make立即停止并将回归标记
为失败。

查看系统程序波形：

```bash
make wave-system-demo
```

重点信号包括`debug_pc`、CPU数据地址和写数据、`u_timer.count`、`uart_tx_line`以及
Data Memory的`memory[0]`和`memory[1]`。
