.section .text.start
.globl _start

_start:
    .option push
    .option norelax

    la sp, __stack_top

    .option pop

    call main

hang:
    j hang
