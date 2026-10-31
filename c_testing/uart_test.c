#include <stdint.h>

#define UART_BASE  0x40006000U

#define UART_THR   (*(volatile uint32_t *)(UART_BASE + 0x00))
#define UART_DIV   (*(volatile uint32_t *)(UART_BASE + 0x08))
#define UART_LCR   (*(volatile uint32_t *)(UART_BASE + 0x0C))
#define UART_LSR   (*(volatile uint32_t *)(UART_BASE + 0x14))

#define UART_DLAB  0x80U
#define UART_8N1   0x03U
#define UART_THRE  (1U << 5)

static void uart_init(void)
{
    UART_LCR = UART_DLAB;
    UART_DIV = 868U;
    UART_LCR = UART_8N1;
}

static void uart_putc(char c)
{
    while ((UART_LSR & UART_THRE) == 0U) {
        /* Wait until transmitter is ready */
    }

    UART_THR = (uint32_t)c;
}

static void uart_puts(const char *str)
{
    while (*str != '\0') {
        uart_putc(*str++);
    }
}

int main(void)
{
    uart_init();

    uart_puts("\r\nRISC-V C UART TEST STARTED\r\n");
    uart_puts("UART CONFIGURATION: 115200 BAUD, 8N1\r\n");
    uart_puts("C PROGRAM EXECUTED SUCCESSFULLY\r\n");

    while (1) {
        /* Keep processor running */
    }

    return 0;
}
