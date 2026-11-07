// =============================================================================
// File    : pwm_soc_pkg.sv
// Project : RISC-V Smart Control SoC Verification
// Type    : Dedicated UVM 1.2 Package for Single-IP PWM SoC Integration
// Scope   : PWM Scoreboard, Environment and Test
// =============================================================================

`timescale 1ns/1ps

package pwm_soc_pkg;

    import uvm_pkg::*;
    `include "uvm_macros.svh"

    import pwm_pkg::*;

    // -------------------------------------------------------------------------
    // PWM Scoreboard: Verifies Pulse Period, Duty Cycle, and Frequency
    // -------------------------------------------------------------------------
    class pwm_soc_scoreboard extends uvm_scoreboard;
        `uvm_component_utils(pwm_soc_scoreboard)

        uvm_analysis_imp #(pwm_seq_item, pwm_soc_scoreboard) item_imp;

        int total_pulses   = 0;
        int match_count    = 0;
        int mismatch_count = 0;

        // Configured expected parameters (100 cycles period @ 10ns = 1000ns, 40 cycles duty = 400ns)
        real expected_period_ns = 1000.0;
        real expected_duty_pct  = 40.0;
        real tolerance_pct      = 2.0;

        function new(string name = "pwm_soc_scoreboard", uvm_component parent = null);
            super.new(name, parent);
            item_imp = new("item_imp", this);
        endfunction

        virtual function void write(pwm_seq_item item);
            real measured_period_ns = item.period_cycles * 10.0;
            total_pulses++;

            `uvm_info(get_type_name(), $sformatf("SoC PWM OUT -> VIP MONITOR: Pulse #%0d - Period=%0d cycles (%.1fns), High=%0d cycles, Duty=%.2f%%, Freq=%.2f kHz",
                      total_pulses, item.period_cycles, measured_period_ns, item.high_cycles, item.duty_cycle_pct, (item.frequency_hz / 1000.0)), UVM_LOW)

            if (abs_val(measured_period_ns - expected_period_ns) <= 20.0 &&
                abs_val(item.duty_cycle_pct - expected_duty_pct) <= tolerance_pct) begin
                match_count++;
                `uvm_info(get_type_name(), $sformatf(">>> [SCOREBOARD MATCH #%0d] PWM Output Matched: Period=%.1fns (Exp: %.1fns), Duty=%.2f%% (Exp: %.1f%%) - VERIFIED! <<<",
                          match_count, measured_period_ns, expected_period_ns, item.duty_cycle_pct, expected_duty_pct), UVM_LOW)
            end else begin
                mismatch_count++;
                `uvm_error(get_type_name(), $sformatf(">>> [SCOREBOARD MISMATCH] Period=%.1fns (Exp: %.1fns), Duty=%.2f%% (Exp: %.1f%%)! <<<",
                           measured_period_ns, expected_period_ns, item.duty_cycle_pct, expected_duty_pct))
            end
        endfunction

        function real abs_val(real val);
            return (val < 0.0) ? -val : val;
        endfunction

        virtual function void check_phase(uvm_phase phase);
            super.check_phase(phase);
            $display("\n==================================================================");
            $display("                   PWM UVM SCOREBOARD REPORT                      ");
            $display("==================================================================");
            $display("   Total PWM Pulses Measured               : %0d", total_pulses);
            $display("   Total Verified Matches (Period & Duty)  : %0d", match_count);
            $display("   Total Parameter Mismatches              : %0d", mismatch_count);
            $display("------------------------------------------------------------------");

            if (match_count >= 5 && mismatch_count == 0) begin
                $display("   >>> PWM UVM SCOREBOARD PASSED: 100%% WAVEFORM INTEGRITY! <<<     ");
                $display("==================================================================\n");
                `uvm_info(get_type_name(), "*** PWM UVM SCOREBOARD MATCH TEST PASSED ***", UVM_NONE)
            end else begin
                $display("   *** PWM UVM SCOREBOARD FAILED! ***                             ");
                $display("==================================================================\n");
                `uvm_error(get_type_name(), "*** PWM UVM SCOREBOARD MATCH TEST FAILED ***")
            end
        endfunction

    endclass : pwm_soc_scoreboard

    // -------------------------------------------------------------------------
    // PWM Single-IP SoC Environment
    // -------------------------------------------------------------------------
    class pwm_soc_env extends uvm_env;
        `uvm_component_utils(pwm_soc_env)

        pwm_agent          agent;
        pwm_config         cfg;
        pwm_soc_scoreboard sb;

        function new(string name = "pwm_soc_env", uvm_component parent = null);
            super.new(name, parent);
        endfunction

        virtual function void build_phase(uvm_phase phase);
            super.build_phase(phase);
            `uvm_info(get_type_name(), "Building Single-IP PWM SoC Environment...", UVM_LOW)

            cfg = pwm_config::type_id::create("cfg");
            cfg.clk_freq_hz = 100_000_000;
            uvm_config_db#(pwm_config)::set(this, "agent*", "cfg", cfg);

            agent = pwm_agent::type_id::create("agent", this);
            sb    = pwm_soc_scoreboard::type_id::create("sb", this);
        endfunction

        virtual function void connect_phase(uvm_phase phase);
            super.connect_phase(phase);
            agent.monitor.ap.connect(sb.item_imp);
            `uvm_info(get_type_name(), "Connected PWM Monitor analysis port to Scoreboard.", UVM_LOW)
        endfunction

    endclass : pwm_soc_env

    // -------------------------------------------------------------------------
    // PWM Single-IP SoC Test
    // -------------------------------------------------------------------------
    class pwm_soc_test extends uvm_test;
        `uvm_component_utils(pwm_soc_test)

        pwm_soc_env env;

        function new(string name = "pwm_soc_test", uvm_component parent = null);
            super.new(name, parent);
        endfunction

        virtual function void build_phase(uvm_phase phase);
            super.build_phase(phase);
            env = pwm_soc_env::type_id::create("env", this);
        endfunction

        virtual task run_phase(uvm_phase phase);
            phase.raise_objection(this);
            `uvm_info(get_type_name(), "=== Starting Single-IP PWM SoC UVM Integration Test ===", UVM_LOW)

            // Wait for system reset release and CPU to program PWM controller
            #500ns;

            // Wait for multiple PWM waveform cycles (each period = 1000ns)
            #15000ns;

            `uvm_info(get_type_name(), "=== Single-IP PWM SoC UVM Integration Test Completed ===", UVM_LOW)
            phase.drop_objection(this);
        endtask

        virtual function void report_phase(uvm_phase phase);
            uvm_report_server svr;
            super.report_phase(phase);
            svr = uvm_report_server::get_server();
            if (svr.get_severity_count(UVM_ERROR) == 0 && svr.get_severity_count(UVM_FATAL) == 0) begin
                `uvm_info(get_type_name(), "\n\n==================================================================\n   >>> SINGLE-IP PWM UVM INTEGRATION TEST PASSED! <<<\n==================================================================\n", UVM_NONE)
            end else begin
                `uvm_error(get_type_name(), "\n\n==================================================================\n   *** SINGLE-IP PWM UVM INTEGRATION TEST FAILED! ***\n==================================================================\n")
            end
        endfunction

    endclass : pwm_soc_test

endpackage : pwm_soc_pkg
