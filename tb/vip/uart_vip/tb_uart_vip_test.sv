// =============================================================================
// File    : tb_uart_vip_test.sv
// Project : RISC-V Smart Control SoC Verification
// Type    : UVM 1.2 Standalone Testbench & Sanity Test for UART VIP
// =============================================================================

`timescale 1ns/1ps

import uvm_pkg::*;
`include "uvm_macros.svh"
import uart_pkg::*;

// -----------------------------------------------------------------------------
// Simple Environment wrapping the UART Agent and Scoreboard
// -----------------------------------------------------------------------------
class uart_env extends uvm_env;
    `uvm_component_utils(uart_env)

    uart_agent  agent;
    uart_config cfg;

    function new(string name = "uart_env", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        cfg = uart_config::type_id::create("cfg");
        cfg.baud_rate   = 115200;
        cfg.clk_freq_hz = 100_000_000;
        cfg.is_active   = UVM_ACTIVE;
        uvm_config_db#(uart_config)::set(this, "agent*", "cfg", cfg);

        agent = uart_agent::type_id::create("agent", this);
    endfunction

endclass : uart_env

// -----------------------------------------------------------------------------
// Base Test verifying UART VIP transmission & reception
// -----------------------------------------------------------------------------
class uart_vip_sanity_test extends uvm_test;
    `uvm_component_utils(uart_vip_sanity_test)

    uart_env env;

    function new(string name = "uart_vip_sanity_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = uart_env::type_id::create("env", this);
    endfunction

    virtual task run_phase(uvm_phase phase);
        uart_send_string_seq seq;
        phase.raise_objection(this);

        `uvm_info(get_type_name(), "=== Starting UART VIP Sanity Test ===", UVM_LOW)

        seq = uart_send_string_seq::type_id::create("seq");
        seq.message = "HELLO RISC-V SOC";
        seq.start(env.agent.sequencer);

        // Wait for serial frames to clear
        #200000ns;

        `uvm_info(get_type_name(), "=== UART VIP Sanity Test Completed ===", UVM_LOW)
        phase.drop_objection(this);
    endtask

endclass : uart_vip_sanity_test

// -----------------------------------------------------------------------------
// Top-Level Testbench Module
// -----------------------------------------------------------------------------
module tb_uart_vip_test;

    logic clk;
    logic rst_n;

    // 100 MHz System Clock
    initial begin
        clk = 0;
        forever #5ns clk = ~clk;
    end

    // Reset Generator
    initial begin
        rst_n = 0;
        #100ns;
        rst_n = 1;
    end

    // Instantiate Physical Interface
    uart_if u_uart_if(
        .clk   (clk),
        .rst_n (rst_n)
    );

    // Loopback wiring for sanity testing:
    // When VIP driver drives uart_rx, loop it back to uart_tx so monitor verifies it
    assign u_uart_if.uart_tx  = u_uart_if.uart_rx;
    assign u_uart_if.uart_irq = 1'b0;

    initial begin
        // Set virtual interface in config_db
        uvm_config_db#(virtual uart_if)::set(null, "*", "uart_vif", u_uart_if);

        // Run the UVM test
        run_test("uart_vip_sanity_test");
    end

endmodule : tb_uart_vip_test
