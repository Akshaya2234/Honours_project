# ==============================================================================
# Makefile for Synopsys VCS and Verdi Simulation
# Project: Honours RISC-V Real-Time Signal Processing & VGA Oscilloscope SoC
# ==============================================================================

SHELL := /bin/bash

# ------------------------------------------------------------------------------
# Tool & Environment Configuration
# ------------------------------------------------------------------------------
export VCS_HOME             ?= /home/student/snps_tools_target/vcs/U-2023.03
export VERDI_HOME           ?= /home/student/snps_tools_target/verdi/U-2023.03-SP1
export SNPSLMD_LICENSE_FILE ?= 27021@14.139.1.126
export PATH                 := $(VCS_HOME)/bin:$(VERDI_HOME)/bin:$(PATH)

# Directory Paths
ROOT_DIR := $(shell pwd)
RUN_DIR  := $(ROOT_DIR)/run

# ------------------------------------------------------------------------------
# Testbench Selection
# Options:
#   uart          - AXI Interconnect + AXI UART (tb_axi_interconnect_uart_top.sv)
#   interconnect  - AXI Interconnect 3x14 (tb_axi_interconnect_wrap_3x14.sv)
#   timer         - System Timer IP (tb_timer.sv)
#   gpio          - GPIO Controller IP (tb_gpio.sv)
#   fir           - FIR Filter IP (tb_fir_filter.sv)
#   sample_buffer - Dual-Port Sample Buffer (tb_sample_buffer.sv)
#   dma           - Autonomous DMA Controller (tb_dma_controller.sv)
#   vga           - VGA Oscilloscope Controller (tb_vga_controller.sv)
#   watchdog      - Watchdog Safety Monitor (tb_watchdog.sv)
#   pipeline      - End-to-End SoC Pipeline (tb_soc_pipeline.sv)
# ------------------------------------------------------------------------------
TEST ?= soc

ifeq ($(TEST), uart)
    FILELIST    := filelist_uart_interconnect.f
    COMPILE_LOG := compile_uart.log
    SIM_LOG     := sim_uart.log
    WAVE_FILE   := dump.fsdb
    RC_FILE     := uart_signals.rc
else ifeq ($(TEST), interconnect)
    FILELIST    := filelist.f
    COMPILE_LOG := compile_interconnect.log
    SIM_LOG     := sim_interconnect.log
    WAVE_FILE   := dump.fsdb
    RC_FILE     := 
else ifeq ($(TEST), timer)
    FILELIST    := filelist_timer.f
    COMPILE_LOG := compile_timer.log
    SIM_LOG     := sim_timer.log
    WAVE_FILE   := dump.fsdb
    RC_FILE     := 
else ifeq ($(TEST), gpio)
    FILELIST    := filelist_gpio.f
    COMPILE_LOG := compile_gpio.log
    SIM_LOG     := sim_gpio.log
    WAVE_FILE   := dump.fsdb
    RC_FILE     := 
else ifeq ($(TEST), fir)
    FILELIST    := filelist_fir.f
    COMPILE_LOG := compile_fir.log
    SIM_LOG     := sim_fir.log
    WAVE_FILE   := dump.fsdb
    RC_FILE     := 
else ifeq ($(TEST), sample_buffer)
    FILELIST    := filelist_sample_buffer.f
    COMPILE_LOG := compile_sample_buffer.log
    SIM_LOG     := sim_sample_buffer.log
    WAVE_FILE   := dump.fsdb
    RC_FILE     := 
else ifeq ($(TEST), dma)
    FILELIST    := filelist_dma.f
    COMPILE_LOG := compile_dma.log
    SIM_LOG     := sim_dma.log
    WAVE_FILE   := dump.fsdb
    RC_FILE     := 
else ifeq ($(TEST), vga)
    FILELIST    := filelist_vga.f
    COMPILE_LOG := compile_vga.log
    SIM_LOG     := sim_vga.log
    WAVE_FILE   := dump.fsdb
    RC_FILE     := 
else ifeq ($(TEST), vga_live)
    FILELIST    := filelist_vga_live.f
    COMPILE_LOG := compile_vga_live.log
    SIM_LOG     := sim_vga_live.log
    WAVE_FILE   := dump.fsdb
    RC_FILE     := 
else ifeq ($(TEST), watchdog)
    FILELIST    := filelist_watchdog.f
    COMPILE_LOG := compile_watchdog.log
    SIM_LOG     := sim_watchdog.log
    WAVE_FILE   := dump.fsdb
    RC_FILE     := 
else ifeq ($(TEST), pipeline)
    FILELIST    := filelist_pipeline.f
    COMPILE_LOG := compile_pipeline.log
    SIM_LOG     := sim_pipeline.log
    WAVE_FILE   := dump.fsdb
    RC_FILE     := 
else ifeq ($(TEST), soc)
    FILELIST    := filelist_soc.f
    COMPILE_LOG := compile_soc.log
    SIM_LOG     := sim_soc.log
    WAVE_FILE   := dump.fsdb
    RC_FILE     := 
else ifeq ($(TEST), hello)
    FILELIST    := filelist_soc_c_hello.f
    COMPILE_LOG := compile_c_hello.log
    SIM_LOG     := sim_c_hello.log
    WAVE_FILE   := dump.fsdb
    RC_FILE     := 
else ifeq ($(TEST), c_uart)
    FILELIST    := filelist_c_uart.f
    COMPILE_LOG := compile_c_uart.log
    SIM_LOG     := sim_c_uart.log
    WAVE_FILE   := dump.fsdb
    RC_FILE     := c_uart_signals.rc
else ifeq ($(TEST), uart_vip)
    FILELIST    := filelist_uart_vip.f
    COMPILE_LOG := compile_uart_vip.log
    SIM_LOG     := sim_uart_vip.log
    WAVE_FILE   := dump.fsdb
    RC_FILE     := 
else ifeq ($(TEST), pwm_vip)
    FILELIST    := filelist_pwm_vip.f
    COMPILE_LOG := compile_pwm_vip.log
    SIM_LOG     := sim_pwm_vip.log
    WAVE_FILE   := dump.fsdb
    RC_FILE     := 
else ifeq ($(TEST), gpio_vip)
    FILELIST    := filelist_gpio_vip.f
    COMPILE_LOG := compile_gpio_vip.log
    SIM_LOG     := sim_gpio_vip.log
    WAVE_FILE   := dump.fsdb
    RC_FILE     := 
else ifeq ($(TEST), spi_adc_vip)
    FILELIST    := filelist_spi_adc_vip.f
    COMPILE_LOG := compile_spi_adc_vip.log
    SIM_LOG     := sim_spi_adc_vip.log
    WAVE_FILE   := dump.fsdb
    RC_FILE     := 
else ifeq ($(TEST), timer_vip)
    FILELIST    := filelist_timer_vip.f
    COMPILE_LOG := compile_timer_vip.log
    SIM_LOG     := sim_timer_vip.log
    WAVE_FILE   := dump.fsdb
    RC_FILE     := 
else ifeq ($(TEST), soc_uart)
    FILELIST    := filelist_soc_uart.f
    COMPILE_LOG := compile_soc_uart.log
    SIM_LOG     := sim_soc_uart.log
    WAVE_FILE   := dump_uart.fsdb
    RC_FILE     := soc_uart_signals.rc
else ifeq ($(TEST), soc_gpio)
    FILELIST    := filelist_soc_gpio.f
    COMPILE_LOG := compile_soc_gpio.log
    SIM_LOG     := sim_soc_gpio.log
    WAVE_FILE   := dump_gpio.fsdb
    RC_FILE     := soc_gpio_signals.rc
else ifeq ($(TEST), soc_pwm)
    FILELIST    := filelist_soc_pwm.f
    COMPILE_LOG := compile_soc_pwm.log
    SIM_LOG     := sim_soc_pwm.log
    WAVE_FILE   := dump_pwm.fsdb
    RC_FILE     := soc_pwm_signals.rc
else ifeq ($(TEST), soc_timer)
    FILELIST    := filelist_soc_timer.f
    COMPILE_LOG := compile_soc_timer.log
    SIM_LOG     := sim_soc_timer.log
    WAVE_FILE   := dump_timer.fsdb
    RC_FILE     := soc_timer_signals.rc
else ifeq ($(TEST), soc_spi_adc)
    FILELIST    := filelist_soc_spi_adc.f
    COMPILE_LOG := compile_soc_spi_adc.log
    SIM_LOG     := sim_soc_spi_adc.log
    WAVE_FILE   := dump_spi_adc.fsdb
    RC_FILE     := soc_spi_adc_signals.rc
else
    $(error Unknown TEST '$(TEST)'. Valid options are: uart, interconnect, timer, gpio, fir, sample_buffer, dma, vga, vga_live, watchdog, pipeline, soc, hello, c_uart, uart_vip, pwm_vip, gpio_vip, spi_adc_vip, timer_vip, soc_uart, soc_gpio, soc_pwm, soc_timer, soc_spi_adc)
endif

# Extra flags for tests with C++/DPI or external libraries
ifeq ($(TEST), vga_live)
    VCS_EXTRA_FLAGS := -CFLAGS "-std=c++11 -DENABLE_VGA_OPENGL -I$(ROOT_DIR)/tb/vga_simulator -I$(ROOT_DIR)/tb/vga_simulator/freeglut/include" \
                       -LDFLAGS "-Wl,--whole-archive $(ROOT_DIR)/tb/vga_simulator/freeglut/lib64/libglut.a -Wl,--no-whole-archive -lGLU -lGL -lX11 -lXrandr -lXxf86vm -lXi -lpthread"
else ifeq ($(TEST), soc)
    VCS_EXTRA_FLAGS := -ntb_opts uvm-1.2
else ifeq ($(TEST), uart_vip)
    VCS_EXTRA_FLAGS := -ntb_opts uvm-1.2
else ifeq ($(TEST), pwm_vip)
    VCS_EXTRA_FLAGS := -ntb_opts uvm-1.2
else ifeq ($(TEST), gpio_vip)
    VCS_EXTRA_FLAGS := -ntb_opts uvm-1.2
else ifeq ($(TEST), spi_adc_vip)
    VCS_EXTRA_FLAGS := -ntb_opts uvm-1.2
else ifeq ($(TEST), timer_vip)
    VCS_EXTRA_FLAGS := -ntb_opts uvm-1.2
else ifeq ($(TEST), soc_uart)
    VCS_EXTRA_FLAGS := -ntb_opts uvm-1.2
else ifeq ($(TEST), soc_gpio)
    VCS_EXTRA_FLAGS := -ntb_opts uvm-1.2
else ifeq ($(TEST), soc_pwm)
    VCS_EXTRA_FLAGS := -ntb_opts uvm-1.2
else ifeq ($(TEST), soc_timer)
    VCS_EXTRA_FLAGS := -ntb_opts uvm-1.2
else ifeq ($(TEST), soc_spi_adc)
    VCS_EXTRA_FLAGS := -ntb_opts uvm-1.2
endif

# VCS Compilation and Simulation Flags
VCS_FLAGS := -full64 -sverilog -timescale=1ns/1ps -debug_access+all -kdb -v2k_generate
SIM_FLAGS := -no_save
VERDI_BIN ?= $(VERDI_HOME)/bin/verdi

.PHONY: all help compile sim run verdi wave clean \
        uart interconnect timer gpio fir sample_buffer dma vga vga-live vga-live-gui vga-live-verdi watchdog pipeline test-all \
        soc soc-compile soc-sim soc-verdi hello hello-verdi \
        soc-uart soc-uart-compile soc-uart-sim soc-uart-verdi \
        soc-gpio soc-gpio-compile soc-gpio-sim soc-gpio-verdi \
        soc-pwm soc-pwm-compile soc-pwm-sim soc-pwm-verdi \
        soc-timer soc-timer-compile soc-timer-sim soc-timer-verdi \
        soc-spi-adc soc-spi-adc-compile soc-spi-adc-sim soc-spi-adc-verdi \
        uart-verdi interconnect-verdi timer-verdi gpio-verdi fir-verdi \
        sample_buffer-verdi dma-verdi vga-verdi watchdog-verdi pipeline-verdi

# Default target: display help menu
all: help

# ------------------------------------------------------------------------------
# Generic Targets (Controlled via TEST=<name>)
# ------------------------------------------------------------------------------
compile:
	@echo "=========================================================="
	@echo " Compiling [$(TEST)] with Synopsys VCS..."
	@echo "=========================================================="
	cd $(RUN_DIR) && vcs $(VCS_FLAGS) $(VCS_EXTRA_FLAGS) -f $(FILELIST) -l $(COMPILE_LOG)

sim:
	@echo "=========================================================="
	@echo " Running Simulation for [$(TEST)]..."
	@echo "=========================================================="
	cd $(RUN_DIR) && ./simv $(SIM_FLAGS) -l $(SIM_LOG)

run: compile sim

verdi wave:
	@echo "=========================================================="
	@echo " Launching Verdi GUI for [$(TEST)]..."
	@echo "=========================================================="
	cd $(RUN_DIR) && $(VERDI_BIN) -dbdir simv.daidir -ssf $(WAVE_FILE) $(if $(RC_FILE),-sswr $(RC_FILE),) &

# ------------------------------------------------------------------------------
# Shortcut Targets for Individual IP Tests
# ------------------------------------------------------------------------------
timer:
	$(MAKE) run TEST=timer

gpio:
	$(MAKE) run TEST=gpio

fir:
	$(MAKE) run TEST=fir

sample_buffer:
	$(MAKE) run TEST=sample_buffer

dma:
	$(MAKE) run TEST=dma

vga:
	$(MAKE) run TEST=vga

vga-live:
	$(MAKE) run TEST=vga_live

vga-live-gui:
	VGA_GUI=1 $(MAKE) run TEST=vga_live

watchdog:
	$(MAKE) run TEST=watchdog

uart:
	$(MAKE) run TEST=uart

uart-vip:
	$(MAKE) run TEST=uart_vip

uart-vip-compile:
	$(MAKE) compile TEST=uart_vip

uart-vip-sim:
	$(MAKE) sim TEST=uart_vip

pwm-vip:
	$(MAKE) run TEST=pwm_vip

pwm-vip-compile:
	$(MAKE) compile TEST=pwm_vip

pwm-vip-sim:
	$(MAKE) sim TEST=pwm_vip

gpio-vip:
	$(MAKE) run TEST=gpio_vip

gpio-vip-compile:
	$(MAKE) compile TEST=gpio_vip

gpio-vip-sim:
	$(MAKE) sim TEST=gpio_vip

spi-adc-vip:
	$(MAKE) run TEST=spi_adc_vip

spi-adc-vip-compile:
	$(MAKE) compile TEST=spi_adc_vip

spi-adc-vip-sim:
	$(MAKE) sim TEST=spi_adc_vip

timer-vip:
	$(MAKE) run TEST=timer_vip

timer-vip-compile:
	$(MAKE) compile TEST=timer_vip

timer-vip-sim:
	$(MAKE) sim TEST=timer_vip

interconnect:
	$(MAKE) run TEST=interconnect

pipeline:
	$(MAKE) run TEST=pipeline

# ------------------------------------------------------------------------------
# Shortcut Targets for RISC-V SoC Top-Level
# ------------------------------------------------------------------------------
soc:
	$(MAKE) run TEST=soc

soc-compile:
	$(MAKE) compile TEST=soc

soc-sim:
	$(MAKE) sim TEST=soc

soc-verdi:
	$(MAKE) verdi TEST=soc

# Shortcut Targets for Single-IP UART SoC UVM Integration Test
soc-uart:
	$(MAKE) run TEST=soc_uart

soc-uart-compile:
	$(MAKE) compile TEST=soc_uart

soc-uart-sim:
	$(MAKE) sim TEST=soc_uart

soc-uart-verdi:
	cd $(RUN_DIR) && ./view_soc_uart.sh &

# Shortcut Targets for Single-IP GPIO SoC UVM Integration Test
soc-gpio:
	$(MAKE) run TEST=soc_gpio

soc-gpio-compile:
	$(MAKE) compile TEST=soc_gpio

soc-gpio-sim:
	$(MAKE) sim TEST=soc_gpio

soc-gpio-verdi:
	cd $(RUN_DIR) && ./view_soc_gpio.sh &

# Shortcut Targets for Single-IP PWM SoC UVM Integration Test
soc-pwm:
	$(MAKE) run TEST=soc_pwm

soc-pwm-compile:
	$(MAKE) compile TEST=soc_pwm

soc-pwm-sim:
	$(MAKE) sim TEST=soc_pwm

soc-pwm-verdi:
	cd $(RUN_DIR) && ./view_soc_pwm.sh &

# Shortcut Targets for Single-IP Timer SoC UVM Integration Test
soc-timer:
	$(MAKE) run TEST=soc_timer

soc-timer-compile:
	$(MAKE) compile TEST=soc_timer

soc-timer-sim:
	$(MAKE) sim TEST=soc_timer

soc-timer-verdi:
	cd $(RUN_DIR) && ./view_soc_timer.sh &

# Shortcut Targets for Single-IP SPI ADC SoC UVM Integration Test
soc-spi-adc:
	$(MAKE) run TEST=soc_spi_adc

soc-spi-adc-compile:
	$(MAKE) compile TEST=soc_spi_adc

soc-spi-adc-sim:
	$(MAKE) sim TEST=soc_spi_adc

soc-spi-adc-verdi:
	cd $(RUN_DIR) && ./view_soc_spi_adc.sh &

# Shortcut Targets for RISC-V C Firmware UART Test
c_uart:
	cd c_testing && ./build.sh
	$(MAKE) run TEST=c_uart

c_uart-compile:
	cd c_testing && ./build.sh
	$(MAKE) compile TEST=c_uart

c_uart-sim:
	$(MAKE) sim TEST=c_uart

c_uart-verdi:
	$(MAKE) verdi TEST=c_uart

# Shortcut Targets for RISC-V C Firmware Hello World
hello:
	$(MAKE) -C sw all
	$(MAKE) run TEST=hello

hello-verdi:
	$(MAKE) verdi TEST=hello

# Shortcut Targets to launch Verdi GUI for individual IP tests
uart-verdi:
	$(MAKE) verdi TEST=uart

interconnect-verdi:
	$(MAKE) verdi TEST=interconnect

pipeline-verdi:
	$(MAKE) verdi TEST=pipeline

timer-verdi:
	$(MAKE) verdi TEST=timer

gpio-verdi:
	$(MAKE) verdi TEST=gpio

fir-verdi:
	$(MAKE) verdi TEST=fir

sample_buffer-verdi:
	$(MAKE) verdi TEST=sample_buffer

dma-verdi:
	$(MAKE) verdi TEST=dma

vga-verdi:
	$(MAKE) verdi TEST=vga

vga-live-verdi:
	$(MAKE) verdi TEST=vga_live

watchdog-verdi:
	$(MAKE) verdi TEST=watchdog

# ------------------------------------------------------------------------------
# Run All Unit & Pipeline Tests
# ------------------------------------------------------------------------------
test-all:
	@echo "=================================================================="
	@echo " RUNNING ALL UNIT & PIPELINE VERIFICATION SUITES WITH VCS         "
	@echo "=================================================================="
	$(MAKE) run TEST=timer
	$(MAKE) run TEST=gpio
	$(MAKE) run TEST=fir
	$(MAKE) run TEST=sample_buffer
	$(MAKE) run TEST=dma
	$(MAKE) run TEST=vga
	$(MAKE) run TEST=watchdog
	$(MAKE) run TEST=pipeline
	@echo "=================================================================="
	@echo " ALL IP & SYSTEM PIPELINE TESTS COMPLETED SUCCESSFULLY!           "
	@echo "=================================================================="

# ------------------------------------------------------------------------------
# Cleanup
# ------------------------------------------------------------------------------
clean:
	@echo "Cleaning simulation files in $(RUN_DIR) and $(ROOT_DIR)..."
	rm -rf $(RUN_DIR)/simv $(RUN_DIR)/simv.daidir $(RUN_DIR)/csrc
	rm -rf $(RUN_DIR)/*.log $(RUN_DIR)/*.fsdb $(RUN_DIR)/novas* $(RUN_DIR)/verdiLog $(RUN_DIR)/ucli.key
	rm -rf $(RUN_DIR)/*.bmp $(RUN_DIR)/*.ppm $(ROOT_DIR)/*.bmp $(ROOT_DIR)/*.ppm
	rm -rf $(ROOT_DIR)/*.log $(ROOT_DIR)/simv $(ROOT_DIR)/simv.daidir $(ROOT_DIR)/csrc $(ROOT_DIR)/verdiLog $(ROOT_DIR)/fsdbreportLog $(ROOT_DIR)/ucli.key
	@echo "Clean completed."

# ------------------------------------------------------------------------------
# Help Menu
# ------------------------------------------------------------------------------
help:
	@echo "========================================================================"
	@echo "      RISC-V Real-Time Oscilloscope SoC Simulation Makefile             "
	@echo "========================================================================"
	@echo " Usage:"
	@echo "   make <target> [TEST=<test_name>]"
	@echo ""
	@echo " Available IP Verification Shortcuts:"
	@echo "   make timer         - Compile & Run System Timer test"
	@echo "   make gpio          - Compile & Run GPIO test"
	@echo "   make fir           - Compile & Run FIR Filter test"
	@echo "   make sample_buffer - Compile & Run Dual-Port Sample Buffer test"
	@echo "   make dma           - Compile & Run Autonomous DMA Controller test"
	@echo "   make vga           - Compile & Run VGA Controller timing test"
	@echo "   make vga-live      - Compile & Run Live VGA Simulator (saves frame BMP/PPM)"
	@echo "   make vga-live-gui  - Run Live VGA Simulator with interactive OpenGL window"
	@echo "   make watchdog      - Compile & Run Watchdog Monitor test"
	@echo "   make uart          - Compile & Run AXI UART test"
	@echo "   make interconnect  - Compile & Run AXI Interconnect test"
	@echo "   make pipeline      - Compile & Run End-to-End SoC Pipeline test"
	@echo "   make soc           - Compile & Run Complete Top-Level SoC test"
	@echo "   make hello         - Compile C firmware & Run UART Hello World test"
	@echo "   make test-all      - Run all testbenches sequentially"
	@echo ""
	@echo " Verdi Waveform Viewing:"
	@echo "   make verdi         - Open Verdi GUI for current TEST (default: soc)"
	@echo "   make wave          - Alias for 'make verdi'"
	@echo "   make soc-verdi     - Open Verdi GUI for Top-Level SoC waveform"
	@echo "   make hello-verdi   - Open Verdi GUI for C Hello World test waveform"
	@echo "   make vga-live-verdi- Open Verdi GUI for Live VGA simulation waveform"
	@echo "   make <ip>-verdi    - Open Verdi GUI for specific IP (e.g. uart-verdi, dma-verdi)"
	@echo "   make verdi TEST=<name> - Open Verdi GUI for specified test"
	@echo ""
	@echo " Other Commands:"
	@echo "   make clean         - Remove simulation outputs, logs, waveforms"
	@echo "   make help          - Display this help message"
	@echo "========================================================================"
