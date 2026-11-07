// =============================================================================
// File    : timer_config.sv
// Project : RISC-V Smart Control SoC Verification
// Type    : UVM 1.2 Configuration Object for System Timer VIP
// =============================================================================

`ifndef TIMER_CONFIG_SV
`define TIMER_CONFIG_SV

class timer_config extends uvm_object;
    `uvm_object_utils(timer_config)

    uvm_active_passive_enum is_active = UVM_PASSIVE;
    int expected_reload = 200; // Default reload value
    int clock_period_ns = 10;  // 100 MHz clock

    function new(string name = "timer_config");
        super.new(name);
    endfunction

endclass : timer_config

`endif // TIMER_CONFIG_SV
