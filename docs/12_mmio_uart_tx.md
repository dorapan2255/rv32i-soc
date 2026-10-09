# Memory-Mapped I/O 与 UART TX

## 地址映射

CPU的数据访问接口经过MMIO interconnect：

| 地址范围/地址 | 名称 | 行为 |
|---|---|---|
| `0x0000_0000`～`0x0000_03ff` | Data Memory | 1 KiB RAM |
| `0x1000_0000` | UART TXDATA | 写入低 8-bit 启动发送 |
| `0x1000_0004` | UART STATUS | 读取 bit 0；1 表示 ready |
| `0x1000_0010` | TIMER COUNT | 32-bit计数值，读写 |
| `0x1000_0014` | TIMER CONTROL | bit 0为enable，读写 |
| 其他地址 | 未映射 | 读取零，写入无副作用 |

CPU 仍然执行普通的 `LW/SW`。地址译码决定访问 RAM 还是外设，因此 CPU core 不需要
知道 UART 的存在。

## 软件访问

```assembly
lui  x1, 0x10000       # x1 = 0x1000_0000
lw   x3, 4(x1)         # 读取 STATUS
addi x2, x0, 65        # ASCII 'A'
sw   x2, 0(x1)         # 写 TXDATA
```

`SW` 写入的是 32-bit 数据，但 UART 只使用 `write_data[7:0]`。

## UART 帧

UART使用8N1：

```text
idle=1 | start=0 | d0 d1 d2 d3 d4 d5 d6 d7 | stop=1
```

- 8 个数据 bit；
- 无 parity；
- 1 个 stop bit；
- 数据低位先发送。

发送 `0x41` 时，数据 bit 顺序为：

```text
1, 0, 0, 0, 0, 0, 1, 0
```

## 波特率分频

每个 UART bit 保持的系统时钟周期数为：

```text
CLKS_PER_BIT = CLOCK_FREQ / BAUD_RATE
```

默认参数为 50 MHz 和 115200 baud，整数分频得到 434 个 clock/bit。实际波特率会
有小量整数截断误差。模块级仿真使用 40/10=4 个 clock/bit，以缩短仿真时间。

## busy 与 ready

UART 开始发送后 `busy=1`，stop bit 完成后回到 0。STATUS bit 0 定义为：

```text
ready = !busy
```

MMIO interconnect 只在 ready 时产生 `uart_write`。如果软件在 busy 时再次写 TXDATA，
该实现忽略busy期间的写入，因此软件发送多个字符时必须轮询STATUS。

## 验证层次

`uart_tx_tb` 从串行线上按每个 bit 的中点采样，重新组成字节，验证 start、data 和
stop bit。它还在 busy 时发起第二次写请求，确认发送中的字节不会被覆盖。

`mmio_interconnect_tb` 单独验证地址译码，确保 UART write 不会同时写 RAM，未知地址
也没有副作用。

`uart_mmio_tb` 让 CPU 执行由`uart_test.c`自动编译生成的`uart_test.hex`。testbench从`uart_tx`引脚
重建 ASCII `A`，检查 STATUS readback 为 1，并使用 Data Memory 哨兵值证明 MMIO
写入没有泄漏到 RAM。

