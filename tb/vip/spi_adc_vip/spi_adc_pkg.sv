// =============================================================================
// File    : spi_adc_pkg.sv
// Project : RISC-V Smart Control SoC Verification
// Type    : UVM 1.2 Verification IP (VIP) Package for SPI ADC
// =============================================================================

`timescale 1ns/1ps

package spi_adc_pkg;

    import uvm_pkg::*;
    `include "uvm_macros.svh"

    `include "spi_adc_seq_item.sv"
    `include "spi_adc_config.sv"
    `include "spi_adc_sequencer.sv"
    `include "spi_adc_driver.sv"
    `include "spi_adc_monitor.sv"
    `include "spi_adc_agent.sv"

endpackage : spi_adc_pkg
