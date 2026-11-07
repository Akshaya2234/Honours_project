// =============================================================================
// File    : timer_if.sv
// Project : RISC-V Smart Control SoC Verification
// Type    : UVM 1.2 Verification IP (VIP) Interface for System Timer
// Scope   : Captures sample_tick pacing pulses and timer interrupt signals
// =============================================================================

`timescale 1ns/1ps

interface timer_if(input logic clk, input logic rst_n);

    // Physical signals from Timer IP
    logic sample_tick; // 1-cycle strobe pulse at configured sample rate
    logic irq_timer;   // Interrupt line asserted on tick/countdown complete

    modport monitor (
        input clk,
        input rst_n,
        input sample_tick,
        input irq_timer
    );

    modport dut (
        input  clk,
        input  rst_n,
        output sample_tick,
        output irq_timer
    );

endinterface : timer_if
