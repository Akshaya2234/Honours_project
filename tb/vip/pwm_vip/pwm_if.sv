// =============================================================================
// File    : pwm_if.sv
// Project : RISC-V Smart Control SoC Verification
// Type    : UVM 1.2 Verification IP (VIP) Interface for PWM Controller
// Scope   : Physical interface capturing PWM output waveforms
// =============================================================================

`timescale 1ns/1ps

interface pwm_if(input logic clk, input logic rst_n);

    // PWM physical output from DUT
    logic pwm_out;

    modport monitor (
        input clk,
        input rst_n,
        input pwm_out
    );

    modport dut (
        output pwm_out
    );

endinterface : pwm_if
