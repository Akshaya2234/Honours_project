// =============================================================================
// File    : gpio_driver.sv
// Project : RISC-V Smart Control SoC Verification
// Type    : UVM 1.2 Verification IP (VIP) Driver for GPIO
// =============================================================================

`ifndef GPIO_DRIVER_SV
`define GPIO_DRIVER_SV

class gpio_driver extends uvm_driver #(gpio_seq_item);
    `uvm_component_utils(gpio_driver)

    virtual gpio_if vif;
    gpio_config     cfg;

    function new(string name = "gpio_driver", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual gpio_if)::get(this, "", "gpio_vif", vif) &&
            !uvm_config_db#(virtual gpio_if)::get(this, "", "vif", vif)) begin
            `uvm_fatal("NOVIF", {"Virtual interface must be set for: ", get_full_name(), ".vif (or gpio_vif)"})
        end
        if (!uvm_config_db#(gpio_config)::get(this, "", "cfg", cfg)) begin
            `uvm_info("NOCFG", "Using default gpio_config in driver", UVM_MEDIUM)
            cfg = gpio_config::type_id::create("cfg");
        end
    endfunction

    virtual task run_phase(uvm_phase phase);
        vif.gpio_in <= 8'h00;

        @(posedge vif.rst_n);
        `uvm_info(get_type_name(), "Reset released. GPIO Driver active.", UVM_MEDIUM)

        forever begin
            seq_item_port.get_next_item(req);
            drive_item(req);
            seq_item_port.item_done();
        end
    endtask

    virtual task drive_item(gpio_seq_item item);
        @(posedge vif.clk);
        vif.gpio_in <= item.in_data;
        `uvm_info(get_type_name(), $sformatf("Driving gpio_in = 0x%02h for %0d cycles",
                  item.in_data, item.hold_cycles), UVM_HIGH)

        repeat (item.hold_cycles) @(posedge vif.clk);
    endtask

endclass : gpio_driver

`endif // GPIO_DRIVER_SV
