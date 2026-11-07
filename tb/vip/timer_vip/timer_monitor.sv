// =============================================================================
// File    : timer_monitor.sv
// Project : RISC-V Smart Control SoC Verification
// Type    : UVM 1.2 Verification IP (VIP) Monitor for System Timer
// =============================================================================

`ifndef TIMER_MONITOR_SV
`define TIMER_MONITOR_SV

class timer_monitor extends uvm_monitor;
    `uvm_component_utils(timer_monitor)

    virtual timer_if                     vif;
    timer_config                         cfg;
    uvm_analysis_port #(timer_seq_item)  ap;

    function new(string name = "timer_monitor", uvm_component parent = null);
        super.new(name, parent);
        ap = new("ap", this);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual timer_if)::get(this, "", "timer_vif", vif)) begin
            `uvm_fatal("NOVIF", {"Virtual interface must be set for: ", get_full_name(), ".timer_vif"})
        end
        if (!uvm_config_db#(timer_config)::get(this, "", "cfg", cfg)) begin
            cfg = timer_config::type_id::create("cfg");
        end
    endfunction

    virtual task run_phase(uvm_phase phase);
        @(posedge vif.rst_n);
        `uvm_info(get_type_name(), "Reset released. Starting Timer Monitor threads.", UVM_MEDIUM)

        fork
            monitor_ticks();
            monitor_irq();
        join
    endtask

    virtual task monitor_ticks();
        int cycle_count = 0;
        time last_tick_time = 0;

        forever begin
            @(posedge vif.clk);
            if (!vif.rst_n) begin
                cycle_count = 0;
                last_tick_time = 0;
            end else begin
                cycle_count++;
                if (vif.sample_tick === 1'b1) begin
                    timer_seq_item item = timer_seq_item::type_id::create("timer_tick_item");
                    item.timestamp          = $time;
                    item.tick_period_cycles = cycle_count;
                    item.irq_asserted       = vif.irq_timer;
                    last_tick_time          = $time;
                    cycle_count             = 0;

                    `uvm_info(get_type_name(), $sformatf("Sample tick observed: %s", item.convert2string()), UVM_MEDIUM)
                    ap.write(item);
                end
            end
        end
    endtask

    virtual task monitor_irq();
        forever begin
            @(vif.irq_timer);
            `uvm_info(get_type_name(), $sformatf("Timer IRQ transitioned to %0b at %0t ps", vif.irq_timer, $time), UVM_HIGH)
        end
    endtask

endclass : timer_monitor

`endif // TIMER_MONITOR_SV
