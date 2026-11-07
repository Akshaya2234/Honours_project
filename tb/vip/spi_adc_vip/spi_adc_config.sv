// =============================================================================
// File    : spi_adc_config.sv
// Project : RISC-V Smart Control SoC Verification
// Type    : UVM 1.2 Verification IP (VIP) Configuration Object for SPI ADC
// =============================================================================

`ifndef SPI_ADC_CONFIG_SV
`define SPI_ADC_CONFIG_SV

class spi_adc_config extends uvm_object;
    `uvm_object_utils(spi_adc_config)

    uvm_active_passive_enum is_active        = UVM_ACTIVE;
    spi_pattern_e           pattern          = SPI_PATTERN_SINE;
    shortint signed         sample_amplitude = 16'sd16000;

    function new(string name = "spi_adc_config");
        super.new(name);
    endfunction

endclass : spi_adc_config

`endif // SPI_ADC_CONFIG_SV
