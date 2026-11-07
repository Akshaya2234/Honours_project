// =============================================================================
// File    : pwm_seq_item.sv
// Project : RISC-V Smart Control SoC Verification
// Type    : UVM 1.2 Verification IP (VIP) Sequence Item / Transaction
// =============================================================================

`ifndef PWM_SEQ_ITEM_SV
`define PWM_SEQ_ITEM_SV

class pwm_seq_item extends uvm_sequence_item;
    `uvm_object_utils(pwm_seq_item)

    // Measured Timing Characteristics
    int      high_cycles;
    int      low_cycles;
    int      period_cycles;

    time     high_duration;
    time     low_duration;
    time     period_duration;

    real     duty_cycle_pct; // Duty Cycle % (0.0 to 100.0)
    real     frequency_hz;   // Calculated frequency

    time     pulse_start_time;

    function new(string name = "pwm_seq_item");
        super.new(name);
    endfunction

    virtual function string convert2string();
        return $sformatf("PWM Pulse: Period=%0d cycles (%0t), High=%0d cycles (%0t), Low=%0d cycles (%0t), Duty=%.2f%%, Freq=%.2f kHz",
                         period_cycles, period_duration,
                         high_cycles, high_duration,
                         low_cycles, low_duration,
                         duty_cycle_pct, (frequency_hz / 1000.0));
    endfunction

    virtual function void do_copy(uvm_object rhs);
        pwm_seq_item rhs_;
        if (!$cast(rhs_, rhs)) begin
            `uvm_error("do_copy", "Cast failed")
            return;
        end
        super.do_copy(rhs);
        this.high_cycles      = rhs_.high_cycles;
        this.low_cycles       = rhs_.low_cycles;
        this.period_cycles    = rhs_.period_cycles;
        this.high_duration    = rhs_.high_duration;
        this.low_duration     = rhs_.low_duration;
        this.period_duration  = rhs_.period_duration;
        this.duty_cycle_pct   = rhs_.duty_cycle_pct;
        this.frequency_hz     = rhs_.frequency_hz;
        this.pulse_start_time = rhs_.pulse_start_time;
    endfunction

    virtual function bit do_compare(uvm_object rhs, uvm_comparer comparer);
        pwm_seq_item rhs_;
        if (!$cast(rhs_, rhs)) return 0;
        return (super.do_compare(rhs, comparer) &&
                (this.period_cycles == rhs_.period_cycles) &&
                (this.high_cycles == rhs_.high_cycles));
    endfunction

endclass : pwm_seq_item

`endif // PWM_SEQ_ITEM_SV
