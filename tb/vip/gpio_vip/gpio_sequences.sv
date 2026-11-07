// =============================================================================
// File    : gpio_sequences.sv
// Project : RISC-V Smart Control SoC Verification
// Type    : UVM 1.2 Verification IP (VIP) Sequences for GPIO
// =============================================================================

`ifndef GPIO_SEQUENCES_SV
`define GPIO_SEQUENCES_SV

class gpio_base_seq extends uvm_sequence #(gpio_seq_item);
    `uvm_object_utils(gpio_base_seq)

    function new(string name = "gpio_base_seq");
        super.new(name);
    endfunction

    virtual task body();
    endtask
endclass : gpio_base_seq

// Injects a single input pattern onto gpio_in
class gpio_set_input_seq extends gpio_base_seq;
    `uvm_object_utils(gpio_set_input_seq)

    rand logic [7:0] pattern;
    rand int         hold_time;

    constraint c_pattern {
        hold_time inside {[5:15]};
    }

    function new(string name = "gpio_set_input_seq");
        super.new(name);
    endfunction

    virtual task body();
        req = gpio_seq_item::type_id::create("gpio_req");
        start_item(req);
        if (!req.randomize() with { in_data == pattern; hold_cycles == hold_time; }) begin
            `uvm_error(get_type_name(), "Randomization failed")
        end
        finish_item(req);
    endtask
endclass : gpio_set_input_seq

// Walks a 1 across all 8 input bits (testing button/switch isolation)
class gpio_walking_ones_seq extends gpio_base_seq;
    `uvm_object_utils(gpio_walking_ones_seq)

    function new(string name = "gpio_walking_ones_seq");
        super.new(name);
    endfunction

    virtual task body();
        `uvm_info(get_type_name(), "Starting GPIO walking 1s sequence", UVM_LOW)
        for (int i = 0; i < 8; i++) begin
            logic [7:0] test_val = (8'b1 << i);
            req = gpio_seq_item::type_id::create($sformatf("req_%0d", i));
            start_item(req);
            if (!req.randomize() with { in_data == test_val; hold_cycles == 5; }) begin
                `uvm_error(get_type_name(), "Randomization failed")
            end
            finish_item(req);
        end
    endtask
endclass : gpio_walking_ones_seq

`endif // GPIO_SEQUENCES_SV
