// =============================================================================
// File    : gpio_soc_pkg.sv
// Project : RISC-V Smart Control SoC Verification
// Type    : Dedicated UVM 1.2 Package for Single-IP GPIO SoC Integration
// Scope   : GPIO Scoreboard, Sequences, Environment and Test
// =============================================================================

`timescale 1ns/1ps

package gpio_soc_pkg;

    import uvm_pkg::*;
    `include "uvm_macros.svh"

    import gpio_pkg::*;

    // -------------------------------------------------------------------------
    // GPIO Scoreboard: Compares Inputs Driven to SoC vs Outputs Echoed by SoC
    // -------------------------------------------------------------------------
    class gpio_soc_scoreboard extends uvm_scoreboard;
        `uvm_component_utils(gpio_soc_scoreboard)

        uvm_analysis_imp #(gpio_seq_item, gpio_soc_scoreboard) item_imp;

        logic [7:0] expected_queue[$];
        int total_driven   = 0;
        int total_observed = 0;
        int match_count    = 0;
        int mismatch_count = 0;

        function new(string name = "gpio_soc_scoreboard", uvm_component parent = null);
            super.new(name, parent);
            item_imp = new("item_imp", this);
        endfunction

        function void expect_value(logic [7:0] val);
            expected_queue.push_back(val);
            total_driven++;
            `uvm_info(get_type_name(), $sformatf("VIP DRIVER -> SoC GPIO IN: Queued expected output 0x%02h", val), UVM_LOW)
        endfunction

        virtual function void write(gpio_seq_item item);
            total_observed++;
            `uvm_info(get_type_name(), $sformatf("SoC GPIO OUT -> VIP MONITOR: Captured output 0x%02h (7-Seg: '%s', digit=%0d, irq=%b)",
                      item.out_data, item.decoded_7seg_char, item.decoded_digit, item.irq_detected), UVM_LOW)

            if (expected_queue.size() > 0) begin
                logic [7:0] exp_val = expected_queue.pop_front();
                if (item.out_data === exp_val) begin
                    match_count++;
                    `uvm_info(get_type_name(), $sformatf(">>> [SCOREBOARD MATCH #%0d] Driven GPIO 0x%02h == Output 0x%02h ('%s') - VERIFIED! <<<",
                              match_count, exp_val, item.out_data, item.decoded_7seg_char), UVM_LOW)
                end else begin
                    mismatch_count++;
                    `uvm_error(get_type_name(), $sformatf(">>> [SCOREBOARD MISMATCH] Expected 0x%02h, but received 0x%02h! <<<",
                               exp_val, item.out_data))
                end
            end
        endfunction

        virtual function void check_phase(uvm_phase phase);
            super.check_phase(phase);
            $display("\n==================================================================");
            $display("                   GPIO UVM SCOREBOARD REPORT                     ");
            $display("==================================================================");
            $display("   Total Patterns Driven into SoC GPIO IN  : %0d", total_driven);
            $display("   Total Patterns Captured from GPIO OUT   : %0d", total_observed);
            $display("   Total Verified Matches                  : %0d", match_count);
            $display("   Total Data Mismatches                   : %0d", mismatch_count);
            $display("------------------------------------------------------------------");

            if (match_count >= 4 && mismatch_count == 0) begin
                $display("   >>> GPIO UVM SCOREBOARD PASSED: 100%% DATA INTEGRITY! <<<       ");
                $display("==================================================================\n");
                `uvm_info(get_type_name(), "*** GPIO UVM SCOREBOARD MATCH TEST PASSED ***", UVM_NONE)
            end else begin
                $display("   *** GPIO UVM SCOREBOARD FAILED! ***                            ");
                $display("==================================================================\n");
                `uvm_error(get_type_name(), "*** GPIO UVM SCOREBOARD MATCH TEST FAILED ***")
            end
        endfunction

    endclass : gpio_soc_scoreboard

    // -------------------------------------------------------------------------
    // GPIO Sequence: Drives 7-segment display patterns ('0', '1', '2', '8')
    // -------------------------------------------------------------------------
    class gpio_soc_seq extends uvm_sequence #(gpio_seq_item);
        `uvm_object_utils(gpio_soc_seq)

        gpio_soc_scoreboard sb;

        function new(string name = "gpio_soc_seq");
            super.new(name);
        endfunction

        virtual task body();
            byte patterns[4] = '{8'h3F, 8'h06, 8'h5B, 8'h7F}; // '0', '1', '2', '8'
            string desc[4]   = '{"Digit '0'", "Digit '1'", "Digit '2'", "Digit '8'"};

            `uvm_info(get_type_name(), "\n------------------------------------------------------------------\n   Starting GPIO UVM Stimulus Sequence (4 Digits)\n------------------------------------------------------------------", UVM_LOW)

            for (int i = 0; i < 4; i++) begin
                req = gpio_seq_item::type_id::create($sformatf("gpio_pat_%0d", i));
                start_item(req);
                req.in_data     = patterns[i];
                req.hold_cycles = 50;

                if (sb != null) begin
                    sb.expect_value(patterns[i]);
                end

                `uvm_info(get_type_name(), $sformatf("Driving GPIO Input [%0d/4]: 0x%02h (%s)",
                          i+1, patterns[i], desc[i]), UVM_LOW)
                finish_item(req);

                // Allow processor loop to read from GPIO_IN and write to GPIO_OUT
                #1000ns;
            end

            `uvm_info(get_type_name(), "All 4 GPIO test patterns driven into SoC successfully.", UVM_LOW)
        endtask
    endclass : gpio_soc_seq

    // -------------------------------------------------------------------------
    // GPIO Single-IP SoC Environment
    // -------------------------------------------------------------------------
    class gpio_soc_env extends uvm_env;
        `uvm_component_utils(gpio_soc_env)

        gpio_agent          agent;
        gpio_config         cfg;
        gpio_soc_scoreboard sb;

        function new(string name = "gpio_soc_env", uvm_component parent = null);
            super.new(name, parent);
        endfunction

        virtual function void build_phase(uvm_phase phase);
            super.build_phase(phase);
            `uvm_info(get_type_name(), "Building Single-IP GPIO SoC Environment...", UVM_LOW)

            cfg = gpio_config::type_id::create("cfg");
            cfg.is_active           = UVM_ACTIVE;
            cfg.enable_7seg_decoder = 1'b1;
            cfg.active_low_segments = 1'b0;
            uvm_config_db#(gpio_config)::set(this, "agent*", "cfg", cfg);

            agent = gpio_agent::type_id::create("agent", this);
            sb    = gpio_soc_scoreboard::type_id::create("sb", this);
        endfunction

        virtual function void connect_phase(uvm_phase phase);
            super.connect_phase(phase);
            agent.monitor.ap.connect(sb.item_imp);
            `uvm_info(get_type_name(), "Connected GPIO Monitor analysis port to Scoreboard.", UVM_LOW)
        endfunction

    endclass : gpio_soc_env

    // -------------------------------------------------------------------------
    // GPIO Single-IP SoC Test
    // -------------------------------------------------------------------------
    class gpio_soc_test extends uvm_test;
        `uvm_component_utils(gpio_soc_test)

        gpio_soc_env env;

        function new(string name = "gpio_soc_test", uvm_component parent = null);
            super.new(name, parent);
        endfunction

        virtual function void build_phase(uvm_phase phase);
            super.build_phase(phase);
            env = gpio_soc_env::type_id::create("env", this);
        endfunction

        virtual task run_phase(uvm_phase phase);
            gpio_soc_seq seq;
            phase.raise_objection(this);
            `uvm_info(get_type_name(), "=== Starting Single-IP GPIO SoC UVM Integration Test ===", UVM_LOW)

            // Wait for system reset to release
            #500ns;

            seq = gpio_soc_seq::type_id::create("seq");
            seq.sb = env.sb;
            seq.start(env.agent.sequencer);

            // Wait for final output to settle and be monitored
            #2000ns;

            `uvm_info(get_type_name(), "=== Single-IP GPIO SoC UVM Integration Test Stimulus Completed ===", UVM_LOW)
            phase.drop_objection(this);
        endtask

        virtual function void report_phase(uvm_phase phase);
            uvm_report_server svr;
            super.report_phase(phase);
            svr = uvm_report_server::get_server();
            if (svr.get_severity_count(UVM_ERROR) == 0 && svr.get_severity_count(UVM_FATAL) == 0) begin
                `uvm_info(get_type_name(), "\n\n==================================================================\n   >>> SINGLE-IP GPIO UVM INTEGRATION TEST PASSED! <<<\n==================================================================\n", UVM_NONE)
            end else begin
                `uvm_error(get_type_name(), "\n\n==================================================================\n   *** SINGLE-IP GPIO UVM INTEGRATION TEST FAILED! ***\n==================================================================\n")
            end
        endfunction

    endclass : gpio_soc_test

endpackage : gpio_soc_pkg
