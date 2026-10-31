#include "uart.h"
#include <stdint.h>

#define GPIO_OUT (*(volatile uint32_t *)0x4000A004)

int main(void)
{
    uart_init(16);

    uart_puts("\nRISC-V Smart Control SoC Started\n");
    uart_puts("UART and GPIO Seven Segment Test\n");

    // Common-cathode seven-segment codes
    const uint8_t seg_codes[10] = {
        0x3F, // 0
        0x06, // 1
        0x5B, // 2
        0x4F, // 3
        0x66, // 4
        0x6D, // 5
        0x7D, // 6
        0x07, // 7
        0x7F, // 8
        0x6F  // 9
    };

    while (1)
    {
        for (int i = 0; i < 10; i++)
        {
            GPIO_OUT = seg_codes[i];

            for (volatile int delay = 0; delay < 500000; delay++);
        }
    }

    return 0;
}
