// =============================================================================
// File    : tb_timer_vip_test.sv
// Project : RISC-V Smart Control SoC Verification
// Type    : Standalone UVM 1.2 Verification Environment for System Timer VIP
// =============================================================================

`timescale 1ns/1ps

import uvm_pkg::*;
`include "uvm_macros.svh"
import timer_pkg::*;

class timer_vip_test_env extends uvm_env;
    `uvm_component_utils(timer_vip_test_env)

    timer_agent agent;

    function new(string name = "timer_vip_test_env", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        agent = timer_agent::type_id::create("agent", this);
    endfunction
endclass

class timer_vip_sanity_test extends uvm_test;
    `uvm_component_utils(timer_vip_sanity_test)

    timer_vip_test_env env;

    function new(string name = "timer_vip_sanity_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = timer_vip_test_env::type_id::create("env", this);
    endfunction

    virtual task run_phase(uvm_phase phase);
        phase.raise_objection(this);
        `uvm_info(get_type_name(), "=== Starting Timer VIP Sanity Test ===", UVM_LOW)
        #50_000;
        `uvm_info(get_type_name(), "=== Timer VIP Sanity Test Completed ===", UVM_LOW)
        phase.drop_objection(this);
    endtask
endclass

module tb_timer_vip_test;
    logic clk;
    logic rst_n;

    // AXI-Lite signals to drive Timer RTL
    logic [31:0] s_axi_awaddr;
    logic        s_axi_awvalid;
    wire         s_axi_awready;
    logic [31:0] s_axi_wdata;
    logic [3:0]  s_axi_wstrb;
    logic        s_axi_wvalid;
    wire         s_axi_wready;
    wire [1:0]   s_axi_bresp;
    wire         s_axi_bvalid;
    logic        s_axi_bready;

    logic [31:0] s_axi_araddr;
    logic        s_axi_arvalid;
    wire         s_axi_arready;
    wire [31:0]  s_axi_rdata;
    wire [1:0]   s_axi_rresp;
    wire         s_axi_rvalid;
    logic        s_axi_rready;

    // Timer outputs
    wire         sample_tick;
    wire         irq_timer;

    timer_if vif(.clk(clk), .rst_n(rst_n));
    assign vif.sample_tick = sample_tick;
    assign vif.irq_timer   = irq_timer;

    // DUT Instantiation
    timer u_dut (
        .clk(clk),
        .rst_n(rst_n),
        .s_axi_awaddr(s_axi_awaddr),
        .s_axi_awvalid(s_axi_awvalid),
        .s_axi_awready(s_axi_awready),
        .s_axi_wdata(s_axi_wdata),
        .s_axi_wstrb(s_axi_wstrb),
        .s_axi_wvalid(s_axi_wvalid),
        .s_axi_wready(s_axi_wready),
        .s_axi_bresp(s_axi_bresp),
        .s_axi_bvalid(s_axi_bvalid),
        .s_axi_bready(s_axi_bready),
        .s_axi_araddr(s_axi_araddr),
        .s_axi_arvalid(s_axi_arvalid),
        .s_axi_arready(s_axi_arready),
        .s_axi_rdata(s_axi_rdata),
        .s_axi_rresp(s_axi_rresp),
        .s_axi_rvalid(s_axi_rvalid),
        .s_axi_rready(s_axi_rready),
        .sample_tick(sample_tick),
        .irq_timer(irq_timer)
    );

    // Clock generator (100 MHz)
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Configuration and stimulus
    initial begin
        rst_n         = 0;
        s_axi_awaddr  = 0;
        s_axi_awvalid = 0;
        s_axi_wdata   = 0;
        s_axi_wstrb   = 4'hF;
        s_axi_wvalid  = 0;
        s_axi_bready  = 1;
        s_axi_araddr  = 0;
        s_axi_arvalid = 0;
        s_axi_rready  = 1;

        #100 rst_n = 1;
        #20;

        // Configure Timer: Reload = 50 cycles
        @(posedge clk);
        s_axi_awaddr  <= 32'h04; // TIMER_RELOAD
        s_axi_awvalid <= 1;
        s_axi_wdata   <= 32'd50;
        s_axi_wvalid  <= 1;
        wait (s_axi_awready && s_axi_wready);
        @(posedge clk);
        s_axi_awvalid <= 0;
        s_axi_wvalid  <= 0;

        // Enable Timer: CTRL = 1
        @(posedge clk);
        s_axi_awaddr  <= 32'h00; // TIMER_CTRL
        s_axi_awvalid <= 1;
        s_axi_wdata   <= 32'd1;  // EN=1
        s_axi_wvalid  <= 1;
        wait (s_axi_awready && s_axi_wready);
        @(posedge clk);
        s_axi_awvalid <= 0;
        s_axi_wvalid  <= 0;
    end

    initial begin
        uvm_config_db#(virtual timer_if)::set(null, "*", "timer_vif", vif);
        run_test("timer_vip_sanity_test");
    end

endmodule
