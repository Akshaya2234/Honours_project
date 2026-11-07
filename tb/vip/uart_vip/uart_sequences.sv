// =============================================================================
// File    : uart_sequences.sv
// Project : RISC-V Smart Control SoC Verification
// Type    : UVM 1.2 Verification IP (VIP) Sequences
// =============================================================================

`ifndef UART_SEQUENCES_SV
`define UART_SEQUENCES_SV

class uart_base_seq extends uvm_sequence #(uart_seq_item);
    `uvm_object_utils(uart_base_seq)

    function new(string name = "uart_base_seq");
        super.new(name);
    endfunction

    virtual task body();
        `uvm_info(get_type_name(), "Executing uart_base_seq", UVM_HIGH)
    endtask
endclass : uart_base_seq

// Transmits a single byte
class uart_tx_byte_seq extends uart_base_seq;
    `uvm_object_utils(uart_tx_byte_seq)

    rand logic [7:0] byte_to_send;

    function new(string name = "uart_tx_byte_seq");
        super.new(name);
    endfunction

    virtual task body();
        req = uart_seq_item::type_id::create("req");
        start_item(req);
        if (!req.randomize() with { data == byte_to_send; }) begin
            `uvm_error(get_type_name(), "Randomization failed")
        end
        finish_item(req);
    endtask
endclass : uart_tx_byte_seq

// Transmits an ASCII string sequence
class uart_send_string_seq extends uart_base_seq;
    `uvm_object_utils(uart_send_string_seq)

    string message = "TEST";

    function new(string name = "uart_send_string_seq");
        super.new(name);
    endfunction

    virtual task body();
        `uvm_info(get_type_name(), $sformatf("Transmitting string '%s' (%0d chars)",
                  message, message.len()), UVM_LOW)
        for (int i = 0; i < message.len(); i++) begin
            byte char_val = message[i];
            req = uart_seq_item::type_id::create($sformatf("req_%0d", i));
            start_item(req);
            if (!req.randomize() with { data == char_val; }) begin
                `uvm_error(get_type_name(), "Randomization failed")
            end
            finish_item(req);
        end
    endtask
endclass : uart_send_string_seq

`endif // UART_SEQUENCES_SV
