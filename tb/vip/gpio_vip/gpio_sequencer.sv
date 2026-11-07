// =============================================================================
// File    : gpio_sequencer.sv
// Project : RISC-V Smart Control SoC Verification
// Type    : UVM 1.2 Verification IP (VIP) Sequencer for GPIO
// =============================================================================

`ifndef GPIO_SEQUENCER_SV
`define GPIO_SEQUENCER_SV

class gpio_sequencer extends uvm_sequencer #(gpio_seq_item);
    `uvm_component_utils(gpio_sequencer)

    function new(string name = "gpio_sequencer", uvm_component parent = null);
        super.new(name, parent);
    endfunction

endclass : gpio_sequencer

`endif // GPIO_SEQUENCER_SV
