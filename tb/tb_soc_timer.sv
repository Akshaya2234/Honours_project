// =============================================================================
// File    : tb_soc_timer.sv
// Project : RISC-V Smart Control SoC Verification
// Type    : UVM 1.2 Top-Level Testbench for Single-IP Timer Integration
// Scope   : Real SoC DUT connected directly to Timer VIP Interface
// =============================================================================

`timescale 1ns/1ps

module tb_soc_timer;

    import el2_pkg::*;
    import uvm_pkg::*;
    `include "uvm_macros.svh"

    import timer_pkg::*;
    import timer_soc_pkg::*;

    // -------------------------------------------------------------------------
    // Parameters
    // -------------------------------------------------------------------------
    localparam DATA_WIDTH       = 32;
    localparam ADDR_WIDTH       = 32;
    localparam STRB_WIDTH       = DATA_WIDTH / 8;
    localparam ID_WIDTH         = 8;

    localparam [ADDR_WIDTH-1:0] IMEM_BASE_ADDR  = 32'h1000_0000;
    localparam [ADDR_WIDTH-1:0] DMEM_BASE_ADDR  = 32'h1002_0000;
    localparam [ADDR_WIDTH-1:0] TIMER_BASE_ADDR = 32'h4000_8000;

    localparam CLK_SYS_PERIOD_NS = 10;  // 100 MHz System Clock
    localparam CLK_VGA_PERIOD_NS = 40;  // 25 MHz Pixel Clock

    // -------------------------------------------------------------------------
    // Clocks and Reset
    // -------------------------------------------------------------------------
    logic clk;
    logic rst_n;
    logic clk_vga;

    initial begin
        clk = 0;
        forever #(CLK_SYS_PERIOD_NS / 2) clk = ~clk;
    end

    initial begin
        clk_vga = 0;
        forever #(CLK_VGA_PERIOD_NS / 2) clk_vga = ~clk_vga;
    end

    // -------------------------------------------------------------------------
    // Instantiate Single Physical Timer VIP Interface
    // -------------------------------------------------------------------------
    timer_if u_timer_vip_if (
        .clk   (clk),
        .rst_n (rst_n)
    );

    // -------------------------------------------------------------------------
    // Explicit Probe Signals for Waveform Analysis:
    // DUT pins vs Interface wires vs UVM VIP Monitor vs Internal Registers
    // -------------------------------------------------------------------------
    wire        dut_sample_tick             = dut.sample_tick;
    wire        dut_irq_timer               = dut.irq_timer;

    wire        interface_sample_tick       = u_timer_vip_if.sample_tick;
    wire        interface_irq_timer         = u_timer_vip_if.irq_timer;

    wire        uvm_vip_monitor_sample_tick = u_timer_vip_if.sample_tick;
    wire        uvm_vip_monitor_irq_timer   = u_timer_vip_if.irq_timer;

    wire        internal_timer_en           = dut.u_timer.timer_en;
    wire [31:0] internal_timer_reload       = dut.u_timer.timer_reload;
    wire [31:0] internal_timer_count        = dut.u_timer.timer_count;
    wire        internal_timer_tick         = dut.u_timer.timer_tick;

    // Unused peripheral lines
    wire         uart_tx;
    wire         uart_irq;
    wire [7:0]   gpio_out;
    wire         adc_spi_sck;
    wire         adc_spi_mosi;
    wire         adc_spi_cs_n;
    wire         vga_hsync;
    wire         vga_vsync;
    wire [3:0]   vga_red, vga_green, vga_blue;
    wire         wdt_reset_out;
    wire         pwm_out;

    wire [31:0]  trace_rv_i_insn_ip;
    wire [31:0]  trace_rv_i_address_ip;
    wire         trace_rv_i_valid_ip;
    wire         trace_rv_i_exception_ip;
    wire [4:0]   trace_rv_i_ecause_ip;
    wire         trace_rv_i_interrupt_ip;
    wire [31:0]  trace_rv_i_tval_ip;
    wire         o_cpu_halt_status;
    wire         o_cpu_halt_ack;
    wire         o_debug_mode_status;

    // -------------------------------------------------------------------------
    // Instantiate Actual Real SoC DUT
    // -------------------------------------------------------------------------
    soc_top #(
        .DATA_WIDTH          (DATA_WIDTH),
        .ADDR_WIDTH          (ADDR_WIDTH),
        .ID_WIDTH            (ID_WIDTH),
        .TIMER_BASE_ADDR     (TIMER_BASE_ADDR),
        .IMEM_BASE_ADDR      (IMEM_BASE_ADDR),
        .DMEM_BASE_ADDR      (DMEM_BASE_ADDR)
    ) dut (
        .clk                 (clk),
        .rst_n               (rst_n),
        .clk_vga             (clk_vga),

        .rst_vec             (31'h0800_0000), // IMEM start 0x1000_0000 >> 1
        .nmi_int             (1'b0),
        .nmi_vec             (31'h0),
        .jtag_id             (31'h0),

        .uart_rx             (1'b1),
        .uart_tx             (uart_tx),
        .uart_irq            (uart_irq),

        .gpio_in             (8'h00),
        .gpio_out            (gpio_out),

        .adc_spi_sck         (adc_spi_sck),
        .adc_spi_mosi        (adc_spi_mosi),
        .adc_spi_miso        (1'b0),
        .adc_spi_cs_n        (adc_spi_cs_n),

        .vga_hsync           (vga_hsync),
        .vga_vsync           (vga_vsync),
        .vga_red             (vga_red),
        .vga_green           (vga_green),
        .vga_blue            (vga_blue),

        .wdt_reset_out       (wdt_reset_out),
        .pwm_out             (pwm_out),

        .ext_irq             ('0),
        .timer_int           (1'b0),

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

    // Bind Timer Interface directly to Real SoC Timer Signals
    assign u_timer_vip_if.sample_tick = dut.sample_tick;
    assign u_timer_vip_if.irq_timer   = dut.irq_timer;

    // -------------------------------------------------------------------------
    // UVM Config DB Setup and Test Launch (Single Timer Interface)
    // -------------------------------------------------------------------------
    initial begin
        // Configure Single Timer virtual interface for UVM
        uvm_config_db#(virtual timer_if)::set(null, "*", "timer_vif", u_timer_vip_if);

        // Run Single-IP Timer UVM Test
        run_test("timer_soc_test");
    end

    // -------------------------------------------------------------------------
    // Verdi FSDB Waveform Dumping
    // -------------------------------------------------------------------------
    initial begin
        $fsdbDumpfile("dump_timer.fsdb");
        $fsdbDumpvars(0, tb_soc_timer, "+all");
        $fsdbDumpSVA;
        $fsdbDumpMDA;
    end

    // -------------------------------------------------------------------------
    // Firmware Preload & System Reset Control
    // -------------------------------------------------------------------------
    task automatic write_imem_word(input int word_addr, input logic [31:0] data);
        dut.u_imem.mem_0[word_addr] = data[7:0];
        dut.u_imem.mem_1[word_addr] = data[15:8];
        dut.u_imem.mem_2[word_addr] = data[23:16];
        dut.u_imem.mem_3[word_addr] = data[31:24];
    endtask

    task automatic preload_timer_firmware();
        // Clear IMEM with NOPs
        for (int i = 0; i < 16384; i++) begin
            dut.u_imem.mem_0[i] = 8'h13;
            dut.u_imem.mem_1[i] = 8'h00;
            dut.u_imem.mem_2[i] = 8'h00;
            dut.u_imem.mem_3[i] = 8'h00;
        end

        // 1. Configure MRAC CSR (0x7c0) -> 0xAAAAAAA6
        write_imem_word(0, 32'haaaab0b7); // lui x1, 0xaaaab
        write_imem_word(1, 32'haa608093); // addi x1, x1, -1370 -> x1 = 0xaaaaaaa6
        write_imem_word(2, 32'h7c009073); // csrw 0x7c0, x1

        // 2. Base address for Timer (0x4000_8000) in x1
        write_imem_word(3, 32'h400080b7); // lui x1, 0x40008

        // 3. Configure Reload = 50 cycles at 0x4000_8004
        write_imem_word(4, 32'h03200113); // addi x2, x0, 50
        write_imem_word(5, 32'h0020a223); // sw x2, 4(x1)

        // 4. Configure Enable = 1 at 0x4000_8000
        write_imem_word(6, 32'h00100193); // addi x3, x0, 1
        write_imem_word(7, 32'h0030a023); // sw x3, 0(x1)

        // 5. Timer IRQ Clear Loop:
        // poll_timer:
        // lw x4, 12(x1)        -> Read TIMER_STATUS at 0x4000_800C
        write_imem_word(8, 32'h00c0a203);
        // andi x5, x4, 1       -> Check TICK bit
        write_imem_word(9, 32'h00127293);
        // sw x5, 12(x1)        -> W1C TICK bit in TIMER_STATUS
        write_imem_word(10, 32'h0050a623);
        // j -12                -> Loop back to poll_timer
        write_imem_word(11, 32'hff5ff06f);

        $display("\n[INIT] Preloaded Timer Pacing Firmware into On-Chip IMEM (0x1000_0000)");
    endtask

    initial begin
        rst_n = 1'b0;
        preload_timer_firmware();
        #100ns;
        rst_n = 1'b1;
        $display("[INIT] System Reset Released. VeeR EL2 core configuring and starting Timer.\n");
    end

    // Safety watchdog timer
    initial begin
        #50_000_000;
        $error("\n[WATCHDOG TIMEOUT] Simulation exceeded 50ms time limit!");
        $finish(2);
    end

endmodule : tb_soc_timer
