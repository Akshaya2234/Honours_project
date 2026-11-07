// =============================================================================
// File    : tb_spi_adc_vip_test.sv
// Project : RISC-V Smart Control SoC Verification
// Type    : UVM 1.2 Standalone Testbench & Sanity Test for SPI ADC VIP
// =============================================================================

`timescale 1ns/1ps

import uvm_pkg::*;
`include "uvm_macros.svh"
import spi_adc_pkg::*;

// -----------------------------------------------------------------------------
// Environment
// -----------------------------------------------------------------------------
class spi_adc_env extends uvm_env;
    `uvm_component_utils(spi_adc_env)

    spi_adc_agent  agent;
    spi_adc_config cfg;

    function new(string name = "spi_adc_env", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        cfg = spi_adc_config::type_id::create("cfg");
        cfg.is_active = UVM_ACTIVE;
        cfg.pattern   = SPI_PATTERN_SINE;
        uvm_config_db#(spi_adc_config)::set(this, "agent*", "cfg", cfg);

        agent = spi_adc_agent::type_id::create("agent", this);
    endfunction

endclass : spi_adc_env

// -----------------------------------------------------------------------------
// Test
// -----------------------------------------------------------------------------
class spi_adc_vip_sanity_test extends uvm_test;
    `uvm_component_utils(spi_adc_vip_sanity_test)

    spi_adc_env env;

    function new(string name = "spi_adc_vip_sanity_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = spi_adc_env::type_id::create("env", this);
    endfunction

    virtual task run_phase(uvm_phase phase);
        phase.raise_objection(this);
        `uvm_info(get_type_name(), "=== Starting SPI ADC VIP Sanity Test ===", UVM_LOW)

        // Wait to capture multiple SPI sample transactions
        #50000ns;

        `uvm_info(get_type_name(), "=== SPI ADC VIP Sanity Test Completed ===", UVM_LOW)
        phase.drop_objection(this);
    endtask

endclass : spi_adc_vip_sanity_test

// -----------------------------------------------------------------------------
// Top-Level Testbench Module
// -----------------------------------------------------------------------------
module tb_spi_adc_vip_test;

    logic clk;
    logic rst_n;
    logic sample_tick;

    wire        sample_ready;
    wire [15:0] sample_data;
    wire        irq_spi;

    // AXI4-Lite lines for SPI Controller CSRs
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

    // Periodic sample_tick generator (emulating Acquisition Timer)
    initial begin
        sample_tick = 0;
        wait(rst_n == 1'b1);
        forever begin
            #500ns;
            @(posedge clk);
            sample_tick = 1'b1;
            @(posedge clk);
            sample_tick = 1'b0;
        end
    end

    // Instantiate SPI Interface
    spi_adc_if u_spi_if(
        .clk   (clk),
        .rst_n (rst_n)
    );

    // Instantiate SPI Controller DUT
    spi_controller #(
        .ADDR_WIDTH (32),
        .DATA_WIDTH (32)
    ) u_spi_dut (
        .clk           (clk),
        .rst_n         (rst_n),
        .sample_tick   (sample_tick),
        .adc_spi_sck   (u_spi_if.adc_spi_sck),
        .adc_spi_mosi  (u_spi_if.adc_spi_mosi),
        .adc_spi_miso  (u_spi_if.adc_spi_miso),
        .adc_spi_cs_n  (u_spi_if.adc_spi_cs_n),
        .sample_ready  (sample_ready),
        .sample_data   (sample_data),
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
        .irq_spi       (irq_spi)
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

    // Configure SPI Controller: EN=1, Auto_Trigger=1, Prescaler=2
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

        // Write SPI_CTRL (0x00): Prescaler=2, Auto_Trigger=1, EN=1 -> 0x23
        axi_write(32'h00, 32'h23);
    end

    initial begin
        uvm_config_db#(virtual spi_adc_if)::set(null, "*", "vif", u_spi_if);
        run_test("spi_adc_vip_sanity_test");
    end

endmodule : tb_spi_adc_vip_test
