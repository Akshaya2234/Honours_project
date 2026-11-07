// =============================================================================
// File    : gpio_config.sv
// Project : RISC-V Smart Control SoC Verification
// Type    : UVM 1.2 Verification IP (VIP) Configuration Object for GPIO
// =============================================================================

`ifndef GPIO_CONFIG_SV
`define GPIO_CONFIG_SV

class gpio_config extends uvm_object;
    `uvm_object_utils(gpio_config)

    uvm_active_passive_enum is_active            = UVM_ACTIVE;
    bit                     enable_7seg_decoder  = 1'b1;
    bit                     active_low_segments  = 1'b0; // 0 = Active HIGH, 1 = Active LOW

    function new(string name = "gpio_config");
        super.new(name);
    endfunction

endclass : gpio_config

`endif // GPIO_CONFIG_SV
