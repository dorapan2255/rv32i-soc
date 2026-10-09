    .section .text
    .globl _start

_start:
    lui  x1, 0x10000       # x1 = 0x1000_0000
    addi x1, x1, 16        # x1 = Timer base 0x1000_0010
    addi x2, x0, 1
    sw   x2, 4(x1)         # CONTROL.enable = 1

    addi x0, x0, 0         # 等待三个计数周期
    addi x0, x0, 0
    addi x0, x0, 0
    lw   x3, 0(x1)         # 保存运行时的 COUNT

    sw   x0, 4(x1)         # CONTROL.enable = 0
    lw   x4, 0(x1)         # 停止后的第一次读数
    addi x0, x0, 0
    addi x0, x0, 0
    lw   x5, 0(x1)         # 应与 x4 相同

loop:
    jal  x0, loop
