#include <stdint.h>

#define UART_TXDATA  (*(volatile uint32_t *)0x10000000u)
#define UART_STATUS  (*(volatile uint32_t *)0x10000004u)
#define TIMER_COUNT  (*(volatile uint32_t *)0x10000010u)
#define TIMER_CONTROL (*(volatile uint32_t *)0x10000014u)

struct demo_results {
    uint32_t sum;
    uint32_t timer;
};

volatile struct demo_results results;

static void uart_put(uint32_t value)
{
    while ((UART_STATUS & 1u) == 0u) {
        // 等待UART可以接收下一个字节。
    }
    UART_TXDATA = value & 0xffu;
}

static uint32_t shift_right_8(uint32_t value)
{
    uint32_t shift = 8u;
    uint32_t result;

    // 当前CPU实现了寄存器SRL，尚未实现SRLI，因此显式要求编译器生成SRL。
    __asm__ volatile ("srl %0, %1, %2"
                      : "=r" (result)
                      : "r" (value), "r" (shift));
    return result;
}

static void uart_put_word(uint32_t value)
{
    uart_put(value);
    value = shift_right_8(value);
    uart_put(value);
    value = shift_right_8(value);
    uart_put(value);
    value = shift_right_8(value);
    uart_put(value);
}

void main(void)
{
    volatile uint32_t sum = 0u;
    uint32_t addend = 1u;
    uint32_t remaining = 10u;
    uint32_t sum_readback;
    uint32_t timer_readback;

    TIMER_CONTROL = 1u;

    do {
        sum = sum + addend;
        addend = addend + 1u;
        remaining = remaining - 1u;
    } while (remaining != 0u);

    results.sum = sum;
    sum_readback = results.sum;

    timer_readback = TIMER_COUNT;
    TIMER_CONTROL = 0u;
    results.timer = timer_readback;

    // 帧格式：'S' + sum(32-bit little-endian) + 'T'
    //        + timer(32-bit little-endian) + '\n'
    uart_put((uint32_t)'S');
    uart_put_word(sum_readback);
    uart_put((uint32_t)'T');
    uart_put_word(timer_readback);
    uart_put((uint32_t)'\n');

    for (;;) {
        __asm__ volatile ("addi x0, x0, 0");
    }
}
