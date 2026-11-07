// =============================================================================
// File    : gpio_monitor.sv
// Project : RISC-V Smart Control SoC Verification
// Type    : UVM 1.2 Verification IP (VIP) Monitor for GPIO & Seven-Segment Display
// =============================================================================

`ifndef GPIO_MONITOR_SV
`define GPIO_MONITOR_SV

class gpio_monitor extends uvm_monitor;
    `uvm_component_utils(gpio_monitor)

    virtual gpio_if                     vif;
    gpio_config                         cfg;
    uvm_analysis_port #(gpio_seq_item)  ap;

    function new(string name = "gpio_monitor", uvm_component parent = null);
        super.new(name, parent);
        ap = new("ap", this);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual gpio_if)::get(this, "", "gpio_vif", vif)) begin
            `uvm_fatal("NOVIF", {"Virtual interface must be set for: ", get_full_name(), ".gpio_vif"})
        end
        if (!uvm_config_db#(gpio_config)::get(this, "", "cfg", cfg)) begin
            `uvm_info("NOCFG", "Using default gpio_config in monitor", UVM_MEDIUM)
            cfg = gpio_config::type_id::create("cfg");
        end
    endfunction

    virtual task run_phase(uvm_phase phase);
        @(posedge vif.rst_n);
        `uvm_info(get_type_name(), "Reset released. Starting GPIO Monitor threads.", UVM_MEDIUM)

        fork
            monitor_gpio_outputs();
            monitor_gpio_irq();
        join
    endtask

    // Monitors changes on gpio_out and decodes 7-segment display patterns
    virtual task monitor_gpio_outputs();
        logic [7:0] prev_out;
        logic [6:0] segs;

        prev_out = 8'hXX;

        forever begin
            @(vif.gpio_out);
            if (vif.gpio_out !== prev_out) begin
                gpio_seq_item item = gpio_seq_item::type_id::create("gpio_mon_item");
                item.sample_time   = $time;
                item.out_data      = vif.gpio_out;
                item.in_data       = vif.gpio_in;
                item.irq_detected  = vif.irq_gpio;
                prev_out           = vif.gpio_out;

                // Decode 7-segment patterns if enabled
                if (cfg.enable_7seg_decoder) begin
                    segs = cfg.active_low_segments ? ~vif.gpio_out[6:0] : vif.gpio_out[6:0];
                    case (segs)
                        7'b0111111: begin item.decoded_digit = 0;  item.decoded_7seg_char = "0"; end
                        7'b0000110: begin item.decoded_digit = 1;  item.decoded_7seg_char = "1"; end
                        7'b1011011: begin item.decoded_digit = 2;  item.decoded_7seg_char = "2"; end
                        7'b1001111: begin item.decoded_digit = 3;  item.decoded_7seg_char = "3"; end
                        7'b1100110: begin item.decoded_digit = 4;  item.decoded_7seg_char = "4"; end
                        7'b1101101: begin item.decoded_digit = 5;  item.decoded_7seg_char = "5"; end
                        7'b1111101: begin item.decoded_digit = 6;  item.decoded_7seg_char = "6"; end
                        7'b0000111: begin item.decoded_digit = 7;  item.decoded_7seg_char = "7"; end
                        7'b1111111: begin item.decoded_digit = 8;  item.decoded_7seg_char = "8"; end
                        7'b1101111: begin item.decoded_digit = 9;  item.decoded_7seg_char = "9"; end
                        7'b1110111: begin item.decoded_digit = 10; item.decoded_7seg_char = "A"; end
                        7'b1111100: begin item.decoded_digit = 11; item.decoded_7seg_char = "b"; end
                        7'b0111001: begin item.decoded_digit = 12; item.decoded_7seg_char = "C"; end
                        7'b1011110: begin item.decoded_digit = 13; item.decoded_7seg_char = "d"; end
                        7'b1111001: begin item.decoded_digit = 14; item.decoded_7seg_char = "E"; end
                        7'b1110001: begin item.decoded_digit = 15; item.decoded_7seg_char = "F"; end
                        default:    begin item.decoded_digit = -1; item.decoded_7seg_char = "RAW_LEDS"; end
                    endcase
                end

                `uvm_info(get_type_name(), $sformatf("Observed %s", item.convert2string()), UVM_MEDIUM)
                ap.write(item);
            end
        end
    endtask

    virtual task monitor_gpio_irq();
        forever begin
            @(vif.irq_gpio);
            `uvm_info(get_type_name(), $sformatf("GPIO Interrupt transitioned: irq_gpio=%0b at %0t ps",
                                                 vif.irq_gpio, $time), UVM_MEDIUM)
        end
    endtask

endclass : gpio_monitor

`endif // GPIO_MONITOR_SV
