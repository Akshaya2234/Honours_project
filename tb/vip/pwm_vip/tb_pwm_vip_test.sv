// =============================================================================
// File    : tb_pwm_vip_test.sv
// Project : RISC-V Smart Control SoC Verification
// Type    : UVM 1.2 Standalone Testbench & Sanity Test for PWM VIP
// =============================================================================

`timescale 1ns/1ps

import uvm_pkg::*;
`include "uvm_macros.svh"
import pwm_pkg::*;

// -----------------------------------------------------------------------------
// Environment containing PWM Agent
// -----------------------------------------------------------------------------
class pwm_env extends uvm_env;
    `uvm_component_utils(pwm_env)

    pwm_agent  agent;
    pwm_config cfg;

    function new(string name = "pwm_env", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        cfg = pwm_config::type_id::create("cfg");
        cfg.clk_freq_hz     = 100_000_000;
        cfg.expected_period = 10;
        cfg.expected_duty   = 5;
        cfg.enable_checks   = 1'b1;
        uvm_config_db#(pwm_config)::set(this, "agent*", "cfg", cfg);

        agent = pwm_agent::type_id::create("agent", this);
    endfunction

endclass : pwm_env

// -----------------------------------------------------------------------------
// PWM Sanity Test
// -----------------------------------------------------------------------------
class pwm_vip_sanity_test extends uvm_test;
    `uvm_component_utils(pwm_vip_sanity_test)

    pwm_env env;

    function new(string name = "pwm_vip_sanity_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = pwm_env::type_id::create("env", this);
    endfunction

    virtual task run_phase(uvm_phase phase);
        phase.raise_objection(this);
        `uvm_info(get_type_name(), "=== Starting PWM VIP Sanity Test ===", UVM_LOW)

        // Wait to capture multiple PWM cycles
        #2000ns;

        `uvm_info(get_type_name(), "=== PWM VIP Sanity Test Completed ===", UVM_LOW)
        phase.drop_objection(this);
    endtask

endclass : pwm_vip_sanity_test

// -----------------------------------------------------------------------------
// Top-Level Testbench Module connecting PWM IP & VIP
// -----------------------------------------------------------------------------
module tb_pwm_vip_test;

    logic clk;
    logic rst_n;

    // AXI4-Lite signals to configure PWM DUT
    logic [31:0] s_axi_awaddr;
    logic        s_axi_awvalid;
    wire         s_axi_awready;
    logic [31:0] s_axi_wdata;
    logic [3:0]  s_axi_wstrb;
    logic        s_axi_wvalid;
    wire         s_axi_wready;
    wire  [1:0]  s_axi_bresp;
    wire         s_axi_bvalid;
    logic        s_axi_bready;

    logic [31:0] s_axi_araddr;
    logic        s_axi_arvalid;
    wire         s_axi_arready;
    wire  [31:0] s_axi_rdata;
    wire  [1:0]  s_axi_rresp;
    wire         s_axi_rvalid;
    logic        s_axi_rready;

    // 100 MHz System Clock
    initial begin
        clk = 0;
        forever #5ns clk = ~clk;
    end

    // Instantiate Physical Interface
    pwm_if u_pwm_if(
        .clk   (clk),
        .rst_n (rst_n)
    );

    // Instantiate PWM DUT IP
    pwm #(
        .ADDR_WIDTH (32),
        .DATA_WIDTH (32)
    ) u_pwm_dut (
        .clk           (clk),
        .rst_n         (rst_n),
        .s_axi_awaddr  (s_axi_awaddr),
        .s_axi_awvalid (s_axi_awvalid),
        .s_axi_awready (s_axi_awready),
        .s_axi_wdata   (s_axi_wdata),
        .s_axi_wstrb   (s_axi_wstrb),
        .s_axi_wvalid  (s_axi_wvalid),
        .s_axi_wready  (s_axi_wready),
        .s_axi_bresp   (s_axi_bresp),
        .s_axi_bvalid  (s_axi_bvalid),
        .s_axi_bready  (s_axi_bready),
        .s_axi_araddr  (s_axi_araddr),
        .s_axi_arvalid (s_axi_arvalid),
        .s_axi_arready (s_axi_arready),
        .s_axi_rdata   (s_axi_rdata),
        .s_axi_rresp   (s_axi_rresp),
        .s_axi_rvalid  (s_axi_rvalid),
        .s_axi_rready  (s_axi_rready),
        .pwm_out       (u_pwm_if.pwm_out)
    );

    // Task to write to PWM AXI register
    task automatic axi_write(input logic [31:0] addr, input logic [31:0] data);
        @(posedge clk);
        s_axi_awaddr  <= addr;
        s_axi_awvalid <= 1'b1;
        s_axi_wdata   <= data;
        s_axi_wstrb   <= 4'hF;
        s_axi_wvalid  <= 1'b1;
        s_axi_bready  <= 1'b1;

        wait (s_axi_awready && s_axi_wready);
        @(posedge clk);
        s_axi_awvalid <= 1'b0;
        s_axi_wvalid  <= 1'b0;

        wait (s_axi_bvalid);
        @(posedge clk);
        s_axi_bready  <= 1'b0;
    endtask

    // Configuration sequence
    initial begin
        rst_n         = 0;
        s_axi_awaddr  = 0;
        s_axi_awvalid = 0;
        s_axi_wdata   = 0;
        s_axi_wstrb   = 0;
        s_axi_wvalid  = 0;
        s_axi_bready  = 0;
        s_axi_araddr  = 0;
        s_axi_arvalid = 0;
        s_axi_rready  = 0;

        #100ns;
        rst_n = 1;
        #50ns;

        // Configure PWM: Period = 10 cycles, Duty = 5 cycles (50%), Enable = 1
        axi_write(32'h04, 32'd10); // PWM_PERIOD
        axi_write(32'h08, 32'd5);  // PWM_DUTY
        axi_write(32'h00, 32'd1);  // PWM_ENABLE
    end

    initial begin
        uvm_config_db#(virtual pwm_if)::set(null, "*", "pwm_vif", u_pwm_if);
        run_test("pwm_vip_sanity_test");
    end

endmodule : tb_pwm_vip_test
