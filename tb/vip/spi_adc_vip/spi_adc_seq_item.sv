// =============================================================================
// File    : spi_adc_seq_item.sv
// Project : RISC-V Smart Control SoC Verification
// Type    : UVM 1.2 Verification IP (VIP) Sequence Item for SPI ADC
// =============================================================================

`ifndef SPI_ADC_SEQ_ITEM_SV
`define SPI_ADC_SEQ_ITEM_SV

typedef enum bit [2:0] {
    SPI_PATTERN_SINE     = 3'd0,
    SPI_PATTERN_SQUARE   = 3'd1,
    SPI_PATTERN_TRIANGLE = 3'd2,
    SPI_PATTERN_DC       = 3'd3,
    SPI_PATTERN_CUSTOM   = 3'd4
} spi_pattern_e;

class spi_adc_seq_item extends uvm_sequence_item;
    `uvm_object_utils(spi_adc_seq_item)

    rand logic signed [15:0] sample_data; // 16-bit Q1.15 ADC sample
    logic [15:0]             mosi_data;   // Captured MOSI command/data
    time                     start_time;
    time                     end_time;
    int                      sample_index;

    function new(string name = "spi_adc_seq_item");
        super.new(name);
        sample_data  = 16'sd0;
        sample_index = 0;
    endfunction

    virtual function string convert2string();
        return $sformatf("SPI ADC Sample #%0d: Data=0x%04h (%0d) at %0t ps",
                         sample_index, sample_data, sample_data, start_time);
    endfunction

    virtual function void do_copy(uvm_object rhs);
        spi_adc_seq_item rhs_;
        if (!$cast(rhs_, rhs)) begin
            `uvm_error("do_copy", "Cast failed")
            return;
        end
        super.do_copy(rhs);
        this.sample_data  = rhs_.sample_data;
        this.mosi_data    = rhs_.mosi_data;
        this.start_time   = rhs_.start_time;
        this.end_time     = rhs_.end_time;
        this.sample_index = rhs_.sample_index;
    endfunction

    virtual function bit do_compare(uvm_object rhs, uvm_comparer comparer);
        spi_adc_seq_item rhs_;
        if (!$cast(rhs_, rhs)) return 0;
        return (super.do_compare(rhs, comparer) &&
                (this.sample_data == rhs_.sample_data));
    endfunction

endclass : spi_adc_seq_item

`endif // SPI_ADC_SEQ_ITEM_SV
