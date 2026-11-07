// =============================================================================
// File    : spi_adc_if.sv
// Project : RISC-V Smart Control SoC Verification
// Type    : UVM 1.2 Verification IP (VIP) Interface for SPI ADC Slave
// Scope   : 4-Wire Serial Peripheral Interface (SCK, CS_N, MOSI, MISO)
// =============================================================================

`timescale 1ns/1ps

interface spi_adc_if(input logic clk, input logic rst_n);

    // 4-Wire SPI Physical Lines
    logic adc_spi_sck;   // Serial clock driven by SoC SPI master
    logic adc_spi_cs_n;  // Active-low chip select driven by SoC SPI master
    logic adc_spi_mosi;  // Master-Out Slave-In driven by SoC
    logic adc_spi_miso;  // Master-In Slave-Out driven by ADC Slave VIP

    modport slave (
        input  clk,
        input  rst_n,
        input  adc_spi_sck,
        input  adc_spi_cs_n,
        input  adc_spi_mosi,
        output adc_spi_miso
    );

    modport monitor (
        input clk,
        input rst_n,
        input adc_spi_sck,
        input adc_spi_cs_n,
        input adc_spi_mosi,
        input adc_spi_miso
    );

    modport dut (
        input  clk,
        input  rst_n,
        output adc_spi_sck,
        output adc_spi_cs_n,
        output adc_spi_mosi,
        input  adc_spi_miso
    );

endinterface : spi_adc_if
