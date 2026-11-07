// =============================================================================
// File    : uart_config.sv
// Project : RISC-V Smart Control SoC Verification
// Type    : UVM 1.2 Verification IP (VIP) Configuration Object
// =============================================================================

`ifndef UART_CONFIG_SV
`define UART_CONFIG_SV

class uart_config extends uvm_object;
    `uvm_object_utils(uart_config)

    // Agent Operating Mode
    uvm_active_passive_enum is_active = UVM_ACTIVE;

    // Serial Parameters
    int                 baud_rate      = 115200;
    int                 clk_freq_hz    = 100_000_000; // 100 MHz System Clock
    uart_parity_e       parity         = UART_PARITY_NONE;
    uart_stop_bits_e    stop_bits      = UART_STOP_1;
    uart_data_bits_e    data_bits      = UART_DATA_8;

    // Coverage & Checking Controls
    bit                 has_coverage   = 1'b1;
    bit                 has_checks     = 1'b1;

    function new(string name = "uart_config");
        super.new(name);
    endfunction

    // Returns exact bit duration in nanoseconds
    virtual function real get_bit_period_ns();
        return (1.0e9 / real'(baud_rate));
    endfunction

    // Returns clock cycle count per baud bit
    virtual function int get_cycles_per_bit();
        return (clk_freq_hz / baud_rate);
    endfunction

endclass : uart_config

`endif // UART_CONFIG_SV
