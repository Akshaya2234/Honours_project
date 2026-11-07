// =============================================================================
// File    : pwm_monitor.sv
// Project : RISC-V Smart Control SoC Verification
// Type    : UVM 1.2 Verification IP (VIP) Monitor for PWM Controller
// =============================================================================

`ifndef PWM_MONITOR_SV
`define PWM_MONITOR_SV

class pwm_monitor extends uvm_monitor;
    `uvm_component_utils(pwm_monitor)

    virtual pwm_if                      vif;
    pwm_config                          cfg;
    uvm_analysis_port #(pwm_seq_item)   ap;

    function new(string name = "pwm_monitor", uvm_component parent = null);
        super.new(name, parent);
        ap = new("ap", this);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual pwm_if)::get(this, "", "pwm_vif", vif)) begin
            `uvm_fatal("NOVIF", {"Virtual interface must be set for: ", get_full_name(), ".pwm_vif"})
        end
        if (!uvm_config_db#(pwm_config)::get(this, "", "cfg", cfg)) begin
            `uvm_info("NOCFG", "Using default pwm_config in monitor", UVM_MEDIUM)
            cfg = pwm_config::type_id::create("cfg");
        end
    endfunction

    virtual task run_phase(uvm_phase phase);
        time t_rise, t_fall, t_next_rise;
        time clk_period_time;

        @(posedge vif.rst_n);
        `uvm_info(get_type_name(), "Reset released. Starting PWM Monitor.", UVM_MEDIUM)

        clk_period_time = (1.0e9 / real'(cfg.clk_freq_hz)) * 1ns; // 10ns for 100MHz

        forever begin
            // 1. Wait for rising edge of PWM pulse
            @(posedge vif.pwm_out);
            t_rise = $time;

            // 2. Wait for falling edge
            @(negedge vif.pwm_out);
            t_fall = $time;

            // 3. Wait for next rising edge to complete full period
            @(posedge vif.pwm_out);
            t_next_rise = $time;

            // 4. Construct measured sequence item
            begin
                pwm_seq_item item = pwm_seq_item::type_id::create("pwm_item");
                item.pulse_start_time = t_rise;
                item.high_duration    = t_fall - t_rise;
                item.low_duration     = t_next_rise - t_fall;
                item.period_duration  = t_next_rise - t_rise;

                item.high_cycles   = item.high_duration / clk_period_time;
                item.low_cycles    = item.low_duration / clk_period_time;
                item.period_cycles = item.period_duration / clk_period_time;

                if (item.period_duration > 0) begin
                    item.duty_cycle_pct = (real'(item.high_duration) / real'(item.period_duration)) * 100.0;
                    item.frequency_hz   = (1.0e12 / real'(item.period_duration / 1ps));
                end

                `uvm_info(get_type_name(), $sformatf("Sampled %s", item.convert2string()), UVM_MEDIUM)

                // Automated checks against expected values
                if (cfg.enable_checks && cfg.expected_period > 0) begin
                    if (item.period_cycles != cfg.expected_period) begin
                        `uvm_error(get_type_name(), $sformatf("Period mismatch! Expected=%0d cycles, Got=%0d cycles",
                                                              cfg.expected_period, item.period_cycles))
                    end
                end
                if (cfg.enable_checks && cfg.expected_duty > 0) begin
                    if (item.high_cycles != cfg.expected_duty) begin
                        `uvm_error(get_type_name(), $sformatf("Duty cycle count mismatch! Expected=%0d cycles, Got=%0d cycles",
                                                              cfg.expected_duty, item.high_cycles))
                    end
                end

                ap.write(item);
            end
        end
    endtask

endclass : pwm_monitor

`endif // PWM_MONITOR_SV
