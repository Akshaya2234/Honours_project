ENTRY(_start)

MEMORY
{
    IMEM (rx)  : ORIGIN = 0x10000000, LENGTH = 64K
    DMEM (rwx) : ORIGIN = 0x10020000, LENGTH = 64K
}

SECTIONS
{
    .text :
    {
        KEEP(*(.text.start))
        *(.text*)
        *(.rodata*)
    } > IMEM

    .data :
    {
        *(.data*)
        *(.sdata*)
    } > DMEM AT > IMEM

    .bss :
    {
        *(.bss*)
        *(.sbss*)
        *(COMMON)
    } > DMEM

    __stack_top = ORIGIN(DMEM) + LENGTH(DMEM) - 16;
}
