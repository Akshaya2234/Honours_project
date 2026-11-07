// =============================================================================
// File    : uart_if.sv
// Project : RISC-V Smart Control SoC Verification
// Type    : UVM 1.2 Verification IP (VIP) Interface
// Scope   : Physical interface for UART Serial Communication
// =============================================================================

`timescale 1ns/1ps

interface uart_if(input logic clk, input logic rst_n);

    // Physical Serial Signals
    logic uart_rx;   // Serial data driven into SoC
    logic uart_tx;   // Serial data driven out from SoC
    logic uart_irq;  // UART interrupt line from SoC

    // Modports for different agent roles
    modport dut (
        input  clk,
        input  rst_n,
        input  uart_rx,
        output uart_tx,
        output uart_irq
    );

    modport driver (
        input  clk,
        input  rst_n,
        output uart_rx
    );

    modport monitor (
        input  clk,
        input  rst_n,
        input  uart_rx,
        input  uart_tx,
        input  uart_irq
    );

endinterface : uart_if
