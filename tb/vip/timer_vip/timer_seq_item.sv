// =============================================================================
// File    : timer_seq_item.sv
// Project : RISC-V Smart Control SoC Verification
// Type    : UVM 1.2 Sequence Item for System Timer VIP
// =============================================================================

`ifndef TIMER_SEQ_ITEM_SV
`define TIMER_SEQ_ITEM_SV

class timer_seq_item extends uvm_sequence_item;

    time             timestamp;
    int              tick_period_cycles;
    bit              irq_asserted;

    `uvm_object_utils_begin(timer_seq_item)
        `uvm_field_int(timestamp,          UVM_ALL_ON)
        `uvm_field_int(tick_period_cycles, UVM_ALL_ON)
        `uvm_field_int(irq_asserted,       UVM_ALL_ON)
    `uvm_object_utils_end

    function new(string name = "timer_seq_item");
        super.new(name);
    endfunction

    virtual function string convert2string();
        return $sformatf("Timer Item @ %0t ps: Period=%0d cycles, IRQ=%0b",
                         timestamp, tick_period_cycles, irq_asserted);
    endfunction

endclass : timer_seq_item

`endif // TIMER_SEQ_ITEM_SV
