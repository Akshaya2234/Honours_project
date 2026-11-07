// =============================================================================
// File    : pwm_config.sv
// Project : RISC-V Smart Control SoC Verification
// Type    : UVM 1.2 Verification IP (VIP) Configuration Object
// =============================================================================

`ifndef PWM_CONFIG_SV
`define PWM_CONFIG_SV

class pwm_config extends uvm_object;
    `uvm_object_utils(pwm_config)

    // Clock frequency of the driving domain (default 100 MHz)
    int  clk_freq_hz        = 100_000_000;

    // Optional expected values for autonomous checking
    int  expected_period    = 0;
    int  expected_duty      = 0;
    real expected_duty_pct  = 0.0;
    real tolerance_pct      = 1.0;

    bit  enable_checks      = 1'b1;

    function new(string name = "pwm_config");
        super.new(name);
    endfunction

endclass : pwm_config

`endif // PWM_CONFIG_SV
