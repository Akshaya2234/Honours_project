// =============================================================================
// File    : uart_monitor.sv
// Project : RISC-V Smart Control SoC Verification
// Type    : UVM 1.2 Verification IP (VIP) Monitor
// =============================================================================

`ifndef UART_MONITOR_SV
`define UART_MONITOR_SV

class uart_monitor extends uvm_monitor;
    `uvm_component_utils(uart_monitor)

    virtual uart_if                         vif;
    uart_config                             cfg;
    uvm_analysis_port #(uart_seq_item)      tx_ap;
    uvm_analysis_port #(uart_seq_item)      rx_ap;

    function new(string name = "uart_monitor", uvm_component parent = null);
        super.new(name, parent);
        tx_ap = new("tx_ap", this);
        rx_ap = new("rx_ap", this);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual uart_if)::get(this, "", "uart_vif", vif)) begin
            `uvm_fatal("NOVIF", {"Virtual interface must be set for: ", get_full_name(), ".uart_vif"})
        end
        if (!uvm_config_db#(uart_config)::get(this, "", "cfg", cfg)) begin
            `uvm_info("NOCFG", "Using default uart_config in monitor", UVM_MEDIUM)
            cfg = uart_config::type_id::create("cfg");
        end
    endfunction

    virtual task run_phase(uvm_phase phase);
        @(posedge vif.rst_n);
        `uvm_info(get_type_name(), "Reset released. Starting UART Monitor threads.", UVM_MEDIUM)

        fork
            monitor_tx_channel();
            monitor_rx_channel();
            monitor_irq_line();
        join
    endtask

    // Monitors transmissions driven by SoC onto uart_tx
    virtual task monitor_tx_channel();
        real bit_ns;
        int  data_width;
        bit  expected_parity;
        bit  sampled_parity;

        forever begin
            uart_seq_item item = uart_seq_item::type_id::create("mon_tx_item");
            item.dir = UART_DIR_TX;
            bit_ns = cfg.get_bit_period_ns();

            case (cfg.data_bits)
                UART_DATA_5: data_width = 5;
                UART_DATA_6: data_width = 6;
                UART_DATA_7: data_width = 7;
                default:     data_width = 8;
            endcase

            // 1. Detect start bit falling edge
            @(negedge vif.uart_tx);
            item.start_time = $time;

            // Wait to center of start bit
            #( (bit_ns / 2.0) * 1ns );
            if (vif.uart_tx !== 1'b0) begin
                `uvm_warning(get_type_name(), "False start bit detected on uart_tx (glitch)")
                continue;
            end

            // 2. Sample data bits at bit centers
            for (int i = 0; i < data_width; i++) begin
                #(bit_ns * 1ns);
                item.data[i] = vif.uart_tx;
            end

            // 3. Sample Parity bit if enabled
            if (cfg.parity != UART_PARITY_NONE) begin
                logic [7:0] data_mask;
                data_mask = (8'h01 << data_width) - 8'h01;
                #(bit_ns * 1ns);
                sampled_parity = vif.uart_tx;
                case (cfg.parity)
                    UART_PARITY_ODD:  expected_parity = ~(^(item.data & data_mask));
                    UART_PARITY_EVEN: expected_parity =  (^(item.data & data_mask));
                    default:          expected_parity = sampled_parity;
                endcase
                if (sampled_parity !== expected_parity) begin
                    item.parity_error_detected = 1'b1;
                    `uvm_error(get_type_name(), $sformatf("Parity error on uart_tx! Sampled=%0b, Expected=%0b",
                                                          sampled_parity, expected_parity))
                end
            end

            // 4. Sample Stop bit (must be 1)
            #(bit_ns * 1ns);
            if (vif.uart_tx !== 1'b1) begin
                item.framing_error_detected = 1'b1;
                `uvm_error(get_type_name(), $sformatf("Framing error on uart_tx! Expected 1, got %0b", vif.uart_tx))
            end

            item.end_time = $time;
            item.baud_rate = cfg.baud_rate;
            `uvm_info(get_type_name(), $sformatf("Captured UART TX Byte: 0x%02h ('%c')",
                      item.data, (item.data >= 32 && item.data <= 126) ? item.data : 8'h2E), UVM_LOW)

            tx_ap.write(item);
        end
    endtask

    // Monitors serial stream on uart_rx
    virtual task monitor_rx_channel();
        real bit_ns;
        int  data_width;

        forever begin
            uart_seq_item item = uart_seq_item::type_id::create("mon_rx_item");
            item.dir = UART_DIR_RX;
            bit_ns = cfg.get_bit_period_ns();

            case (cfg.data_bits)
                UART_DATA_5: data_width = 5;
                UART_DATA_6: data_width = 6;
                UART_DATA_7: data_width = 7;
                default:     data_width = 8;
            endcase

            @(negedge vif.uart_rx);
            item.start_time = $time;

            #( (bit_ns / 2.0) * 1ns );
            if (vif.uart_rx !== 1'b0) continue;

            for (int i = 0; i < data_width; i++) begin
                #(bit_ns * 1ns);
                item.data[i] = vif.uart_rx;
            end

            #(bit_ns * 1ns); // Parity or Stop bit
            item.end_time = $time;
            rx_ap.write(item);
        end
    endtask

    // Monitors UART Interrupt line
    virtual task monitor_irq_line();
        forever begin
            @(vif.uart_irq);
            `uvm_info(get_type_name(), $sformatf("uart_irq transition detected: %0b at time %0t ps",
                                                 vif.uart_irq, $time), UVM_MEDIUM)
        end
    endtask

endclass : uart_monitor

`endif // UART_MONITOR_SV
