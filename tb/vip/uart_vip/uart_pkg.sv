// =============================================================================
// File    : uart_pkg.sv
// Project : RISC-V Smart Control SoC Verification
// Type    : UVM 1.2 Verification IP (VIP) Package
// =============================================================================

`timescale 1ns/1ps

package uart_pkg;

    import uvm_pkg::*;
    `include "uvm_macros.svh"

    `include "uart_seq_item.sv"
    `include "uart_config.sv"
    `include "uart_sequencer.sv"
    `include "uart_driver.sv"
    `include "uart_monitor.sv"
    `include "uart_agent.sv"
    `include "uart_sequences.sv"

endpackage : uart_pkg
