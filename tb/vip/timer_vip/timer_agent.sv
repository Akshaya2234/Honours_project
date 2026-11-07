// =============================================================================
// File    : timer_agent.sv
// Project : RISC-V Smart Control SoC Verification
// Type    : UVM 1.2 Verification IP (VIP) Agent for System Timer
// =============================================================================

`ifndef TIMER_AGENT_SV
`define TIMER_AGENT_SV

class timer_agent extends uvm_agent;
    `uvm_component_utils(timer_agent)

    virtual timer_if vif;
    timer_config     cfg;
    timer_monitor    monitor;

    function new(string name = "timer_agent", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(timer_config)::get(this, "", "cfg", cfg)) begin
            cfg = timer_config::type_id::create("cfg");
        end

        if (!uvm_config_db#(virtual timer_if)::get(this, "", "timer_vif", vif)) begin
            `uvm_fatal("NOVIF", {"Virtual interface must be set for: ", get_full_name(), ".timer_vif"})
        end

        uvm_config_db#(virtual timer_if)::set(this, "monitor", "timer_vif", vif);
        uvm_config_db#(timer_config)::set(this, "monitor", "cfg", cfg);

        monitor = timer_monitor::type_id::create("monitor", this);
    endfunction

endclass : timer_agent

`endif // TIMER_AGENT_SV
