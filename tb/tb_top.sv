// =============================================================================
// File    : tb_top.sv
// Project : RISC-V Smart Control SoC Verification
// Type    : UVM 1.2 Top-Level Testbench for Single-IP UART Integration
// Scope   : Real SoC DUT connected directly to UART VIP Interface
// =============================================================================

`timescale 1ns/1ps

module tb_top;

    import el2_pkg::*;
    import uvm_pkg::*;
    `include "uvm_macros.svh"

    import uart_pkg::*;
    import uart_soc_pkg::*;

    // -------------------------------------------------------------------------
    // Parameters
    // -------------------------------------------------------------------------
    localparam DATA_WIDTH       = 32;
    localparam ADDR_WIDTH       = 32;
    localparam STRB_WIDTH       = DATA_WIDTH / 8;
    localparam ID_WIDTH         = 8;

    localparam [ADDR_WIDTH-1:0] IMEM_BASE_ADDR  = 32'h1000_0000;
    localparam [ADDR_WIDTH-1:0] DMEM_BASE_ADDR  = 32'h1002_0000;
    localparam [ADDR_WIDTH-1:0] UART_BASE_ADDR  = 32'h4000_6000;

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
    // Instantiate Single Physical UART VIP Interface
    // -------------------------------------------------------------------------
    uart_if u_uart_vip_if (
        .clk   (clk),
        .rst_n (rst_n)
    );

    // Explicit probe signals for Waveform: DUT vs Interface vs UVM VIP Monitor
    wire dut_uart_tx        = dut.uart_tx;
    wire interface_uart_tx  = u_uart_vip_if.uart_tx;
    wire uvm_vip_monitor_tx = u_uart_vip_if.uart_tx;

    // -------------------------------------------------------------------------
    // Unused peripheral lines
    // -------------------------------------------------------------------------
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
        .UART_BASE_ADDR      (UART_BASE_ADDR),
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

        // UART Interface Connected Directly to Real SoC UART Hardware
        .uart_rx             (u_uart_vip_if.uart_rx),
        .uart_tx             (u_uart_vip_if.uart_tx),
        .uart_irq            (u_uart_vip_if.uart_irq),

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

    // -------------------------------------------------------------------------
    // UVM Config DB Setup and Test Launch
    // -------------------------------------------------------------------------
    initial begin
        // Configure Single UART virtual interface for UVM
        uvm_config_db#(virtual uart_if)::set(null, "*", "uart_vif", u_uart_vip_if);

        // Run Single-IP UART UVM Test
        run_test("uart_soc_test");
    end

    // -------------------------------------------------------------------------
    // Verdi FSDB Waveform Dumping
    // -------------------------------------------------------------------------
    initial begin
        $fsdbDumpfile("dump_uart.fsdb");
        $fsdbDumpvars(0, tb_top, "+all");
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

    task automatic preload_uart_echo_firmware();
        // Clear IMEM with NOPs
        for (int i = 0; i < 16384; i++) begin
            dut.u_imem.mem_0[i] = 8'h13;
            dut.u_imem.mem_1[i] = 8'h00;
            dut.u_imem.mem_2[i] = 8'h00;
            dut.u_imem.mem_3[i] = 8'h00;
        end

        // 1. Configure MRAC CSR (0x7c0) -> 0xAAAAAAA6 (Region 1 = Memory, Region 4 = Device)
        write_imem_word(0, 32'haaaab0b7); // lui x1, 0xaaaab
        write_imem_word(1, 32'haa608093); // addi x1, x1, -1370 -> x1 = 0xaaaaaaa6
        write_imem_word(2, 32'h7c009073); // csrw 0x7c0, x1

        // 2. Configure UART (0x4000_6000) Base address in x1
        write_imem_word(3, 32'h400060b7); // lui x1, 0x40006
        write_imem_word(4, 32'h00300113); // addi x2, x0, 3
        write_imem_word(5, 32'h0020a623); // sw x2, 12(x1)  -> LCR (0x0C) = 3 (8N1)
        write_imem_word(6, 32'h00100513); // addi x10, x0, 1
        write_imem_word(7, 32'h00a0a223); // sw x10, 4(x1)  -> IER (0x04) = 1 (RX IRQ Enable)

        // 3. UART Hardware Echo Loop:
        // poll_rx:
        // lw x4, 20(x1)         -> Read LSR (0x4000_6014)
        write_imem_word(8,  32'h0140a203);
        // andi x5, x4, 1        -> Test Data Ready bit (LSR[0])
        write_imem_word(9,  32'h00127293);
        // beqz x5, -8           -> If no data, jump back to poll_rx
        write_imem_word(10, 32'hfe028ce3);
        // lw x6, 0(x1)          -> Read received byte from RBR (0x4000_6000)
        write_imem_word(11, 32'h0000a303);
        // sw x6, 0(x1)          -> Write byte directly to THR (0x4000_6000) to serialize on uart_tx
        write_imem_word(12, 32'h0060a023);
        // j -20                 -> Loop back to poll_rx
        write_imem_word(13, 32'hfedff06f);

        $display("\n[INIT] Preloaded UART Hardware Echo Firmware (14 instructions) into On-Chip IMEM (0x1000_0000)");
    endtask

    initial begin
        rst_n = 1'b0;
        preload_uart_echo_firmware();
        #100ns;
        rst_n = 1'b1;
        $display("[INIT] System Reset Released. VeeR EL2 core booted and running UART echo firmware.\n");
    end

    // Instruction retirement tracer
    always @(posedge clk) begin
        if (rst_n && trace_rv_i_valid_ip) begin
            $display("   [CPU TRACE @ %0t ps] PC = 0x%08h | Instr = 0x%08h",
                     $time, trace_rv_i_address_ip, trace_rv_i_insn_ip);
        end
    end

    // Safety watchdog timer
    initial begin
        #50_000_000; // 50ms maximum simulation limit
        $error("\n[WATCHDOG TIMEOUT] Simulation exceeded 50ms time limit!");
        $finish(2);
    end

endmodule : tb_top
