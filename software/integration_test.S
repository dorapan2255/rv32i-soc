    .section .text
    .globl _start

_start:
    addi x1,  x0, 10
    addi x2,  x0, 20
    add  x3,  x1, x2

    sw   x3,  0(x0)
    lw   x4,  0(x0)

    beq  x4,  x3, after_beq
    addi x5,  x0, 1          # 分支正确时应被跳过

after_beq:
    addi x5,  x0, 2

    jal  x6,  after_jal
    addi x7,  x0, 1          # 跳转正确时应被跳过

after_jal:
    lui  x7,  0x12345
    auipc x8, 0

    bne  x1,  x2, after_bne
    addi x9,  x0, 1          # 分支正确时应被跳过

after_bne:
    xor  x10, x1, x2
    .word 0x00000000         # 当前 CPU 视为非法指令
