// =============================================================================
// File    : pwm_pkg.sv
// Project : RISC-V Smart Control SoC Verification
// Type    : UVM 1.2 Verification IP (VIP) Package for PWM Controller
// =============================================================================

`timescale 1ns/1ps

package pwm_pkg;

    import uvm_pkg::*;
    `include "uvm_macros.svh"

    `include "pwm_seq_item.sv"
    `include "pwm_config.sv"
    `include "pwm_monitor.sv"
    `include "pwm_agent.sv"

endpackage : pwm_pkg
