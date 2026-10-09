OUTPUT_ARCH(riscv)
ENTRY(_start)

MEMORY
{
    IMEM (rx) : ORIGIN = 0x00000000, LENGTH = 1K
    DMEM (rw) : ORIGIN = 0x00000000, LENGTH = 1K
}

SECTIONS
{
    .text 0x00000000 :
    {
        KEEP(*(.text.start))
        *(.text .text.*)
        *(.rodata .rodata.*)
    } > IMEM

    .data 0x00000000 : AT(ALIGN(SIZEOF(.text), 4))
    {
        __data_start = .;
        *(.data .data.*)
        *(.sdata .sdata.*)
        __data_end = .;
    } > DMEM

    .bss (NOLOAD) :
    {
        . = ALIGN(4);
        __bss_start = .;
        *(.bss .bss.*)
        *(.sbss .sbss.*)
        *(COMMON)
        . = ALIGN(4);
        __bss_end = .;
    } > DMEM

    __stack_top = ORIGIN(DMEM) + LENGTH(DMEM);

    /DISCARD/ :
    {
        *(.comment)
        *(.note*)
        *(.eh_frame*)
        *(.riscv.attributes)
    }
}

ASSERT(SIZEOF(.text) <= LENGTH(IMEM), "程序超过1 KiB Instruction Memory")
ASSERT(__bss_end <= 0x00000300, "静态数据侵入保留的256-byte栈空间")
