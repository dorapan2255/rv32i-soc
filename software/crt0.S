    .section .text.start
    .globl _start

_start:
    # 栈顶为Data Memory末端0x400，栈向低地址增长。
    lui  x2, %hi(__stack_top)
    addi x2, x2, %lo(__stack_top)

    # .data已由独立的Data Memory镜像预装；启动代码负责清零.bss。
    lui  x5, %hi(__bss_start)
    addi x5, x5, %lo(__bss_start)
    lui  x6, %hi(__bss_end)
    addi x6, x6, %lo(__bss_end)

clear_bss:
    beq  x5, x6, call_main
    sw   x0, 0(x5)
    addi x5, x5, 4
    jal  x0, clear_bss

call_main:
    jal  x1, main

halt:
    jal  x0, halt
