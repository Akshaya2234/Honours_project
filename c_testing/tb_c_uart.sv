// =============================================================================
// Testbench : tb_c_uart.sv
// Top Module: soc_top
// Tool      : Synopsys VCS / Verdi (SystemVerilog)
// Project   : Honours RISC-V Real-Time Signal Processing & VGA Oscilloscope SoC
//
// Description:
//   Self-checking verification testbench for the fully integrated SoC top level.
//   Verifies end-to-end integration of:
//     1. Western Digital VeeR EL2 RISC-V Processor Core (RV32IMC)
//     2. AXI4 64-bit to 32-bit Width Adapters (LSU, IFU, SB)
//     3. 5-Master x 20-Slave AXI4 Interconnect Crossbar
//     4. On-Chip 64 KB AXI4 Instruction Memory (IMEM at 0x1000_0000)
//     5. On-Chip 64 KB AXI4 Data Memory (DMEM at 0x1002_0000)
//     6. AXI UART IP Core (0x4000_6000) - Serial Tx/Rx & IRQ
//     7. Acquisition Timer (0x4000_8000) - Periodic sample_tick
//     8. GPIO Controller (0x4000_A000) - LED outputs & switch inputs
//     9. SPI Master Controller (0x4000_C000) - ADC acquisition interface
//    10. Watchdog Safety Monitor (0x4000_E000) - Trip status & NMI
//    11. Autonomous Streaming DMA Controller (0x4001_0000)
//    12. 16-Tap Q1.15 Fixed-Point FIR Filter (0x4001_2000)
//    13. Real-Time Oscilloscope VGA Controller with Software UI (0x4001_4000)
//    14. True Dual-Port Ping-Pong Double Sample Buffer (0x4001_6000)
//    15. PIC Interrupts & Watchdog NMI prewarn
// =============================================================================

`timescale 1ns/1ps

module tb_c_uart;
    import el2_pkg::*;

    // -------------------------------------------------------------------------
    // Parameters
    // -------------------------------------------------------------------------
    localparam DATA_WIDTH       = 32;
    localparam ADDR_WIDTH       = 32;
    localparam STRB_WIDTH       = DATA_WIDTH / 8;
    localparam ID_WIDTH         = 8;

    // Memory Map Base Addresses
    localparam [ADDR_WIDTH-1:0] IMEM_BASE_ADDR  = 32'h1000_0000;
    localparam [ADDR_WIDTH-1:0] DMEM_BASE_ADDR  = 32'h1002_0000;
    localparam [ADDR_WIDTH-1:0] UART_BASE_ADDR  = 32'h4000_6000;
    localparam [ADDR_WIDTH-1:0] TIMER_BASE_ADDR = 32'h4000_8000;
    localparam [ADDR_WIDTH-1:0] GPIO_BASE_ADDR  = 32'h4000_A000;
    localparam [ADDR_WIDTH-1:0] SPI_BASE_ADDR   = 32'h4000_C000;
    localparam [ADDR_WIDTH-1:0] WDT_BASE_ADDR   = 32'h4000_E000;
    localparam [ADDR_WIDTH-1:0] DMA_BASE_ADDR   = 32'h4001_0000;
    localparam [ADDR_WIDTH-1:0] FIR_BASE_ADDR   = 32'h4001_2000;
    localparam [ADDR_WIDTH-1:0] VGA_BASE_ADDR   = 32'h4001_4000;
    localparam [ADDR_WIDTH-1:0] SBUF_BASE_ADDR  = 32'h4001_6000;

    // Clock Periods
    localparam CLK_SYS_PERIOD_NS = 10;  // 100 MHz System Clock
    localparam CLK_VGA_PERIOD_NS = 40;  // 25 MHz Pixel Clock
    localparam UART_BAUD_DIV     = 868; // 115200 baud at 100 MHz
    localparam BIT_PERIOD_NS     = CLK_SYS_PERIOD_NS * UART_BAUD_DIV;

    // -------------------------------------------------------------------------
    // DUT Signals
    // -------------------------------------------------------------------------
    logic                    clk;
    logic                    rst_n;
    logic                    clk_vga;

    logic [31:1]             rst_vec;
    logic                    nmi_int;
    logic [31:1]             nmi_vec;
    logic [31:1]             jtag_id;

    logic                    uart_rx;
    wire                     uart_tx;
    wire                     uart_irq;

    logic [7:0]              gpio_in;
    wire [7:0]               gpio_out;

    wire                     adc_spi_sck;
    wire                     adc_spi_mosi;
    wire                     adc_spi_miso;
    wire                     adc_spi_cs_n;

    wire                     vga_hsync;
    wire                     vga_vsync;
    wire [3:0]               vga_red;
    wire [3:0]               vga_green;
    wire [3:0]               vga_blue;

    wire                     wdt_reset_out;
    wire                     pwm_out;

    logic [23:0]             ext_irq;
    logic                    timer_int;

    wire [31:0]              trace_rv_i_insn_ip;
    wire [31:0]              trace_rv_i_address_ip;
    wire                     trace_rv_i_valid_ip;
    wire                     trace_rv_i_exception_ip;
    wire [4:0]               trace_rv_i_ecause_ip;
    wire                     trace_rv_i_interrupt_ip;
    wire [31:0]              trace_rv_i_tval_ip;

    wire                     o_cpu_halt_status;
    wire                     o_cpu_halt_ack;
    wire                     o_debug_mode_status;

    // -------------------------------------------------------------------------
    // Test Statistics
    // -------------------------------------------------------------------------
    int test_pass_count  = 0;
    int test_fail_count  = 0;
    int total_assertions = 0;

    // -------------------------------------------------------------------------
    // DUT Instantiation
    // -------------------------------------------------------------------------
    soc_top #(
        .DATA_WIDTH          (DATA_WIDTH),
        .ADDR_WIDTH          (ADDR_WIDTH),
        .ID_WIDTH            (ID_WIDTH),
        .UART_BASE_ADDR      (UART_BASE_ADDR),
        .IMEM_BASE_ADDR      (IMEM_BASE_ADDR),
        .DMEM_BASE_ADDR      (DMEM_BASE_ADDR),
        .TIMER_BASE_ADDR     (TIMER_BASE_ADDR),
        .GPIO_BASE_ADDR      (GPIO_BASE_ADDR),
        .SPI_BASE_ADDR       (SPI_BASE_ADDR),
        .WDT_BASE_ADDR       (WDT_BASE_ADDR),
        .DMA_BASE_ADDR       (DMA_BASE_ADDR),
        .FIR_BASE_ADDR       (FIR_BASE_ADDR),
        .VGA_BASE_ADDR       (VGA_BASE_ADDR),
        .SBUF_BASE_ADDR      (SBUF_BASE_ADDR)
    ) dut (
        .clk                 (clk),
        .rst_n               (rst_n),
        .clk_vga             (clk_vga),

        .rst_vec             (rst_vec),
        .nmi_int             (nmi_int),
        .nmi_vec             (nmi_vec),
        .jtag_id             (jtag_id),

        .uart_rx             (uart_rx),
        .uart_tx             (uart_tx),
        .uart_irq            (uart_irq),

        .gpio_in             (gpio_in),
        .gpio_out            (gpio_out),

        .adc_spi_sck         (adc_spi_sck),
        .adc_spi_mosi        (adc_spi_mosi),
        .adc_spi_miso        (adc_spi_miso),
        .adc_spi_cs_n        (adc_spi_cs_n),

        .vga_hsync           (vga_hsync),
        .vga_vsync           (vga_vsync),
        .vga_red             (vga_red),
        .vga_green           (vga_green),
        .vga_blue            (vga_blue),

        .wdt_reset_out       (wdt_reset_out),
       .pwm_out             (pwm_out),
 
        .ext_irq             (ext_irq),
        .timer_int           (timer_int),

        .trace_rv_i_insn_ip  (trace_rv_i_insn_ip),
        .trace_rv_i_address_ip (trace_rv_i_address_ip),
        .trace_rv_i_valid_ip (trace_rv_i_valid_ip),
        .trace_rv_i_exception_ip (trace_rv_i_exception_ip),
        .trace_rv_i_ecause_ip(trace_rv_i_ecause_ip),
        .trace_rv_i_interrupt_ip(trace_rv_i_interrupt_ip),
        .trace_rv_i_tval_ip  (trace_rv_i_tval_ip),

        .o_cpu_halt_status   (o_cpu_halt_status),
        .o_cpu_halt_ack      (o_cpu_halt_ack),
        .o_debug_mode_status (o_debug_mode_status)
    );

    // -------------------------------------------------------------------------
    // Behavioral ADC Model Connected to Physical SPI Pins
    // -------------------------------------------------------------------------
    adc_model #(
        .DEFAULT_PATTERN     (0),          // Sine wave
        .SAMPLE_AMPLITUDE    (16'sd16000)
    ) u_adc_model (
        .adc_spi_sck         (adc_spi_sck),
        .adc_spi_miso        (adc_spi_miso),
        .adc_spi_mosi        (adc_spi_mosi),
        .adc_spi_cs_n        (adc_spi_cs_n)
    );

    // -------------------------------------------------------------------------
    // Verdi Waveform Dumping (FSDB)
    // -------------------------------------------------------------------------
    initial begin
        $fsdbDumpfile("dump.fsdb");
        $fsdbDumpvars(0, tb_c_uart, "+all");
        $fsdbDumpSVA;
        $fsdbDumpMDA;
    end

    // -------------------------------------------------------------------------
    // Clocks Generation
    // -------------------------------------------------------------------------
    initial begin
        clk = 0;
        forever #(CLK_SYS_PERIOD_NS / 2) clk = ~clk;
    end

    initial begin
        clk_vga = 0;
        forever #(CLK_VGA_PERIOD_NS / 2) clk_vga = ~clk_vga;
    end

    // -------------------------------------------------------------------------
    // Assertion Helper Task
    // -------------------------------------------------------------------------
    task automatic check(input string test_name, input logic condition, input string err_msg = "");
        total_assertions++;
        if (condition) begin
            $display("[PASS] %s", test_name);
            test_pass_count++;
        end else begin
            $error("[FAIL] %s - %s", test_name, err_msg);
            test_fail_count++;
        end
    endtask

    // -------------------------------------------------------------------------
    // UART Helper Tasks
    // -------------------------------------------------------------------------
    task automatic receive_uart_byte(output logic [7:0] rx_byte, input int timeout_ns = 500_000);
        int elapsed_ns = 0;
        rx_byte = 8'h00;

        while (uart_tx !== 1'b0 && elapsed_ns < timeout_ns) begin
            #10;
            elapsed_ns += 10;
        end

        if (elapsed_ns >= timeout_ns) begin
            $error("[TIMEOUT] Waiting for UART Tx start bit exceeded %0d ns", timeout_ns);
            return;
        end

        #(BIT_PERIOD_NS / 2);

        for (int i = 0; i < 8; i++) begin
            #BIT_PERIOD_NS;
            rx_byte[i] = uart_tx;
        end

        #BIT_PERIOD_NS;
        if (uart_tx !== 1'b1) begin
            $error("[UART FRAME ERROR] Stop bit not high on uart_tx! Observed: %b", uart_tx);
        end
    endtask

    task automatic transmit_uart_byte(input logic [7:0] tx_byte);
        int bit_cycles = UART_BAUD_DIV + 1;
        @(posedge clk);
        uart_rx <= 1'b0; // Start bit
        repeat (bit_cycles) @(posedge clk);

        for (int i = 0; i < 8; i++) begin
            uart_rx <= tx_byte[i];
            repeat (bit_cycles) @(posedge clk);
        end

        uart_rx <= 1'b1; // Stop bit
        repeat (bit_cycles) @(posedge clk);
    endtask

    // -------------------------------------------------------------------------
    // Trace & Instruction Retirement Monitor
    // -------------------------------------------------------------------------
    int retired_instructions = 0;
    always @(posedge clk) begin
        if (rst_n && trace_rv_i_valid_ip) begin
            retired_instructions++;
            $display("   [TRACE @ %0t ps] PC = 0x%08h | Instr = 0x%08h | Total Retired = %0d",
                     $time, trace_rv_i_address_ip, trace_rv_i_insn_ip, retired_instructions);
        end
        if (rst_n) begin
            if (dut.ifu_axi_arvalid && dut.ifu_axi_arready)
                $display("   [IFU AR HANDSHAKE] time=%0t ps | addr=0x%08h len=%0d", $time, dut.ifu_axi_araddr, dut.ifu_axi_arlen);
            if (dut.ifu_axi_rvalid && dut.ifu_axi_rready)
                $display("   [IFU R HANDSHAKE ] time=%0t ps | data=0x%016h last=%b resp=%b", $time, dut.ifu_axi_rdata, dut.ifu_axi_rlast, dut.ifu_axi_rresp);
            if (dut.lsu_axi_awvalid && dut.lsu_axi_awready)
                $display("   [LSU AW HANDSHAKE] time=%0t ps | addr=0x%08h size=%0d len=%0d", $time, dut.lsu_axi_awaddr, dut.lsu_axi_awsize, dut.lsu_axi_awlen);
            if (dut.lsu_axi_wvalid && dut.lsu_axi_wready)
                $display("   [LSU W HANDSHAKE ] time=%0t ps | data=0x%016h strb=0x%02h last=%b", $time, dut.lsu_axi_wdata, dut.lsu_axi_wstrb, dut.lsu_axi_wlast);
            if (dut.lsu_axi_bvalid && dut.lsu_axi_bready)
                $display("   [LSU B HANDSHAKE ] time=%0t ps | resp=%b", $time, dut.lsu_axi_bresp);
            if (dut.lsu_axi_arvalid && dut.lsu_axi_arready)
                $display("   [LSU AR HANDSHAKE] time=%0t ps | addr=0x%08h", $time, dut.lsu_axi_araddr);
            if (dut.lsu_axi_rvalid && dut.lsu_axi_rready)
                $display("   [LSU R HANDSHAKE ] time=%0t ps | data=0x%016h resp=%b", $time, dut.lsu_axi_rdata, dut.lsu_axi_rresp);
            if (dut.trace_rv_i_exception_ip)
                $display("   [CPU EXCEPTION] time=%0t ps | cause=%0d | tval=0x%08h", $time, dut.trace_rv_i_ecause_ip, dut.trace_rv_i_tval_ip);
        end
    end

    // -------------------------------------------------------------------------

    task automatic write_imem_word(input int word_addr, input logic [31:0] data);
        dut.u_imem.mem_0[word_addr] = data[7:0];
        dut.u_imem.mem_1[word_addr] = data[15:8];
        dut.u_imem.mem_2[word_addr] = data[23:16];
        dut.u_imem.mem_3[word_addr] = data[31:24];
    endtask

    initial begin
        logic [31:0] firmware_words [0:1023];
        logic [7:0] rx_byte;
        integer i;
        string uart_capture;
        string expected;

        uart_capture = "";
        expected = "\015\012RISC-V C UART TEST STARTED\015\012UART CONFIGURATION: 115200 BAUD, 8N1\015\012C PROGRAM EXECUTED SUCCESSFULLY\015\012";

        $display("\n===== RISC-V C UART TEST =====");

        rst_n = 1'b0;
        uart_rx = 1'b1;
        gpio_in = '0;
        ext_irq = '0;
        timer_int = 1'b0;
        nmi_int = 1'b0;
        nmi_vec = 31'h77000000;
        jtag_id = 31'h00000045;
        rst_vec = (IMEM_BASE_ADDR >> 1);

        // Preload IMEM with NOPs
        for (i = 0; i < 16384; i = i + 1)
            write_imem_word(i, 32'h0000_0013);

        for (i = 0; i < 1024; i = i + 1)
            firmware_words[i] = 32'h0000_0013;

        $readmemh("../c_testing/uart_test.hex", firmware_words);

        for (i = 0; i < 1024; i = i + 1)
            write_imem_word(i, firmware_words[i]);

        $display("[INFO] Loaded firmware from uart_test.hex into IMEM");

        repeat (10) @(posedge clk);
        rst_n = 1'b1;
        $display("[INFO] Reset released. C program running.");

        fork
            begin : uart_receiver
                forever begin
                    @(negedge uart_tx);
                    #(BIT_PERIOD_NS / 2);
                    for (integer b = 0; b < 8; b = b + 1) begin
                        #(BIT_PERIOD_NS);
                        rx_byte[b] = uart_tx;
                    end
                    #(BIT_PERIOD_NS);
                    if (uart_tx === 1'b1) begin
                        uart_capture = $sformatf("%s%c", uart_capture, rx_byte);
                        $write("%c", rx_byte);
                        if (uart_capture == expected) begin
                            $display("\n\n[INFO] UART bytes captured: %0d", uart_capture.len());
                            $display("[PASS] C firmware UART output matches expected text.");
                            $display("[PASS] C UART TEST SUCCESSFUL");
                            $display("[INFO] Retired instructions: %0d", retired_instructions);
                            $finish(0);
                        end
                    end
                end
            end

            begin : test_timeout
                #15_000_000;
                $display("\n\n[INFO] UART bytes captured: %0d", uart_capture.len());
                if (uart_capture == expected) begin
                    $display("[PASS] C firmware UART output matches expected text.");
                    $display("[PASS] C UART TEST SUCCESSFUL");
                end else begin
                    $display("[FAIL] UART output did not match expected text.");
                    $display("[CAPTURED] %s", uart_capture);
                    $error("C UART TEST FAILED");
                end
                $display("[INFO] Retired instructions: %0d", retired_instructions);
                $finish(1);
            end
        join
    end

    // Safety simulation watchdog timer
    initial begin
        #50_000_000; // 50ms maximum simulation limit
        $error("\n[WATCHDOG TIMEOUT] Simulation exceeded maximum allowed time limit (50ms)!");
        $finish(2);
    end

endmodule
