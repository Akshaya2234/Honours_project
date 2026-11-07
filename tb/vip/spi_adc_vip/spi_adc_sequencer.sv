// =============================================================================
// File    : spi_adc_sequencer.sv
// Project : RISC-V Smart Control SoC Verification
// Type    : UVM 1.2 Verification IP (VIP) Sequencer for SPI ADC
// =============================================================================

`ifndef SPI_ADC_SEQUENCER_SV
`define SPI_ADC_SEQUENCER_SV

class spi_adc_sequencer extends uvm_sequencer #(spi_adc_seq_item);
    `uvm_component_utils(spi_adc_sequencer)

    function new(string name = "spi_adc_sequencer", uvm_component parent = null);
        super.new(name, parent);
    endfunction

endclass : spi_adc_sequencer

`endif // SPI_ADC_SEQUENCER_SV
