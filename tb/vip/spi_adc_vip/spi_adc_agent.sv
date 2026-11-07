// =============================================================================
// File    : spi_adc_agent.sv
// Project : RISC-V Smart Control SoC Verification
// Type    : UVM 1.2 Verification IP (VIP) Agent for SPI ADC
// =============================================================================

`ifndef SPI_ADC_AGENT_SV
`define SPI_ADC_AGENT_SV

class spi_adc_agent extends uvm_agent;
    `uvm_component_utils(spi_adc_agent)

    virtual spi_adc_if  vif;
    spi_adc_config      cfg;
    spi_adc_sequencer   sequencer;
    spi_adc_driver      driver;
    spi_adc_monitor     monitor;

    function new(string name = "spi_adc_agent", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        if (!uvm_config_db#(spi_adc_config)::get(this, "", "cfg", cfg)) begin
            `uvm_info(get_type_name(), "No spi_adc_config found; creating default", UVM_MEDIUM)
            cfg = spi_adc_config::type_id::create("cfg");
        end

        if (!uvm_config_db#(virtual spi_adc_if)::get(this, "", "spi_adc_vif", vif) &&
            !uvm_config_db#(virtual spi_adc_if)::get(this, "", "vif", vif)) begin
            `uvm_fatal("NOVIF", {"Virtual interface must be set for: ", get_full_name(), ".vif (or spi_adc_vif)"})
        end

        uvm_config_db#(spi_adc_config)::set(this, "driver", "cfg", cfg);
        uvm_config_db#(spi_adc_config)::set(this, "monitor", "cfg", cfg);
        uvm_config_db#(virtual spi_adc_if)::set(this, "driver", "vif", vif);
        uvm_config_db#(virtual spi_adc_if)::set(this, "driver", "spi_adc_vif", vif);
        uvm_config_db#(virtual spi_adc_if)::set(this, "monitor", "vif", vif);
        uvm_config_db#(virtual spi_adc_if)::set(this, "monitor", "spi_adc_vif", vif);

        monitor = spi_adc_monitor::type_id::create("monitor", this);

        if (cfg.is_active == UVM_ACTIVE) begin
            driver    = spi_adc_driver::type_id::create("driver", this);
            sequencer = spi_adc_sequencer::type_id::create("sequencer", this);
        end
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        if (cfg.is_active == UVM_ACTIVE) begin
            driver.seq_item_port.connect(sequencer.seq_item_export);
        end
    endfunction

endclass : spi_adc_agent

`endif // SPI_ADC_AGENT_SV
