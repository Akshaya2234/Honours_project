// =============================================================================
// File    : tb_gpio_vip_test.sv
// Project : RISC-V Smart Control SoC Verification
// Type    : UVM 1.2 Standalone Testbench & Sanity Test for GPIO / 7-Segment VIP
// =============================================================================

`timescale 1ns/1ps

import uvm_pkg::*;
`include "uvm_macros.svh"
import gpio_pkg::*;

// -----------------------------------------------------------------------------
// GPIO Environment
// -----------------------------------------------------------------------------
class gpio_env extends uvm_env;
    `uvm_component_utils(gpio_env)

    gpio_agent  agent;
    gpio_config cfg;

    function new(string name = "gpio_env", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        cfg = gpio_config::type_id::create("cfg");
        cfg.is_active           = UVM_ACTIVE;
        cfg.enable_7seg_decoder = 1'b1;
        cfg.active_low_segments = 1'b0;
        uvm_config_db#(gpio_config)::set(this, "agent*", "cfg", cfg);

        agent = gpio_agent::type_id::create("agent", this);
    endfunction

endclass : gpio_env

// -----------------------------------------------------------------------------
// GPIO Sanity Test
// -----------------------------------------------------------------------------
class gpio_vip_sanity_test extends uvm_test;
    `uvm_component_utils(gpio_vip_sanity_test)

    gpio_env env;

    function new(string name = "gpio_vip_sanity_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = gpio_env::type_id::create("env", this);
    endfunction

    virtual task run_phase(uvm_phase phase);
        gpio_set_input_seq input_seq;
        phase.raise_objection(this);

        `uvm_info(get_type_name(), "=== Starting GPIO & 7-Segment VIP Sanity Test ===", UVM_LOW)

        input_seq = gpio_set_input_seq::type_id::create("input_seq");
        input_seq.pattern = 8'hA5;
        input_seq.hold_time = 10;
        input_seq.start(env.agent.sequencer);

        #500ns;

        `uvm_info(get_type_name(), "=== GPIO & 7-Segment VIP Sanity Test Completed ===", UVM_LOW)
        phase.drop_objection(this);
    endtask

endclass : gpio_vip_sanity_test

// -----------------------------------------------------------------------------
// Top-Level Testbench Module
// -----------------------------------------------------------------------------
module tb_gpio_vip_test;

    logic clk;
    logic rst_n;

    // AXI4-Lite Interface signals for GPIO IP
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

    // 100 MHz Clock Generator
    initial begin
        clk = 0;
        forever #5ns clk = ~clk;
    end

    // Instantiate GPIO Interface
    gpio_if u_gpio_if(
        .clk   (clk),
        .rst_n (rst_n)
    );

    // Instantiate GPIO DUT IP
    gpio #(
        .ADDR_WIDTH (32),
        .DATA_WIDTH (32)
    ) u_gpio_dut (
        .clk           (clk),
        .rst_n         (rst_n),
        .gpio_in       (u_gpio_if.gpio_in),
        .gpio_out      (u_gpio_if.gpio_out),
        .irq_gpio      (u_gpio_if.irq_gpio),
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
        .s_axi_rready  (s_axi_rready)
    );

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

    // Stimulus: Drive 7-Segment display digits to GPIO_OUT (0x04)
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

        // Enable interrupt on pin changes: GPIO_IRQ_EN (0x08) = 0xFF
        axi_write(32'h08, 32'hFF);

        // Display digits: '0' (0x3F), '1' (0x06), '2' (0x5B), '8' (0x7F)
        #20ns;
        axi_write(32'h04, 32'h3F); // Digit '0'
        #50ns;
        axi_write(32'h04, 32'h06); // Digit '1'
        #50ns;
        axi_write(32'h04, 32'h5B); // Digit '2'
        #50ns;
        axi_write(32'h04, 32'h7F); // Digit '8'
    end

    initial begin
        uvm_config_db#(virtual gpio_if)::set(null, "*", "vif", u_gpio_if);
        run_test("gpio_vip_sanity_test");
    end

endmodule : tb_gpio_vip_test
