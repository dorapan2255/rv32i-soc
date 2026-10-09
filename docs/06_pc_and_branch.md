# PC 与分支/跳转逻辑

## PC 的作用

程序计数器（Program Counter，PC）保存当前指令地址。当前项目每条指令为
32-bit，即 4-byte，因此普通情况下下一条指令地址为：

```text
next_pc = current_pc + 4
```

PC 是状态，需要由触发器保存。该设计在时钟上升沿更新：

```systemverilog
always_ff @(posedge clk) begin
    if (reset)
        current_pc <= 32'b0;
    else
        current_pc <= next_pc;
end
```

这里使用同步高电平复位：只有在时钟上升沿检测到 `reset=1`，PC 才会回到零。

## next_pc 的三个来源

```text
普通执行：current_pc + 4
条件分支：current_pc + B 型立即数
JAL 跳转：current_pc + J 型立即数
```

Branch/Jump Unit 是组合逻辑，根据当前控制信号选择其中一个结果。

## BEQ 和 BNE 如何判断

Control Unit 让 BEQ/BNE 使用 ALU 的 SUB 操作：

```text
alu_result = rs1_data - rs2_data
```

所以：

```text
alu_result == 0  → 两个操作数相等
alu_result != 0  → 两个操作数不相等
```

`BR_EQ` 在结果为零时令 `branch_taken=1`，`BR_NE` 在结果非零时令它为 1。

## JAL 的优先级

当 `jump=1` 时，下一 PC 无条件选择：

```text
current_pc + immediate
```

实现中 JAL 的选择优先于条件分支。正常 Control Unit 不会同时请求 JAL 和分支，
但定义明确的优先级可以让组合逻辑在任何输入下都有确定行为。

`branch_taken` 只表示 BEQ/BNE 条件是否成立，不表示 JAL。是否发生 JAL 可以直接
观察 `jump`。

## 负偏移为什么可以直接相加

Immediate Generator 已经把负立即数符号扩展成 32-bit 二进制补码。例如 `-8`：

```text
immediate = 32'hffff_fff8
```

因此从 PC=100 向后跳 8-byte 可以直接计算：

```text
100 + 0xfffffff8 = 92
```

32-bit 加法器会自然得到正确结果，不需要额外的减法路径。

## 对齐与异常边界

该设计未实现指令地址未对齐异常。B/J型立即数的最低位由Immediate Generator保证
为零；没有C扩展时，目标地址还应满足4-byte对齐。

## 验证信号

PC 波形中观察：

- `current_pc` 只在时钟上升沿改变；
- `reset=1` 时，上升沿后 PC 变为零；
- `next_pc` 在两个上升沿之间可以变化，但不会立即改变 `current_pc`。

Branch/Jump 波形中观察：

- 无分支时 `next_pc=current_pc+4`；
- BEQ/BNE 成立时 `branch_taken=1`；
- 正偏移向前跳，负偏移向后跳；
- `jump=1` 时无条件选择 `current_pc+immediate`。
