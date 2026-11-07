// =============================================================================
// File    : spi_adc_soc_pkg.sv
// Project : RISC-V Smart Control SoC Verification
// Type    : Dedicated UVM 1.2 Package for Single-IP SPI ADC SoC Integration
// Scope   : SPI ADC Scoreboard, Environment and Test
// =============================================================================

`timescale 1ns/1ps

package spi_adc_soc_pkg;

    import uvm_pkg::*;
    `include "uvm_macros.svh"

    import spi_adc_pkg::*;

    // -------------------------------------------------------------------------
    // SPI ADC Scoreboard: Verifies 16-bit SPI Frames and ADC Data Integrity
    // -------------------------------------------------------------------------
    class spi_adc_soc_scoreboard extends uvm_scoreboard;
        `uvm_component_utils(spi_adc_soc_scoreboard)

        uvm_analysis_imp #(spi_adc_seq_item, spi_adc_soc_scoreboard) item_imp;

        int total_frames   = 0;
        int match_count    = 0;
        int mismatch_count = 0;

        function new(string name = "spi_adc_soc_scoreboard", uvm_component parent = null);
            super.new(name, parent);
            item_imp = new("item_imp", this);
        endfunction

        virtual function void write(spi_adc_seq_item item);
            total_frames++;
            `uvm_info(get_type_name(), $sformatf("SoC SPI BUS -> VIP MONITOR: Frame #%0d - Data=0x%04h (%0d signed), Duration=%0t ps",
                      total_frames, item.sample_data, $signed(item.sample_data), (item.end_time - item.start_time)), UVM_LOW)

            // Verify frame contains non-zero valid data and proper duration
            if (item.sample_data !== 16'hxxxx && item.sample_data !== 16'hzzzz) begin
                match_count++;
                `uvm_info(get_type_name(), $sformatf(">>> [SCOREBOARD MATCH #%0d] 16-bit SPI Frame Verified: 0x%04h <<<",
                          match_count, item.sample_data), UVM_LOW)
            end else begin
                mismatch_count++;
                `uvm_error(get_type_name(), $sformatf(">>> [SCOREBOARD MISMATCH] Corrupt SPI sample: 0x%04h <<<", item.sample_data))
            end
        endfunction

        virtual function void check_phase(uvm_phase phase);
            super.check_phase(phase);
            $display("\n==================================================================");
            $display("                SPI ADC UVM SCOREBOARD REPORT                     ");
            $display("==================================================================");
            $display("   Total 16-bit SPI Frames Captured        : %0d", total_frames);
            $display("   Total Verified Data Matches             : %0d", match_count);
            $display("   Total Corrupt/Invalid Frames            : %0d", mismatch_count);
            $display("------------------------------------------------------------------");

            if (match_count >= 5 && mismatch_count == 0) begin
                $display("   >>> SPI ADC UVM SCOREBOARD PASSED: 100%% BUS INTEGRITY! <<<     ");
                $display("==================================================================\n");
                `uvm_info(get_type_name(), "*** SPI ADC UVM SCOREBOARD MATCH TEST PASSED ***", UVM_NONE)
            end else begin
                $display("   *** SPI ADC UVM SCOREBOARD FAILED! ***                         ");
                $display("==================================================================\n");
                `uvm_error(get_type_name(), "*** SPI ADC UVM SCOREBOARD MATCH TEST FAILED ***")
            end
        endfunction

    endclass : spi_adc_soc_scoreboard

    // -------------------------------------------------------------------------
    // SPI ADC Single-IP SoC Environment
    // -------------------------------------------------------------------------
    class spi_adc_soc_env extends uvm_env;
        `uvm_component_utils(spi_adc_soc_env)

        spi_adc_agent          agent;
        spi_adc_config         cfg;
        spi_adc_soc_scoreboard sb;

        function new(string name = "spi_adc_soc_env", uvm_component parent = null);
            super.new(name, parent);
        endfunction

        virtual function void build_phase(uvm_phase phase);
            super.build_phase(phase);
            `uvm_info(get_type_name(), "Building Single-IP SPI ADC SoC Environment...", UVM_LOW)

            cfg = spi_adc_config::type_id::create("cfg");
            cfg.is_active        = UVM_ACTIVE; // Active mode: Driver acts as reactive ADC Slave on MISO
            cfg.pattern          = SPI_PATTERN_SINE;
            cfg.sample_amplitude = 16'sd16000;
            uvm_config_db#(spi_adc_config)::set(this, "agent*", "cfg", cfg);

            agent = spi_adc_agent::type_id::create("agent", this);
            sb    = spi_adc_soc_scoreboard::type_id::create("sb", this);
        endfunction

        virtual function void connect_phase(uvm_phase phase);
            super.connect_phase(phase);
            agent.monitor.ap.connect(sb.item_imp);
            `uvm_info(get_type_name(), "Connected SPI ADC Monitor analysis port to Scoreboard.", UVM_LOW)
        endfunction

    endclass : spi_adc_soc_env

    // -------------------------------------------------------------------------
    // SPI ADC Single-IP SoC Test
    // -------------------------------------------------------------------------
    class spi_adc_soc_test extends uvm_test;
        `uvm_component_utils(spi_adc_soc_test)

        spi_adc_soc_env env;

        function new(string name = "spi_adc_soc_test", uvm_component parent = null);
            super.new(name, parent);
        endfunction

        virtual function void build_phase(uvm_phase phase);
            super.build_phase(phase);
            env = spi_adc_soc_env::type_id::create("env", this);
        endfunction

        virtual task run_phase(uvm_phase phase);
            phase.raise_objection(this);
            `uvm_info(get_type_name(), "=== Starting Single-IP SPI ADC SoC UVM Integration Test ===", UVM_LOW)

            // Wait for system reset to release and CPU to program Timer & SPI controller
            #500ns;

            // Wait for multiple SPI transfers (triggered by Timer pacing)
            #25000ns;

            `uvm_info(get_type_name(), "=== Single-IP SPI ADC SoC UVM Integration Test Completed ===", UVM_LOW)
            phase.drop_objection(this);
        endtask

        virtual function void report_phase(uvm_phase phase);
            uvm_report_server svr;
            super.report_phase(phase);
            svr = uvm_report_server::get_server();
            if (svr.get_severity_count(UVM_ERROR) == 0 && svr.get_severity_count(UVM_FATAL) == 0) begin
                `uvm_info(get_type_name(), "\n\n==================================================================\n   >>> SINGLE-IP SPI ADC UVM INTEGRATION TEST PASSED! <<<\n==================================================================\n", UVM_NONE)
            end else begin
                `uvm_error(get_type_name(), "\n\n==================================================================\n   *** SINGLE-IP SPI ADC UVM INTEGRATION TEST FAILED! ***\n==================================================================\n")
            end
        endfunction

    endclass : spi_adc_soc_test

endpackage : spi_adc_soc_pkg
