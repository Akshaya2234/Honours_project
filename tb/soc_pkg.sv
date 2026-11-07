// =============================================================================
// File    : soc_pkg.sv
// Project : RISC-V Smart Control SoC Verification
// Type    : Top-Level UVM 1.2 Package for SoC Environment & Tests
// Scope   : Integrates UART, Timer, GPIO, PWM, and SPI ADC VIPs
// =============================================================================

`timescale 1ns/1ps

package soc_pkg;

    import uvm_pkg::*;
    `include "uvm_macros.svh"

    import uart_pkg::*;
    import timer_pkg::*;
    import gpio_pkg::*;
    import pwm_pkg::*;
    import spi_adc_pkg::*;

    // -------------------------------------------------------------------------
    // Top-Level UVM Environment integrating all 5 VIP Agents
    // -------------------------------------------------------------------------
    class soc_env extends uvm_env;
        `uvm_component_utils(soc_env)

        // VIP Agents for all 5 target IPs
        uart_agent    uart_agt;
        timer_agent   timer_agt;
        gpio_agent    gpio_agt;
        pwm_agent     pwm_agt;
        spi_adc_agent spi_adc_agt;

        // Configuration objects
        uart_config    uart_cfg;
        timer_config   timer_cfg;
        gpio_config    gpio_cfg;
        pwm_config     pwm_cfg;
        spi_adc_config spi_adc_cfg;

        function new(string name = "soc_env", uvm_component parent = null);
            super.new(name, parent);
        endfunction

        virtual function void build_phase(uvm_phase phase);
            super.build_phase(phase);
            `uvm_info(get_type_name(), "=== Building Full SoC UVM Environment with 5 VIP Agents ===", UVM_LOW)

            // 1. UART VIP Configuration (Passive Monitor on SoC TX/RX)
            if (!uvm_config_db#(uart_config)::get(this, "", "uart_cfg", uart_cfg)) begin
                uart_cfg = uart_config::type_id::create("uart_cfg");
                uart_cfg.baud_rate   = 115200;
                uart_cfg.clk_freq_hz = 100_000_000;
                uart_cfg.is_active   = UVM_PASSIVE;
            end
            uvm_config_db#(uart_config)::set(this, "uart_agt*", "cfg", uart_cfg);
            uart_agt = uart_agent::type_id::create("uart_agt", this);

            // 2. Timer VIP Configuration (Passive Monitor on sample_tick & irq_timer)
            if (!uvm_config_db#(timer_config)::get(this, "", "timer_cfg", timer_cfg)) begin
                timer_cfg = timer_config::type_id::create("timer_cfg");
            end
            uvm_config_db#(timer_config)::set(this, "timer_agt*", "cfg", timer_cfg);
            timer_agt = timer_agent::type_id::create("timer_agt", this);

            // 3. GPIO / 7-Segment VIP Configuration (Passive Monitor & 7-Seg decoder)
            if (!uvm_config_db#(gpio_config)::get(this, "", "gpio_cfg", gpio_cfg)) begin
                gpio_cfg = gpio_config::type_id::create("gpio_cfg");
                gpio_cfg.enable_7seg_decoder = 1;
                gpio_cfg.active_low_segments = 0; // SoC GPIO drives raw segments
                gpio_cfg.is_active           = UVM_PASSIVE;
            end
            uvm_config_db#(gpio_config)::set(this, "gpio_agt*", "cfg", gpio_cfg);
            gpio_agt = gpio_agent::type_id::create("gpio_agt", this);

            // 4. PWM VIP Configuration (Passive Monitor on pwm_out)
            if (!uvm_config_db#(pwm_config)::get(this, "", "pwm_cfg", pwm_cfg)) begin
                pwm_cfg = pwm_config::type_id::create("pwm_cfg");
                pwm_cfg.clk_freq_hz = 100_000_000;
            end
            uvm_config_db#(pwm_config)::set(this, "pwm_agt*", "cfg", pwm_cfg);
            pwm_agt = pwm_agent::type_id::create("pwm_agt", this);

            // 5. SPI ADC VIP Configuration (Passive Monitor on SPI Mode 0 bus)
            if (!uvm_config_db#(spi_adc_config)::get(this, "", "spi_adc_cfg", spi_adc_cfg)) begin
                spi_adc_cfg = spi_adc_config::type_id::create("spi_adc_cfg");
                spi_adc_cfg.is_active = UVM_PASSIVE;
            end
            uvm_config_db#(spi_adc_config)::set(this, "spi_adc_agt*", "cfg", spi_adc_cfg);
            spi_adc_agt = spi_adc_agent::type_id::create("spi_adc_agt", this);
        endfunction

        virtual function void connect_phase(uvm_phase phase);
            super.connect_phase(phase);
            `uvm_info(get_type_name(), "All 5 VIP Agents successfully instantiated and connected.", UVM_MEDIUM)
        endfunction

    endclass : soc_env

    // -------------------------------------------------------------------------
    // Top-Level Base UVM Test
    // -------------------------------------------------------------------------
    class soc_base_test extends uvm_test;
        `uvm_component_utils(soc_base_test)

        soc_env env;

        function new(string name = "soc_base_test", uvm_component parent = null);
            super.new(name, parent);
        endfunction

        virtual function void build_phase(uvm_phase phase);
            super.build_phase(phase);
            env = soc_env::type_id::create("env", this);
        endfunction

        virtual function void end_of_elaboration_phase(uvm_phase phase);
            super.end_of_elaboration_phase(phase);
            `uvm_info(get_type_name(), "UVM Test Elaboration Phase: Topology constructed successfully.", UVM_LOW)
        endfunction

        virtual task run_phase(uvm_phase phase);
            uvm_event done_ev;
            phase.raise_objection(this);
            `uvm_info(get_type_name(), "=== Starting Full SoC UVM Integration Simulation ===", UVM_LOW)

            // Wait for SoC directed checks to complete
            done_ev = uvm_event_pool::get_global("soc_test_done");
            done_ev.wait_trigger();

            `uvm_info(get_type_name(), "=== Received SoC Test Completion Event ===", UVM_LOW)
            #100ns;
            `uvm_info(get_type_name(), "=== Dropping Objection - Proceeding to UVM Report Phase ===", UVM_LOW)
            phase.drop_objection(this);
        endtask

        virtual function void report_phase(uvm_phase phase);
            uvm_report_server svr;
            super.report_phase(phase);
            svr = uvm_report_server::get_server();
            if (svr.get_severity_count(UVM_ERROR) == 0 && svr.get_severity_count(UVM_FATAL) == 0) begin
                `uvm_info(get_type_name(), "\n\n==================================================================\n   >>> FULL SOC UVM INTEGRATION PASSED WITH 0 ERRORS! <<<\n==================================================================\n", UVM_NONE)
            end else begin
                `uvm_error(get_type_name(), "\n\n==================================================================\n   *** FULL SOC UVM INTEGRATION REPORTED ERRORS! ***\n==================================================================\n")
            end
        endfunction

    endclass : soc_base_test

    // -------------------------------------------------------------------------
    // Concrete Test Registrations for Factory Lookup
    // -------------------------------------------------------------------------
    class soc_test extends soc_base_test;
        `uvm_component_utils(soc_test)
        function new(string name = "soc_test", uvm_component parent = null);
            super.new(name, parent);
        endfunction
    endclass : soc_test

    class soc_integration_test extends soc_base_test;
        `uvm_component_utils(soc_integration_test)
        function new(string name = "soc_integration_test", uvm_component parent = null);
            super.new(name, parent);
        endfunction
    endclass : soc_integration_test

endpackage : soc_pkg
