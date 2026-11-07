// =============================================================================
// File    : gpio_seq_item.sv
// Project : RISC-V Smart Control SoC Verification
// Type    : UVM 1.2 Verification IP (VIP) Sequence Item for GPIO & 7-Segment Display
// =============================================================================

`ifndef GPIO_SEQ_ITEM_SV
`define GPIO_SEQ_ITEM_SV

class gpio_seq_item extends uvm_sequence_item;
    `uvm_object_utils(gpio_seq_item)

    // Input stimulus data
    rand logic [7:0] in_data;
    rand int         hold_cycles;

    // Output sampled data & status
    logic [7:0]      out_data;
    bit              irq_detected;
    time             sample_time;

    // Decoded Seven-Segment representation
    string           decoded_7seg_char;
    int              decoded_digit;

    constraint c_default {
        hold_cycles inside {[1:20]};
    }

    function new(string name = "gpio_seq_item");
        super.new(name);
        hold_cycles       = 5;
        decoded_digit     = -1;
        decoded_7seg_char = "UNKNOWN";
    endfunction

    virtual function string convert2string();
        return $sformatf("GPIO Item: in=0x%02h, out=0x%02h (7-Seg: '%s', digit=%0d), irq=%0b",
                         in_data, out_data, decoded_7seg_char, decoded_digit, irq_detected);
    endfunction

    virtual function void do_copy(uvm_object rhs);
        gpio_seq_item rhs_;
        if (!$cast(rhs_, rhs)) begin
            `uvm_error("do_copy", "Cast failed")
            return;
        end
        super.do_copy(rhs);
        this.in_data           = rhs_.in_data;
        this.hold_cycles       = rhs_.hold_cycles;
        this.out_data          = rhs_.out_data;
        this.irq_detected      = rhs_.irq_detected;
        this.sample_time       = rhs_.sample_time;
        this.decoded_7seg_char = rhs_.decoded_7seg_char;
        this.decoded_digit     = rhs_.decoded_digit;
    endfunction

    virtual function bit do_compare(uvm_object rhs, uvm_comparer comparer);
        gpio_seq_item rhs_;
        if (!$cast(rhs_, rhs)) return 0;
        return (super.do_compare(rhs, comparer) &&
                (this.out_data == rhs_.out_data));
    endfunction

endclass : gpio_seq_item

`endif // GPIO_SEQ_ITEM_SV
