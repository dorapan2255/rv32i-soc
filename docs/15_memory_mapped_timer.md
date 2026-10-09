# Memory-Mapped Timer

## 1. 功能与地址映射

Timer是一个32-bit自由运行计数器。CPU不需要专用Timer指令，仍然使用普通`LW/SW`
访问寄存器。

| 地址 | 名称 | 权限 | 功能 |
|---|---|---|---|
| `0x1000_0010` | `TIMER_COUNT` | 读写 | 读取当前计数值；写入装载新值 |
| `0x1000_0014` | `TIMER_CONTROL` | 读写 | bit 0为enable，其余位读取为0 |

复位后`COUNT=0`、`enable=0`。enable为1时，每个系统时钟上升沿加1；从
`0xffff_ffff`继续计数会自然回绕到0。

Timer不包含prescaler、compare寄存器或中断输出；CPU通过轮询方式读取计数值。

## 2. RTL接口与硬件含义

`timer.sv`不直接解释32-bit地址。MMIO interconnect负责地址译码，并产生：

- `count_write`：CPU写`TIMER_COUNT`时产生一个周期的脉冲；
- `count_write_data`：要装载的32-bit值；
- `control_write`：CPU写`TIMER_CONTROL`时产生一个周期的脉冲；
- `control_enable`：写数据的bit 0；
- `count`和`enabled`：送回MMIO read mux。

这种划分让Timer只关心自身状态，让地址映射集中在interconnect中。

时序优先级为：

```text
reset > COUNT写入 > 自动加1
```

CONTROL写入与COUNT更新可以在同一`always_ff`中完成。写CONTROL=0的边沿会立即停止
计数，不会在停用边沿额外加1。写CONTROL=1后从下一个时钟周期开始计数。

## 3. 软件示例

```assembly
lui  x1, 0x10000       # x1 = 0x1000_0000
addi x1, x1, 16        # x1 = Timer base
addi x2, x0, 1
sw   x2, 4(x1)         # enable = 1

# 执行其他工作
lw   x3, 0(x1)         # 读取COUNT

sw   x0, 4(x1)         # enable = 0
```

若要从指定值开始计数，应先写COUNT，再写CONTROL：

```assembly
sw x2, 0(x1)           # COUNT = x2
sw x3, 4(x1)           # CONTROL.enable = x3[0]
```

## 4. MMIO数据路径

```text
CPU LW/SW
   │ address/write_data
   ▼
MMIO interconnect
   ├── 0x0000_0000～0x0000_03ff → Data Memory
   ├── 0x1000_0000/0004         → UART
   └── 0x1000_0010/0014         → Timer
```

Timer地址不会产生`ram_write`或`uart_write`，因此外设之间不会发生写入泄漏。未映射
地址仍然读取0、写入无副作用。

## 5. 验证

### 模块级

```bash
make test-timer
```

`timer_tb`检查复位、停止状态、启动、连续计数、COUNT装载、32-bit回绕和停止后保持。

### MMIO译码级

```bash
make test-mmio
```

测试读取COUNT/CONTROL、两个写脉冲、写数据传递，以及Timer访问不会选中RAM或UART。

### CPU程序级

```bash
make test-timer-mmio
```

CPU执行由`timer_test.S`自动汇编和链接生成的`timer_test.hex`：启动Timer、等待、读取运行值、停止Timer、再次读取
两次。testbench检查运行值非零、停止后的两次读数相同，并确认最终enable为0。

波形文件为：

```text
waveforms/timer.vcd
waveforms/timer_mmio.vcd
```

程序级验证信号包括`debug_pc`、`data_address`、`cpu_mem_write`、
`timer_control_write`、`timer_count`和`timer_enabled`。
