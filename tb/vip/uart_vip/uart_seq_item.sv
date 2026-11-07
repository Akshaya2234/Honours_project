// =============================================================================
// File    : uart_seq_item.sv
// Project : RISC-V Smart Control SoC Verification
// Type    : UVM 1.2 Verification IP (VIP) Sequence Item
// =============================================================================

`ifndef UART_SEQ_ITEM_SV
`define UART_SEQ_ITEM_SV

typedef enum bit [2:0] {
    UART_PARITY_NONE  = 3'b000,
    UART_PARITY_ODD   = 3'b001,
    UART_PARITY_EVEN  = 3'b010,
    UART_PARITY_MARK  = 3'b011,
    UART_PARITY_SPACE = 3'b100
} uart_parity_e;

typedef enum bit {
    UART_STOP_1 = 1'b0,
    UART_STOP_2 = 1'b1
} uart_stop_bits_e;

typedef enum bit [1:0] {
    UART_DATA_5 = 2'b00,
    UART_DATA_6 = 2'b01,
    UART_DATA_7 = 2'b10,
    UART_DATA_8 = 2'b11
} uart_data_bits_e;

typedef enum bit {
    UART_DIR_TX = 1'b0, // SoC -> TB
    UART_DIR_RX = 1'b1  // TB -> SoC
} uart_direction_e;

class uart_seq_item extends uvm_sequence_item;
    `uvm_object_utils(uart_seq_item)

    // Payload & Configuration
    rand logic [7:0]         data;
    rand int                 baud_rate;
    rand uart_parity_e       parity_type;
    rand uart_stop_bits_e    stop_bits;
    rand uart_data_bits_e    data_bits;

    // Error Injection
    rand bit                 inject_parity_error;
    rand bit                 inject_framing_error;

    // Monitor Output / Status
    uart_direction_e         dir;
    bit                      parity_error_detected;
    bit                      framing_error_detected;
    time                     start_time;
    time                     end_time;

    // Default constraints
    constraint c_default {
        baud_rate            == 115200;
        parity_type          == UART_PARITY_NONE;
        stop_bits            == UART_STOP_1;
        data_bits            == UART_DATA_8;
        inject_parity_error  == 1'b0;
        inject_framing_error == 1'b0;
    }

    function new(string name = "uart_seq_item");
        super.new(name);
        baud_rate            = 115200;
        parity_type          = UART_PARITY_NONE;
        stop_bits            = UART_STOP_1;
        data_bits            = UART_DATA_8;
        inject_parity_error  = 1'b0;
        inject_framing_error = 1'b0;
    endfunction

    virtual function string convert2string();
        return $sformatf("dir=%s data=0x%02h ('%c') baud=%0d parity=%s stop=%s data_bits=%s err(P=%0b, F=%0b)",
                         dir.name(), data, (data >= 32 && data <= 126) ? data : 8'h2E,
                         baud_rate, parity_type.name(), stop_bits.name(), data_bits.name(),
                         parity_error_detected, framing_error_detected);
    endfunction

    virtual function void do_copy(uvm_object rhs);
        uart_seq_item rhs_;
        if (!$cast(rhs_, rhs)) begin
            `uvm_error("do_copy", "Cast failed")
            return;
        end
        super.do_copy(rhs);
        this.data                   = rhs_.data;
        this.baud_rate              = rhs_.baud_rate;
        this.parity_type            = rhs_.parity_type;
        this.stop_bits              = rhs_.stop_bits;
        this.data_bits              = rhs_.data_bits;
        this.inject_parity_error    = rhs_.inject_parity_error;
        this.inject_framing_error   = rhs_.inject_framing_error;
        this.dir                    = rhs_.dir;
        this.parity_error_detected  = rhs_.parity_error_detected;
        this.framing_error_detected = rhs_.framing_error_detected;
        this.start_time             = rhs_.start_time;
        this.end_time               = rhs_.end_time;
    endfunction

    virtual function bit do_compare(uvm_object rhs, uvm_comparer comparer);
        uart_seq_item rhs_;
        if (!$cast(rhs_, rhs)) return 0;
        return (super.do_compare(rhs, comparer) &&
                (this.data == rhs_.data) &&
                (this.parity_error_detected == rhs_.parity_error_detected) &&
                (this.framing_error_detected == rhs_.framing_error_detected));
    endfunction

endclass : uart_seq_item

`endif // UART_SEQ_ITEM_SV
