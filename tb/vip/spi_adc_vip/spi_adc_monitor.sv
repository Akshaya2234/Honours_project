// =============================================================================
// File    : spi_adc_monitor.sv
// Project : RISC-V Smart Control SoC Verification
// Type    : UVM 1.2 Verification IP (VIP) Monitor for SPI ADC
// =============================================================================

`ifndef SPI_ADC_MONITOR_SV
`define SPI_ADC_MONITOR_SV

class spi_adc_monitor extends uvm_monitor;
    `uvm_component_utils(spi_adc_monitor)

    virtual spi_adc_if                      vif;
    spi_adc_config                          cfg;
    uvm_analysis_port #(spi_adc_seq_item)   ap;
    int                                     mon_sample_idx = 0;

    function new(string name = "spi_adc_monitor", uvm_component parent = null);
        super.new(name, parent);
        ap = new("ap", this);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual spi_adc_if)::get(this, "", "spi_adc_vif", vif) &&
            !uvm_config_db#(virtual spi_adc_if)::get(this, "", "vif", vif)) begin
            `uvm_fatal("NOVIF", {"Virtual interface must be set for: ", get_full_name(), ".vif (or spi_adc_vif)"})
        end
        if (!uvm_config_db#(spi_adc_config)::get(this, "", "cfg", cfg)) begin
            `uvm_info("NOCFG", "Using default spi_adc_config in monitor", UVM_MEDIUM)
            cfg = spi_adc_config::type_id::create("cfg");
        end
    endfunction

    virtual task run_phase(uvm_phase phase);
        logic [15:0] captured_miso;
        logic [15:0] captured_mosi;
        time         t_cs_assert;

        @(posedge vif.rst_n);
        `uvm_info(get_type_name(), "Reset released. Starting SPI ADC Monitor.", UVM_MEDIUM)

        forever begin
            // 1. Wait for CS active
            @(negedge vif.adc_spi_cs_n);
            t_cs_assert   = $time;
            captured_miso = 16'h0000;
            captured_mosi = 16'h0000;

            // 2. Sample 16 bits on rising SCK edges (SPI Mode 0 standard sampling)
            for (int i = 15; i >= 0; i--) begin
                @(posedge vif.adc_spi_sck);
                if (vif.adc_spi_cs_n !== 1'b0) break;
                captured_miso[i] = vif.adc_spi_miso;
                captured_mosi[i] = vif.adc_spi_mosi;
            end

            // 3. Wait for CS deassertion
            @(posedge vif.adc_spi_cs_n);

            begin
                spi_adc_seq_item item = spi_adc_seq_item::type_id::create("spi_item");
                item.start_time   = t_cs_assert;
                item.end_time     = $time;
                item.sample_data  = captured_miso;
                item.mosi_data    = captured_mosi;
                item.sample_index = mon_sample_idx;
                mon_sample_idx++;

                `uvm_info(get_type_name(), $sformatf("Captured %s", item.convert2string()), UVM_MEDIUM)
                ap.write(item);
            end
        end
    endtask

endclass : spi_adc_monitor

`endif // SPI_ADC_MONITOR_SV
