// =============================================================================
// File    : timer_soc_pkg.sv
// Project : RISC-V Smart Control SoC Verification
// Type    : Dedicated UVM 1.2 Package for Single-IP Timer SoC Integration
// Scope   : Timer Scoreboard, Environment and Test
// =============================================================================

`timescale 1ns/1ps

package timer_soc_pkg;

    import uvm_pkg::*;
    `include "uvm_macros.svh"

    import timer_pkg::*;

    // -------------------------------------------------------------------------
    // Timer Scoreboard: Verifies Sample Tick Period and Interrupt Signaling
    // -------------------------------------------------------------------------
    class timer_soc_scoreboard extends uvm_scoreboard;
        `uvm_component_utils(timer_soc_scoreboard)

        uvm_analysis_imp #(timer_seq_item, timer_soc_scoreboard) item_imp;

        int total_ticks    = 0;
        int match_count    = 0;
        int mismatch_count = 0;

        // Configured expected period: 50 reload cycles + 1 tick pulse cycle = 51 cycles
        int expected_period_cycles = 51;

        function new(string name = "timer_soc_scoreboard", uvm_component parent = null);
            super.new(name, parent);
            item_imp = new("item_imp", this);
        endfunction

        virtual function void write(timer_seq_item item);
            total_ticks++;

            `uvm_info(get_type_name(), $sformatf("SoC TIMER -> VIP MONITOR: Tick #%0d - Period=%0d cycles, IRQ=%b",
                      total_ticks, item.tick_period_cycles, item.irq_asserted), UVM_LOW)

            // First tick has no prior reference, subsequent ticks must match expected period
            if (total_ticks == 1) begin
                `uvm_info(get_type_name(), "First sample_tick recorded (baseline).", UVM_LOW)
            end else begin
                if (item.tick_period_cycles == expected_period_cycles) begin
                    match_count++;
                    `uvm_info(get_type_name(), $sformatf(">>> [SCOREBOARD MATCH #%0d] Timer Pacing Verified: Period=%0d cycles, IRQ=%b <<<",
                              match_count, item.tick_period_cycles, item.irq_asserted), UVM_LOW)
                end else begin
                    mismatch_count++;
                    `uvm_error(get_type_name(), $sformatf(">>> [SCOREBOARD MISMATCH] Period=%0d cycles (Exp: %0d) <<<",
                               item.tick_period_cycles, expected_period_cycles))
                end
            end
        endfunction

        virtual function void check_phase(uvm_phase phase);
            super.check_phase(phase);
            $display("\n==================================================================");
            $display("                  TIMER UVM SCOREBOARD REPORT                     ");
            $display("==================================================================");
            $display("   Total Sample Ticks Observed             : %0d", total_ticks);
            $display("   Total Verified Periodic Matches         : %0d", match_count);
            $display("   Total Timing Mismatches                 : %0d", mismatch_count);
            $display("------------------------------------------------------------------");

            if (match_count >= 10 && mismatch_count == 0) begin
                $display("   >>> TIMER UVM SCOREBOARD PASSED: 100%% PACING INTEGRITY! <<<    ");
                $display("==================================================================\n");
                `uvm_info(get_type_name(), "*** TIMER UVM SCOREBOARD MATCH TEST PASSED ***", UVM_NONE)
            end else begin
                $display("   *** TIMER UVM SCOREBOARD FAILED! ***                           ");
                $display("==================================================================\n");
                `uvm_error(get_type_name(), "*** TIMER UVM SCOREBOARD MATCH TEST FAILED ***")
            end
        endfunction

    endclass : timer_soc_scoreboard

    // -------------------------------------------------------------------------
    // Timer Single-IP SoC Environment
    // -------------------------------------------------------------------------
    class timer_soc_env extends uvm_env;
        `uvm_component_utils(timer_soc_env)

        timer_agent          agent;
        timer_config         cfg;
        timer_soc_scoreboard sb;

        function new(string name = "timer_soc_env", uvm_component parent = null);
            super.new(name, parent);
        endfunction

        virtual function void build_phase(uvm_phase phase);
            super.build_phase(phase);
            `uvm_info(get_type_name(), "Building Single-IP Timer SoC Environment...", UVM_LOW)

            cfg = timer_config::type_id::create("cfg");
            cfg.clock_period_ns = 10;
            cfg.expected_reload = 50;
            uvm_config_db#(timer_config)::set(this, "agent*", "cfg", cfg);

            agent = timer_agent::type_id::create("agent", this);
            sb    = timer_soc_scoreboard::type_id::create("sb", this);
        endfunction

        virtual function void connect_phase(uvm_phase phase);
            super.connect_phase(phase);
            agent.monitor.ap.connect(sb.item_imp);
            `uvm_info(get_type_name(), "Connected Timer Monitor analysis port to Scoreboard.", UVM_LOW)
        endfunction

    endclass : timer_soc_env

    // -------------------------------------------------------------------------
    // Timer Single-IP SoC Test
    // -------------------------------------------------------------------------
    class timer_soc_test extends uvm_test;
        `uvm_component_utils(timer_soc_test)

        timer_soc_env env;

        function new(string name = "timer_soc_test", uvm_component parent = null);
            super.new(name, parent);
        endfunction

        virtual function void build_phase(uvm_phase phase);
            super.build_phase(phase);
            env = timer_soc_env::type_id::create("env", this);
        endfunction

        virtual task run_phase(uvm_phase phase);
            phase.raise_objection(this);
            `uvm_info(get_type_name(), "=== Starting Single-IP Timer SoC UVM Integration Test ===", UVM_LOW)

            // Wait for system reset to release and CPU to program Timer
            #500ns;

            // Wait for multiple Timer tick periods (51 cycles * 10ns = 510ns each)
            #15000ns;

            `uvm_info(get_type_name(), "=== Single-IP Timer SoC UVM Integration Test Completed ===", UVM_LOW)
            phase.drop_objection(this);
        endtask

        virtual function void report_phase(uvm_phase phase);
            uvm_report_server svr;
            super.report_phase(phase);
            svr = uvm_report_server::get_server();
            if (svr.get_severity_count(UVM_ERROR) == 0 && svr.get_severity_count(UVM_FATAL) == 0) begin
                `uvm_info(get_type_name(), "\n\n==================================================================\n   >>> SINGLE-IP TIMER UVM INTEGRATION TEST PASSED! <<<\n==================================================================\n", UVM_NONE)
            end else begin
                `uvm_error(get_type_name(), "\n\n==================================================================\n   *** SINGLE-IP TIMER UVM INTEGRATION TEST FAILED! ***\n==================================================================\n")
            end
        endfunction

    endclass : timer_soc_test

endpackage : timer_soc_pkg
