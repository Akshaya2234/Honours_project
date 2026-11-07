// =============================================================================
// File    : spi_adc_driver.sv
// Project : RISC-V Smart Control SoC Verification
// Type    : UVM 1.2 Verification IP (VIP) Reactive Slave Driver for SPI ADC
// =============================================================================

`ifndef SPI_ADC_DRIVER_SV
`define SPI_ADC_DRIVER_SV

class spi_adc_driver extends uvm_driver #(spi_adc_seq_item);
    `uvm_component_utils(spi_adc_driver)

    virtual spi_adc_if  vif;
    spi_adc_config      cfg;
    int                 sample_counter = 0;

    // 16-point discrete sine lookup table
    shortint signed sine_lut [0:15];

    function new(string name = "spi_adc_driver", uvm_component parent = null);
        super.new(name, parent);
        sine_lut[0]  = 16'sd0;
        sine_lut[1]  = 16'sd6123;
        sine_lut[2]  = 16'sd11314;
        sine_lut[3]  = 16'sd14782;
        sine_lut[4]  = 16'sd16000;
        sine_lut[5]  = 16'sd14782;
        sine_lut[6]  = 16'sd11314;
        sine_lut[7]  = 16'sd6123;
        sine_lut[8]  = 16'sd0;
        sine_lut[9]  = -16'sd6123;
        sine_lut[10] = -16'sd11314;
        sine_lut[11] = -16'sd14782;
        sine_lut[12] = -16'sd16000;
        sine_lut[13] = -16'sd14782;
        sine_lut[14] = -16'sd11314;
        sine_lut[15] = -16'sd6123;
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual spi_adc_if)::get(this, "", "spi_adc_vif", vif)) begin
            `uvm_fatal("NOVIF", {"Virtual interface must be set for: ", get_full_name(), ".spi_adc_vif"})
        end
        if (!uvm_config_db#(spi_adc_config)::get(this, "", "cfg", cfg)) begin
            `uvm_info("NOCFG", "Using default spi_adc_config in driver", UVM_MEDIUM)
            cfg = spi_adc_config::type_id::create("cfg");
        end
    endfunction

    virtual function shortint signed generate_sample(int idx, spi_pattern_e pat);
        case (pat)
            SPI_PATTERN_SINE:     return sine_lut[idx % 16];
            SPI_PATTERN_SQUARE:   return ((idx % 16) < 8) ? cfg.sample_amplitude : -cfg.sample_amplitude;
            SPI_PATTERN_TRIANGLE: return -cfg.sample_amplitude + ((idx % 16) * 16'sd2000);
            SPI_PATTERN_DC:       return 16'sd8000;
            default:              return sine_lut[idx % 16];
        endcase
    endfunction

    virtual task run_phase(uvm_phase phase);
        logic [15:0] shift_reg;
        int          bit_idx;

        vif.adc_spi_miso <= 1'b0;

        @(posedge vif.rst_n);
        `uvm_info(get_type_name(), "Reset released. SPI ADC Reactive Slave active.", UVM_MEDIUM)

        forever begin
            // 1. Wait for Master to assert Chip Select (active low)
            @(negedge vif.adc_spi_cs_n);

            // 2. Generate or retrieve sample
            shift_reg = generate_sample(sample_counter, cfg.pattern);
            sample_counter++;

            // 3. Drive initial MSB onto MISO
            vif.adc_spi_miso <= shift_reg[15];

            // 4. Shift subsequent bits out on falling SCK edges
            for (bit_idx = 14; bit_idx >= 0; bit_idx--) begin
                @(negedge vif.adc_spi_sck);
                if (vif.adc_spi_cs_n !== 1'b0) break; // Early abort if master deasserts CS
                vif.adc_spi_miso <= shift_reg[bit_idx];
            end

            // 5. Wait for CS to deassert (return high)
            @(posedge vif.adc_spi_cs_n);
            vif.adc_spi_miso <= 1'b0;
        end
    endtask

endclass : spi_adc_driver

`endif // SPI_ADC_DRIVER_SV
