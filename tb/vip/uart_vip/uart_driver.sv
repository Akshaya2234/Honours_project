// =============================================================================
// File    : uart_driver.sv
// Project : RISC-V Smart Control SoC Verification
// Type    : UVM 1.2 Verification IP (VIP) Driver
// =============================================================================

`ifndef UART_DRIVER_SV
`define UART_DRIVER_SV

class uart_driver extends uvm_driver #(uart_seq_item);
    `uvm_component_utils(uart_driver)

    virtual uart_if vif;
    uart_config     cfg;

    function new(string name = "uart_driver", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual uart_if)::get(this, "", "uart_vif", vif)) begin
            `uvm_fatal("NOVIF", {"Virtual interface must be set for: ", get_full_name(), ".uart_vif"})
        end
        if (!uvm_config_db#(uart_config)::get(this, "", "cfg", cfg)) begin
            `uvm_info("NOCFG", "Using default uart_config in driver", UVM_MEDIUM)
            cfg = uart_config::type_id::create("cfg");
        end
    endfunction

    virtual task run_phase(uvm_phase phase);
        // Default line idle state is HIGH
        vif.uart_rx <= 1'b1;

        // Wait for system reset to deassert
        @(posedge vif.rst_n);
        `uvm_info(get_type_name(), "Reset released. UART Driver initialized.", UVM_MEDIUM)

        forever begin
            seq_item_port.get_next_item(req);
            drive_item(req);
            seq_item_port.item_done();
        end
    endtask

    virtual task drive_item(uart_seq_item item);
        real bit_ns;
        int  data_width;
        bit  parity_bit;
        bit  stop_level;

        bit_ns = (item.baud_rate > 0) ? (1.0e9 / real'(item.baud_rate)) : cfg.get_bit_period_ns();

        case (item.data_bits)
            UART_DATA_5: data_width = 5;
            UART_DATA_6: data_width = 6;
            UART_DATA_7: data_width = 7;
            default:     data_width = 8;
        endcase

        item.start_time = $time;
        `uvm_info(get_type_name(), $sformatf("Driving item onto uart_rx: %s", item.convert2string()), UVM_HIGH)

        // 1. Start Bit (LOW)
        vif.uart_rx <= 1'b0;
        #(bit_ns * 1ns);

        // 2. Data Bits (LSB first)
        for (int i = 0; i < data_width; i++) begin
            vif.uart_rx <= item.data[i];
            #(bit_ns * 1ns);
        end

        // 3. Optional Parity Bit
        if (item.parity_type != UART_PARITY_NONE) begin
            logic [7:0] data_mask;
            data_mask = (8'h01 << data_width) - 8'h01;
            case (item.parity_type)
                UART_PARITY_ODD:   parity_bit = ~(^(item.data & data_mask));
                UART_PARITY_EVEN:  parity_bit =  (^(item.data & data_mask));
                UART_PARITY_MARK:  parity_bit = 1'b1;
                UART_PARITY_SPACE: parity_bit = 1'b0;
                default:           parity_bit = 1'b0;
            endcase
            if (item.inject_parity_error) begin
                parity_bit = ~parity_bit; // Inject corrupted parity
                `uvm_info(get_type_name(), "Injected parity bit error", UVM_HIGH)
            end
            vif.uart_rx <= parity_bit;
            #(bit_ns * 1ns);
        end

        // 4. Stop Bit(s) (normally HIGH)
        stop_level = item.inject_framing_error ? 1'b0 : 1'b1;
        vif.uart_rx <= stop_level;
        #(bit_ns * 1ns);

        if (item.stop_bits == UART_STOP_2) begin
            vif.uart_rx <= 1'b1;
            #(bit_ns * 1ns);
        end

        item.end_time = $time;
        // Return to idle HIGH
        vif.uart_rx <= 1'b1;
    endtask

endclass : uart_driver

`endif // UART_DRIVER_SV
