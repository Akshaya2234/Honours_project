.section .text.start
.globl _start

_start:
    /* Disable interrupts */
    csrci   mstatus, 8

    /* Configure VeeR EL2 MRAC CSR (0x7C0) -> 0xAAAAAAA6 (Region 1 = Memory, Region 4 = Device) */
    lui     t0, 0xaaaab
    addi    t0, t0, -1370
    csrw    0x7c0, t0

    .option push
    .option norelax
    la      sp, __stack_top
    .option pop

    call    main

hang:
    j       hang
