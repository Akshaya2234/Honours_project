#!/bin/bash
set -e

CROSS=/home/student/riscv_toolchain/riscstar-toolchain-16.1-r1-x86_64-riscv32-none-elf/bin/riscv32-none-elf-
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Compiling C firmware..."
$CROSS"gcc" -march=rv32imc_zicsr -mabi=ilp32 -mcmodel=medlow -Os -Wall -Wextra \
    -ffreestanding -nostdlib -fno-builtin -I. \
    -T "$DIR/link.ld" \
    "$DIR/startup.S" "$DIR/uart_test.c" \
    -o "$DIR/uart_test.elf" -Wl,-Map="$DIR/uart_test.map"

echo "Generating binary..."
$CROSS"objcopy" -O binary "$DIR/uart_test.elf" "$DIR/uart_test.bin"

echo "Generating disassembly..."
$CROSS"objdump" -d "$DIR/uart_test.elf" > "$DIR/uart_test.dump"

echo "Converting binary to 32-bit word hex for testbench..."
python3 - << EOF
import sys, os

dir_path = "$DIR"
bin_path = os.path.join(dir_path, "uart_test.bin")
hex_path = os.path.join(dir_path, "uart_test.hex")
bytes_hex_path = os.path.join(dir_path, "uart_test_bytes.hex")

with open(bin_path, "rb") as f:
    data = f.read()

# Pad to 4-byte boundary
if len(data) % 4 != 0:
    data += b'\x00' * (4 - (len(data) % 4))

num_words = len(data) // 4
with open(hex_path, "w") as f:
    for i in range(0, len(data), 4):
        word = data[i] | (data[i+1] << 8) | (data[i+2] << 16) | (data[i+3] << 24)
        f.write(f"{word:08x}\n")

with open(bytes_hex_path, "w") as f:
    f.write("@10000000\n")
    for i in range(0, len(data), 16):
        line = data[i:i+16]
        f.write(" ".join(f"{b:02X}" for b in line) + "\n")

print(f"Generated {hex_path} with {num_words} 32-bit words ({len(data)} bytes).")
EOF

$CROSS"size" "$DIR/uart_test.elf"
