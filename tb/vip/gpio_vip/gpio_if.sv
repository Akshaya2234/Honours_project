// =============================================================================
// File    : gpio_if.sv
// Project : RISC-V Smart Control SoC Verification
// Type    : UVM 1.2 Verification IP (VIP) Interface for GPIO / Seven-Segment Display
// Scope   : Physical interface capturing GPIO in/out boundary pins
// =============================================================================

`timescale 1ns/1ps

interface gpio_if(input logic clk, input logic rst_n);

    // GPIO External Boundary Signals
    logic [7:0] gpio_in;   // Inputs to SoC (Buttons/Switches driven by VIP)
    logic [7:0] gpio_out;  // Outputs from SoC (Status LEDs / 7-Segment Display)
    logic       irq_gpio;  // Interrupt signal from GPIO controller

    modport driver (
        input  clk,
        input  rst_n,
        output gpio_in
    );

    modport monitor (
        input  clk,
        input  rst_n,
        input  gpio_in,
        input  gpio_out,
        input  irq_gpio
    );

    modport dut (
        input  clk,
        input  rst_n,
        input  gpio_in,
        output gpio_out,
        output irq_gpio
    );

endinterface : gpio_if
