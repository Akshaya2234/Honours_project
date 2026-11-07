#!/bin/bash
# ==============================================================================
# Script to launch Verdi with automated waveform setup for Single-IP Timer SoC
# Project: Honours RISC-V SoC UVM Integration
# ==============================================================================

export DISPLAY="${DISPLAY:-:0}"
export VCS_HOME=/home/student/snps_tools_target/vcs/U-2023.03
export VERDI_HOME=/home/student/snps_tools_target/verdi/U-2023.03-SP1
export SNPSLMD_LICENSE_FILE=27021@14.139.1.126
export PATH=$VCS_HOME/bin:$VERDI_HOME/bin:$PATH

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
cd "$SCRIPT_DIR"

if [ ! -f "dump_timer.fsdb" ]; then
    echo "[ERROR] dump_timer.fsdb not found in $SCRIPT_DIR!"
    echo "Please run simulation first: make soc-timer-sim"
    exit 1
fi

if [ ! -d "simv.daidir" ]; then
    echo "[ERROR] simv.daidir not found in $SCRIPT_DIR!"
    echo "Please run compilation first: make soc-timer-compile"
    exit 1
fi

echo "=========================================================="
echo " Launching Verdi GUI with Automated Signal Setup..."
echo " Waveform : dump_timer.fsdb"
echo " Signals  : soc_timer_signals.rc"
echo " Database : simv.daidir"
echo " Auto-Play: load_timer_wave.cmd"
echo "=========================================================="

verdi -play load_timer_wave.cmd
