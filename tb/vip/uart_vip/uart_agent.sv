// =============================================================================
// File    : uart_agent.sv
// Project : RISC-V Smart Control SoC Verification
// Type    : UVM 1.2 Verification IP (VIP) Agent
// =============================================================================

`ifndef UART_AGENT_SV
`define UART_AGENT_SV

class uart_agent extends uvm_agent;
    `uvm_component_utils(uart_agent)

    virtual uart_if                         vif;
    uart_config                             cfg;
    uart_sequencer                          sequencer;
    uart_driver                             driver;
    uart_monitor                            monitor;

    function new(string name = "uart_agent", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        if (!uvm_config_db#(uart_config)::get(this, "", "cfg", cfg)) begin
            `uvm_info(get_type_name(), "No uart_config found in config_db; creating default", UVM_MEDIUM)
            cfg = uart_config::type_id::create("cfg");
        end

        if (!uvm_config_db#(virtual uart_if)::get(this, "", "uart_vif", vif)) begin
            `uvm_fatal("NOVIF", {"Virtual interface must be set for: ", get_full_name(), ".uart_vif"})
        end

        // Pass config and vif down to child components
        uvm_config_db#(uart_config)::set(this, "driver", "cfg", cfg);
        uvm_config_db#(uart_config)::set(this, "monitor", "cfg", cfg);
        uvm_config_db#(virtual uart_if)::set(this, "driver", "uart_vif", vif);
        uvm_config_db#(virtual uart_if)::set(this, "monitor", "uart_vif", vif);

        monitor = uart_monitor::type_id::create("monitor", this);

        if (cfg.is_active == UVM_ACTIVE) begin
            driver    = uart_driver::type_id::create("driver", this);
            sequencer = uart_sequencer::type_id::create("sequencer", this);
        end
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        if (cfg.is_active == UVM_ACTIVE) begin
            driver.seq_item_port.connect(sequencer.seq_item_export);
        end
    endfunction

endclass : uart_agent

`endif // UART_AGENT_SV
