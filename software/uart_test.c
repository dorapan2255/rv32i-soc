#include <stdint.h>

#define UART_TXDATA (*(volatile uint32_t *)0x10000000u)
#define UART_STATUS (*(volatile uint32_t *)0x10000004u)

uint32_t initialized_word = 0x11223344u;
uint32_t zero_initialized_word;

__attribute__((noinline))
static uint32_t build_character(uint32_t base)
{
    // volatile局部数组强制编译器建立栈帧并执行栈上的LW/SW。
    volatile uint32_t locals[2];
    locals[0] = base;
    locals[1] = initialized_word;
    zero_initialized_word = locals[1];
    return locals[0] + 1u;
}

void main(void)
{
    uint32_t character;

    if (zero_initialized_word != 0u) {
        character = (uint32_t)'B';
    } else if (initialized_word != 0x11223344u) {
        character = (uint32_t)'D';
    } else {
        character = build_character(64u);
    }

    while ((UART_STATUS & 1u) == 0u) {
        // 等待UART可以接受下一个字节。
    }

    UART_TXDATA = character;

    // 当前CPU没有退出环境，程序完成后停在原地。
    for (;;) {
        __asm__ volatile ("addi x0, x0, 0");
    }
}
