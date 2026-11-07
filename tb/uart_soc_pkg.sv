// =============================================================================
// File    : uart_soc_pkg.sv
// Project : RISC-V Smart Control SoC Verification
// Type    : Dedicated UVM 1.2 Package for Single-IP UART SoC Integration
// Scope   : UART Scoreboard, Sequences, Environment and Test
// =============================================================================

`timescale 1ns/1ps

package uart_soc_pkg;

    import uvm_pkg::*;
    `include "uvm_macros.svh"

    import uart_pkg::*;

    `uvm_analysis_imp_decl(_rx)
    `uvm_analysis_imp_decl(_tx)

    // -------------------------------------------------------------------------
    // UART Scoreboard: Compares Data Sent into SoC RX vs Echoed out of SoC TX
    // -------------------------------------------------------------------------
    class uart_soc_scoreboard extends uvm_scoreboard;
        `uvm_component_utils(uart_soc_scoreboard)

        uvm_analysis_imp_rx #(uart_seq_item, uart_soc_scoreboard) rx_imp;
        uvm_analysis_imp_tx #(uart_seq_item, uart_soc_scoreboard) tx_imp;

        logic [7:0] expected_queue[$];
        int total_sent     = 0;
        int total_received = 0;
        int match_count    = 0;
        int mismatch_count = 0;

        function new(string name = "uart_soc_scoreboard", uvm_component parent = null);
            super.new(name, parent);
            rx_imp = new("rx_imp", this);
            tx_imp = new("tx_imp", this);
        endfunction

        virtual function void write_rx(uart_seq_item item);
            `uvm_info(get_type_name(), $sformatf("VIP DRIVER -> SoC UART RX: Sent byte 0x%02h ('%c')",
                      item.data, (item.data >= 32 && item.data <= 126) ? item.data : 8'h2E), UVM_LOW)
            expected_queue.push_back(item.data);
            total_sent++;
        endfunction

        virtual function void write_tx(uart_seq_item item);
            total_received++;
            `uvm_info(get_type_name(), $sformatf("SoC UART TX -> VIP MONITOR: Captured byte 0x%02h ('%c')",
                      item.data, (item.data >= 32 && item.data <= 126) ? item.data : 8'h2E), UVM_LOW)

            if (expected_queue.size() == 0) begin
                `uvm_error(get_type_name(), $sformatf("Unexpected byte on uart_tx: 0x%02h", item.data))
                mismatch_count++;
            end else begin
                logic [7:0] exp_byte = expected_queue.pop_front();
                if (item.data === exp_byte) begin
                    match_count++;
                    `uvm_info(get_type_name(), $sformatf(">>> [SCOREBOARD MATCH #%0d] Transmitted 0x%02h == Received 0x%02h - VERIFIED! <<<",
                              match_count, exp_byte, item.data), UVM_LOW)
                end else begin
                    mismatch_count++;
                    `uvm_error(get_type_name(), $sformatf(">>> [SCOREBOARD MISMATCH] Expected 0x%02h, but received 0x%02h! <<<",
                               exp_byte, item.data))
                end
            end
        endfunction

        virtual function void check_phase(uvm_phase phase);
            super.check_phase(phase);
            $display("\n==================================================================");
            $display("                   UART UVM SCOREBOARD REPORT                     ");
            $display("==================================================================");
            $display("   Total Characters Sent into SoC RX     : %0d", total_sent);
            $display("   Total Characters Received from SoC TX : %0d", total_received);
            $display("   Total Verified Matches                : %0d", match_count);
            $display("   Total Data Mismatches                 : %0d", mismatch_count);
            $display("------------------------------------------------------------------");

            if (match_count == 3 && mismatch_count == 0 && expected_queue.size() == 0) begin
                $display("   >>> UART UVM SCOREBOARD PASSED: 100%% DATA INTEGRITY! <<<       ");
                $display("==================================================================\n");
                `uvm_info(get_type_name(), "*** UART UVM SCOREBOARD MATCH TEST PASSED ***", UVM_NONE)
            end else begin
                $display("   *** UART UVM SCOREBOARD FAILED! ***                            ");
                $display("==================================================================\n");
                `uvm_error(get_type_name(), "*** UART UVM SCOREBOARD MATCH TEST FAILED ***")
            end
        endfunction

    endclass : uart_soc_scoreboard

    // -------------------------------------------------------------------------
    // UART Sequence: Transmits 0x55, 0xAA, and 0x39
    // -------------------------------------------------------------------------
    class uart_soc_seq extends uvm_sequence #(uart_seq_item);
        `uvm_object_utils(uart_soc_seq)

        function new(string name = "uart_soc_seq");
            super.new(name);
        endfunction

        virtual task body();
            byte test_chars[3] = '{8'h55, 8'hAA, 8'h39};

            `uvm_info(get_type_name(), "\n------------------------------------------------------------------\n   Starting UART UVM Stimulus Sequence: 0x55, 0xAA, 0x39\n------------------------------------------------------------------", UVM_LOW)

            for (int i = 0; i < 3; i++) begin
                req = uart_seq_item::type_id::create($sformatf("uart_char_%0d", i));
                start_item(req);
                if (!req.randomize() with {
                    data        == test_chars[i];
                    baud_rate   == 115200;
                    parity_type == UART_PARITY_NONE;
                    stop_bits   == UART_STOP_1;
                    data_bits   == UART_DATA_8;
                }) begin
                    `uvm_error(get_type_name(), "Randomization failed")
                end
                `uvm_info(get_type_name(), $sformatf("Sending character [%0d/3] = 0x%02h ('%c')",
                          i+1, test_chars[i], (test_chars[i] >= 32 && test_chars[i] <= 126) ? test_chars[i] : 8'h2E), UVM_LOW)
                finish_item(req);

                // Guard time allowing hardware UART to deserialize, buffer, and processor to echo
                #30000ns;
            end

            `uvm_info(get_type_name(), "All 3 test characters transmitted into SoC UART RX successfully.", UVM_LOW)
        endtask
    endclass : uart_soc_seq

    // -------------------------------------------------------------------------
    // UART Single-IP SoC Environment
    // -------------------------------------------------------------------------
    class uart_soc_env extends uvm_env;
        `uvm_component_utils(uart_soc_env)

        uart_agent          agent;
        uart_config         cfg;
        uart_soc_scoreboard sb;

        function new(string name = "uart_soc_env", uvm_component parent = null);
            super.new(name, parent);
        endfunction

        virtual function void build_phase(uvm_phase phase);
            super.build_phase(phase);
            `uvm_info(get_type_name(), "Building Single-IP UART SoC Environment...", UVM_LOW)

            cfg = uart_config::type_id::create("cfg");
            cfg.baud_rate   = 115200;
            cfg.clk_freq_hz = 100_000_000;
            cfg.is_active   = UVM_ACTIVE; // Active mode: Driver + Sequencer + Monitor
            uvm_config_db#(uart_config)::set(this, "agent*", "cfg", cfg);

            agent = uart_agent::type_id::create("agent", this);
            sb    = uart_soc_scoreboard::type_id::create("sb", this);
        endfunction

        virtual function void connect_phase(uvm_phase phase);
            super.connect_phase(phase);
            agent.monitor.rx_ap.connect(sb.rx_imp);
            agent.monitor.tx_ap.connect(sb.tx_imp);
            `uvm_info(get_type_name(), "Connected UART Monitor RX & TX analysis ports to Scoreboard.", UVM_LOW)
        endfunction

    endclass : uart_soc_env

    // -------------------------------------------------------------------------
    // UART Single-IP SoC Test
    // -------------------------------------------------------------------------
    class uart_soc_test extends uvm_test;
        `uvm_component_utils(uart_soc_test)

        uart_soc_env env;

        function new(string name = "uart_soc_test", uvm_component parent = null);
            super.new(name, parent);
        endfunction

        virtual function void build_phase(uvm_phase phase);
            super.build_phase(phase);
            env = uart_soc_env::type_id::create("env", this);
        endfunction

        virtual task run_phase(uvm_phase phase);
            uart_soc_seq seq;
            phase.raise_objection(this);
            `uvm_info(get_type_name(), "=== Starting Single-IP UART SoC UVM Integration Test ===", UVM_LOW)

            // Wait for system reset to release
            #500ns;

            seq = uart_soc_seq::type_id::create("seq");
            seq.start(env.agent.sequencer);

            // Wait for final character to be completely transmitted and echoed
            #150000ns;

            `uvm_info(get_type_name(), "=== Single-IP UART SoC UVM Integration Test Stimulus Completed ===", UVM_LOW)
            phase.drop_objection(this);
        endtask

        virtual function void report_phase(uvm_phase phase);
            uvm_report_server svr;
            super.report_phase(phase);
            svr = uvm_report_server::get_server();
            if (svr.get_severity_count(UVM_ERROR) == 0 && svr.get_severity_count(UVM_FATAL) == 0) begin
                `uvm_info(get_type_name(), "\n\n==================================================================\n   >>> SINGLE-IP UART UVM INTEGRATION TEST PASSED! <<<\n==================================================================\n", UVM_NONE)
            end else begin
                `uvm_error(get_type_name(), "\n\n==================================================================\n   *** SINGLE-IP UART UVM INTEGRATION TEST FAILED! ***\n==================================================================\n")
            end
        endfunction

    endclass : uart_soc_test

endpackage : uart_soc_pkg
