input_file = "c_testing/uart_test.bin"
output_file = "c_testing/uart_test_bytes.hex"

with open(input_file, "rb") as f:
    data = bytearray(f.read())

with open(output_file, "w") as f:
    f.write("@10000000\n")
    for i in range(0, len(data), 16):
        line = data[i:i+16]
        f.write(" ".join(f"{byte:02X}" for byte in line) + "\n")

print("Binary size:", len(data), "bytes")
print("HEX file generated:", output_file)
