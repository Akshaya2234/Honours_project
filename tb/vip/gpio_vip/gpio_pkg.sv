// =============================================================================
// File    : gpio_pkg.sv
// Project : RISC-V Smart Control SoC Verification
// Type    : UVM 1.2 Verification IP (VIP) Package for GPIO
// =============================================================================

`timescale 1ns/1ps

package gpio_pkg;

    import uvm_pkg::*;
    `include "uvm_macros.svh"

    `include "gpio_seq_item.sv"
    `include "gpio_config.sv"
    `include "gpio_sequencer.sv"
    `include "gpio_driver.sv"
    `include "gpio_monitor.sv"
    `include "gpio_agent.sv"
    `include "gpio_sequences.sv"

endpackage : gpio_pkg
