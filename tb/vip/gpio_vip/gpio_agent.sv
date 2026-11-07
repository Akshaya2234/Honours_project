// =============================================================================
// File    : gpio_agent.sv
// Project : RISC-V Smart Control SoC Verification
// Type    : UVM 1.2 Verification IP (VIP) Agent for GPIO
// =============================================================================

`ifndef GPIO_AGENT_SV
`define GPIO_AGENT_SV

class gpio_agent extends uvm_agent;
    `uvm_component_utils(gpio_agent)

    virtual gpio_if vif;
    gpio_config     cfg;
    gpio_sequencer  sequencer;
    gpio_driver     driver;
    gpio_monitor    monitor;

    function new(string name = "gpio_agent", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        if (!uvm_config_db#(gpio_config)::get(this, "", "cfg", cfg)) begin
            `uvm_info(get_type_name(), "No gpio_config found; creating default", UVM_MEDIUM)
            cfg = gpio_config::type_id::create("cfg");
        end

        if (!uvm_config_db#(virtual gpio_if)::get(this, "", "gpio_vif", vif) &&
            !uvm_config_db#(virtual gpio_if)::get(this, "", "vif", vif)) begin
            `uvm_fatal("NOVIF", {"Virtual interface must be set for: ", get_full_name(), ".vif (or gpio_vif)"})
        end

        uvm_config_db#(gpio_config)::set(this, "driver", "cfg", cfg);
        uvm_config_db#(gpio_config)::set(this, "monitor", "cfg", cfg);
        uvm_config_db#(virtual gpio_if)::set(this, "driver", "vif", vif);
        uvm_config_db#(virtual gpio_if)::set(this, "driver", "gpio_vif", vif);
        uvm_config_db#(virtual gpio_if)::set(this, "monitor", "vif", vif);
        uvm_config_db#(virtual gpio_if)::set(this, "monitor", "gpio_vif", vif);

        monitor = gpio_monitor::type_id::create("monitor", this);

        if (cfg.is_active == UVM_ACTIVE) begin
            driver    = gpio_driver::type_id::create("driver", this);
            sequencer = gpio_sequencer::type_id::create("sequencer", this);
        end
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        if (cfg.is_active == UVM_ACTIVE) begin
            driver.seq_item_port.connect(sequencer.seq_item_export);
        end
    endfunction

endclass : gpio_agent

`endif // GPIO_AGENT_SV
