// =============================================================================
// File    : pwm_agent.sv
// Project : RISC-V Smart Control SoC Verification
// Type    : UVM 1.2 Verification IP (VIP) Agent for PWM Controller
// =============================================================================

`ifndef PWM_AGENT_SV
`define PWM_AGENT_SV

class pwm_agent extends uvm_agent;
    `uvm_component_utils(pwm_agent)

    virtual pwm_if  vif;
    pwm_config      cfg;
    pwm_monitor     monitor;

    function new(string name = "pwm_agent", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        if (!uvm_config_db#(pwm_config)::get(this, "", "cfg", cfg)) begin
            `uvm_info(get_type_name(), "No pwm_config found; creating default", UVM_MEDIUM)
            cfg = pwm_config::type_id::create("cfg");
        end

        if (!uvm_config_db#(virtual pwm_if)::get(this, "", "pwm_vif", vif)) begin
            `uvm_fatal("NOVIF", {"Virtual interface must be set for: ", get_full_name(), ".pwm_vif"})
        end

        uvm_config_db#(pwm_config)::set(this, "monitor", "cfg", cfg);
        uvm_config_db#(virtual pwm_if)::set(this, "monitor", "pwm_vif", vif);

        monitor = pwm_monitor::type_id::create("monitor", this);
    endfunction

endclass : pwm_agent

`endif // PWM_AGENT_SV
